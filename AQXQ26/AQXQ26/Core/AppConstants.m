//
//  AppConstants.m
//  WorkSpace
//

#import "AppConstants.h"

NSNotificationName const WSDataDidChangeNotification = @"WSDataDidChangeNotification";
NSString * const WSChangedKindsKey = @"kinds";

NSString * const ActivityTypeTaskCreated       = @"task.created";
NSString * const ActivityTypeTaskUpdated       = @"task.updated";
NSString * const ActivityTypeTaskCompleted     = @"task.completed";
NSString * const ActivityTypeTaskDeleted       = @"task.deleted";
NSString * const ActivityTypeProjectCreated    = @"project.created";
NSString * const ActivityTypeProjectUpdated    = @"project.updated";
NSString * const ActivityTypeProjectCompleted  = @"project.completed";
NSString * const ActivityTypeProjectDeleted    = @"project.deleted";
NSString * const ActivityTypeNoteCreated       = @"note.created";
NSString * const ActivityTypeNoteEdited        = @"note.edited";
NSString * const ActivityTypeNoteDeleted       = @"note.deleted";
NSString * const ActivityTypeFileImported      = @"file.imported";
NSString * const ActivityTypeFileDeleted       = @"file.deleted";
NSString * const ActivityTypeScheduleCreated   = @"schedule.created";
NSString * const ActivityTypeScheduleUpdated   = @"schedule.updated";
NSString * const ActivityTypeScheduleCompleted = @"schedule.completed";
NSString * const ActivityTypeScheduleDeleted   = @"schedule.deleted";
NSString * const ActivityTypeTemplateCreated   = @"template.created";
NSString * const ActivityTypeTemplateUsed      = @"template.used";
NSString * const ActivityTypeDataImported      = @"data.imported";

NSString *WSLocalized(NSString *key) {
    if (key.length == 0) return @"";
    NSInteger language = [NSUserDefaults.standardUserDefaults integerForKey:@"CurrentLanguage"];
    NSBundle *bundle = NSBundle.mainBundle;
    if (language == 1 || language == 2) {
        static NSMutableDictionary<NSNumber *, NSBundle *> *cache;
        static dispatch_once_t once;
        dispatch_once(&once, ^{ cache = NSMutableDictionary.new; });
        @synchronized (cache) {
            bundle = cache[@(language)];
            if (!bundle) {
                NSString *path = [NSBundle.mainBundle pathForResource:(language == 1 ? @"zh-Hans" : @"en") ofType:@"lproj"];
                bundle = (path ? [NSBundle bundleWithPath:path] : nil) ?: NSBundle.mainBundle;
                cache[@(language)] = bundle;
            }
        }
    }
    return [bundle localizedStringForKey:key value:key table:@"WorkSpace"];
}

static NSString *WSPick(NSArray<NSString *> *list, NSInteger index) {
    return (index >= 0 && index < (NSInteger)list.count) ? list[index] : @"";
}

#pragma mark - Object kinds

NSString *WSObjectKindTitle(WSObjectKind kind) {
    return WSPick(@[WSText(@"Task"), WSText(@"Project"), WSText(@"Note"), WSText(@"File"), WSText(@"Schedule"),
                    WSText(@"Template"), WSText(@"Tag"), WSText(@"Category"), WSText(@"Activity")], kind);
}

NSString *WSObjectKindPluralTitle(WSObjectKind kind) {
    return WSPick(@[WSText(@"Tasks"), WSText(@"Projects"), WSText(@"Notes"), WSText(@"Files"), WSText(@"Schedule"),
                    WSText(@"Templates"), WSText(@"Tags"), WSText(@"Categories"), WSText(@"Activity")], kind);
}

NSString *WSObjectKindSymbol(WSObjectKind kind) {
    return WSPick(@[@"checkmark.circle", @"folder", @"note.text", @"doc", @"calendar",
                    @"square.on.square", @"tag", @"tray.2", @"clock.arrow.circlepath"], kind);
}

NSString *WSObjectKindEntityName(WSObjectKind kind) {
    return WSPick(@[@"Task", @"Project", @"Note", @"FileItem", @"Schedule",
                    @"Template", @"Tag", @"NoteCategory", @"Activity"], kind);
}

#pragma mark - Tasks

NSArray<NSString *> *TaskStatusTitles(void) {
    return @[WSText(@"To Do"), WSText(@"In Progress"), WSText(@"Completed"), WSText(@"Cancelled")];
}
NSString *TaskStatusTitle(TaskStatus status) { return WSPick(TaskStatusTitles(), status); }

NSArray<NSString *> *TaskPriorityTitles(void) {
    return @[WSText(@"Low"), WSText(@"Medium"), WSText(@"High"), WSText(@"Urgent")];
}
NSString *TaskPriorityTitle(TaskPriority priority) { return WSPick(TaskPriorityTitles(), priority); }

NSArray<NSString *> *RepeatRuleTitles(void) {
    return @[WSText(@"Never"), WSText(@"Every Day"), WSText(@"Weekdays"), WSText(@"Every Week"),
             WSText(@"Every Month"), WSText(@"Every Year")];
}
NSString *RepeatRuleTitle(RepeatRule rule) { return WSPick(RepeatRuleTitles(), rule); }

