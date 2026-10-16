//
//  Task.m
//  WorkSpace
//

#import "Task.h"
#import "ChecklistItem.h"
#import "FileItem.h"
#import "Project.h"
#import "Tag.h"

@implementation Task

+ (NSFetchRequest<Task *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Task"];
}

@dynamic uuid, title, detail, notes, category, status, priority, repeatRule, sortIndex, isFavorite, createdAt, updatedAt, dueDate, reminderDate, completedAt, lastOpenedAt, project, parent, subtasks, checklistItems, tags, attachments;

@end
