//
//  ScheduleEditViewController.h
//  WorkSpace
//

#import "WSFormViewController.h"

@class Schedule;

NS_ASSUME_NONNULL_BEGIN

@interface ScheduleEditViewController : WSFormViewController
- (instancetype)initWithSchedule:(nullable Schedule *)schedule day:(nullable NSDate *)day;
@end

NS_ASSUME_NONNULL_END
