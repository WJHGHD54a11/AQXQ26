//
//  Template.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Template+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface Template : NSManagedObject

+ (NSFetchRequest<Template *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *detail;
@property (nonatomic, assign) TemplateKind kind;
@property (nonatomic, nullable, copy) NSString *payload;
@property (nonatomic, assign) int32_t useCount;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;


@end

NS_ASSUME_NONNULL_END
