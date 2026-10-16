//
//  TaskCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Task;

NS_ASSUME_NONNULL_BEGIN

/// Task row: completion button, title, due / project / checklist meta, priority pill.
@interface TaskCell : UICollectionViewListCell

- (void)configureWithTask:(Task *)task showProject:(BOOL)showProject;
@property (nonatomic, copy, nullable) void (^onToggleComplete)(void);

@end

NS_ASSUME_NONNULL_END
