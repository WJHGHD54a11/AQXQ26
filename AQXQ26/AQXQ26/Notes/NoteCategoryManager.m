//
//  NoteCategoryManager.m
//  WorkSpace
//

#import "NoteCategoryManager.h"
#import "DataManager.h"
#import "NoteCategory.h"
#import "Note.h"

@implementation NoteCategoryManager

+ (instancetype)shared {
    static NoteCategoryManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSArray<NoteCategory *> *)allCategories {
    NSFetchRequest *request = [NoteCategory fetchRequest];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    return [DataManager.shared fetch:request];
}

- (NSUInteger)noteCountIn:(NoteCategory *)category {
    NSFetchRequest *request = [Note fetchRequest];
    request.predicate = category ? [NSPredicate predicateWithFormat:@"category == %@", category]
                                 : [NSPredicate predicateWithFormat:@"category == nil"];
    return [DataManager.shared count:request];
}

- (NSString *)validName:(NSString *)name except:(NoteCategory *)current error:(NSError **)error {
    NSString *clean = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *message = nil;
    if (clean.length == 0) {
        message = WSText(@"Category name can't be empty.");
    } else {
        NSFetchRequest *request = [NoteCategory fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"name ==[c] %@", clean];
        NoteCategory *existing = [DataManager.shared fetch:request].firstObject;
        if (existing && existing != current) message = WSText(@"A category with this name already exists.");
    }
    if (message) {
        if (error) *error = [NSError errorWithDomain:@"WorkSpace" code:5 userInfo:@{NSLocalizedDescriptionKey: message}];
        return nil;
    }
    return clean;
}

- (NoteCategory *)createCategory:(NSString *)name color:(NSString *)color error:(NSError **)error {
    NSString *clean = [self validName:name except:nil error:error];
    if (!clean) return nil;
    NoteCategory *category = [DataManager.shared insertEntity:@"NoteCategory"];
    category.name = clean;
    category.colorIdentifier = color ?: @"indigo";
    category.sortIndex = (int32_t)[self allCategories].count;
    return [DataManager.shared save:error] ? category : nil;
}

- (BOOL)updateCategory:(NoteCategory *)category name:(NSString *)name color:(NSString *)color error:(NSError **)error {
    NSString *clean = [self validName:name except:category error:error];
    if (!clean) return NO;
    category.name = clean;
    if (color) category.colorIdentifier = color;
    return [DataManager.shared save:error];
}

- (BOOL)deleteCategory:(NoteCategory *)category error:(NSError **)error {
    if (![DataManager.shared deleteObject:category]) return YES; // notes are nullified, not deleted
    return [DataManager.shared save:error];
}

- (BOOL)moveCategory:(NoteCategory *)category toIndex:(NSUInteger)index error:(NSError **)error {
    NSMutableArray *list = [[self allCategories] mutableCopy];
    NSUInteger from = [list indexOfObject:category];
    if (from == NSNotFound || index >= list.count) return NO;
    [list removeObjectAtIndex:from];
    [list insertObject:category atIndex:index];
    [list enumerateObjectsUsingBlock:^(NoteCategory *c, NSUInteger idx, BOOL *stop) { c.sortIndex = (int32_t)idx; }];
    return [DataManager.shared save:error];
}

@end
