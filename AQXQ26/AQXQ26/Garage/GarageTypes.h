//
//  GarageTypes.h
//  WorkSpace
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int16_t, VehicleFuelType) {
    VehicleFuelGasoline = 0,
    VehicleFuelDiesel,
    VehicleFuelHybrid,
};

typedef NS_ENUM(int16_t, ServiceCategory) {
    ServiceCategoryMaintenance = 0,
    ServiceCategoryRepair,
    ServiceCategoryTires,
    ServiceCategoryWash,
    ServiceCategoryInsurance,
    ServiceCategoryInspection,
    ServiceCategoryParking,
    ServiceCategoryOther,
};
/// Fuel is not a ServiceCategory (it lives in FuelLog) but is charted alongside them.
static const NSInteger ServiceCategoryFuelChart = 100;

FOUNDATION_EXPORT NSArray<NSString *> *VehicleFuelTypeTitles(void);
FOUNDATION_EXPORT NSArray<NSString *> *ServiceCategoryTitles(void);
FOUNDATION_EXPORT NSString *ServiceCategorySymbol(NSInteger category);
FOUNDATION_EXPORT NSString *ServiceCategoryColor(NSInteger category);   // palette identifier

/// Localized string from Garage.strings (catalog text) with WorkSpace.strings as the UI table.
FOUNDATION_EXPORT NSString *GarageText(NSString *key);

NS_ASSUME_NONNULL_END
