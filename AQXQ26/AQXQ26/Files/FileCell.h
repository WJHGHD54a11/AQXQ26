//
//  FileCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class FileItem;

NS_ASSUME_NONNULL_BEGIN

@interface FileCell : UICollectionViewListCell
- (void)configureWithFile:(FileItem *)file;
@end

NS_ASSUME_NONNULL_END
