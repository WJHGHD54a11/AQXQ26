//
//  Note.m
//  WorkSpace
//

#import "Note.h"
#import "NoteCategory.h"
#import "Project.h"
#import "Tag.h"

@implementation Note

+ (NSFetchRequest<Note *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Note"];
}

@dynamic uuid, title, content, isFavorite, isPinned, createdAt, updatedAt, lastOpenedAt, category, project, tags;

@end
