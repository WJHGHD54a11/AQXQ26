//
//  RecentManager.m
//  WorkSpace
//

#import "RecentManager.h"
#import "DataManager.h"

@implementation RecentManager

+ (instancetype)shared {
    static RecentManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

+ (NSArray<NSNumber *> *)trackedKinds {
    return @[@(WSObjectKindTask), @(WSObjectKindProject), @(WSObjectKindNote), @(WSObjectKindFile), @(WSObjectKindSchedule)];
}

- (void)markOpened:(NSManagedObject *)object {
    if (!object || object.isDeleted || !object.entity.attributesByName[@"lastOpenedAt"]) return;
    NSDate *last = [object valueForKey:@"lastOpenedAt"];
    // Avoid a save (and a list reload) when the same item is reopened within a minute.
    if (last && -last.timeIntervalSinceNow < 60) return;
    [object setValue:NSDate.date forKey:@"lastOpenedAt"];
    [DataManager.shared save:nil];
}

- (NSArray *)recentOfKind:(WSObjectKind)kind limit:(NSUInteger)limit {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WSObjectKindEntityName(kind)];
    request.predicate = [NSPredicate predicateWithFormat:@"lastOpenedAt != nil"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastOpenedAt" ascending:NO]];
    request.fetchLimit = limit;
    return [DataManager.shared fetch:request];
}

- (NSArray<NSManagedObject *> *)recentItems:(NSUInteger)limit {
    NSMutableArray *all = NSMutableArray.new;
    for (NSNumber *kind in self.class.trackedKinds) {
        [all addObjectsFromArray:[self recentOfKind:kind.integerValue limit:limit]];
    }
    [all sortUsingComparator:^NSComparisonResult(NSManagedObject *a, NSManagedObject *b) {
        return [[b valueForKey:@"lastOpenedAt"] compare:[a valueForKey:@"lastOpenedAt"]];
    }];
    return all.count > limit ? [all subarrayWithRange:NSMakeRange(0, limit)] : all;
}

@end
