//
//  ChecklistItem.m
//  WorkSpace
//

#import "ChecklistItem.h"
#import "Task.h"

@implementation ChecklistItem

+ (NSFetchRequest<ChecklistItem *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"ChecklistItem"];
}

@dynamic uuid, title, completed, sortIndex, task;

@end
