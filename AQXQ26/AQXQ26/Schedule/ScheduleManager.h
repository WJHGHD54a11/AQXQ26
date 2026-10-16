//
//  ScheduleManager.h
//  WorkSpace
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class Schedule;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ScheduleScope) {
    ScheduleScopeToday = 0,
    ScheduleScopeUpcoming,   // after today, planned
    ScheduleScopeDay,        // a chosen day (date list)
    ScheduleScopePast,       // completed / cancelled / ended
};

@interface ScheduleDraft : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic, copy, nullable) NSString *location;
@property (nonatomic) ScheduleKind kind;
@property (nonatomic) RepeatRule repeatRule;
@property (nonatomic) int32_t reminderOffset;   // minutes before; -1 none
@property (nonatomic) BOOL allDay;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong, nullable) NSDate *endTime;
+ (instancetype)draftFromSchedule:(nullable Schedule *)schedule;
@end

@interface ScheduleManager : NSObject

+ (instancetype)shared;

/// kind == nil means every kind.
- (NSArray<Schedule *> *)schedulesIn:(ScheduleScope)scope day:(nullable NSDate *)day kind:(nullable NSNumber *)kind;
/// Days in [from, from + days) that have at least one planned item (for the date strip dots).
- (NSSet<NSDate *> *)busyDaysFrom:(NSDate *)from days:(NSInteger)days;
- (NSUInteger)countToday;

- (nullable Schedule *)createSchedule:(ScheduleDraft *)draft error:(NSError **)error;
- (BOOL)updateSchedule:(Schedule *)schedule with:(ScheduleDraft *)draft error:(NSError **)error;
/// A repeating item rolls to its next occurrence on complete.
- (BOOL)complete:(Schedule *)schedule error:(NSError **)error;
- (BOOL)cancel:(Schedule *)schedule error:(NSError **)error;
- (BOOL)reopen:(Schedule *)schedule error:(NSError **)error;
- (BOOL)deleteSchedule:(Schedule *)schedule error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
