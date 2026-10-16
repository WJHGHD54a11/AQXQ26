//
//  Schedule.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Schedule+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface Schedule : NSManagedObject

+ (NSFetchRequest<Schedule *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *detail;
@property (nonatomic, nullable, copy) NSString *location;
@property (nonatomic, assign) ScheduleKind kind;
@property (nonatomic, assign) ScheduleStatus status;
@property (nonatomic, assign) RepeatRule repeatRule;
@property (nonatomic, assign) int32_t reminderOffset;
@property (nonatomic, assign) BOOL allDay;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, nullable, strong) NSDate *endTime;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) NSDate *lastOpenedAt;


@end

NS_ASSUME_NONNULL_END
