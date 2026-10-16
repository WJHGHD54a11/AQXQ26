//
//  NoteManager.m
//  WorkSpace
//

#import "NoteManager.h"
#import "DataManager.h"
#import "ActivityManager.h"
#import "TagManager.h"
#import "Note.h"
#import "NoteCategory.h"
#import "Project.h"
#import "Tag.h"
#import "Activity.h"

NSString *NoteSortTitle(NoteSort sort) {
    NSArray *titles = @[WSText(@"Last Edited"), WSText(@"Date Created"), WSText(@"Title")];
    return sort < (NSInteger)titles.count ? titles[sort] : @"";
}

@implementation NoteQuery
@end

@implementation NoteManager

+ (instancetype)shared {
    static NoteManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSArray<Note *> *)notesMatching:(NoteQuery *)query {
    NSFetchRequest *request = [Note fetchRequest];
    NSMutableArray *predicates = NSMutableArray.new;
    NSString *text = [query.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (text.length) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@ OR content CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", text, text, text]];
    }
    if (query.category) [predicates addObject:[NSPredicate predicateWithFormat:@"category == %@", query.category]];
    else if (query.uncategorizedOnly) [predicates addObject:[NSPredicate predicateWithFormat:@"category == nil"]];
    if (query.tag) [predicates addObject:[NSPredicate predicateWithFormat:@"ANY tags == %@", query.tag]];
    if (query.favoritesOnly) [predicates addObject:[NSPredicate predicateWithFormat:@"isFavorite == YES"]];
    if (predicates.count) request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    NSSortDescriptor *secondary;
    switch (query.sort) {
        case NoteSortUpdated: secondary = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]; break;
        case NoteSortCreated: secondary = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]; break;
        case NoteSortAlphabetical:   secondary = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(localizedStandardCompare:)]; break;
    }
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"isPinned" ascending:NO], secondary];
    request.fetchBatchSize = 40;
    request.relationshipKeyPathsForPrefetching = @[@"category"];
    return [DataManager.shared fetch:request];
}

- (NSUInteger)totalCount {
    return [DataManager.shared count:[Note fetchRequest]];
}

+ (NSString *)derivedTitleFrom:(NSString *)content {
    for (NSString *line in [content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (trimmed.length) return trimmed.length > 80 ? [trimmed substringToIndex:80] : trimmed;
    }
    return @"";
}

+ (NSString *)previewOf:(Note *)note {
    NSString *content = note.content ?: @"";
    if (content.length > 400) content = [content substringToIndex:400];
    NSString *flat = [[content componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet] componentsJoinedByString:@" "];
    flat = [flat stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    // Skip the first line when it is the title itself.
    if (note.title.length && [flat hasPrefix:note.title]) {
        flat = [[flat substringFromIndex:note.title.length] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    }
    return flat;
}

- (BOOL)resolveTitle:(NSString **)title content:(NSString *)content error:(NSError **)error {
    NSString *t = [*title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (t.length == 0) t = [NoteManager derivedTitleFrom:content];
    if (t.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"WorkSpace" code:4 userInfo:@{NSLocalizedDescriptionKey: WSText(@"Add a title or some content before saving.")}];
        return NO;
    }
    *title = t;
    return YES;
}

- (Note *)createNoteWithTitle:(NSString *)title content:(NSString *)content category:(NoteCategory *)category tags:(NSArray<NSString *> *)tags project:(Project *)project error:(NSError **)error {
    NSString *t = title;
    if (![self resolveTitle:&t content:content error:error]) return nil;
    Note *note = [DataManager.shared insertEntity:@"Note"];
    note.title = t;
    note.content = content;
    note.category = category;
    note.project = project;
    note.tags = [TagManager.shared tagsForNames:tags];
    note.lastOpenedAt = NSDate.date;
    [ActivityManager.shared record:ActivityTypeNoteCreated title:t detail:category.name objectId:note.uuid];
    return [DataManager.shared save:error] ? note : nil;
}

- (BOOL)updateNote:(Note *)note title:(NSString *)title content:(NSString *)content category:(NoteCategory *)category tags:(NSArray<NSString *> *)tags error:(NSError **)error {
    if (!note || note.isDeleted) {
        if (error) *error = [NSError errorWithDomain:@"WorkSpace" code:404 userInfo:@{NSLocalizedDescriptionKey: WSText(@"This note no longer exists.")}];
        return NO;
    }
    NSString *t = title;
    if (![self resolveTitle:&t content:content error:error]) return NO;
    BOOL changed = ![note.title isEqualToString:t] || ![(note.content ?: @"") isEqualToString:(content ?: @"")];
    note.title = t;
    note.content = content;
    note.category = category;
    note.tags = [TagManager.shared tagsForNames:tags];
    note.updatedAt = NSDate.date;
    if (changed) {
        // One "edited" entry per note per 10 minutes is enough history.
        Activity *last = [ActivityManager.shared activitiesForObjectIds:@[note.uuid] limit:1].firstObject;
        BOOL recentlyLogged = [last.type isEqualToString:ActivityTypeNoteEdited] && -last.createdAt.timeIntervalSinceNow < 600;
        if (!recentlyLogged) {
            [ActivityManager.shared record:ActivityTypeNoteEdited title:t detail:nil objectId:note.uuid];
        }
    }
    return [DataManager.shared save:error];
}

- (BOOL)deleteNote:(Note *)note error:(NSError **)error {
    if (!note || note.isDeleted) return YES;
    [ActivityManager.shared record:ActivityTypeNoteDeleted title:note.title detail:nil objectId:note.uuid];
    [DataManager.shared deleteObject:note];
    return [DataManager.shared save:error];
}

- (BOOL)togglePinned:(Note *)note error:(NSError **)error {
    note.isPinned = !note.isPinned;
    return [DataManager.shared save:error];
}

- (BOOL)toggleFavorite:(Note *)note error:(NSError **)error {
    note.isFavorite = !note.isFavorite;
    return [DataManager.shared save:error];
}

@end
