//
//  ScheduleManager.m
//  WorkSpace
//

#import "ScheduleManager.h"
#import "DataManager.h"
#import "ActivityManager.h"
#import "ReminderManager.h"
#import "Schedule.h"

@implementation ScheduleDraft

- (instancetype)init {
    if ((self = [super init])) {
        _title = @"";
        _kind = ScheduleKindAppointment;
        _reminderOffset = 15;
        // Next full hour, one hour long.
        NSCalendar *cal = NSCalendar.currentCalendar;
        NSDate *now = NSDate.date;
        NSDateComponents *c = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour fromDate:now];
        c.hour += 1;
        _startTime = [cal dateFromComponents:c];
        _endTime = [_startTime dateByAddingTimeInterval:3600];
    }
    return self;
}

+ (instancetype)draftFromSchedule:(Schedule *)schedule {
    ScheduleDraft *draft = [[ScheduleDraft alloc] init];
    if (!schedule) return draft;
    draft.title = schedule.title ?: @"";
    draft.detail = schedule.detail;
    draft.location = schedule.location;
    draft.kind = schedule.kind;
    draft.repeatRule = schedule.repeatRule;
    draft.reminderOffset = schedule.reminderOffset;
    draft.allDay = schedule.allDay;
    draft.startTime = schedule.startTime ?: schedule.date ?: NSDate.date;
    draft.endTime = schedule.endTime;
    return draft;
}

@end

@implementation ScheduleManager

