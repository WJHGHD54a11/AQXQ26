//
//  FileImportManager.m
//  WorkSpace
//

#import "FileImportManager.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "FileManagerService.h"
#import "DataManager.h"
#import "ActivityManager.h"
#import "FileItem.h"
#import "Project.h"
#import "Task.h"

@implementation FileImportResult
@end

/// What the copy step produced for one source file, before touching Core Data.
@interface WSCopiedFile : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *storedName;
@property (nonatomic, copy, nullable) NSString *ext;
@property (nonatomic, copy, nullable) NSString *typeIdentifier;
@property (nonatomic) int64_t size;
@property (nonatomic, strong, nullable) NSDate *created;
@end
@implementation WSCopiedFile
@end

@interface FileImportManager ()
@property (nonatomic, strong, nullable) Project *pendingProject;
@property (nonatomic, strong, nullable) Task *pendingTask;
@property (nonatomic, copy, nullable) NSString *pendingFolder;
@property (nonatomic, copy, nullable) void (^pendingCompletion)(FileImportResult *);
@end

@implementation FileImportManager {
    dispatch_queue_t _queue;
}

+ (instancetype)shared {
    static FileImportManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (instancetype)init {
    if ((self = [super init])) {
        _queue = dispatch_queue_create("workspace.file-import", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Picker

- (void)presentPickerFrom:(UIViewController *)presenter project:(Project *)project task:(Task *)task folder:(NSString *)folder completion:(void (^)(FileImportResult *))completion {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem] asCopy:YES];
    picker.allowsMultipleSelection = YES;
    picker.delegate = self;
    self.pendingProject = project;
    self.pendingTask = task;
    self.pendingFolder = folder;
    self.pendingCompletion = completion;
    [presenter presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self importURLs:urls project:self.pendingProject task:self.pendingTask folder:self.pendingFolder completion:self.pendingCompletion];
    [self clearPending];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self clearPending];
}

- (void)clearPending {
    self.pendingProject = nil;
    self.pendingTask = nil;
    self.pendingFolder = nil;
    self.pendingCompletion = nil;
}

#pragma mark - Import

- (void)importURLs:(NSArray<NSURL *> *)urls project:(Project *)project task:(Task *)task folder:(NSString *)folder completion:(void (^)(FileImportResult *))completion {
    NSURL *store = FileManagerService.shared.storageDirectory;
    dispatch_async(_queue, ^{
        NSMutableArray<WSCopiedFile *> *copied = NSMutableArray.new;
        NSMutableArray<NSString *> *failed = NSMutableArray.new;
        for (NSURL *url in urls) {
            WSCopiedFile *file = [self copy:url into:store];
            if (file) [copied addObject:file];
            else [failed addObject:url.lastPathComponent ?: @"?"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self commit:copied failed:failed project:project task:task folder:folder completion:completion];
        });
    });
}

/// Runs on the import queue. Copies through NSFileCoordinator so iCloud / provider files are materialised.
- (WSCopiedFile *)copy:(NSURL *)source into:(NSURL *)store {
    BOOL scoped = [source startAccessingSecurityScopedResource];
    __block WSCopiedFile *result = nil;
    NSError *coordError = nil;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [coordinator coordinateReadingItemAtURL:source options:NSFileCoordinatorReadingWithoutChanges error:&coordError byAccessor:^(NSURL *readURL) {
        NSNumber *isDir = nil;
        [readURL getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil];
        if (isDir.boolValue) return; // folders are not supported; reported as failed

        NSString *ext = readURL.pathExtension.lowercaseString;
        NSString *stored = ext.length ? [NSUUID.UUID.UUIDString stringByAppendingPathExtension:ext] : NSUUID.UUID.UUIDString;
        NSURL *dest = [store URLByAppendingPathComponent:stored];
        NSError *copyError = nil;
        if (![NSFileManager.defaultManager copyItemAtURL:readURL toURL:dest error:&copyError]) {
            NSLog(@"[Import] copy %@ failed: %@", readURL.lastPathComponent, copyError);
            return;
        }
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:dest.path error:nil];
        UTType *type = ext.length ? [UTType typeWithFilenameExtension:ext] : nil;

        WSCopiedFile *f = [[WSCopiedFile alloc] init];
        f.name = readURL.lastPathComponent.length ? readURL.lastPathComponent : WSText(@"Untitled");
        f.storedName = stored;
        f.ext = ext.length ? ext : nil;
        f.typeIdentifier = type.identifier;
        f.size = [attrs[NSFileSize] longLongValue];
        NSDate *created = nil;
        [readURL getResourceValue:&created forKey:NSURLCreationDateKey error:nil];
        f.created = created;
        result = f;
    }];
    if (coordError) NSLog(@"[Import] coordinate %@ failed: %@", source.lastPathComponent, coordError);
    if (scoped) [source stopAccessingSecurityScopedResource];
    return result;
}

- (void)commit:(NSArray<WSCopiedFile *> *)copied failed:(NSArray<NSString *> *)failed project:(Project *)project task:(Task *)task
        folder:(NSString *)folder completion:(void (^)(FileImportResult *))completion {
    NSMutableArray<FileItem *> *items = NSMutableArray.new;
    NSMutableArray<NSString *> *failedNames = [failed mutableCopy];
    BOOL projectAlive = project && !project.isDeleted;
    BOOL taskAlive = task && !task.isDeleted;

    for (WSCopiedFile *f in copied) {
        FileItem *item = [DataManager.shared insertEntity:@"FileItem"];
        item.name = f.name;
        item.storedName = f.storedName;
        item.fileExtension = f.ext;
        item.typeIdentifier = f.typeIdentifier;
        item.byteSize = f.size;
        item.folder = folder.length ? folder : nil;
        if (f.created) item.createdAt = f.created;
        item.lastOpenedAt = NSDate.date;
        if (projectAlive) item.project = project;
        if (taskAlive) {
            item.task = task;
            if (!item.project) item.project = task.project;
        }
        NSString *where = projectAlive ? project.name : (taskAlive ? task.title : [FileManagerService sizeText:f.size]);
        [ActivityManager.shared record:ActivityTypeFileImported title:f.name detail:where objectId:item.uuid];
        [items addObject:item];
    }
    if (projectAlive && items.count) project.updatedAt = NSDate.date;
    if (taskAlive && items.count) task.updatedAt = NSDate.date;

    NSError *error = nil;
    if (items.count && ![DataManager.shared save:&error]) {
        // Rows rolled back: remove the copied bytes so nothing is orphaned.
        NSURL *store = FileManagerService.shared.storageDirectory;
        for (WSCopiedFile *f in copied) {
            [NSFileManager.defaultManager removeItemAtURL:[store URLByAppendingPathComponent:f.storedName] error:nil];
            [failedNames addObject:f.name];
        }
        [items removeAllObjects];
    }

    FileImportResult *result = [[FileImportResult alloc] init];
    result.imported = items;
    result.failedNames = failedNames;
    if (completion) completion(result);
}

@end
