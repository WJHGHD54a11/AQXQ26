//
//  DataManager.h
//  WorkSpace
//
//  Façade over Core Data used by every feature manager:
//  insert / fetch / save, and the WSDataDidChangeNotification broadcast that
//  keeps Dashboard, lists and details in sync without manual refresh calls.
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface DataManager : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) NSManagedObjectContext *context;

/// New object with uuid / createdAt / updatedAt filled in where the entity has them.
- (__kindof NSManagedObject *)insertEntity:(NSString *)entityName;

- (NSArray *)fetch:(NSFetchRequest *)request;
- (NSUInteger)count:(NSFetchRequest *)request;
- (nullable __kindof NSManagedObject *)objectOfKind:(WSObjectKind)kind uuid:(NSString *)uuid;

/// Saves the view context. On failure the context is rolled back, `error` is filled,
/// and NO is returned; callers show the message instead of crashing.
- (BOOL)save:(NSError **)error;

/// Deletes the object if it still exists. Returns NO when it was already gone.
- (BOOL)deleteObject:(nullable NSManagedObject *)object;

/// Short-circuit for screens that must refresh on the next run loop after a save.
- (void)observeChanges:(id)observer selector:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
