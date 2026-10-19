//
//  GarageCatalog.h
//  WorkSpace
//
//  Built-in maintenance knowledge: service items with recommended intervals,
//  dashboard warning lights and inspection checklists. Text is English, translated in Garage.strings.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GarageItem : NSObject
@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *symbol;
@property (nonatomic, readonly) double intervalKm;       // 0 = time only
@property (nonatomic, readonly) NSInteger intervalMonths; // 0 = mileage only
@property (nonatomic, copy, readonly) NSString *summary;
@property (nonatomic, copy, readonly) NSArray<NSString *> *tips;
/// Created as a plan when a vehicle is added.
@property (nonatomic, readonly) BOOL defaultPlan;
@end

typedef NS_ENUM(NSInteger, WarningLevel) {
    WarningLevelInfo = 0,   // green / blue
    WarningLevelCaution,    // amber: check soon
    WarningLevelStop,       // red: stop safely
};

@interface GarageWarningLight : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *symbol;
@property (nonatomic, readonly) WarningLevel level;
@property (nonatomic, copy, readonly) NSString *meaning;
@property (nonatomic, copy, readonly) NSString *action;
@end

@interface GarageChecklist : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *symbol;
@property (nonatomic, copy, readonly) NSString *summary;
@property (nonatomic, copy, readonly) NSArray<NSString *> *items;
@end

@interface GarageCatalog : NSObject
+ (NSArray<GarageItem *> *)items;
+ (nullable GarageItem *)itemForKey:(nullable NSString *)key;
+ (NSArray<GarageWarningLight *> *)warningLights;
+ (NSArray<GarageChecklist *> *)checklists;
+ (UIColor *)colorForWarningLevel:(WarningLevel)level;
@end

NS_ASSUME_NONNULL_END
