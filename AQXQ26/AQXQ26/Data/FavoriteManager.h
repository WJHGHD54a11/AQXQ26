//
//  FavoriteManager.h
//  WorkSpace
//
//  Favorites are the isFavorite flag on Task / Project / Note / FileItem /
//  Schedule / Template; this class is the single place that toggles and lists them.
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface FavoriteManager : NSObject

+ (instancetype)shared;

- (BOOL)isFavorite:(NSManagedObject *)object;
/// Flips the flag and saves. Returns the new state.
- (BOOL)toggleFavorite:(NSManagedObject *)object error:(NSError **)error;

/// Favorites grouped by kind (only kinds with at least one item).
- (NSDictionary<NSNumber *, NSArray<NSManagedObject *> *> *)favoritesByKind;
- (NSUInteger)favoriteCount;

@end

NS_ASSUME_NONNULL_END
