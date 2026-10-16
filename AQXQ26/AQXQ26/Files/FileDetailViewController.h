//
//  FileDetailViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class FileItem;

NS_ASSUME_NONNULL_BEGIN

/// Name, type, size, dates, location, links + preview / share / favorite / rename / move / delete.
@interface FileDetailViewController : UIViewController
- (instancetype)initWithFile:(FileItem *)file;
@end

NS_ASSUME_NONNULL_END
