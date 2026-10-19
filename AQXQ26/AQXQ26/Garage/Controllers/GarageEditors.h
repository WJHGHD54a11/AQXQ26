//
//  GarageEditors.h
//  WorkSpace
//
//  Forms for vehicles, service records, fuel logs and maintenance plans.
//

#import "WSFormViewController.h"

@class Vehicle, ServiceRecord, FuelLog, MaintenancePlan;

NS_ASSUME_NONNULL_BEGIN

@interface VehicleEditViewController : WSFormViewController
- (instancetype)initWithVehicle:(nullable Vehicle *)vehicle;
@property (nonatomic, strong, readonly, nullable) Vehicle *savedVehicle;
@end

@interface ServiceEditViewController : WSFormViewController
/// `itemKeys` preselects catalog items for a new record (e.g. from a plan).
- (instancetype)initWithVehicle:(Vehicle *)vehicle record:(nullable ServiceRecord *)record itemKeys:(nullable NSArray<NSString *> *)itemKeys;
@end

@interface FuelEditViewController : WSFormViewController
- (instancetype)initWithVehicle:(Vehicle *)vehicle log:(nullable FuelLog *)log;
@end

@interface PlanEditViewController : WSFormViewController
- (instancetype)initWithPlan:(MaintenancePlan *)plan;
@end

/// Multi-select list of catalog maintenance items.
@interface GarageItemPickerViewController : UITableViewController
- (instancetype)initWithSelected:(NSArray<NSString *> *)keys completion:(void (^)(NSArray<NSString *> *keys))completion;
@end

NS_ASSUME_NONNULL_END
