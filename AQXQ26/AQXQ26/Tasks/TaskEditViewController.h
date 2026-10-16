//
//  TaskEditViewController.h
//  WorkSpace
//

#import "WSFormViewController.h"

@class Task, Project;

NS_ASSUME_NONNULL_BEGIN

/// Create (task == nil) or edit a task.
@interface TaskEditViewController : WSFormViewController
- (instancetype)initWithTask:(nullable Task *)task project:(nullable Project *)project parent:(nullable Task *)parent;
/// Set after a successful create.
@property (nonatomic, strong, readonly, nullable) Task *savedTask;
@end

NS_ASSUME_NONNULL_END
