//
//  TaskManager.m
//  WorkSpace
//

#import "TaskManager.h"
#import "DataManager.h"
#import "ActivityManager.h"
#import "ReminderManager.h"
#import "TagManager.h"
#import "Task+Logic.h"
#import "ChecklistItem.h"
#import "Project.h"
#import "FileItem.h"
#import "Tag.h"

NSString *TaskFilterTitle(TaskFilter filter) {
    NSArray *titles = @[WSText(@"All"), WSText(@"Today"), WSText(@"Upcoming"), WSText(@"Overdue"),
                        WSText(@"Completed"), WSText(@"High Priority"), WSText(@"By Project"), WSText(@"By Tag")];
    return filter < (NSInteger)titles.count ? titles[filter] : @"";
}

NSString *TaskSortTitle(TaskSort sort) {
    NSArray *titles = @[WSText(@"Due Date"), WSText(@"Created Date"), WSText(@"Priority"), WSText(@"Updated Date"), WSText(@"Manual Order")];
    return sort < (NSInteger)titles.count ? titles[sort] : @"";
}

@implementation TaskDraft

- (instancetype)init {
    if ((self = [super init])) {
        _title = @"";
        _priority = TaskPriorityMedium;
        _tagNames = @[];
        _checklistTitles = @[];
    }
    return self;
}

+ (instancetype)draftFromTask:(Task *)task {
    TaskDraft *draft = [[TaskDraft alloc] init];
    if (!task) return draft;
    draft.title = task.title ?: @"";
    draft.detail = task.detail;
    draft.notes = task.notes;
    draft.category = task.category;
    draft.status = task.status;
    draft.priority = task.priority;
    draft.repeatRule = task.repeatRule;
    draft.dueDate = task.dueDate;
    draft.reminderDate = task.reminderDate;
    draft.project = task.project;
    draft.parent = task.parent;
    draft.tagNames = [[task.tags valueForKey:@"name"] allObjects] ?: @[];
    return draft;
}

@end

@implementation TaskManager

+ (instancetype)shared {
    static TaskManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSError *)error:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:2 userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Query

- (NSPredicate *)predicateForFilter:(TaskFilter)filter project:(Project *)project tag:(Tag *)tag {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *now = NSDate.date;
    NSDate *startOfToday = [cal startOfDayForDate:now];
    NSDate *startOfTomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfToday options:0];
    NSPredicate *open = [NSPredicate predicateWithFormat:@"status < %d", TaskStatusCompleted];

    switch (filter) {
        case TaskFilterAll:
            return nil;
        case TaskFilterToday:
            return [NSCompoundPredicate andPredicateWithSubpredicates:@[open,
                    [NSPredicate predicateWithFormat:@"dueDate < %@", startOfTomorrow]]];
        case TaskFilterUpcoming:
            return [NSCompoundPredicate andPredicateWithSubpredicates:@[open,
                    [NSPredicate predicateWithFormat:@"dueDate >= %@", startOfTomorrow]]];
        case TaskFilterOverdue:
            return [NSCompoundPredicate andPredicateWithSubpredicates:@[open,
                    [NSPredicate predicateWithFormat:@"dueDate < %@", now]]];
        case TaskFilterCompleted:
            return [NSPredicate predicateWithFormat:@"status == %d", TaskStatusCompleted];
        case TaskFilterHighPriority:
            return [NSCompoundPredicate andPredicateWithSubpredicates:@[open,
                    [NSPredicate predicateWithFormat:@"priority >= %d", TaskPriorityHigh]]];
        case TaskFilterProject:
            return project ? [NSPredicate predicateWithFormat:@"project == %@", project]
                           : [NSPredicate predicateWithFormat:@"project != nil"];
        case TaskFilterTag:
            return tag ? [NSPredicate predicateWithFormat:@"ANY tags == %@", tag]
                       : [NSPredicate predicateWithFormat:@"tags.@count > 0"];
    }
    return nil;
}

- (NSArray<NSSortDescriptor *> *)sortDescriptors:(TaskSort)sort {
    NSSortDescriptor *created = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    switch (sort) {
        case TaskSortDueDate:  return @[[NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES], created];
        case TaskSortCreated:  return @[created];
        case TaskSortPriority: return @[[NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO],
                                        [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES], created];
        case TaskSortUpdated:  return @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
        case TaskSortManual:   return @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES], created];
    }
    return @[created];
}

