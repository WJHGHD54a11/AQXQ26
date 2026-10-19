//
//  MaintenancePlan.m
//  WorkSpace
//

#import "MaintenancePlan.h"
#import "Vehicle.h"

@implementation MaintenancePlan

+ (NSFetchRequest<MaintenancePlan *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"MaintenancePlan"];
}

@dynamic uuid, itemKey, intervalKm, intervalMonths, lastOdometer, lastDate, enabled, taskId, createdAt, updatedAt, vehicle;

@end
