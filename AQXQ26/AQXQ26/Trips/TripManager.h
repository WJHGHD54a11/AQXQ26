//
//  TripManager.h
//  WorkSpace
//
//  Trip log: CRUD, statistics, mileage reimbursement and CSV export.
//  Trips move the vehicle odometer forward, which feeds the maintenance plans.
//

#import <Foundation/Foundation.h>
#import "Trip.h"

@class Vehicle;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSArray<NSString *> *TripPurposeTitles(void);
FOUNDATION_EXPORT NSString *TripPurposeSymbol(TripPurpose purpose);
FOUNDATION_EXPORT NSString *TripPurposeColor(TripPurpose purpose);   // palette identifier
enum { TripPurposeCount = 5 };

@interface TripDraft : NSObject
@property (nonatomic, strong, nullable) Vehicle *vehicle;
@property (nonatomic) TripPurpose purpose;
@property (nonatomic, copy, nullable) NSString *title, *fromPlace, *toPlace, *notes;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic) double startOdometer, endOdometer, expense;
+ (instancetype)draftFromTrip:(nullable Trip *)trip vehicle:(nullable Vehicle *)vehicle;
@end

@interface TripStats : NSObject
@property (nonatomic) double distance;            // km in range
@property (nonatomic) NSUInteger count;
@property (nonatomic) double businessDistance;
@property (nonatomic) double expense;             // all trip expenses in range
@property (nonatomic) double businessExpense;
@property (nonatomic) double reimbursement;       // businessDistance × rate + businessExpense
/// Distance per purpose, index = TripPurpose.
@property (nonatomic, copy) NSArray<NSNumber *> *byPurpose;
@property (nonatomic, strong, nullable) Trip *longest;
@end

@interface TripManager : NSObject

+ (instancetype)shared;

- (NSArray<Trip *> *)tripsFrom:(nullable NSDate *)from to:(nullable NSDate *)to purpose:(NSInteger)purpose;   // purpose -1 = all, newest first
- (nullable Trip *)createTrip:(TripDraft *)draft error:(NSError **)error;
- (BOOL)updateTrip:(Trip *)trip with:(TripDraft *)draft error:(NSError **)error;
- (BOOL)deleteTrip:(Trip *)trip error:(NSError **)error;

#pragma mark Stats
- (TripStats *)statsFrom:(nullable NSDate *)from to:(nullable NSDate *)to;
/// Last 12 months, oldest first: @{ @"month": NSDate, @"values": @[distance per purpose] }
- (NSArray<NSDictionary *> *)monthlyDistance;
/// startOfDay → km, for the last `days` days.
- (NSDictionary<NSDate *, NSNumber *> *)dailyDistanceForLast:(NSInteger)days;
/// Most frequent from → to pairs: @{ @"from", @"to", @"count", @"distance" }
- (NSArray<NSDictionary *> *)topRoutes:(NSUInteger)limit;
+ (NSDate *)startOfMonthOffset:(NSInteger)months;   // 0 = this month, -1 = last month

#pragma mark Reimbursement
/// Amount paid per km for business trips. 0 = not set.
@property (class, nonatomic) double reimbursementRate;

#pragma mark Export
/// Writes a CSV for the range to a temporary file.
- (nullable NSURL *)exportCSVFrom:(nullable NSDate *)from to:(nullable NSDate *)to error:(NSError **)error;

#pragma mark Sample data
/// Inserts (does not save) ~6 months of trips that fit the vehicle's odometer timeline.
- (void)insertSampleTripsFor:(Vehicle *)vehicle days:(NSInteger)days odometerAt:(double (^)(NSInteger daysAgo))odometerAt;

@end

NS_ASSUME_NONNULL_END