NSDate *RepeatRuleNextDate(RepeatRule rule, NSDate *date) {
    NSCalendar *cal = NSCalendar.currentCalendar;
    switch (rule) {
        case RepeatRuleDaily:   return [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
        case RepeatRuleWeekly:  return [cal dateByAddingUnit:NSCalendarUnitWeekOfYear value:1 toDate:date options:0];
        case RepeatRuleMonthly: return [cal dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:date options:0];
        case RepeatRuleYearly:  return [cal dateByAddingUnit:NSCalendarUnitYear value:1 toDate:date options:0];
        case RepeatRuleWeekdays: {
            NSDate *next = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
            while ([cal isDateInWeekend:next]) {
                next = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:next options:0];
            }
            return next;
        }
        case RepeatRuleNone:
        default:
            return nil;
    }
}

#pragma mark - Projects

NSArray<NSString *> *ProjectStatusTitles(void) {
    return @[WSText(@"Planning"), WSText(@"Active"), WSText(@"Paused"), WSText(@"Completed"), WSText(@"Archived")];
}
NSString *ProjectStatusTitle(ProjectStatus status) { return WSPick(ProjectStatusTitles(), status); }

#pragma mark - Schedule

NSArray<NSString *> *ScheduleKindTitles(void) {
    return @[WSText(@"Appointment"), WSText(@"Meeting"), WSText(@"Event"), WSText(@"Personal"), WSText(@"Reminder")];
}
NSString *ScheduleKindTitle(ScheduleKind kind) { return WSPick(ScheduleKindTitles(), kind); }

NSString *ScheduleKindSymbol(ScheduleKind kind) {
    return WSPick(@[@"person.crop.circle.badge.clock", @"person.3", @"star", @"heart", @"bell"], kind);
}

NSString *ScheduleStatusTitle(ScheduleStatus status) {
    return WSPick(@[WSText(@"Planned"), WSText(@"Completed"), WSText(@"Cancelled")], status);
}

NSArray<NSNumber *> *ScheduleReminderOffsets(void) {
    return @[@-1, @0, @5, @15, @30, @60, @120, @1440];
}

NSString *ScheduleReminderOffsetTitle(int32_t minutes) {
    if (minutes < 0) return WSText(@"None");
    if (minutes == 0) return WSText(@"At start time");
    if (minutes < 60) return [NSString stringWithFormat:WSText(@"%d min before"), minutes];
    if (minutes < 1440) return [NSString stringWithFormat:WSText(@"%d hr before"), minutes / 60];
    return [NSString stringWithFormat:WSText(@"%d day before"), minutes / 1440];
}

#pragma mark - Templates

NSArray<NSString *> *TemplateKindTitles(void) {
    return @[WSText(@"Task"), WSText(@"Project"), WSText(@"Checklist")];
}
NSString *TemplateKindTitle(TemplateKind kind) { return WSPick(TemplateKindTitles(), kind); }

#pragma mark - Activity

NSString *ActivityTypeTitle(NSString *type) {
    static NSDictionary<NSString *, NSString *> *titles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        titles = @{
            ActivityTypeTaskCreated: @"Task created", ActivityTypeTaskUpdated: @"Task updated",
            ActivityTypeTaskCompleted: @"Task completed", ActivityTypeTaskDeleted: @"Task deleted",
            ActivityTypeProjectCreated: @"Project created", ActivityTypeProjectUpdated: @"Project updated",
            ActivityTypeProjectCompleted: @"Project completed", ActivityTypeProjectDeleted: @"Project deleted",
            ActivityTypeNoteCreated: @"Note created", ActivityTypeNoteEdited: @"Note edited",
            ActivityTypeNoteDeleted: @"Note deleted", ActivityTypeFileImported: @"File imported",
            ActivityTypeFileDeleted: @"File deleted", ActivityTypeScheduleCreated: @"Schedule created",
            ActivityTypeScheduleUpdated: @"Schedule updated", ActivityTypeScheduleCompleted: @"Schedule completed",
            ActivityTypeScheduleDeleted: @"Schedule deleted", ActivityTypeTemplateCreated: @"Template created",
            ActivityTypeTemplateUsed: @"Template used", ActivityTypeDataImported: @"Data imported",
        };
    });
    NSString *title = titles[type];
    return title ? WSText(title) : type;
}

WSObjectKind ActivityTypeObjectKind(NSString *type) {
    if ([type hasPrefix:@"task."]) return WSObjectKindTask;
    if ([type hasPrefix:@"project."]) return WSObjectKindProject;
    if ([type hasPrefix:@"note."]) return WSObjectKindNote;
    if ([type hasPrefix:@"file."]) return WSObjectKindFile;
    if ([type hasPrefix:@"schedule."]) return WSObjectKindSchedule;
    if ([type hasPrefix:@"template."]) return WSObjectKindTemplate;
    return WSObjectKindActivity;
}
