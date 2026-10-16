//
//  FilePreviewViewController.h
//  WorkSpace
//

#import <QuickLook/QuickLook.h>

@class FileItem;

NS_ASSUME_NONNULL_BEGIN

/// Quick Look over WorkSpace files; swipes through `files` starting at `index`.
@interface FilePreviewViewController : QLPreviewController
- (instancetype)initWithFiles:(NSArray<FileItem *> *)files index:(NSUInteger)index;
/// NO when the file is missing on disk or Quick Look can't show it.
+ (BOOL)canPreview:(FileItem *)file;
@end

NS_ASSUME_NONNULL_END
