//
//  TaskListViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>
#import "TaskManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Tasks tab: filter chips, sort menu, search, swipe complete / delete, manual reorder.
@interface TaskListViewController : UIViewController
- (instancetype)init;
/// Opens with a preset filter (used by Dashboard summary tiles).
- (instancetype)initWithFilter:(TaskFilter)filter;
- (void)applyFilter:(TaskFilter)filter;
@end

NS_ASSUME_NONNULL_END
