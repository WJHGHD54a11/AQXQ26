//
//  RecentManager.h
//  WorkSpace
//
//  "Recently opened" is stored as lastOpenedAt on each entity so it survives
//  backup/restore and disappears automatically when the object is deleted.
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecentManager : NSObject

+ (instancetype)shared;

/// Stamps lastOpenedAt and saves quietly. Ignored for kinds that do not track recents.
- (void)markOpened:(NSManagedObject *)object;

- (NSArray *)recentOfKind:(WSObjectKind)kind limit:(NSUInteger)limit;

/// Mixed list across Task / Project / Note / File / Schedule, newest first.
- (NSArray<NSManagedObject *> *)recentItems:(NSUInteger)limit;

@end

NS_ASSUME_NONNULL_END
