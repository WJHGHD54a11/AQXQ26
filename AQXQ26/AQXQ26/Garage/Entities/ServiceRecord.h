//
//  ServiceRecord.h
//  WorkSpace
//

#import <CoreData/CoreData.h>
#import "GarageTypes.h"

@class Vehicle;

NS_ASSUME_NONNULL_BEGIN

@interface ServiceRecord : NSManagedObject

+ (NSFetchRequest<ServiceRecord *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) ServiceCategory category;
@property (nonatomic, copy) NSString *title;
/// Comma separated catalog item keys covered by this visit (e.g. "oil,oil_filter").
@property (nonatomic, nullable, copy) NSString *itemKeys;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) double odometer;
@property (nonatomic, assign) double cost;
@property (nonatomic, nullable, copy) NSString *shop;
@property (nonatomic, nullable, copy) NSString *notes;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) Vehicle *vehicle;

@end

NS_ASSUME_NONNULL_END
