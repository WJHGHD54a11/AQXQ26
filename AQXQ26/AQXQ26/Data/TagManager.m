//
//  TagManager.m
//  WorkSpace
//

#import "TagManager.h"
#import "DataManager.h"
#import "AppThemeManager.h"
#import "Tag.h"

@implementation TagManager

+ (instancetype)shared {
    static TagManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSArray<Tag *> *)allTags {
    NSFetchRequest *request = [Tag fetchRequest];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    return [DataManager.shared fetch:request];
}

- (Tag *)tagNamed:(NSString *)name {
    NSString *clean = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) return nil;
    NSFetchRequest *request = [Tag fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"name ==[c] %@", clean];
    request.fetchLimit = 1;
    return [DataManager.shared fetch:request].firstObject;
}

- (Tag *)tagNamedOrCreate:(NSString *)name {
    Tag *tag = [self tagNamed:name];
    if (tag) return tag;
    tag = [DataManager.shared insertEntity:@"Tag"];
    tag.name = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSArray *palette = AppThemeManager.shared.paletteIdentifiers;
    tag.colorIdentifier = palette[arc4random_uniform((uint32_t)palette.count)];
    return tag;
}

- (NSSet<Tag *> *)tagsForNames:(NSArray<NSString *> *)names {
    NSMutableSet *tags = NSMutableSet.new;
    for (NSString *name in names) {
        if ([name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length == 0) continue;
        [tags addObject:[self tagNamedOrCreate:name]];
    }
    return tags;
}

- (NSError *)errorWithMessage:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (Tag *)createTag:(NSString *)name color:(NSString *)color error:(NSError **)error {
    NSString *clean = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) {
        if (error) *error = [self errorWithMessage:WSText(@"Tag name can't be empty.")];
        return nil;
    }
    if ([self tagNamed:clean]) {
        if (error) *error = [self errorWithMessage:WSText(@"A tag with this name already exists.")];
        return nil;
    }
    Tag *tag = [self tagNamedOrCreate:clean];
    if (color) tag.colorIdentifier = color;
    return [DataManager.shared save:error] ? tag : nil;
}

- (BOOL)renameTag:(Tag *)tag to:(NSString *)name color:(NSString *)color error:(NSError **)error {
    NSString *clean = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) {
        if (error) *error = [self errorWithMessage:WSText(@"Tag name can't be empty.")];
        return NO;
    }
    Tag *existing = [self tagNamed:clean];
    if (existing && existing != tag) {
        if (error) *error = [self errorWithMessage:WSText(@"A tag with this name already exists.")];
        return NO;
    }
    tag.name = clean;
    if (color) tag.colorIdentifier = color;
    return [DataManager.shared save:error];
}

- (BOOL)deleteTag:(Tag *)tag error:(NSError **)error {
    if (![DataManager.shared deleteObject:tag]) return YES;
    return [DataManager.shared save:error];
}

- (NSUInteger)usageCountForTag:(Tag *)tag {
    return tag.tasks.count + tag.projects.count + tag.notes.count;
}

+ (NSString *)joinedNames:(NSSet<Tag *> *)tags {
    NSArray *names = [[tags valueForKey:@"name"] allObjects];
    return [[names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@", "];
}

@end
