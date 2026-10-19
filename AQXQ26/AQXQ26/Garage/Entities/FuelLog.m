//
//  FuelLog.m
//  WorkSpace
//

#import "FuelLog.h"
#import "Vehicle.h"

@implementation FuelLog

+ (NSFetchRequest<FuelLog *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"FuelLog"];
}

@dynamic uuid, date, odometer, volume, cost, isFullTank, station, createdAt, updatedAt, vehicle;

@end
