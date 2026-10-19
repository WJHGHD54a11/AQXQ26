//
//  TripEditViewController.h
//  WorkSpace
//

#import "WSFormViewController.h"

@class Trip, Vehicle;

NS_ASSUME_NONNULL_BEGIN

@interface TripEditViewController : WSFormViewController
/// New trip when `trip` is nil; `template` prefills purpose and places (repeat a route).
- (instancetype)initWithTrip:(nullable Trip *)trip vehicle:(nullable Vehicle *)vehicle template:(nullable Trip *)templateTrip;
/// Prefills a new trip's route (call before presenting). `km` > 0 also suggests the end mileage.
- (void)prefillFrom:(nullable NSString *)from to:(nullable NSString *)to purpose:(NSInteger)purpose distance:(double)km;
@end

NS_ASSUME_NONNULL_END
