//
//  ChecklistItem.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in ChecklistItem+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class Task;

NS_ASSUME_NONNULL_BEGIN

@interface ChecklistItem : NSManagedObject

+ (NSFetchRequest<ChecklistItem *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, assign) int32_t sortIndex;

@property (nonatomic, nullable, strong) Task *task;

@end

NS_ASSUME_NONNULL_END
