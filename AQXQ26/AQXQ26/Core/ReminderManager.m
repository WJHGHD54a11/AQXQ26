//
//  ReminderManager.m
//  WorkSpace
//

#import "ReminderManager.h"
#import "AppConstants.h"
#import "DataManager.h"
#import "Task.h"
#import "Schedule.h"

static NSString * const kKindKey = @"ws.kind";
static NSString * const kIdKey = @"ws.id";

@implementation ReminderManager

+ (instancetype)shared {
    static ReminderManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (UNUserNotificationCenter *)center {
    return UNUserNotificationCenter.currentNotificationCenter;
}

- (void)activate {
    self.center.delegate = self;
    [self refreshAuthorizationStatus:nil];
}

#pragma mark - Authorization

- (void)refreshAuthorizationStatus:(void (^)(UNAuthorizationStatus))completion {
    [self.center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_lastKnownStatus = settings.authorizationStatus;
            if (completion) completion(settings.authorizationStatus);
        });
    }];
}

- (void)ensureAuthorization:(void (^)(BOOL))completion {
    [self refreshAuthorizationStatus:^(UNAuthorizationStatus status) {
        if (status == UNAuthorizationStatusNotDetermined) {
            [self.center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                                       completionHandler:^(BOOL granted, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_lastKnownStatus = granted ? UNAuthorizationStatusAuthorized : UNAuthorizationStatusDenied;
                    if (completion) completion(granted);
                });
            }];
            return;
        }
        BOOL ok = status == UNAuthorizationStatusAuthorized || status == UNAuthorizationStatusProvisional;
        if (completion) completion(ok);
    }];
}

#pragma mark - Identifiers

+ (NSString *)taskReminderId:(NSString *)uuid { return [@"task.reminder." stringByAppendingString:uuid]; }
+ (NSString *)taskDueId:(NSString *)uuid      { return [@"task.due." stringByAppendingString:uuid]; }
+ (NSString *)scheduleId:(NSString *)uuid     { return [@"schedule." stringByAppendingString:uuid]; }

#pragma mark - Tasks

- (void)syncTask:(Task *)task {
    if (task.uuid.length == 0) return;
    NSString *uuid = task.uuid;
    [self removeTaskWithId:uuid];

    BOOL open = task.status == TaskStatusToDo || task.status == TaskStatusInProgress;
    if (!open || task.isDeleted) return;

    NSDate *now = NSDate.date;
    if (task.reminderDate && [task.reminderDate compare:now] == NSOrderedDescending) {
        NSString *body = task.dueDate
            ? [NSString stringWithFormat:WSText(@"Due %@"), [NSDateFormatter localizedStringFromDate:task.dueDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]]
            : (task.detail.length ? task.detail : WSText(@"Task reminder"));
        [self add:[ReminderManager taskReminderId:uuid] title:task.title body:body date:task.reminderDate
           repeat:task.repeatRule kind:@"task" uuid:uuid];
    }
    if (task.dueDate && [task.dueDate compare:now] == NSOrderedDescending) {
        [self add:[ReminderManager taskDueId:uuid] title:task.title body:WSText(@"This task is due now.")
             date:task.dueDate repeat:RepeatRuleNone kind:@"task" uuid:uuid];
    }
}

- (void)removeTaskWithId:(NSString *)uuid {
    if (uuid.length == 0) return;
    NSArray *ids = @[[ReminderManager taskReminderId:uuid], [ReminderManager taskDueId:uuid]];
    [self.center removePendingNotificationRequestsWithIdentifiers:ids];
    [self.center removeDeliveredNotificationsWithIdentifiers:ids];
}

#pragma mark - Schedule

- (void)syncSchedule:(Schedule *)schedule {
    if (schedule.uuid.length == 0) return;
    [self removeScheduleWithId:schedule.uuid];
    if (schedule.isDeleted || schedule.status != ScheduleStatusPlanned || schedule.reminderOffset < 0 || !schedule.startTime) return;

    NSDate *fire = [schedule.startTime dateByAddingTimeInterval:-60.0 * schedule.reminderOffset];
    if ([fire compare:NSDate.date] != NSOrderedDescending && schedule.repeatRule == RepeatRuleNone) return;

    NSMutableArray *parts = NSMutableArray.new;
    [parts addObject:[NSDateFormatter localizedStringFromDate:schedule.startTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
    if (schedule.location.length) [parts addObject:schedule.location];
    [self add:[ReminderManager scheduleId:schedule.uuid] title:schedule.title body:[parts componentsJoinedByString:@" · "]
         date:fire repeat:schedule.repeatRule kind:@"schedule" uuid:schedule.uuid];
}

- (void)removeScheduleWithId:(NSString *)uuid {
    if (uuid.length == 0) return;
    NSString *identifier = [ReminderManager scheduleId:uuid];
    [self.center removePendingNotificationRequestsWithIdentifiers:@[identifier]];
    [self.center removeDeliveredNotificationsWithIdentifiers:@[identifier]];
}

#pragma mark - Request building

- (void)add:(NSString *)identifier title:(NSString *)title body:(NSString *)body date:(NSDate *)date
     repeat:(RepeatRule)repeat kind:(NSString *)kind uuid:(NSString *)uuid {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title.length ? title : WSText(@"Untitled");
    content.body = body ?: @"";
    content.sound = UNNotificationSound.defaultSound;
    content.userInfo = @{kKindKey: kind, kIdKey: uuid};
    content.threadIdentifier = kind;

    UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:[self componentsFor:date repeat:repeat]
                                                                                                     repeats:repeat != RepeatRuleNone && repeat != RepeatRuleWeekdays];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [self.center addNotificationRequest:request withCompletionHandler:^(NSError *error) {
        if (error) NSLog(@"[Reminder] add %@ failed: %@", identifier, error);
    }];
}

/// Repeating triggers only keep the components that recur. Weekdays has no single
/// calendar match, so it is scheduled as one-shot and re-armed when the item is next saved.
- (NSDateComponents *)componentsFor:(NSDate *)date repeat:(RepeatRule)repeat {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSCalendarUnit units;
    switch (repeat) {
        case RepeatRuleDaily:   units = NSCalendarUnitHour | NSCalendarUnitMinute; break;
        case RepeatRuleWeekly:  units = NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute; break;
        case RepeatRuleMonthly: units = NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute; break;
        case RepeatRuleYearly:  units = NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute; break;
        default:
            units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    }
    return [cal components:units fromDate:date];
}

- (void)rescheduleAll {
    [self.center removeAllPendingNotificationRequests];
    NSFetchRequest *tasks = [Task fetchRequest];
    tasks.predicate = [NSPredicate predicateWithFormat:@"(reminderDate > %@ OR dueDate > %@) AND status < %d",
                       NSDate.date, NSDate.date, TaskStatusCompleted];
    for (Task *t in [DataManager.shared fetch:tasks]) [self syncTask:t];

    NSFetchRequest *schedules = [Schedule fetchRequest];
    schedules.predicate = [NSPredicate predicateWithFormat:@"reminderOffset >= 0 AND status == %d", ScheduleStatusPlanned];
    for (Schedule *s in [DataManager.shared fetch:schedules]) [self syncSchedule:s];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList | UNNotificationPresentationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    NSDictionary *info = response.notification.request.content.userInfo;
    NSString *kind = info[kKindKey], *uuid = info[kIdKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (kind && uuid && self.openHandler) self.openHandler(kind, uuid);
        completionHandler();
    });
}

@end
