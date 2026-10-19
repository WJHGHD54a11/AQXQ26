//
//  ImportManager.m
//  WorkSpace
//

#import "ImportManager.h"
#import "BackupManager.h"
#import "CoreDataManager.h"
#import "ReminderManager.h"
#import "ActivityManager.h"
#import "DataManager.h"
#import "AppConstants.h"

static NSUInteger const kMaxBackupBytes = 50 * 1024 * 1024;

@implementation ImportReport

- (NSString *)summary {
    NSMutableArray *lines = NSMutableArray.new;
    [lines addObject:[NSString stringWithFormat:WSText(@"%lu added, %lu updated"), (unsigned long)self.created, (unsigned long)self.updated]];
    if (self.skipped) [lines addObject:[NSString stringWithFormat:WSText(@"%lu already up to date"), (unsigned long)self.skipped]];
    if (self.invalid) [lines addObject:[NSString stringWithFormat:WSText(@"%lu invalid records ignored"), (unsigned long)self.invalid]];
    return [lines componentsJoinedByString:@"\n"];
}

@end

/// Import order matters: referenced rows must exist before rows that point at them.
@interface WSImportSection : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *entity;
@property (nonatomic, copy) NSArray<NSString *> *required;   // non-empty string fields
@end
@implementation WSImportSection
+ (instancetype)key:(NSString *)key entity:(NSString *)entity required:(NSArray *)required {
    WSImportSection *s = [[self alloc] init];
    s.key = key; s.entity = entity; s.required = required;
    return s;
}
@end

@implementation ImportManager

+ (instancetype)shared {
    static ImportManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

+ (NSArray<WSImportSection *> *)sections {
    return @[[WSImportSection key:@"tags" entity:@"Tag" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"noteCategories" entity:@"NoteCategory" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"projects" entity:@"Project" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"tasks" entity:@"Task" required:@[@"uuid", @"title"]],
             [WSImportSection key:@"checklistItems" entity:@"ChecklistItem" required:@[@"uuid", @"title"]],
             [WSImportSection key:@"notes" entity:@"Note" required:@[@"uuid", @"title"]],
             [WSImportSection key:@"schedules" entity:@"Schedule" required:@[@"uuid", @"title", @"startTime"]],
             [WSImportSection key:@"templates" entity:@"Template" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"files" entity:@"FileItem" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"vehicles" entity:@"Vehicle" required:@[@"uuid", @"name"]],
             [WSImportSection key:@"serviceRecords" entity:@"ServiceRecord" required:@[@"uuid", @"date"]],
             [WSImportSection key:@"fuelLogs" entity:@"FuelLog" required:@[@"uuid", @"date"]],
             [WSImportSection key:@"maintenancePlans" entity:@"MaintenancePlan" required:@[@"uuid", @"itemKey"]],
             [WSImportSection key:@"trips" entity:@"Trip" required:@[@"uuid", @"date"]]];
}

- (NSError *)error:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:10 userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Entry

- (void)importBackupAt:(NSURL *)url completion:(void (^)(ImportReport *, NSError *))completion {
    void (^finish)(ImportReport *, NSError *) = ^(ImportReport *r, NSError *e) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(r, e); });
    };
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        BOOL scoped = [url startAccessingSecurityScopedResource];
        NSError *readError = nil;
        NSNumber *size = nil;
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        NSData *data = size.unsignedIntegerValue > kMaxBackupBytes ? nil : [NSData dataWithContentsOfURL:url options:0 error:&readError];
        if (scoped) [url stopAccessingSecurityScopedResource];

        if (!data) {
            finish(nil, [self error:size.unsignedIntegerValue > kMaxBackupBytes ? WSText(@"This file is too large to be a WorkSpace backup.")
                                                                                 : WSText(@"The file could not be read.")]);
            return;
        }
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSError *formatError = [self validateRoot:json];
        if (formatError) {
            finish(nil, formatError);
            return;
        }
        [self importRoot:json completion:finish];
    });
}

- (NSError *)validateRoot:(id)json {
    if (![json isKindOfClass:NSDictionary.class]) return [self error:WSText(@"This file is not valid JSON.")];
    if (![json[@"format"] isEqual:BackupFormatIdentifier]) return [self error:WSText(@"This JSON file is not a WorkSpace backup.")];
    NSInteger version = [json[@"version"] respondsToSelector:@selector(integerValue)] ? [json[@"version"] integerValue] : 0;
    if (version < 1 || version > BackupFormatVersion) {
        return [self error:WSText(@"This backup was made by a newer version of WorkSpace.")];
    }
    return nil;
}

