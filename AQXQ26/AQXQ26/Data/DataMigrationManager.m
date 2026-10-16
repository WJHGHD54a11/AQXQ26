//
//  DataMigrationManager.m
//  WorkSpace
//

#import "DataMigrationManager.h"
#import "NoteCategory.h"
#import "AppConstants.h"

static NSString * const kDataVersionKey = @"WorkSpace.dataVersion";

@implementation DataMigrationManager

+ (NSURL *)dataDirectoryURL {
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [support URLByAppendingPathComponent:@"WorkSpace" isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

+ (NSURL *)storeURL {
    return [[self dataDirectoryURL] URLByAppendingPathComponent:@"WorkSpace.sqlite"];
}

+ (NSInteger)currentDataVersion {
    return 1;
}

+ (void)runPostLoadStepsInContext:(NSManagedObjectContext *)context {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSInteger version = [defaults integerForKey:kDataVersionKey];
    if (version >= [self currentDataVersion]) return;

    if (version < 1) {
        [self seedDefaultCategoriesInContext:context];
    }

    NSError *error = nil;
    if (context.hasChanges && ![context save:&error]) {
        NSLog(@"[Migration] save failed: %@", error);
        [context rollback];
        return; // retry next launch
    }
    [defaults setInteger:[self currentDataVersion] forKey:kDataVersionKey];
}

/// Starter categories. They are ordinary rows: users can rename or delete them.
+ (void)seedDefaultCategoriesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NoteCategory fetchRequest];
    if ([context countForFetchRequest:request error:nil] > 0) return;

    NSArray *defaults = @[@[@"Personal", @"teal"], @[@"Work", @"indigo"], @[@"Ideas", @"amber"]];
    [defaults enumerateObjectsUsingBlock:^(NSArray *pair, NSUInteger idx, BOOL *stop) {
        NoteCategory *category = [NSEntityDescription insertNewObjectForEntityForName:@"NoteCategory" inManagedObjectContext:context];
        category.uuid = NSUUID.UUID.UUIDString;
        category.name = WSLocalized(pair[0]);
        category.colorIdentifier = pair[1];
        category.sortIndex = (int32_t)idx;
        category.createdAt = NSDate.date;
    }];
}

@end
