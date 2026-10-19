//
//  Trip.m
//  WorkSpace
//

#import "Trip.h"
#import "Vehicle.h"

@implementation Trip

+ (NSFetchRequest<Trip *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Trip"];
}

@dynamic uuid, purpose, title, fromPlace, toPlace, date, endDate, startOdometer, endOdometer, expense, notes,
         createdAt, updatedAt, vehicle;

- (double)distance {
    return MAX(0, self.endOdometer - self.startOdometer);
}

@end
