//
//  MaintenancePlan.h
//  WorkSpace
//

#import <CoreData/CoreData.h>
#import "GarageTypes.h"

@class Vehicle;

NS_ASSUME_NONNULL_BEGIN

@interface MaintenancePlan : NSManagedObject

+ (NSFetchRequest<MaintenancePlan *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *itemKey;          // GarageCatalog item key
@property (nonatomic, assign) double intervalKm;        // 0 = no mileage interval
@property (nonatomic, assign) int16_t intervalMonths;   // 0 = no time interval
@property (nonatomic, assign) double lastOdometer;
@property (nonatomic, nullable, strong) NSDate *lastDate;
@property (nonatomic, assign) BOOL enabled;
/// Reminder task created for the next due service, if any.
@property (nonatomic, nullable, copy) NSString *taskId;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) Vehicle *vehicle;

@end

NS_ASSUME_NONNULL_END
