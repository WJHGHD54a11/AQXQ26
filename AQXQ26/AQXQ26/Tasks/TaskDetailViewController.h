//
//  TaskDetailViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Task;

NS_ASSUME_NONNULL_BEGIN

/// Overview, status / priority menus, checklist, subtasks with progress, attachments, notes, history.
@interface TaskDetailViewController : UIViewController
- (instancetype)initWithTask:(Task *)task;
@property (nonatomic, strong, readonly) Task *task;
@end

NS_ASSUME_NONNULL_END