- (NSArray<Task *> *)tasksWithFilter:(TaskFilter)filter sort:(TaskSort)sort project:(Project *)project tag:(Tag *)tag includeSubtasks:(BOOL)includeSubtasks {
    NSFetchRequest *request = [Task fetchRequest];
    NSMutableArray *predicates = NSMutableArray.new;
    NSPredicate *p = [self predicateForFilter:filter project:project tag:tag];
    if (p) [predicates addObject:p];
    if (!includeSubtasks) [predicates addObject:[NSPredicate predicateWithFormat:@"parent == nil"]];
    if (predicates.count) request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    request.sortDescriptors = [self sortDescriptors:sort];
    request.fetchBatchSize = 50;
    request.relationshipKeyPathsForPrefetching = @[@"project", @"tags"];
    NSArray *tasks = [DataManager.shared fetch:request];

    // Core Data puts nil due dates first when ascending; undated tasks belong at the end.
    if (sort == TaskSortDueDate) {
        NSPredicate *dated = [NSPredicate predicateWithFormat:@"dueDate != nil"];
        NSArray *withDate = [tasks filteredArrayUsingPredicate:dated];
        NSArray *without = [tasks filteredArrayUsingPredicate:[NSCompoundPredicate notPredicateWithSubpredicate:dated]];
        tasks = [withDate arrayByAddingObjectsFromArray:without];
    }
    return tasks;
}

- (NSArray<Task *> *)tasksDueOn:(NSDate *)day {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *start = [cal startOfDayForDate:day];
    NSDate *end = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
    NSFetchRequest *request = [Task fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"dueDate >= %@ AND dueDate < %@", start, end];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES]];
    return [DataManager.shared fetch:request];
}

- (NSUInteger)countForFilter:(TaskFilter)filter {
    NSFetchRequest *request = [Task fetchRequest];
    request.predicate = [self predicateForFilter:filter project:nil tag:nil];
    return [DataManager.shared count:request];
}

- (NSUInteger)countForStatus:(TaskStatus)status {
    NSFetchRequest *request = [Task fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"status == %d", status];
    return [DataManager.shared count:request];
}

- (NSUInteger)completedCountOn:(NSDate *)day {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *start = [cal startOfDayForDate:day];
    NSDate *end = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:start options:0];
    NSFetchRequest *request = [Task fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"completedAt >= %@ AND completedAt < %@", start, end];
    return [DataManager.shared count:request];
}

#pragma mark - Create / edit