#pragma mark - Import

- (void)importRoot:(NSDictionary *)root completion:(void (^)(ImportReport *, NSError *))finish {
    NSManagedObjectContext *context = [CoreDataManager.shared newBackgroundContext];
    [context performBlock:^{
        ImportReport *report = [[ImportReport alloc] init];
        NSMutableDictionary *sections = NSMutableDictionary.new;
        // uuid → object for everything touched, used to resolve references cheaply.
        NSMutableDictionary<NSString *, NSManagedObject *> *index = NSMutableDictionary.new;
        NSMutableArray *pendingLinks = NSMutableArray.new;

        for (WSImportSection *section in ImportManager.sections) {
            id rows = root[section.key];
            if (!rows) continue;
            if (![rows isKindOfClass:NSArray.class]) { report.invalid++; continue; }
            NSUInteger created = 0, updated = 0;
            NSDictionary *existing = [self existingIn:section.entity uuids:[rows valueForKey:@"uuid"] context:context];
            for (id row in rows) {
                if (![self rowIsValid:row section:section]) { report.invalid++; continue; }
                NSManagedObject *object = existing[row[@"uuid"]];
                if (object) {
                    if (![self isNewer:row than:object]) {
                        report.skipped++;
                        index[row[@"uuid"]] = object;
                        continue;
                    }
                    updated++;
                } else {
                    object = [NSEntityDescription insertNewObjectForEntityForName:section.entity inManagedObjectContext:context];
                    created++;
                }
                [self applyAttributes:row to:object];
                index[row[@"uuid"]] = object;
                [pendingLinks addObject:@[object, row]];
            }
            report.created += created;
            report.updated += updated;
            sections[section.key] = @[@(created), @(updated)];
        }

        // Second pass once every row exists, so forward references (subtask before parent) resolve.
        for (NSArray *pair in pendingLinks) [self applyRelationships:pair[1] to:pair[0] index:index context:context];
        report.sections = sections;

        NSError *error = nil;
        if (context.hasChanges && ![context save:&error]) {
            NSLog(@"[Import] save failed: %@", error);
            [context rollback];
            finish(nil, [self error:WSText(@"The backup could not be saved. Nothing was changed.")]);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (report.created + report.updated > 0) {
                [ActivityManager.shared record:ActivityTypeDataImported title:WSText(@"Backup restored")
                                        detail:[report summary] objectId:nil];
                [DataManager.shared save:nil];
            }
            [ReminderManager.shared rescheduleAll];
        });
        finish(report, nil);
    }];
}

