//
//  ScheduleDetailViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Schedule;

NS_ASSUME_NONNULL_BEGIN

@interface ScheduleDetailViewController : UIViewController
- (instancetype)initWithSchedule:(Schedule *)schedule;
@end

NS_ASSUME_NONNULL_END
