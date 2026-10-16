//
//  FileImportManager.h
//  WorkSpace
//
//  Copies picked documents into the app's store on a background queue and
//  creates FileItem rows. Accepts any file type.
//

#import <UIKit/UIKit.h>

@class FileItem, Project, Task;

NS_ASSUME_NONNULL_BEGIN

@interface FileImportResult : NSObject
@property (nonatomic, copy) NSArray<FileItem *> *imported;
@property (nonatomic, copy) NSArray<NSString *> *failedNames;
@end

@interface FileImportManager : NSObject <UIDocumentPickerDelegate>

+ (instancetype)shared;

/// Presents the system document picker (all types, multiple selection) from `presenter`.
/// Imported files are linked to `project` / `task` / `folder` when given.
- (void)presentPickerFrom:(UIViewController *)presenter
                  project:(nullable Project *)project
                     task:(nullable Task *)task
                   folder:(nullable NSString *)folder
               completion:(nullable void (^)(FileImportResult *result))completion;

/// Imports URLs directly (Share/Open In, drag & drop). Security-scoped URLs are handled.
- (void)importURLs:(NSArray<NSURL *> *)urls project:(nullable Project *)project task:(nullable Task *)task
            folder:(nullable NSString *)folder completion:(nullable void (^)(FileImportResult *result))completion;

@end

NS_ASSUME_NONNULL_END
