//
//  FileManagerService.m
//  WorkSpace
//

#import "FileManagerService.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <QuickLookThumbnailing/QuickLookThumbnailing.h>
#import "DataManager.h"
#import "DataMigrationManager.h"
#import "ActivityManager.h"
#import "FileItem.h"

NSString *FileCategoryTitle(FileCategory category) {
    NSArray *titles = @[WSText(@"All"), WSText(@"Images"), WSText(@"Documents"), WSText(@"Other")];
    return category < (NSInteger)titles.count ? titles[category] : @"";
}

NSString *FileSortTitle(FileSort sort) {
    NSArray *titles = @[WSText(@"Date Modified"), WSText(@"Name"), WSText(@"Size"), WSText(@"Kind")];
    return sort < (NSInteger)titles.count ? titles[sort] : @"";
}

@implementation FileStorageStats
@end

@implementation FileManagerService {
    NSCache<NSString *, UIImage *> *_thumbnails;
}

+ (instancetype)shared {
    static FileManagerService *service;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ service = [[self alloc] init]; });
    return service;
}

- (instancetype)init {
    if ((self = [super init])) {
        _storageDirectory = [[DataMigrationManager dataDirectoryURL] URLByAppendingPathComponent:@"Files" isDirectory:YES];
        [NSFileManager.defaultManager createDirectoryAtURL:_storageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        // Imported files are user data; keep them out of iCloud backup exclusion but protect at rest.
        [_storageDirectory setResourceValue:NSFileProtectionCompleteUntilFirstUserAuthentication forKey:NSURLFileProtectionKey error:nil];
        _thumbnails = [[NSCache alloc] init];
        _thumbnails.countLimit = 200;
    }
    return self;
}

#pragma mark - Type helpers

+ (NSSet<NSString *> *)imageExtensions {
    static NSSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = [NSSet setWithArray:@[@"jpg", @"jpeg", @"png", @"heic", @"heif", @"gif", @"webp", @"tif", @"tiff", @"bmp"]]; });
    return set;
}

+ (NSSet<NSString *> *)documentExtensions {
    static NSSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        set = [NSSet setWithArray:@[@"pdf", @"txt", @"rtf", @"md", @"doc", @"docx", @"xls", @"xlsx", @"csv", @"ppt", @"pptx",
                                    @"pages", @"numbers", @"key", @"json", @"html", @"xml"]];
    });
    return set;
}

+ (FileCategory)categoryForExtension:(NSString *)ext {
    NSString *e = ext.lowercaseString;
    if ([[self imageExtensions] containsObject:e]) return FileCategoryImages;
    if ([[self documentExtensions] containsObject:e]) return FileCategoryDocuments;
    return FileCategoryOther;
}

+ (NSString *)typeDescriptionFor:(FileItem *)file {
    UTType *type = file.typeIdentifier ? [UTType typeWithIdentifier:file.typeIdentifier] : nil;
    if (!type && file.fileExtension.length) type = [UTType typeWithFilenameExtension:file.fileExtension];
    if (type.localizedDescription.length) return type.localizedDescription;
    return file.fileExtension.length ? [NSString stringWithFormat:WSText(@"%@ File"), file.fileExtension.uppercaseString] : WSText(@"File");
}

+ (NSString *)symbolFor:(FileItem *)file {
    NSString *e = file.fileExtension.lowercaseString ?: @"";
    if ([[self imageExtensions] containsObject:e]) return @"photo";
    if ([e isEqualToString:@"pdf"]) return @"doc.richtext";
    if ([@[@"xls", @"xlsx", @"csv", @"numbers"] containsObject:e]) return @"tablecells";
    if ([@[@"ppt", @"pptx", @"key"] containsObject:e]) return @"rectangle.on.rectangle.angled";
    if ([@[@"zip", @"rar", @"7z", @"gz", @"tar"] containsObject:e]) return @"doc.zipper";
    if ([@[@"mp3", @"m4a", @"wav", @"aac"] containsObject:e]) return @"waveform";
    if ([@[@"mp4", @"mov", @"m4v"] containsObject:e]) return @"film";
    if ([[self documentExtensions] containsObject:e]) return @"doc.text";
    return @"doc";
}

+ (NSString *)sizeText:(int64_t)bytes {
    return [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleFile];
}

#pragma mark - Query

- (NSPredicate *)predicateForCategory:(FileCategory)category {
    NSArray *images = [FileManagerService imageExtensions].allObjects;
    NSArray *docs = [FileManagerService documentExtensions].allObjects;
    switch (category) {
        case FileCategoryAll:       return nil;
        case FileCategoryImages:    return [NSPredicate predicateWithFormat:@"fileExtension IN[c] %@", images];
        case FileCategoryDocuments: return [NSPredicate predicateWithFormat:@"fileExtension IN[c] %@", docs];
        case FileCategoryOther:     return [NSPredicate predicateWithFormat:@"fileExtension == nil OR NOT (fileExtension IN[c] %@)",
                                            [images arrayByAddingObjectsFromArray:docs]];
    }
    return nil;
}

- (NSArray<FileItem *> *)filesIn:(FileCategory)category folder:(NSString *)folder text:(NSString *)text sort:(FileSort)sort favoritesOnly:(BOOL)favoritesOnly {
    NSMutableArray *predicates = NSMutableArray.new;
    NSPredicate *p = [self predicateForCategory:category];
    if (p) [predicates addObject:p];
    if (folder.length) [predicates addObject:[NSPredicate predicateWithFormat:@"folder == %@", folder]];
    if (favoritesOnly) [predicates addObject:[NSPredicate predicateWithFormat:@"isFavorite == YES"]];
    NSString *q = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (q.length) [predicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR folder CONTAINS[cd] %@", q, q]];

    NSFetchRequest *request = [FileItem fetchRequest];
    if (predicates.count) request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    switch (sort) {
        case FileSortModified: request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedAt" ascending:NO]]; break;
        case FileSortName:     request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)]]; break;
        case FileSortSize:     request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"byteSize" ascending:NO]]; break;
        case FileSortType:     request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"fileExtension" ascending:YES],
                                                           [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)]]; break;
    }
    request.fetchBatchSize = 50;
    return [DataManager.shared fetch:request];
}

