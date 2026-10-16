//
//  BackupManager.m
//  WorkSpace
//

#import "BackupManager.h"
#import "CoreDataManager.h"
#import "AppConstants.h"

NSString * const BackupFormatIdentifier = @"workspace.backup";
NSInteger const BackupFormatVersion = 1;

@implementation BackupManager

+ (instancetype)shared {
    static BackupManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

#pragma mark - Encoding helpers

+ (NSISO8601DateFormatter *)dateFormatter {
    static NSISO8601DateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = [[NSISO8601DateFormatter alloc] init];
        f.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    });
    return f;
}

/// Attributes → JSON-safe values; to-one relationships → uuid; to-many → [uuid].
/// `skip` lists keys that should not be written (back-references, derived).
- (NSDictionary *)encode:(NSManagedObject *)object skip:(NSSet<NSString *> *)skip {
    NSMutableDictionary *out = NSMutableDictionary.new;
    [object.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attr, BOOL *stop) {
        if ([skip containsObject:key]) return;
        id value = [object valueForKey:key];
        if (!value) return;
        if ([value isKindOfClass:NSDate.class]) value = [BackupManager.dateFormatter stringFromDate:value];
        out[key] = value;
    }];
    [object.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *rel, BOOL *stop) {
        if ([skip containsObject:key]) return;
        id value = [object valueForKey:key];
        if (rel.isToMany) {
            NSArray *ids = [[value valueForKey:@"uuid"] allObjects];
            if (ids.count) out[key] = [ids sortedArrayUsingSelector:@selector(compare:)];
        } else if (value) {
            NSString *uuid = [value valueForKey:@"uuid"];
            if (uuid) out[key] = uuid;
        }
    }];
    return out;
}

- (NSArray *)all:(NSString *)entity skip:(NSSet *)skip in:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    request.fetchBatchSize = 200;
    NSMutableArray *rows = NSMutableArray.new;
    for (NSManagedObject *o in [context executeFetchRequest:request error:nil]) {
        [rows addObject:[self encode:o skip:skip]];
    }
    return rows;
}

#pragma mark - Export

- (void)exportWithCompletion:(void (^)(NSURL *, NSError *))completion {
    NSManagedObjectContext *context = [CoreDataManager.shared newBackgroundContext];
    [context performBlock:^{
        // Relationships are written from one side only; the importer rebuilds inverses.
        NSSet *common = [NSSet setWithObjects:@"lastOpenedAt", nil];
        NSDictionary *sections = @{
            @"tags":           [self all:@"Tag" skip:[common setByAddingObjectsFromArray:@[@"tasks", @"projects", @"notes"]] in:context],
            @"noteCategories": [self all:@"NoteCategory" skip:[common setByAddingObject:@"notes"] in:context],
            @"projects":       [self all:@"Project" skip:[common setByAddingObjectsFromArray:@[@"tasks", @"notes", @"files"]] in:context],
            @"tasks":          [self all:@"Task" skip:[common setByAddingObjectsFromArray:@[@"subtasks", @"checklistItems", @"attachments"]] in:context],
            @"checklistItems": [self allChecklistIn:context],
            @"notes":          [self all:@"Note" skip:common in:context],
            @"schedules":      [self all:@"Schedule" skip:common in:context],
            @"templates":      [self all:@"Template" skip:common in:context],
            @"files":          [self all:@"FileItem" skip:[common setByAddingObject:@"storedName"] in:context],
        };
        [context reset];

        NSMutableDictionary *counts = NSMutableDictionary.new;
        [sections enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *rows, BOOL *stop) { counts[key] = @(rows.count); }];

        NSMutableDictionary *root = [sections mutableCopy];
        root[@"format"] = BackupFormatIdentifier;
        root[@"version"] = @(BackupFormatVersion);
        root[@"exportedAt"] = [BackupManager.dateFormatter stringFromDate:NSDate.date];
        root[@"app"] = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";

        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:root options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
        NSURL *url = nil;
        if (data) {
            NSDateFormatter *df = NSDateFormatter.new;
            df.dateFormat = @"yyyy-MM-dd";
            NSString *name = [NSString stringWithFormat:@"WorkSpace Backup %@.json", [df stringFromDate:NSDate.date]];
            url = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:name];
            [NSFileManager.defaultManager removeItemAtURL:url error:nil];
            if (![data writeToURL:url options:NSDataWritingAtomic error:&error]) url = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_lastExportCounts = counts;
            completion(url, url ? nil : (error ?: [NSError errorWithDomain:@"WorkSpace" code:9
                                                                  userInfo:@{NSLocalizedDescriptionKey: WSText(@"Export failed.")}]));
        });
    }];
}

/// Checklist items are exported flat with their task uuid so order and state survive.
- (NSArray *)allChecklistIn:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChecklistItem"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]];
    NSMutableArray *rows = NSMutableArray.new;
    for (NSManagedObject *o in [context executeFetchRequest:request error:nil]) {
        if (![o valueForKey:@"task"]) continue;
        [rows addObject:[self encode:o skip:[NSSet set]]];
    }
    return rows;
}

@end
