//
//  Task+Logic.h
//  WorkSpace
//
//  Derived values used by cells, detail screens and dashboard counts.
//

#import "Task.h"

NS_ASSUME_NONNULL_BEGIN

@interface Task (Logic)

@property (nonatomic, readonly) BOOL isOpen;          // To Do or In Progress
@property (nonatomic, readonly) BOOL isOverdue;
@property (nonatomic, readonly) BOOL isDueToday;
@property (nonatomic, readonly) NSUInteger checklistDoneCount;
@property (nonatomic, readonly) NSUInteger subtaskDoneCount;
/// "3 / 5 subtasks completed", nil when there are none.
@property (nonatomic, readonly, nullable) NSString *subtaskProgressText;
/// "Today 14:00", "Tomorrow", "Mon, 12 Oct"...
@property (nonatomic, readonly, nullable) NSString *dueText;

+ (NSString *)relativeDayText:(NSDate *)date includeTime:(BOOL)includeTime;

@end

NS_ASSUME_NONNULL_END