- (NSDictionary<NSString *, NSManagedObject *> *)existingIn:(NSString *)entity uuids:(NSArray *)uuids context:(NSManagedObjectContext *)context {
    NSArray *valid = [uuids filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", NSString.class]];
    if (valid.count == 0) return @{};
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    request.predicate = [NSPredicate predicateWithFormat:@"uuid IN %@", valid];
    NSMutableDictionary *map = NSMutableDictionary.new;
    for (NSManagedObject *o in [context executeFetchRequest:request error:nil]) map[[o valueForKey:@"uuid"]] = o;
    return map;
}

- (BOOL)rowIsValid:(id)row section:(WSImportSection *)section {
    if (![row isKindOfClass:NSDictionary.class]) return NO;
    for (NSString *key in section.required) {
        id value = row[key];
        if (![value isKindOfClass:NSString.class] || [value length] == 0) return NO;
    }
    return YES;
}

- (BOOL)isNewer:(NSDictionary *)row than:(NSManagedObject *)object {
    NSString *key = object.entity.attributesByName[@"updatedAt"] ? @"updatedAt" : (object.entity.attributesByName[@"modifiedAt"] ? @"modifiedAt" : nil);
    if (!key) return NO; // no timestamp (tags, checklist) → keep local copy
    NSDate *incoming = [self dateFrom:row[key]];
    NSDate *local = [object valueForKey:key];
    return incoming && (!local || [incoming compare:local] == NSOrderedDescending);
}

- (NSDate *)dateFrom:(id)value {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSISO8601DateFormatter *f = [[NSISO8601DateFormatter alloc] init];
    f.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    NSDate *date = [f dateFromString:value];
    if (!date) {
        f.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        date = [f dateFromString:value];
    }
    return date;
}

/// Only known attributes with the right type are copied; anything else is ignored.
- (void)applyAttributes:(NSDictionary *)row to:(NSManagedObject *)object {
    [object.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSAttributeDescription *attr, BOOL *stop) {
        if ([key isEqualToString:@"storedName"]) return;
        id value = row[key];
        if (!value || value == NSNull.null) {
            if (!attr.isOptional) return;
            if (row[key] == NSNull.null) [object setValue:nil forKey:key];
            return;
        }
        switch (attr.attributeType) {
            case NSStringAttributeType:
                if ([value isKindOfClass:NSString.class]) [object setValue:value forKey:key];
                break;
            case NSDateAttributeType: {
                NSDate *d = [self dateFrom:value];
                if (d) [object setValue:d forKey:key];
                break;
            }
            case NSBooleanAttributeType:
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            case NSDoubleAttributeType:
                if ([value isKindOfClass:NSNumber.class]) [object setValue:value forKey:key];
                break;
            default:
                break;
        }
    }];
    // Required dates must never be nil after import.
    NSDate *now = NSDate.date;
    for (NSString *key in @[@"createdAt", @"updatedAt", @"modifiedAt", @"date", @"startTime"]) {
        NSAttributeDescription *attr = object.entity.attributesByName[key];
        if (attr && !attr.isOptional && ![object valueForKey:key]) [object setValue:now forKey:key];
    }
    if (object.entity.attributesByName[@"storedName"] && ![object valueForKey:@"storedName"]) {
        [object setValue:@"" forKey:@"storedName"]; // metadata only; Files shows it as missing
    }
    [self clampEnums:object];
}

/// Out-of-range enum values from a hand-edited file fall back to the default.
- (void)clampEnums:(NSManagedObject *)o {
    NSDictionary<NSString *, NSNumber *> *limits = @{@"Task.status": @3, @"Task.priority": @3, @"Task.repeatRule": @5,
                                                     @"Project.status": @4, @"Project.priority": @3,
                                                     @"Schedule.kind": @4, @"Schedule.status": @2, @"Schedule.repeatRule": @5,
                                                     @"Template.kind": @2, @"Vehicle.fuelType": @2, @"ServiceRecord.category": @7, @"Trip.purpose": @4};
    [limits enumerateKeysAndObjectsUsingBlock:^(NSString *path, NSNumber *max, BOOL *stop) {
        NSArray *parts = [path componentsSeparatedByString:@"."];
        if (![o.entity.name isEqualToString:parts[0]]) return;
        NSInteger v = [[o valueForKey:parts[1]] integerValue];
        if (v < 0 || v > max.integerValue) [o setValue:@0 forKey:parts[1]];
    }];
}

- (void)applyRelationships:(NSDictionary *)row to:(NSManagedObject *)object index:(NSDictionary *)index context:(NSManagedObjectContext *)context {
    [object.entity.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSRelationshipDescription *rel, BOOL *stop) {
        id value = row[key];
        if (!value) return;
        if (rel.isToMany) {
            if (![value isKindOfClass:NSArray.class]) return;
            NSMutableSet *set = NSMutableSet.new;
            for (id uuid in value) {
                NSManagedObject *target = [uuid isKindOfClass:NSString.class] ? [self resolve:uuid entity:rel.destinationEntity.name index:index context:context] : nil;
                if (target) [set addObject:target];
            }
            [object setValue:set forKey:key];
        } else if ([value isKindOfClass:NSString.class]) {
            NSManagedObject *target = [self resolve:value entity:rel.destinationEntity.name index:index context:context];
            if (target == object) return; // a task can't be its own parent
            [object setValue:target forKey:key];
        }
    }];
}

- (NSManagedObject *)resolve:(NSString *)uuid entity:(NSString *)entity index:(NSDictionary *)index context:(NSManagedObjectContext *)context {
    NSManagedObject *hit = index[uuid];
    if (hit && [hit.entity.name isEqualToString:entity]) return hit;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entity];
    request.predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    request.fetchLimit = 1;
    return [context executeFetchRequest:request error:nil].firstObject;
}

@end
