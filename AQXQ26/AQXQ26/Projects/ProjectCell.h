//
//  ProjectCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Project;

NS_ASSUME_NONNULL_BEGIN

/// Card with color bar, name, status pill, due date, progress ring and task counts.
@interface ProjectCell : UICollectionViewListCell
- (void)configureWithProject:(Project *)project;
@end

NS_ASSUME_NONNULL_END
