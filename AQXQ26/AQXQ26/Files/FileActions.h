//
//  FileActions.h
//  WorkSpace
//
//  Rename / move / share / preview / delete flows shared by the file list,
//  file detail and attachment lists, so every entry point behaves the same.
//

#import <UIKit/UIKit.h>

@class FileItem;

NS_ASSUME_NONNULL_BEGIN

@interface FileActions : NSObject
+ (void)rename:(FileItem *)file from:(UIViewController *)vc;
+ (void)move:(FileItem *)file from:(UIViewController *)vc;
+ (void)share:(FileItem *)file from:(UIViewController *)vc source:(nullable id)source;
/// Quick Look when possible, otherwise explains and offers Share.
+ (void)preview:(FileItem *)file among:(nullable NSArray<FileItem *> *)files from:(UIViewController *)vc;
+ (void)confirmDelete:(FileItem *)file from:(UIViewController *)vc completion:(nullable void (^)(void))completion;
+ (void)toggleFavorite:(FileItem *)file from:(UIViewController *)vc;
/// Context menu with all of the above.
+ (UIMenu *)menuFor:(FileItem *)file among:(nullable NSArray<FileItem *> *)files from:(UIViewController *)vc;
@end

NS_ASSUME_NONNULL_END
