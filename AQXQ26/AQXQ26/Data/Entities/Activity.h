//
//  Activity.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Activity+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface Activity : NSManagedObject

+ (NSFetchRequest<Activity *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *detail;
@property (nonatomic, nullable, copy) NSString *objectId;
@property (nonatomic, nullable, copy) NSString *objectKind;
@property (nonatomic, strong) NSDate *createdAt;


@end

NS_ASSUME_NONNULL_END