+ (instancetype)shared {
    static ScheduleManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSError *)error:(NSString *)message code:(NSInteger)code {
    return [NSError errorWithDomain:@"WorkSpace" code:code userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Query

- (NSArray<Schedule *> *)schedulesIn:(ScheduleScope)scope day:(NSDate *)day kind:(NSNumber *)kind {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *today = [cal startOfDayForDate:NSDate.date];
    NSDate *tomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:today options:0];
    NSMutableArray *predicates = NSMutableArray.new;
    BOOL ascending = YES;

    switch (scope) {
        case ScheduleScopeToday:
            [predicates addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", today, tomorrow]];
            break;
        case ScheduleScopeUpcoming:
            [predicates addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND status == %d", tomorrow, ScheduleStatusPlanned]];
            break;
        case ScheduleScopeDay: {
            NSDate *start = [cal startOfDayForDate:day ?: NSDate.date];
            NSDate *end = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
            [predicates addObject:[NSPredicate predicateWithFormat:@"date >= %@ AND date < %@", start, end]];
            break;
        }
        case ScheduleScopePast:
            [predicates addObject:[NSPredicate predicateWithFormat:@"status != %d OR date < %@", ScheduleStatusPlanned, today]];
            ascending = NO;
            break;
    }
    if (kind) [predicates addObject:[NSPredicate predicateWithFormat:@"kind == %d", kind.intValue]];

    NSFetchRequest *request = [Schedule fetchRequest];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:ascending]];
    request.fetchBatchSize = 40;
    return [DataManager.shared fetch:request];
}

- (NSSet<NSDate *> *)busyDaysFrom:(NSDate *)from days:(NSInteger)days {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *start = [cal startOfDayForDate:from];
    NSDate *end = [cal dateByAddingUnit:NSCalendarUnitDay value:days toDate:start options:0];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
    request.predicate = [NSPredicate predicateWithFormat:@"date >= %@ AND date < %@ AND status == %d", start, end, ScheduleStatusPlanned];
    request.resultType = NSDictionaryResultType;
    request.propertiesToFetch = @[@"date"];
    NSMutableSet *set = NSMutableSet.new;
    for (NSDictionary *row in [DataManager.shared fetch:request]) [set addObject:[cal startOfDayForDate:row[@"date"]]];
    return set;
}

- (NSUInteger)countToday {
    return [self schedulesIn:ScheduleScopeToday day:nil kind:nil].count;
}

#pragma mark - Mutations

- (BOOL)validate:(ScheduleDraft *)draft error:(NSError **)error {
    if ([draft.title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        if (error) *error = [self error:WSText(@"Give the schedule a title.") code:6];
        return NO;
    }
    if (!draft.startTime) {
        if (error) *error = [self error:WSText(@"Pick a start time.") code:6];
        return NO;
    }
    if (draft.endTime && [draft.endTime compare:draft.startTime] == NSOrderedAscending) {
        if (error) *error = [self error:WSText(@"End time must be after the start time.") code:6];
        return NO;
    }
    return YES;
}

- (void)apply:(ScheduleDraft *)draft to:(Schedule *)s {
    NSCalendar *cal = NSCalendar.currentCalendar;
    s.title = [draft.title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    s.detail = draft.detail.length ? draft.detail : nil;
    s.location = draft.location.length ? draft.location : nil;
    s.kind = draft.kind;
    s.repeatRule = draft.repeatRule;
    s.reminderOffset = draft.reminderOffset;
    s.allDay = draft.allDay;
    if (draft.allDay) {
        NSDate *day = [cal startOfDayForDate:draft.startTime];
        s.startTime = [cal dateBySettingHour:9 minute:0 second:0 ofDate:day options:0]; // reminder anchor
        s.endTime = nil;
    } else {
        s.startTime = draft.startTime;
        s.endTime = draft.endTime;
    }
    s.date = [cal startOfDayForDate:s.startTime];
    s.updatedAt = NSDate.date;
}

- (Schedule *)createSchedule:(ScheduleDraft *)draft error:(NSError **)error {
    if (![self validate:draft error:error]) return nil;
    Schedule *s = [DataManager.shared insertEntity:@"Schedule"];
    s.status = ScheduleStatusPlanned;
    [self apply:draft to:s];
    [ActivityManager.shared record:ActivityTypeScheduleCreated title:s.title detail:ScheduleKindTitle(s.kind) objectId:s.uuid];
    if (![DataManager.shared save:error]) return nil;
    [ReminderManager.shared syncSchedule:s];
    return s;
}

- (BOOL)updateSchedule:(Schedule *)schedule with:(ScheduleDraft *)draft error:(NSError **)error {
    if (!schedule || schedule.isDeleted) {
        if (error) *error = [self error:WSText(@"This schedule no longer exists.") code:404];
        return NO;
    }
    if (![self validate:draft error:error]) return NO;
    [self apply:draft to:schedule];
    [ActivityManager.shared record:ActivityTypeScheduleUpdated title:schedule.title detail:nil objectId:schedule.uuid];
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncSchedule:schedule];
    return YES;
}

- (BOOL)complete:(Schedule *)schedule error:(NSError **)error {
    [ActivityManager.shared record:ActivityTypeScheduleCompleted title:schedule.title detail:nil objectId:schedule.uuid];
    NSDate *next = RepeatRuleNextDate(schedule.repeatRule, schedule.startTime);
    if (next) {
        NSTimeInterval length = schedule.endTime ? [schedule.endTime timeIntervalSinceDate:schedule.startTime] : 0;
        schedule.startTime = next;
        schedule.endTime = schedule.endTime ? [next dateByAddingTimeInterval:length] : nil;
        schedule.date = [NSCalendar.currentCalendar startOfDayForDate:next];
        schedule.status = ScheduleStatusPlanned;
    } else {
        schedule.status = ScheduleStatusCompleted;
    }
    schedule.updatedAt = NSDate.date;
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncSchedule:schedule];
    return YES;
}

- (BOOL)cancel:(Schedule *)schedule error:(NSError **)error {
    schedule.status = ScheduleStatusCancelled;
    schedule.updatedAt = NSDate.date;
    [ActivityManager.shared record:ActivityTypeScheduleUpdated title:schedule.title detail:WSText(@"Cancelled") objectId:schedule.uuid];
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncSchedule:schedule];
    return YES;
}

- (BOOL)reopen:(Schedule *)schedule error:(NSError **)error {
    schedule.status = ScheduleStatusPlanned;
    schedule.updatedAt = NSDate.date;
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncSchedule:schedule];
    return YES;
}

- (BOOL)deleteSchedule:(Schedule *)schedule error:(NSError **)error {
    if (!schedule || schedule.isDeleted) return YES;
    NSString *uuid = schedule.uuid;
    [ActivityManager.shared record:ActivityTypeScheduleDeleted title:schedule.title detail:nil objectId:uuid];
    [DataManager.shared deleteObject:schedule];
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared removeScheduleWithId:uuid];
    return YES;
}

@end
