//
//  ScheduleEditViewController.m
//  WorkSpace
//

#import "ScheduleEditViewController.h"
#import "ScheduleManager.h"
#import "ReminderManager.h"
#import "Schedule.h"

@interface ScheduleEditViewController ()
@property (nonatomic, strong, nullable) Schedule *schedule;
@property (nonatomic, strong) ScheduleDraft *draft;
@end

@implementation ScheduleEditViewController

- (instancetype)initWithSchedule:(Schedule *)schedule day:(NSDate *)day {
    if ((self = [super init])) {
        _schedule = schedule;
        _draft = [ScheduleDraft draftFromSchedule:schedule];
        if (!schedule && day && ![NSCalendar.currentCalendar isDateInToday:day]) {
            // Same time of day as the default, moved onto the chosen day.
            NSCalendar *cal = NSCalendar.currentCalendar;
            NSDateComponents *hm = [cal components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:_draft.startTime];
            NSDate *start = [cal dateBySettingHour:MIN(MAX(hm.hour, 8), 20) minute:0 second:0 ofDate:day options:0];
            _draft.startTime = start;
            _draft.endTime = [start dateByAddingTimeInterval:3600];
        }
        self.title = schedule ? WSText(@"Edit Schedule") : WSText(@"New Schedule");
        self.saveTitle = schedule ? WSText(@"Save") : WSText(@"Add");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    ScheduleDraft *d = self.draft;
    __weak typeof(self) weakSelf = self;

    WSFormRow *title = [WSFormRow type:WSFormRowText key:@"title" title:WSText(@"Title") value:d.title];
    title.placeholder = WSText(@"What's happening?");
    WSFormRow *kind = [WSFormRow type:WSFormRowChoice key:@"kind" title:WSText(@"Type") value:@(d.kind)];
    kind.options = ScheduleKindTitles();
    kind.symbol = @"square.grid.2x2";
    WSFormRow *location = [WSFormRow type:WSFormRowText key:@"location" title:WSText(@"Location") value:d.location];
    location.placeholder = WSText(@"Location (optional)");

    WSFormRow *allDay = [WSFormRow type:WSFormRowToggle key:@"allDay" title:WSText(@"All day") value:@(d.allDay)];
    allDay.symbol = @"sun.max";
    allDay.onChange = ^(WSFormRow *row) {
        // Switch picker modes without losing what was typed elsewhere.
        [weakSelf captureDraft];
        [weakSelf reloadForm];
    };
    WSFormRow *start = [WSFormRow type:WSFormRowDate key:@"start" title:d.allDay ? WSText(@"Date") : WSText(@"Starts") value:d.startTime];
    start.dateRequired = YES;
    start.dateMode = d.allDay ? UIDatePickerModeDate : UIDatePickerModeDateAndTime;
    start.onChange = ^(WSFormRow *row) {
        // Keep the duration when the start moves.
        WSFormRow *end = [weakSelf rowForKey:@"end"];
        NSDate *oldStart = weakSelf.draft.startTime;
        if (end.value && oldStart && row.value) {
            NSTimeInterval length = [end.value timeIntervalSinceDate:oldStart];
            if (length < 0) length = 3600;
            [weakSelf setFormValue:[row.value dateByAddingTimeInterval:length] forKey:@"end"];
        }
        weakSelf.draft.startTime = row.value;
    };
    NSMutableArray *timeRows = [NSMutableArray arrayWithObjects:allDay, start, nil];
    if (!d.allDay) {
        WSFormRow *end = [WSFormRow type:WSFormRowDate key:@"end" title:WSText(@"Ends") value:d.endTime];
        end.dateMode = UIDatePickerModeDateAndTime;
        [timeRows addObject:end];
    }

    NSArray<NSNumber *> *offsets = ScheduleReminderOffsets();
    NSMutableArray *offsetTitles = NSMutableArray.new;
    for (NSNumber *n in offsets) [offsetTitles addObject:ScheduleReminderOffsetTitle(n.intValue)];
    NSUInteger offsetIndex = [offsets indexOfObject:@(d.reminderOffset)];
    WSFormRow *reminder = [WSFormRow type:WSFormRowChoice key:@"reminder" title:WSText(@"Reminder")
                                    value:@(offsetIndex == NSNotFound ? 0 : offsetIndex)];
    reminder.options = offsetTitles;
    reminder.symbol = @"bell";
    WSFormRow *repeat = [WSFormRow type:WSFormRowChoice key:@"repeat" title:WSText(@"Repeat") value:@(d.repeatRule)];
    repeat.options = RepeatRuleTitles();
    repeat.symbol = @"repeat";

    WSFormRow *detail = [WSFormRow type:WSFormRowTextArea key:@"detail" title:WSText(@"Notes") value:d.detail];
    detail.placeholder = WSText(@"Agenda, people, links…");

    NSMutableArray *sections = [NSMutableArray arrayWithArray:@[
        [WSFormSection title:nil rows:@[title, kind, location]],
        [WSFormSection title:WSText(@"Time") rows:timeRows],
        [WSFormSection title:WSText(@"Alerts") rows:@[reminder, repeat]],
        [WSFormSection title:WSText(@"Notes") rows:@[detail]],
    ]];
    if (ReminderManager.shared.lastKnownStatus == UNAuthorizationStatusDenied) {
        ((WSFormSection *)sections[2]).footer = WSText(@"Notifications are turned off for WorkSpace. Reminders will be saved but won't alert you until you allow notifications in Settings.");
    }
    return sections;
}

/// Pulls current field values into the draft (used before rebuilding the form).
- (void)captureDraft {
    ScheduleDraft *d = self.draft;
    d.title = [self formValueForKey:@"title"] ?: @"";
    d.location = [self stringForKey:@"location"];
    d.detail = [self formValueForKey:@"detail"];
    d.kind = (ScheduleKind)[[self formValueForKey:@"kind"] integerValue];
    d.repeatRule = (RepeatRule)[[self formValueForKey:@"repeat"] integerValue];
    d.allDay = [[self formValueForKey:@"allDay"] boolValue];
    NSDate *start = [self formValueForKey:@"start"];
    if (start) d.startTime = start;
    WSFormRow *end = [self rowForKey:@"end"];
    if (end) d.endTime = end.value;
    NSArray<NSNumber *> *offsets = ScheduleReminderOffsets();
    NSInteger i = [[self formValueForKey:@"reminder"] integerValue];
    d.reminderOffset = (i >= 0 && i < (NSInteger)offsets.count) ? offsets[i].intValue : -1;
}

- (BOOL)save {
    [self captureDraft];
    ScheduleDraft *d = self.draft;
    if (d.allDay) d.endTime = nil;

    NSError *error = nil;
    Schedule *saved = self.schedule;
    BOOL ok = saved ? [ScheduleManager.shared updateSchedule:saved with:d error:&error]
                    : ((saved = [ScheduleManager.shared createSchedule:d error:&error]) != nil);
    if (!ok) {
        [self ws_showError:error];
        return NO;
    }
    if (d.reminderOffset >= 0) {
        // Ask after saving so a denied prompt never blocks the edit itself.
        UIViewController *presenter = self.presentingViewController;
        [ReminderManager.shared ensureAuthorization:^(BOOL granted) {
            if (granted) {
                if (!saved.isDeleted) [ReminderManager.shared syncSchedule:saved];
            } else {
                [presenter ws_showMessage:WSText(@"The schedule was saved, but WorkSpace isn't allowed to send notifications. Turn them on in Settings to get reminders.")
                                    title:WSText(@"Notifications Off")];
            }
        }];
    }
    return YES;
}

@end
