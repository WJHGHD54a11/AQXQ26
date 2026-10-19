//
//  Vehicle.h
//  WorkSpace
//

#import <CoreData/CoreData.h>
#import "GarageTypes.h"

@class ServiceRecord, FuelLog, MaintenancePlan, Trip;

NS_ASSUME_NONNULL_BEGIN

@interface Vehicle : NSManagedObject

+ (NSFetchRequest<Vehicle *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *make;
@property (nonatomic, nullable, copy) NSString *model;
@property (nonatomic, assign) int16_t year;
@property (nonatomic, nullable, copy) NSString *plate;
@property (nonatomic, nullable, copy) NSString *vin;
@property (nonatomic, assign) double odometer;          // km
@property (nonatomic, assign) VehicleFuelType fuelType;
@property (nonatomic, nullable, copy) NSString *colorIdentifier;
@property (nonatomic, assign) double sortIndex;
@property (nonatomic, nullable, strong) NSDate *purchaseDate;
@property (nonatomic, nullable, strong) NSDate *insuranceDue;
@property (nonatomic, nullable, strong) NSDate *inspectionDue;
@property (nonatomic, nullable, copy) NSString *notes;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;

@property (nonatomic, nullable, strong) NSSet<ServiceRecord *> *records;
@property (nonatomic, nullable, strong) NSSet<FuelLog *> *fuelLogs;
@property (nonatomic, nullable, strong) NSSet<MaintenancePlan *> *plans;
@property (nonatomic, nullable, strong) NSSet<Trip *> *trips;

@end

NS_ASSUME_NONNULL_END
