//
//  GarageManager.h
//  WorkSpace
//
//  Vehicles, service records, fuel logs and maintenance plans. All writes go through here;
//  saves are merged by DataManager and broadcast as WSDataDidChangeNotification.
//

#import <Foundation/Foundation.h>
#import "GarageTypes.h"

@class Vehicle, ServiceRecord, FuelLog, MaintenancePlan, GarageItem, Task;

NS_ASSUME_NONNULL_BEGIN

/// Where a maintenance plan stands right now (computed, never stored).
@interface PlanStatus : NSObject
@property (nonatomic, strong) MaintenancePlan *plan;
@property (nonatomic, strong, nullable) GarageItem *item;
@property (nonatomic) double remainingKm;            // NAN when the plan has no mileage interval
@property (nonatomic) NSInteger remainingDays;       // NSIntegerMax when no time interval
@property (nonatomic, strong, nullable) NSDate *dueDate;
@property (nonatomic) double dueOdometer;            // 0 when no mileage interval
/// Remaining life 0…1 (lowest of mileage / time). 0 = due or overdue.
@property (nonatomic) double health;
@property (nonatomic, readonly) BOOL isOverdue;
@property (nonatomic, readonly) BOOL isDueSoon;      // < 15% life left
@property (nonatomic, readonly) NSString *remainingText;
@end

@interface GarageStats : NSObject
@property (nonatomic) double totalCost;              // service + fuel in range
@property (nonatomic) double fuelCost;
@property (nonatomic) double serviceCost;
@property (nonatomic) double distance;               // km covered by records in range
@property (nonatomic) double costPerKm;              // 0 when unknown
@property (nonatomic) double averageConsumption;     // L/100km, 0 when unknown
/// Last 12 months, oldest first: @{ @"month": NSDate, @"service": NSNumber, @"fuel": NSNumber }
@property (nonatomic, copy) NSArray<NSDictionary *> *monthly;
/// Sorted by amount desc: @{ @"category": NSNumber (ServiceCategory or ServiceCategoryFuelChart), @"amount": NSNumber }
@property (nonatomic, copy) NSArray<NSDictionary *> *byCategory;
/// Per full-tank interval, oldest first: @{ @"date": NSDate, @"value": NSNumber (L/100km) }
@property (nonatomic, copy) NSArray<NSDictionary *> *consumption;
@end

/// One row of the vehicle timeline (service record or fuel log).
@interface GarageTimelineEntry : NSObject
@property (nonatomic, strong) id object;             // ServiceRecord or FuelLog
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) double odometer;
@property (nonatomic) double cost;
@property (nonatomic) NSInteger category;            // ServiceCategory or ServiceCategoryFuelChart
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *subtitle;
@end

@interface VehicleDraft : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *make, *model, *plate, *vin, *notes;
@property (nonatomic) int16_t year;
@property (nonatomic) double odometer;
@property (nonatomic) VehicleFuelType fuelType;
@property (nonatomic, copy) NSString *colorIdentifier;
@property (nonatomic, strong, nullable) NSDate *purchaseDate, *insuranceDue, *inspectionDue;
+ (instancetype)draftFromVehicle:(nullable Vehicle *)vehicle;
@end

@interface ServiceDraft : NSObject
@property (nonatomic) ServiceCategory category;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NSString *> *itemKeys;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) double odometer, cost;
@property (nonatomic, copy, nullable) NSString *shop, *notes;
+ (instancetype)draftFromRecord:(nullable ServiceRecord *)record vehicle:(Vehicle *)vehicle;
@end

@interface FuelDraft : NSObject
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) double odometer, volume, cost;
@property (nonatomic) BOOL isFullTank;
@property (nonatomic, copy, nullable) NSString *station;
+ (instancetype)draftFromLog:(nullable FuelLog *)log vehicle:(Vehicle *)vehicle;
@end

@interface GarageManager : NSObject

+ (instancetype)shared;

