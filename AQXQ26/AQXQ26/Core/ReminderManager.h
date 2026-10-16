//
//  ReminderManager.h
//  WorkSpace
//
//  Wraps UNUserNotificationCenter. Each object owns notification identifiers
//  derived from its uuid, so editing replaces and deleting removes them.
//

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@class Task, Schedule;

NS_ASSUME_NONNULL_BEGIN

@interface ReminderManager : NSObject <UNUserNotificationCenterDelegate>

+ (instancetype)shared;

/// Installs itself as the notification center delegate (foreground banners + tap routing).
- (void)activate;

/// Asks for permission the first time a reminder is set. `granted` is NO when denied.
- (void)ensureAuthorization:(void (^)(BOOL granted))completion;
@property (nonatomic, readonly) UNAuthorizationStatus lastKnownStatus;
- (void)refreshAuthorizationStatus:(nullable void (^)(UNAuthorizationStatus status))completion;

/// Reminder at reminderDate + "due now" alert at dueDate (when in the future and task is open).
- (void)syncTask:(Task *)task;
- (void)removeTaskWithId:(NSString *)uuid;

/// Reminder `reminderOffset` minutes before start; repeats follow repeatRule.
- (void)syncSchedule:(Schedule *)schedule;
- (void)removeScheduleWithId:(NSString *)uuid;

/// Rebuilds all pending requests from the database (after a restore).
- (void)rescheduleAll;

/// Called when the user taps a notification. Arguments: kind ("task"/"schedule"), uuid.
@property (nonatomic, copy, nullable) void (^openHandler)(NSString *kind, NSString *uuid);

@end

NS_ASSUME_NONNULL_END
