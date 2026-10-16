//
//  CoreDataManager.h
//  WorkSpace
//
//  Owns the persistent container. Everything else talks to DataManager.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataManager : NSObject

+ (instancetype)shared;

/// Loads the store synchronously. Safe to call more than once.
- (void)loadStoreWithCompletion:(void (^)(NSError * _Nullable error))completion;

@property (nonatomic, readonly) NSPersistentContainer *container;
@property (nonatomic, readonly) NSManagedObjectContext *viewContext;
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;
/// Set when the store could not be opened; the app then runs on an in-memory store.
@property (nonatomic, readonly, nullable) NSError *loadError;

/// Private-queue context for imports / exports / search. Merges into viewContext on save.
- (NSManagedObjectContext *)newBackgroundContext;

@end

NS_ASSUME_NONNULL_END
