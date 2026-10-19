//
//  FuelLog.h
//  WorkSpace
//

#import <CoreData/CoreData.h>
#import "GarageTypes.h"

@class Vehicle;

NS_ASSUME_NONNULL_BEGIN

@interface FuelLog : NSManagedObject

+ (NSFetchRequest<FuelLog *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) double odometer;
@property (nonatomic, assign) double volume;   // liters
@property (nonatomic, assign) double cost;
@property (nonatomic, assign) BOOL isFullTank;
@property (nonatomic, nullable, copy) NSString *station;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) Vehicle *vehicle;

@end

NS_ASSUME_NONNULL_END
