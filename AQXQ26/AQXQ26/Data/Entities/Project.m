//
//  Project.m
//  WorkSpace
//

#import "Project.h"
#import "FileItem.h"
#import "Note.h"
#import "Tag.h"
#import "Task.h"

@implementation Project

+ (NSFetchRequest<Project *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Project"];
}

@dynamic uuid, name, detail, status, priority, colorIdentifier, isFavorite, startDate, dueDate, createdAt, updatedAt, lastOpenedAt, tasks, notes, files, tags;

@end
