//
//  Tag.m
//  WorkSpace
//

#import "Tag.h"
#import "Note.h"
#import "Project.h"
#import "Task.h"

@implementation Tag

+ (NSFetchRequest<Tag *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
}

@dynamic uuid, name, colorIdentifier, createdAt, tasks, projects, notes;

@end