- (NSArray<NSString *> *)folders {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FileItem"];
    request.predicate = [NSPredicate predicateWithFormat:@"folder != nil AND folder != ''"];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"folder"];
    request.returnsDistinctResults = YES;
    NSArray *names = [[DataManager.shared fetch:request] valueForKey:@"folder"];
    return [names sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
}

/// Aggregated in SQLite (sum per category) so no FileItem objects are materialised.
- (FileStorageStats *)storageStats {
    FileStorageStats *stats = [[FileStorageStats alloc] init];
    NSExpressionDescription *sum = [[NSExpressionDescription alloc] init];
    sum.name = @"bytes";
    sum.expression = [NSExpression expressionForFunction:@"sum:" arguments:@[[NSExpression expressionForKeyPath:@"byteSize"]]];
    sum.expressionResultType = NSInteger64AttributeType;
    NSExpressionDescription *count = [[NSExpressionDescription alloc] init];
    count.name = @"files";
    count.expression = [NSExpression expressionForFunction:@"count:" arguments:@[[NSExpression expressionForKeyPath:@"uuid"]]];
    count.expressionResultType = NSInteger64AttributeType;

    for (NSNumber *c in @[@(FileCategoryImages), @(FileCategoryDocuments), @(FileCategoryOther)]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"FileItem"];
        request.predicate = [self predicateForCategory:c.integerValue];
        request.resultType = NSDictionaryResultType;
        request.propertiesToFetch = @[sum, count];
        NSDictionary *row = [DataManager.shared fetch:request].firstObject;
        NSUInteger n = [row[@"files"] unsignedIntegerValue];
        int64_t bytes = [row[@"bytes"] longLongValue];
        switch (c.integerValue) {
            case FileCategoryImages:    stats.imageCount = n;    stats.imageBytes = bytes;    break;
            case FileCategoryDocuments: stats.documentCount = n; stats.documentBytes = bytes; break;
            default:                    stats.otherCount = n;    stats.otherBytes = bytes;    break;
        }
    }
    stats.totalFiles = stats.imageCount + stats.documentCount + stats.otherCount;
    stats.totalBytes = stats.imageBytes + stats.documentBytes + stats.otherBytes;
    return stats;
}

#pragma mark - Disk

- (NSURL *)urlFor:(FileItem *)file {
    return [self.storageDirectory URLByAppendingPathComponent:file.storedName.length ? file.storedName : @"_missing"];
}

- (BOOL)fileExists:(FileItem *)file {
    return file.storedName.length && [NSFileManager.defaultManager fileExistsAtPath:[self urlFor:file].path];
}

- (NSError *)error:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:8 userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Mutations

- (BOOL)rename:(FileItem *)file to:(NSString *)name error:(NSError **)error {
    NSString *clean = [[name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]
                       stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    if (clean.length == 0) {
        if (error) *error = [self error:WSText(@"File name can't be empty.")];
        return NO;
    }
    // Keep the original extension so previews keep working.
    if (file.fileExtension.length && ![clean.pathExtension.lowercaseString isEqualToString:file.fileExtension.lowercaseString]) {
        clean = [clean stringByAppendingPathExtension:file.fileExtension];
    }
    file.name = clean;
    file.modifiedAt = NSDate.date;
    return [DataManager.shared save:error];
}

- (BOOL)move:(FileItem *)file toFolder:(NSString *)folder error:(NSError **)error {
    NSString *clean = [folder stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    file.folder = clean.length ? clean : nil;
    file.modifiedAt = NSDate.date;
    return [DataManager.shared save:error];
}

- (BOOL)deleteFile:(FileItem *)file error:(NSError **)error {
    if (!file || file.isDeleted) return YES;
    NSURL *url = [self urlFor:file];
    NSString *uuid = file.uuid, *name = file.name;
    [ActivityManager.shared record:ActivityTypeFileDeleted title:name detail:[FileManagerService sizeText:file.byteSize] objectId:uuid];
    [DataManager.shared deleteObject:file];
    if (![DataManager.shared save:error]) return NO;
    [_thumbnails removeObjectForKey:uuid];
    // Remove bytes after the row is gone; a leftover file is harmless, a dangling row is not.
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [NSFileManager.defaultManager removeItemAtURL:url error:nil];
    });
    return YES;
}

#pragma mark - Thumbnails

- (void)thumbnailFor:(FileItem *)file size:(CGSize)size completion:(void (^)(UIImage *))completion {
    NSString *key = file.uuid;
    UIImage *cached = key ? [_thumbnails objectForKey:key] : nil;
    if (cached || !key || ![self fileExists:file]) {
        completion(cached);
        return;
    }
    CGFloat scale = UIScreen.mainScreen.scale;
    QLThumbnailGenerationRequest *request = [[QLThumbnailGenerationRequest alloc] initWithFileAtURL:[self urlFor:file] size:size scale:scale
                                                                             representationTypes:QLThumbnailGenerationRequestRepresentationTypeThumbnail];
    [QLThumbnailGenerator.sharedGenerator generateBestRepresentationForRequest:request
                                                             completionHandler:^(QLThumbnailRepresentation *thumbnail, NSError *error) {
        UIImage *image = thumbnail.UIImage;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) [self->_thumbnails setObject:image forKey:key];
            completion(image);
        });
    }];
}

@end
