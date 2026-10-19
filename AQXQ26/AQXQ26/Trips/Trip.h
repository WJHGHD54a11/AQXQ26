//
//  Trip.h
//  WorkSpace
//

#import <CoreData/CoreData.h>

@class Vehicle;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int16_t, TripPurpose) {
    TripPurposeCommute = 0,
    TripPurposeBusiness,
    TripPurposePersonal,
    TripPurposeTravel,
    TripPurposeOther,
};

@interface Trip : NSManagedObject

+ (NSFetchRequest<Trip *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) TripPurpose purpose;
@property (nonatomic, nullable, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *fromPlace;
@property (nonatomic, nullable, copy) NSString *toPlace;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, nullable, strong) NSDate *endDate;
@property (nonatomic, assign) double startOdometer;   // km
@property (nonatomic, assign) double endOdometer;     // km
/// Tolls, parking and other costs paid on the trip (reimbursable).
@property (nonatomic, assign) double expense;
@property (nonatomic, nullable, copy) NSString *notes;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) Vehicle *vehicle;

@property (nonatomic, readonly) double distance;      // km, never negative

@end

NS_ASSUME_NONNULL_END
