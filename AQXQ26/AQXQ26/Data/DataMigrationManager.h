//
//  DataMigrationManager.h
//  WorkSpace
//
//  Store location, data version bookkeeping and one-time setup that has to
//  happen after the store opens (default note categories, file folder moves).
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface DataMigrationManager : NSObject

/// Application Support/WorkSpace/WorkSpace.sqlite
+ (NSURL *)storeURL;
/// Application Support/WorkSpace/
+ (NSURL *)dataDirectoryURL;

/// Current data version. Bump when a post-load step is added.
+ (NSInteger)currentDataVersion;

+ (void)runPostLoadStepsInContext:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
