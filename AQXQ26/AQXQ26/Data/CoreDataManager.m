//
//  CoreDataManager.m
//  WorkSpace
//

#import "CoreDataManager.h"
#import "DataMigrationManager.h"

@implementation CoreDataManager

+ (instancetype)shared {
    static CoreDataManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (instancetype)init {
    if ((self = [super init])) {
        _container = [NSPersistentContainer persistentContainerWithName:@"WorkSpace"];
        NSPersistentStoreDescription *store = _container.persistentStoreDescriptions.firstObject;
        store.URL = [DataMigrationManager storeURL];
        store.shouldMigrateStoreAutomatically = YES;
        store.shouldInferMappingModelAutomatically = YES;
        [store setOption:@YES forKey:NSPersistentHistoryTrackingKey];
    }
    return self;
}

- (NSManagedObjectContext *)viewContext {
    return self.container.viewContext;
}

- (void)loadStoreWithCompletion:(void (^)(NSError *))completion {
    if (self.loaded) {
        if (completion) completion(self.loadError);
        return;
    }
    __block NSError *failure = nil;
    [self.container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *description, NSError *error) {
        failure = error;
    }];

    if (failure) {
        // Keep the app usable instead of crashing: fall back to memory and surface the error.
        NSLog(@"[CoreData] store failed to load: %@", failure);
        _loadError = failure;
        NSPersistentStoreDescription *memory = [NSPersistentStoreDescription persistentStoreDescriptionWithURL:[NSURL fileURLWithPath:@"/dev/null"]];
        memory.type = NSInMemoryStoreType;
        self.container.persistentStoreDescriptions = @[memory];
        [self.container loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *d, NSError *e) {}];
    }

    NSManagedObjectContext *context = self.container.viewContext;
    context.automaticallyMergesChangesFromParent = YES;
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    context.undoManager = nil;
    context.name = @"view";
    _loaded = YES;

    [DataMigrationManager runPostLoadStepsInContext:context];
    if (completion) completion(self.loadError);
}

- (NSManagedObjectContext *)newBackgroundContext {
    NSManagedObjectContext *context = [self.container newBackgroundContext];
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    context.undoManager = nil;
    return context;
}

@end
