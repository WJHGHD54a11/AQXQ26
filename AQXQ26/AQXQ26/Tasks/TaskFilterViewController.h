//
//  TaskFilterViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>
#import "TaskManager.h"

@class Project, Tag;

NS_ASSUME_NONNULL_BEGIN

/// Sheet for choosing filter (+ project / tag) and sort.
@interface TaskFilterViewController : UITableViewController
- (instancetype)initWithFilter:(TaskFilter)filter sort:(TaskSort)sort project:(nullable Project *)project tag:(nullable Tag *)tag;
@property (nonatomic, copy, nullable) void (^onApply)(TaskFilter filter, TaskSort sort, Project * _Nullable project, Tag * _Nullable tag);
@end

NS_ASSUME_NONNULL_END