#pragma mark Vehicles
- (NSArray<Vehicle *> *)vehicles;
/// Remembered selection, falling back to the first vehicle.
@property (nonatomic, strong, nullable) Vehicle *currentVehicle;
- (nullable Vehicle *)createVehicle:(VehicleDraft *)draft error:(NSError **)error;   // also creates default plans
- (BOOL)updateVehicle:(Vehicle *)vehicle with:(VehicleDraft *)draft error:(NSError **)error;
- (BOOL)deleteVehicle:(Vehicle *)vehicle error:(NSError **)error;
- (BOOL)updateOdometer:(double)odometer forVehicle:(Vehicle *)vehicle error:(NSError **)error;

#pragma mark Records
- (NSArray<GarageTimelineEntry *> *)timelineFor:(Vehicle *)vehicle limit:(NSUInteger)limit;   // 0 = all
- (nullable ServiceRecord *)addService:(ServiceDraft *)draft to:(Vehicle *)vehicle error:(NSError **)error;
- (BOOL)updateService:(ServiceRecord *)record with:(ServiceDraft *)draft error:(NSError **)error;
- (nullable FuelLog *)addFuel:(FuelDraft *)draft to:(Vehicle *)vehicle error:(NSError **)error;
- (BOOL)updateFuel:(FuelLog *)log with:(FuelDraft *)draft error:(NSError **)error;
- (BOOL)deleteEntry:(id)recordOrLog error:(NSError **)error;

#pragma mark Plans
- (NSArray<PlanStatus *> *)planStatusesFor:(Vehicle *)vehicle;   // enabled plans, most urgent first
- (PlanStatus *)statusForPlan:(MaintenancePlan *)plan;
- (NSArray<MaintenancePlan *> *)allPlansFor:(Vehicle *)vehicle;  // sorted by catalog order
/// Overall vehicle health 0…1 (average of plan health, overdue items weigh double).
- (double)healthFor:(Vehicle *)vehicle;
- (nullable MaintenancePlan *)addPlanForItem:(NSString *)itemKey to:(Vehicle *)vehicle error:(NSError **)error;
- (BOOL)updatePlan:(MaintenancePlan *)plan intervalKm:(double)km months:(NSInteger)months
      lastOdometer:(double)lastOdometer lastDate:(nullable NSDate *)lastDate enabled:(BOOL)enabled error:(NSError **)error;
- (BOOL)deletePlan:(MaintenancePlan *)plan error:(NSError **)error;
/// Marks the item as serviced now at the vehicle's odometer (logs a maintenance record).
- (BOOL)markPlanDone:(MaintenancePlan *)plan cost:(double)cost error:(NSError **)error;
/// Creates (or returns the existing open) task reminding about this plan.
- (nullable Task *)reminderTaskForPlan:(MaintenancePlan *)plan error:(NSError **)error;
/// Turns a catalog checklist into a task with checklist items.
- (nullable Task *)taskFromChecklistAt:(NSUInteger)index vehicle:(nullable Vehicle *)vehicle error:(NSError **)error;

#pragma mark Stats
/// months = 0 → all time.
- (GarageStats *)statsFor:(Vehicle *)vehicle months:(NSInteger)months;
/// Next due plan across all vehicles (for Home).
- (NSArray<PlanStatus *> *)upcomingAcrossVehicles:(NSUInteger)limit;

#pragma mark Sample data
- (BOOL)createSampleGarage:(NSError **)error;

#pragma mark Units
/// Stored values are always km; the user can show miles instead (Settings in Garage).
@property (class, nonatomic) BOOL usesMiles;
+ (NSString *)distanceUnit;                       // "km" / "mi"
+ (double)displayFromKm:(double)km;
+ (double)kmFromDisplay:(double)value;

#pragma mark Formatting
+ (NSString *)formatCost:(double)amount;
+ (NSString *)formatDistance:(double)km;
+ (NSString *)formatNumber:(double)value digits:(NSInteger)digits;
/// Parses user input with either decimal separator; NAN when invalid.
+ (double)parseNumber:(nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END
