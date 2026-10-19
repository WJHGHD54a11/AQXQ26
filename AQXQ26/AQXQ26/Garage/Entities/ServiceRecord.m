//
//  ServiceRecord.m
//  WorkSpace
//

#import "ServiceRecord.h"
#import "Vehicle.h"

@implementation ServiceRecord

+ (NSFetchRequest<ServiceRecord *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"ServiceRecord"];
}

@dynamic uuid, category, title, itemKeys, date, odometer, cost, shop, notes, createdAt, updatedAt, vehicle;

@end
