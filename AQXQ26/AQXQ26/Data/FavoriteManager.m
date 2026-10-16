//
//  FavoriteManager.m
//  WorkSpace
//

#import "FavoriteManager.h"
#import "DataManager.h"

@implementation FavoriteManager

+ (instancetype)shared {
    static FavoriteManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

+ (NSArray<NSNumber *> *)favoritableKinds {
    return @[@(WSObjectKindTask), @(WSObjectKindProject), @(WSObjectKindNote),
             @(WSObjectKindFile), @(WSObjectKindSchedule), @(WSObjectKindTemplate)];
}

- (BOOL)supports:(NSManagedObject *)object {
    return object.entity.attributesByName[@"isFavorite"] != nil;
}

- (BOOL)isFavorite:(NSManagedObject *)object {
    return [self supports:object] && [[object valueForKey:@"isFavorite"] boolValue];
}

- (BOOL)toggleFavorite:(NSManagedObject *)object error:(NSError **)error {
    if (![self supports:object] || object.isDeleted) return NO;
    BOOL newValue = ![self isFavorite:object];
    [object setValue:@(newValue) forKey:@"isFavorite"];
    if (![DataManager.shared save:error]) return !newValue;
    return newValue;
}

- (NSDictionary<NSNumber *, NSArray<NSManagedObject *> *> *)favoritesByKind {
    NSMutableDictionary *result = NSMutableDictionary.new;
    for (NSNumber *kind in self.class.favoritableKinds) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WSObjectKindEntityName(kind.integerValue)];
        request.predicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
        if (kind.integerValue == WSObjectKindFile) {
            request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedAt" ascending:NO]];
        }
        NSArray *items = [DataManager.shared fetch:request];
        if (items.count) result[kind] = items;
    }
    return result;
}

- (NSUInteger)favoriteCount {
    NSUInteger total = 0;
    for (NSNumber *kind in self.class.favoritableKinds) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WSObjectKindEntityName(kind.integerValue)];
        request.predicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
        total += [DataManager.shared count:request];
    }
    return total;
}

@end
