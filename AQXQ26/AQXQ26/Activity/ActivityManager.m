//
//  ActivityManager.m
//  WorkSpace
//

#import "ActivityManager.h"
#import "DataManager.h"
#import "Activity.h"

/// Older history is trimmed so the table stays small on long-term use.
static NSUInteger const kActivityKeepLimit = 2000;

@implementation ActivityManager

+ (instancetype)shared {
    static ActivityManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (void)record:(NSString *)type title:(NSString *)title detail:(NSString *)detail objectId:(NSString *)objectId {
    Activity *activity = [DataManager.shared insertEntity:@"Activity"];
    activity.type = type;
    activity.title = title.length ? title : WSText(@"Untitled");
    activity.detail = detail;
    activity.objectId = objectId;
    activity.objectKind = WSObjectKindEntityName(ActivityTypeObjectKind(type));
    [self trimIfNeeded];
}

- (void)trimIfNeeded {
    NSFetchRequest *count = [Activity fetchRequest];
    NSUInteger total = [DataManager.shared count:count];
    if (total <= kActivityKeepLimit + 100) return;

    NSFetchRequest *old = [Activity fetchRequest];
    old.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    old.fetchLimit = total - kActivityKeepLimit;
    for (Activity *a in [DataManager.shared fetch:old]) [DataManager.shared deleteObject:a];
}

- (NSArray<Activity *> *)recentActivities:(NSUInteger)limit {
    NSFetchRequest *request = [self requestForKind:nil day:nil];
    request.fetchLimit = limit;
    return [DataManager.shared fetch:request];
}

- (NSFetchRequest *)requestForKind:(NSNumber *)kind day:(NSDate *)day {
    NSFetchRequest *request = [Activity fetchRequest];
    NSMutableArray *predicates = NSMutableArray.new;
    if (kind) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"objectKind == %@", WSObjectKindEntityName(kind.integerValue)]];
    }
    if (day) {
        NSCalendar *cal = NSCalendar.currentCalendar;
        NSDate *start = [cal startOfDayForDate:day];
        NSDate *end = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
        [predicates addObject:[NSPredicate predicateWithFormat:@"createdAt >= %@ AND createdAt < %@", start, end]];
    }
    if (predicates.count) request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    request.fetchBatchSize = 40;
    return request;
}

- (NSArray<Activity *> *)activitiesForObjectIds:(NSArray<NSString *> *)objectIds limit:(NSUInteger)limit {
    if (objectIds.count == 0) return @[];
    NSFetchRequest *request = [Activity fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", objectIds];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    request.fetchLimit = limit;
    return [DataManager.shared fetch:request];
}

- (BOOL)deleteActivity:(Activity *)activity error:(NSError **)error {
    if (![DataManager.shared deleteObject:activity]) return YES;
    return [DataManager.shared save:error];
}

- (BOOL)clearKind:(NSNumber *)kind day:(NSDate *)day error:(NSError **)error {
    NSFetchRequest *request = [self requestForKind:kind day:day];
    request.includesPropertyValues = NO;
    for (Activity *a in [DataManager.shared fetch:request]) [DataManager.shared deleteObject:a];
    return [DataManager.shared save:error];
}

@end
