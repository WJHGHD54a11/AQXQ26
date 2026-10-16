//
//  FilePreviewViewController.m
//  WorkSpace
//

#import "FilePreviewViewController.h"
#import "FileManagerService.h"
#import "RecentManager.h"
#import "FileItem.h"

/// Quick Look item with the user-facing name instead of the stored UUID name.
@interface WSPreviewItem : NSObject <QLPreviewItem>
@property (nonatomic, strong) NSURL *previewItemURL;
@property (nonatomic, strong) NSString *previewItemTitle;
@end
@implementation WSPreviewItem
@end

@interface FilePreviewViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate>
@property (nonatomic, copy) NSArray<WSPreviewItem *> *items;
@property (nonatomic, copy) NSArray<FileItem *> *files;
@end

@implementation FilePreviewViewController

+ (BOOL)canPreview:(FileItem *)file {
    if (![FileManagerService.shared fileExists:file]) return NO;
    return [QLPreviewController canPreviewItem:[FileManagerService.shared urlFor:file]];
}

- (instancetype)initWithFiles:(NSArray<FileItem *> *)files index:(NSUInteger)index {
    if ((self = [super init])) {
        NSMutableArray *items = NSMutableArray.new, *kept = NSMutableArray.new;
        NSUInteger start = 0;
        for (NSUInteger i = 0; i < files.count; i++) {
            FileItem *f = files[i];
            if (![FilePreviewViewController canPreview:f]) continue;
            if (i == index) start = items.count;
            WSPreviewItem *item = WSPreviewItem.new;
            item.previewItemURL = [FileManagerService.shared urlFor:f];
            item.previewItemTitle = f.name;
            [items addObject:item];
            [kept addObject:f];
        }
        _items = items;
        _files = kept;
        self.dataSource = self;
        self.delegate = self;
        self.currentPreviewItemIndex = start;
    }
    return self;
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.items.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.items.count) return nil;
    FileItem *file = self.files[index];
    if (!file.isDeleted) [RecentManager.shared markOpened:file];
    return self.items[index];
}

/// Read-only: edits made in Quick Look markup are not written back.
- (QLPreviewItemEditingMode)previewController:(QLPreviewController *)controller editingModeForPreviewItem:(id<QLPreviewItem>)previewItem {
    return QLPreviewItemEditingModeDisabled;
}

@end
