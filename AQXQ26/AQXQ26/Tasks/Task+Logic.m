//
//  Task+Logic.m
//  WorkSpace
//

#import "Task+Logic.h"
#import "ChecklistItem.h"

@implementation Task (Logic)

- (BOOL)isOpen {
    return self.status == TaskStatusToDo || self.status == TaskStatusInProgress;
}

- (BOOL)isOverdue {
    return self.isOpen && self.dueDate && [self.dueDate compare:NSDate.date] == NSOrderedAscending;
}

- (BOOL)isDueToday {
    return self.dueDate && [NSCalendar.currentCalendar isDateInToday:self.dueDate];
}

- (NSUInteger)checklistDoneCount {
    return [[self.checklistItems filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"completed == YES"]] count];
}

- (NSUInteger)subtaskDoneCount {
    return [[self.subtasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"status == %d", TaskStatusCompleted]] count];
}

- (NSString *)subtaskProgressText {
    if (self.subtasks.count == 0) return nil;
    return [NSString stringWithFormat:WSText(@"%lu / %lu subtasks completed"),
            (unsigned long)self.subtaskDoneCount, (unsigned long)self.subtasks.count];
}

- (NSString *)dueText {
    if (!self.dueDate) return nil;
    NSDateComponents *c = [NSCalendar.currentCalendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.dueDate];
    BOOL hasTime = !(c.hour == 23 && c.minute == 59) && !(c.hour == 0 && c.minute == 0);
    return [Task relativeDayText:self.dueDate includeTime:hasTime];
}

+ (NSString *)relativeDayText:(NSDate *)date includeTime:(BOOL)includeTime {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSString *day;
    if ([cal isDateInToday:date]) day = WSText(@"Today");
    else if ([cal isDateInTomorrow:date]) day = WSText(@"Tomorrow");
    else if ([cal isDateInYesterday:date]) day = WSText(@"Yesterday");
    else {
        static NSDateFormatter *sameYear, *otherYear;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            sameYear = NSDateFormatter.new;
            [sameYear setLocalizedDateFormatFromTemplate:@"EEE d MMM"];
            otherYear = NSDateFormatter.new;
            [otherYear setLocalizedDateFormatFromTemplate:@"d MMM yyyy"];
        });
        BOOL thisYear = [cal component:NSCalendarUnitYear fromDate:date] == [cal component:NSCalendarUnitYear fromDate:NSDate.date];
        day = [(thisYear ? sameYear : otherYear) stringFromDate:date];
    }
    if (!includeTime) return day;
    NSString *time = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"%@ %@", day, time];
}

@end