- (BOOL)validate:(TaskDraft *)draft task:(Task *)task error:(NSError **)error {
    NSString *title = [draft.title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (title.length == 0) {
        if (error) *error = [self error:WSText(@"Please enter a title.")];
        return NO;
    }
    // A task can't become a subtask of itself or of one of its own subtasks.
    for (Task *p = draft.parent; p; p = p.parent) {
        if (task && p == task) {
            if (error) *error = [self error:WSText(@"A task can't be a subtask of itself.")];
            return NO;
        }
    }
    return YES;
}

- (void)apply:(TaskDraft *)draft to:(Task *)task {
    task.title = [draft.title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    task.detail = draft.detail.length ? draft.detail : nil;
    task.notes = draft.notes.length ? draft.notes : nil;
    task.category = draft.category.length ? draft.category : nil;
    task.priority = draft.priority;
    task.repeatRule = draft.repeatRule;
    task.dueDate = draft.dueDate;
    task.reminderDate = draft.reminderDate;
    task.project = draft.parent ? draft.parent.project : draft.project;
    task.parent = draft.parent;
    task.tags = [TagManager.shared tagsForNames:draft.tagNames];
    task.updatedAt = NSDate.date;
    [self applyStatus:draft.status to:task];
}

- (void)applyStatus:(TaskStatus)status to:(Task *)task {
    task.status = status;
    task.completedAt = status == TaskStatusCompleted ? (task.completedAt ?: NSDate.date) : nil;
}

- (Task *)createTask:(TaskDraft *)draft error:(NSError **)error {
    if (![self validate:draft task:nil error:error]) return nil;
    Task *task = [DataManager.shared insertEntity:@"Task"];
    task.sortIndex = -NSDate.date.timeIntervalSince1970; // newest first in manual order
    [self apply:draft to:task];
    [draft.checklistTitles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        NSString *clean = [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (clean.length == 0) return;
        ChecklistItem *item = [DataManager.shared insertEntity:@"ChecklistItem"];
        item.title = clean;
        item.sortIndex = (int32_t)idx;
        item.task = task;
    }];
    NSString *detail = task.parent ? [NSString stringWithFormat:WSText(@"Subtask of %@"), task.parent.title] : task.project.name;
    [ActivityManager.shared record:ActivityTypeTaskCreated title:task.title detail:detail objectId:task.uuid];
    if (task.project) [self touchProject:task.project];
    if (![DataManager.shared save:error]) return nil;
    [ReminderManager.shared syncTask:task];
    return task;
}

- (BOOL)updateTask:(Task *)task with:(TaskDraft *)draft error:(NSError **)error {
    if (task.isDeleted) {
        if (error) *error = [self error:WSText(@"This task no longer exists.")];
        return NO;
    }
    if (![self validate:draft task:task error:error]) return NO;
    BOOL wasCompleted = task.status == TaskStatusCompleted;
    Project *oldProject = task.project;
    [self apply:draft to:task];
    // Subtasks follow their parent into another project.
    for (Task *sub in task.subtasks) sub.project = task.project;

    BOOL nowCompleted = task.status == TaskStatusCompleted;
    NSString *type = (!wasCompleted && nowCompleted) ? ActivityTypeTaskCompleted : ActivityTypeTaskUpdated;
    [ActivityManager.shared record:type title:task.title detail:task.project.name objectId:task.uuid];
    if (oldProject) [self touchProject:oldProject];
    if (task.project && task.project != oldProject) [self touchProject:task.project];
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncTask:task];
    return YES;
}

- (BOOL)deleteTask:(Task *)task error:(NSError **)error {
    if (!task || task.isDeleted) return YES;
    NSMutableArray *ids = [NSMutableArray arrayWithObject:task.uuid ?: @""];
    for (Task *sub in task.subtasks) [ids addObject:sub.uuid ?: @""];
    [ActivityManager.shared record:ActivityTypeTaskDeleted title:task.title detail:task.project.name objectId:task.uuid];
    if (task.project) [self touchProject:task.project];
    [DataManager.shared deleteObject:task];
    if (![DataManager.shared save:error]) return NO;
    for (NSString *uuid in ids) [ReminderManager.shared removeTaskWithId:uuid];
    return YES;
}

- (Task *)duplicateTask:(Task *)task error:(NSError **)error {
    TaskDraft *draft = [TaskDraft draftFromTask:task];
    draft.title = [NSString stringWithFormat:WSText(@"%@ Copy"), task.title];
    draft.status = TaskStatusToDo;
    draft.reminderDate = nil;
    draft.checklistTitles = [[self orderedChecklist:task] valueForKey:@"title"];
    return [self createTask:draft error:error];
}

- (void)touchProject:(Project *)project {
    if (!project.isDeleted) project.updatedAt = NSDate.date;
}

#pragma mark - Status

- (BOOL)setStatus:(TaskStatus)status forTask:(Task *)task error:(NSError **)error {
    if (task.isDeleted) return NO;
    if (task.status == status) return YES;

    if (status == TaskStatusCompleted && task.repeatRule != RepeatRuleNone && task.dueDate) {
        return [self rollRepeatingTask:task error:error];
    }
    BOOL completing = status == TaskStatusCompleted;
    [self applyStatus:status to:task];
    task.updatedAt = NSDate.date;
    [ActivityManager.shared record:completing ? ActivityTypeTaskCompleted : ActivityTypeTaskUpdated
                             title:task.title
                            detail:completing ? task.project.name : TaskStatusTitle(status)
                          objectId:task.uuid];
    if (task.project) [self touchProject:task.project];
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncTask:task];
    return YES;
}

/// Logs completion of this occurrence, then moves due/reminder to the next one and
/// resets the checklist so the task can be worked again.
- (BOOL)rollRepeatingTask:(Task *)task error:(NSError **)error {
    NSDate *nextDue = RepeatRuleNextDate(task.repeatRule, task.dueDate);
    // Skip occurrences already in the past so the task lands on the next future date.
    while (nextDue && [nextDue compare:NSDate.date] == NSOrderedAscending) {
        nextDue = RepeatRuleNextDate(task.repeatRule, nextDue);
    }
    NSTimeInterval shift = [nextDue timeIntervalSinceDate:task.dueDate];
    [ActivityManager.shared record:ActivityTypeTaskCompleted title:task.title
                            detail:[NSString stringWithFormat:WSText(@"Repeats · next %@"), [Task relativeDayText:nextDue includeTime:NO]]
                          objectId:task.uuid];
    task.dueDate = nextDue;
    if (task.reminderDate) task.reminderDate = [task.reminderDate dateByAddingTimeInterval:shift];
    task.status = TaskStatusToDo;
    task.completedAt = nil;
    task.updatedAt = NSDate.date;
    for (ChecklistItem *item in task.checklistItems) item.completed = NO;
    if (![DataManager.shared save:error]) return NO;
    [ReminderManager.shared syncTask:task];
    return YES;
}

- (BOOL)toggleCompleted:(Task *)task error:(NSError **)error {
    TaskStatus target = task.status == TaskStatusCompleted ? TaskStatusToDo : TaskStatusCompleted;
    return [self setStatus:target forTask:task error:error];
}

