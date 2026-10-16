//
//  Schedule.m
//  WorkSpace
//

#import "Schedule.h"


@implementation Schedule

+ (NSFetchRequest<Schedule *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Schedule"];
}

@dynamic uuid, title, detail, location, kind, status, repeatRule, reminderOffset, allDay, isFavorite, date, startTime, endTime, createdAt, updatedAt, lastOpenedAt;

@end
