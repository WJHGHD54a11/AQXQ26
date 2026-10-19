//
//  Vehicle.m
//  WorkSpace
//

#import "Vehicle.h"


@implementation Vehicle

+ (NSFetchRequest<Vehicle *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Vehicle"];
}

@dynamic uuid, name, make, model, year, plate, vin, odometer, fuelType, colorIdentifier, sortIndex, purchaseDate, insuranceDue, inspectionDue, notes, createdAt, updatedAt, records, fuelLogs, plans, trips;

@end