- (BOOL)setPriority:(TaskPriority)priority forTask:(Task *)task error:(NSError **)error {
    if (task.isDeleted || task.priority == priority) return YES;
    task.priority = priority;
    task.updatedAt = NSDate.date;
    [ActivityManager.shared record:ActivityTypeTaskUpdated title:task.title
                            detail:[NSString stringWithFormat:WSText(@"Priority: %@"), TaskPriorityTitle(priority)]
                          objectId:task.uuid];
    return [DataManager.shared save:error];
}

#pragma mark - Checklist

- (NSArray<ChecklistItem *> *)orderedChecklist:(Task *)task {
    return [task.checklistItems sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES]]] ?: @[];
}

- (ChecklistItem *)addChecklistItem:(NSString *)title toTask:(Task *)task error:(NSError **)error {
    NSString *clean = [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) {
        if (error) *error = [self error:WSText(@"Please enter a title.")];
        return nil;
    }
    ChecklistItem *item = [DataManager.shared insertEntity:@"ChecklistItem"];
    item.title = clean;
    item.sortIndex = [self orderedChecklist:task].lastObject.sortIndex + 1;
    item.task = task;
    task.updatedAt = NSDate.date;
    return [DataManager.shared save:error] ? item : nil;
}

- (BOOL)renameChecklistItem:(ChecklistItem *)item to:(NSString *)title error:(NSError **)error {
    NSString *clean = [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (clean.length == 0) {
        if (error) *error = [self error:WSText(@"Please enter a title.")];
        return NO;
    }
    item.title = clean;
    item.task.updatedAt = NSDate.date;
    return [DataManager.shared save:error];
}

- (BOOL)toggleChecklistItem:(ChecklistItem *)item error:(NSError **)error {
    if (item.isDeleted) return NO;
    item.completed = !item.completed;
    item.task.updatedAt = NSDate.date;
    return [DataManager.shared save:error];
}

- (BOOL)deleteChecklistItem:(ChecklistItem *)item error:(NSError **)error {
    Task *task = item.task;
    if (![DataManager.shared deleteObject:item]) return YES;
    task.updatedAt = NSDate.date;
    return [DataManager.shared save:error];
}

- (BOOL)moveChecklistItemInTask:(Task *)task from:(NSUInteger)from to:(NSUInteger)to error:(NSError **)error {
    NSMutableArray *items = [[self orderedChecklist:task] mutableCopy];
    if (from >= items.count || to >= items.count) return NO;
    ChecklistItem *moved = items[from];
    [items removeObjectAtIndex:from];
    [items insertObject:moved atIndex:to];
    [items enumerateObjectsUsingBlock:^(ChecklistItem *item, NSUInteger idx, BOOL *stop) { item.sortIndex = (int32_t)idx; }];
    return [DataManager.shared save:error];
}

#pragma mark - Manual order

- (BOOL)moveTask:(Task *)task inList:(NSArray<Task *> *)list toIndex:(NSUInteger)index error:(NSError **)error {
    NSMutableArray *ordered = [list mutableCopy];
    NSUInteger from = [ordered indexOfObject:task];
    if (from == NSNotFound || index >= ordered.count) return NO;
    [ordered removeObjectAtIndex:from];
    [ordered insertObject:task atIndex:index];
    // Place between the neighbours so rows hidden by the current filter keep their order.
    BOOL hasPrev = index > 0, hasNext = index + 1 < ordered.count;
    double prev = hasPrev ? ((Task *)ordered[index - 1]).sortIndex : 0;
    double next = hasNext ? ((Task *)ordered[index + 1]).sortIndex : 0;
    if (hasPrev && hasNext)  task.sortIndex = (prev + next) / 2.0;
    else if (hasPrev)        task.sortIndex = prev + 1;
    else if (hasNext)        task.sortIndex = next - 1;
    if (hasPrev && hasNext && fabs(next - prev) < 1e-6) {
        [ordered enumerateObjectsUsingBlock:^(Task *t, NSUInteger idx, BOOL *stop) { t.sortIndex = idx; }];
    }
    return [DataManager.shared save:error];
}

#pragma mark - Attachments

- (BOOL)attachFile:(FileItem *)file toTask:(Task *)task error:(NSError **)error {
    file.task = task;
    task.updatedAt = NSDate.date;
    [ActivityManager.shared record:ActivityTypeTaskUpdated title:task.title
                            detail:[NSString stringWithFormat:WSText(@"Attached %@"), file.name] objectId:task.uuid];
    return [DataManager.shared save:error];
}

- (BOOL)detachFile:(FileItem *)file fromTask:(Task *)task error:(NSError **)error {
    if (file.task != task) return YES;
    file.task = nil;
    task.updatedAt = NSDate.date;
    return [DataManager.shared save:error];
}

@end
