//
//  GarageScreens.h
//  WorkSpace
//
//  Secondary Garage screens: statistics, timeline, maintenance items, guide, vehicle info, settings.
//

#import <UIKit/UIKit.h>

@class Vehicle, PlanStatus, WSFormViewController;

NS_ASSUME_NONNULL_BEGIN

/// Costs by month / category, fuel economy trend.
@interface GarageStatsViewController : UIViewController
- (instancetype)initWithVehicle:(Vehicle *)vehicle;
@end

/// Every service record and refuel, grouped by month.
@interface GarageTimelineViewController : UITableViewController
- (instancetype)initWithVehicle:(Vehicle *)vehicle;
@end

/// All maintenance plans with their health; add / edit / remove items.
@interface GaragePlansViewController : UITableViewController
- (instancetype)initWithVehicle:(Vehicle *)vehicle;
@end

/// 0 = maintenance items, 1 = warning lights, 2 = checklists.
@interface GarageGuideViewController : UITableViewController
- (instancetype)initWithSection:(NSInteger)section;
@end

/// Vehicle information with edit / delete.
@interface GarageVehicleViewController : UITableViewController
- (instancetype)initWithVehicle:(Vehicle *)vehicle;
@end

/// Units and sample data.
@interface GarageSettingsViewController : UITableViewController
@end

/// Editor for a ServiceRecord or FuelLog.
FOUNDATION_EXPORT WSFormViewController *GarageEditorForEntry(id entry, Vehicle *vehicle);
/// Action sheet for a maintenance item: mark done, log service, reminder task, edit, guide.
FOUNDATION_EXPORT void GarageShowPlanActions(UIViewController *from, PlanStatus *status);

NS_ASSUME_NONNULL_END
