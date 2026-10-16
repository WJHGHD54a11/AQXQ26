//
//  FileManagerService.h
//  WorkSpace
//
//  Owns the on-disk store (Application Support/WorkSpace/Files/<storedName>)
//  and every FileItem mutation. File bytes never go through Core Data.
//

#import <UIKit/UIKit.h>
#import "AppConstants.h"

@class FileItem, Project;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FileCategory) {
    FileCategoryAll = 0,
    FileCategoryImages,
    FileCategoryDocuments,
    FileCategoryOther,
};

typedef NS_ENUM(NSInteger, FileSort) {
    FileSortModified = 0,
    FileSortName,
    FileSortSize,
    FileSortType,
};

FOUNDATION_EXPORT NSString *FileCategoryTitle(FileCategory category);
FOUNDATION_EXPORT NSString *FileSortTitle(FileSort sort);

@interface FileStorageStats : NSObject
@property (nonatomic) NSUInteger totalFiles;
@property (nonatomic) int64_t totalBytes;
@property (nonatomic) NSUInteger imageCount;
@property (nonatomic) int64_t imageBytes;
@property (nonatomic) NSUInteger documentCount;
@property (nonatomic) int64_t documentBytes;
@property (nonatomic) NSUInteger otherCount;
@property (nonatomic) int64_t otherBytes;
@end

@interface FileManagerService : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSURL *storageDirectory;

- (NSArray<FileItem *> *)filesIn:(FileCategory)category folder:(nullable NSString *)folder
                            text:(nullable NSString *)text sort:(FileSort)sort favoritesOnly:(BOOL)favoritesOnly;
/// Distinct user folders, sorted.
- (NSArray<NSString *> *)folders;
- (FileStorageStats *)storageStats;

- (NSURL *)urlFor:(FileItem *)file;
- (BOOL)fileExists:(FileItem *)file;

- (BOOL)rename:(FileItem *)file to:(NSString *)name error:(NSError **)error;
/// folder nil / empty = root.
- (BOOL)move:(FileItem *)file toFolder:(nullable NSString *)folder error:(NSError **)error;
- (BOOL)deleteFile:(FileItem *)file error:(NSError **)error;

#pragma mark Type helpers
+ (FileCategory)categoryForExtension:(nullable NSString *)ext;
/// "PDF Document", "PNG Image"... from UTType.
+ (NSString *)typeDescriptionFor:(FileItem *)file;
+ (NSString *)symbolFor:(FileItem *)file;
+ (NSString *)sizeText:(int64_t)bytes;

/// Small thumbnail for images (cached, generated off the main thread). Calls back on main.
- (void)thumbnailFor:(FileItem *)file size:(CGSize)size completion:(void (^)(UIImage * _Nullable image))completion;

@end

NS_ASSUME_NONNULL_END
