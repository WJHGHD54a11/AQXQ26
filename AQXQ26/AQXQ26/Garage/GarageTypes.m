//
//  GarageTypes.m
//  WorkSpace
//

#import "GarageTypes.h"
#import "AppConstants.h"

NSArray<NSString *> *VehicleFuelTypeTitles(void) {
    return @[WSText(@"Gasoline"), WSText(@"Diesel"), WSText(@"Hybrid")];
}

NSArray<NSString *> *ServiceCategoryTitles(void) {
    return @[WSText(@"Maintenance"), WSText(@"Repair"), WSText(@"Tires"), WSText(@"Car Wash"),
             WSText(@"Insurance"), WSText(@"Inspection"), WSText(@"Parking & Tolls"), WSText(@"Other")];
}

NSString *ServiceCategorySymbol(NSInteger category) {
    if (category == ServiceCategoryFuelChart) return @"fuelpump.fill";
    NSArray *symbols = @[@"wrench.and.screwdriver.fill", @"hammer.fill", @"circle.circle.fill", @"drop.fill",
                         @"shield.lefthalf.filled", @"checkmark.seal.fill", @"parkingsign.circle.fill", @"ellipsis.circle.fill"];
    return (category >= 0 && category < (NSInteger)symbols.count) ? symbols[category] : symbols.lastObject;
}

NSString *ServiceCategoryColor(NSInteger category) {
    if (category == ServiceCategoryFuelChart) return @"amber";
    NSArray *colors = @[@"indigo", @"rose", @"teal", @"sky", @"violet", @"lime", @"amber", @"slate"];
    return (category >= 0 && category < (NSInteger)colors.count) ? colors[category] : @"slate";
}

NSString *GarageText(NSString *key) {
    if (key.length == 0) return @"";
    return [NSBundle.mainBundle localizedStringForKey:key value:key table:@"Garage"];
}
