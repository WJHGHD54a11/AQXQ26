//
//  DataManager.m
//  WorkSpace
//

#import "DataManager.h"
#import "CoreDataManager.h"

@implementation DataManager

+ (instancetype)shared {
    static DataManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (instancetype)init {
    if ((self = [super init])) {
        // Background contexts (import, restore) merge into the view context; broadcast those too.
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(contextDidSave:)
                                                   name:NSManagedObjectContextObjectsDidChangeNotification
                                                 object:nil];
    }
    return self;
}

- (NSManagedObjectContext *)context {
    return CoreDataManager.shared.viewContext;
}

- (__kindof NSManagedObject *)insertEntity:(NSString *)entityName {
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.context];
    NSDictionary *attributes = object.entity.attributesByName;
    NSDate *now = NSDate.date;
    if (attributes[@"uuid"])       [object setValue:NSUUID.UUID.UUIDString forKey:@"uuid"];
    if (attributes[@"createdAt"])  [object setValue:now forKey:@"createdAt"];
    if (attributes[@"updatedAt"])  [object setValue:now forKey:@"updatedAt"];
    if (attributes[@"modifiedAt"]) [object setValue:now forKey:@"modifiedAt"];
    return object;
}

- (NSArray *)fetch:(NSFetchRequest *)request {
    NSError *error = nil;
    NSArray *result = [self.context executeFetchRequest:request error:&error];
    if (error) NSLog(@"[Data] fetch %@ failed: %@", request.entityName, error);
    return result ?: @[];
}

- (NSUInteger)count:(NSFetchRequest *)request {
    NSUInteger n = [self.context countForFetchRequest:request error:nil];
    return n == NSNotFound ? 0 : n;
}

- (NSManagedObject *)objectOfKind:(WSObjectKind)kind uuid:(NSString *)uuid {
    if (uuid.length == 0) return nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WSObjectKindEntityName(kind)];
    request.predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    request.fetchLimit = 1;
    return [self fetch:request].firstObject;
}

- (BOOL)save:(NSError **)error {
    if (!self.context.hasChanges) return YES;
    NSError *saveError = nil;
    if ([self.context save:&saveError]) return YES;
    NSLog(@"[Data] save failed: %@", saveError);
    [self.context rollback];
    if (error) {
        *error = [NSError errorWithDomain:@"WorkSpace" code:saveError.code
                                 userInfo:@{NSLocalizedDescriptionKey: WSText(@"Could not save your changes. Please try again."),
                                            NSUnderlyingErrorKey: saveError}];
    }
    return NO;
}

- (BOOL)deleteObject:(NSManagedObject *)object {
    if (!object || object.isDeleted || object.managedObjectContext == nil) return NO;
    [self.context deleteObject:object];
    return YES;
}

- (void)observeChanges:(id)observer selector:(SEL)selector {
    [NSNotificationCenter.defaultCenter addObserver:observer selector:selector name:WSDataDidChangeNotification object:nil];
}

#pragma mark - Broadcast

/// Collapses Core Data's per-object change notification into one "kinds changed" event per run loop.
- (void)contextDidSave:(NSNotification *)note {
    if (note.object != self.context) return;
    NSMutableSet<NSNumber *> *kinds = NSMutableSet.new;
    for (NSString *key in @[NSInsertedObjectsKey, NSUpdatedObjectsKey, NSDeletedObjectsKey, NSRefreshedObjectsKey]) {
        for (NSManagedObject *object in note.userInfo[key]) {
            NSNumber *kind = [self kindForEntity:object.entity.name];
            if (kind) [kinds addObject:kind];
        }
    }
    if (kinds.count == 0) return;
    [self.pendingKinds unionSet:kinds];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(flushChanges) object:nil];
    [self performSelector:@selector(flushChanges) withObject:nil afterDelay:0];
}

- (NSMutableSet<NSNumber *> *)pendingKinds {
    static NSMutableSet *set;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ set = NSMutableSet.new; });
    return set;
}

- (void)flushChanges {
    NSSet *kinds = [self.pendingKinds copy];
    [self.pendingKinds removeAllObjects];
    [NSNotificationCenter.defaultCenter postNotificationName:WSDataDidChangeNotification object:self
                                                    userInfo:@{WSChangedKindsKey: kinds}];
}

- (NSNumber *)kindForEntity:(NSString *)entity {
    static NSDictionary *map;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        map = @{@"Task": @(WSObjectKindTask), @"ChecklistItem": @(WSObjectKindTask), @"Project": @(WSObjectKindProject),
                @"Note": @(WSObjectKindNote), @"NoteCategory": @(WSObjectKindNoteCategory), @"FileItem": @(WSObjectKindFile),
                @"Schedule": @(WSObjectKindSchedule), @"Template": @(WSObjectKindTemplate), @"Activity": @(WSObjectKindActivity),
                @"Tag": @(WSObjectKindTag)};
    });
    return map[entity];
}

@end
