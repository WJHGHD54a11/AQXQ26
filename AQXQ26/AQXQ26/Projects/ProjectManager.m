//
//  ProjectManager.m
//  WorkSpace
//

#import "ProjectManager.h"
#import "DataManager.h"
#import "ActivityManager.h"
#import "ReminderManager.h"
#import "TagManager.h"
#import "AppThemeManager.h"
#import "Project.h"
#import "Task.h"
#import "Note.h"
#import "FileItem.h"

@implementation ProjectDraft

- (instancetype)init {
    if ((self = [super init])) {
        _name = @"";
        _status = ProjectStatusActive;
        _priority = TaskPriorityMedium;
        _colorIdentifier = @"indigo";
        _tagNames = @[];
        _defaultTaskTitles = @[];
    }
    return self;
}

+ (instancetype)draftFromProject:(Project *)project {
    ProjectDraft *draft = [[ProjectDraft alloc] init];
    if (!project) return draft;
    draft.name = project.name ?: @"";
    draft.detail = project.detail;
    draft.status = project.status;
    draft.priority = project.priority;
    draft.startDate = project.startDate;
    draft.dueDate = project.dueDate;
    draft.colorIdentifier = project.colorIdentifier ?: @"indigo";
    draft.tagNames = [[project.tags valueForKey:@"name"] allObjects] ?: @[];
    return draft;
}

@end

@implementation ProjectManager

+ (instancetype)shared {
    static ProjectManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (NSError *)error:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:3 userInfo:@{NSLocalizedDescriptionKey: message}];
}

#pragma mark - Query

- (NSArray<Project *> *)projectsInScope:(ProjectListScope)scope {
    NSFetchRequest *request = [Project fetchRequest];
    switch (scope) {
        case ProjectListScopeCurrent:
            request.predicate = [NSPredicate predicateWithFormat:@"status <= %d", ProjectStatusPaused]; break;
        case ProjectListScopeCompleted:
            request.predicate = [NSPredicate predicateWithFormat:@"status == %d", ProjectStatusCompleted]; break;
        case ProjectListScopeArchived:
            request.predicate = [NSPredicate predicateWithFormat:@"status == %d", ProjectStatusArchived]; break;
        case ProjectListScopeAll:
            break;
    }
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]];
    request.relationshipKeyPathsForPrefetching = @[@"tasks"];
    // Active first, then Planning, Paused, Completed, Archived; newest within each.
    static NSArray *rank;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        rank = @[@(ProjectStatusActive), @(ProjectStatusPlanning), @(ProjectStatusPaused), @(ProjectStatusCompleted), @(ProjectStatusArchived)];
    });
    return [[DataManager.shared fetch:request] sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(Project *a, Project *b) {
        return [@([rank indexOfObject:@(a.status)]) compare:@([rank indexOfObject:@(b.status)])];
    }];
}

- (NSUInteger)countForStatus:(ProjectStatus)status {
    NSFetchRequest *request = [Project fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"status == %d", status];
    return [DataManager.shared count:request];
}

- (ProjectProgress)progressFor:(Project *)project {
    ProjectProgress p = {0, 0, 0, 0};
    NSDate *now = NSDate.date;
    for (Task *task in project.tasks) {
        if (task.isDeleted || task.status == TaskStatusCancelled) continue;
        p.total++;
        if (task.status == TaskStatusCompleted) p.completed++;
        else if (task.dueDate && [task.dueDate compare:now] == NSOrderedAscending) p.overdue++;
    }
    p.fraction = p.total ? (double)p.completed / p.total : 0;
    return p;
}

- (double)overallProgress {
    double sum = 0;
    NSUInteger counted = 0;
    for (Project *project in [self projectsInScope:ProjectListScopeCurrent]) {
        ProjectProgress p = [self progressFor:project];
        if (p.total == 0) continue;
        sum += p.fraction;
        counted++;
    }
    return counted ? sum / counted : 0;
}

- (NSArray<Task *> *)tasksFor:(Project *)project {
    NSArray *sorts = @[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES],
                       [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO],
                       [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    NSSet *topLevel = [project.tasks filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"parent == nil"]];
    return [topLevel sortedArrayUsingDescriptors:sorts] ?: @[];
}

- (NSArray<Note *> *)notesFor:(Project *)project {
    return [project.notes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO]]] ?: @[];
}

- (NSArray<FileItem *> *)filesFor:(Project *)project {
    return [project.files sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"modifiedAt" ascending:NO]]] ?: @[];
}

#pragma mark - Mutations

- (BOOL)validate:(ProjectDraft *)draft error:(NSError **)error {
    if ([draft.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0) {
        if (error) *error = [self error:WSText(@"Please enter a project name.")];
        return NO;
    }
    if (draft.startDate && draft.dueDate && [draft.dueDate compare:draft.startDate] == NSOrderedAscending) {
        if (error) *error = [self error:WSText(@"The due date must be after the start date.")];
        return NO;
    }
    return YES;
}

- (void)apply:(ProjectDraft *)draft to:(Project *)project {
    project.name = [draft.name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    project.detail = draft.detail.length ? draft.detail : nil;
    project.status = draft.status;
    project.priority = draft.priority;
    project.startDate = draft.startDate;
    project.dueDate = draft.dueDate;
    project.colorIdentifier = draft.colorIdentifier;
    project.tags = [TagManager.shared tagsForNames:draft.tagNames];
    project.updatedAt = NSDate.date;
}

- (Project *)createProject:(ProjectDraft *)draft error:(NSError **)error {
    if (![self validate:draft error:error]) return nil;
    Project *project = [DataManager.shared insertEntity:@"Project"];
    [self apply:draft to:project];
    NSDate *now = NSDate.date;
    [draft.defaultTaskTitles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        NSString *clean = [title stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (clean.length == 0) return;
        Task *task = [DataManager.shared insertEntity:@"Task"];
        task.title = clean;
        task.priority = TaskPriorityMedium;
        task.sortIndex = -now.timeIntervalSince1970 + idx;
        task.project = project;
    }];
    NSString *detail = draft.defaultTaskTitles.count
        ? [NSString stringWithFormat:WSText(@"%lu tasks added"), (unsigned long)project.tasks.count] : ProjectStatusTitle(project.status);
    [ActivityManager.shared record:ActivityTypeProjectCreated title:project.name detail:detail objectId:project.uuid];
    return [DataManager.shared save:error] ? project : nil;
}

- (BOOL)updateProject:(Project *)project with:(ProjectDraft *)draft error:(NSError **)error {
    if (project.isDeleted) {
        if (error) *error = [self error:WSText(@"This project no longer exists.")];
        return NO;
    }
    if (![self validate:draft error:error]) return NO;
    BOOL completing = project.status != ProjectStatusCompleted && draft.status == ProjectStatusCompleted;
    [self apply:draft to:project];
    [ActivityManager.shared record:completing ? ActivityTypeProjectCompleted : ActivityTypeProjectUpdated
                             title:project.name detail:ProjectStatusTitle(project.status) objectId:project.uuid];
    return [DataManager.shared save:error];
}

- (BOOL)setStatus:(ProjectStatus)status forProject:(Project *)project error:(NSError **)error {
    if (project.isDeleted || project.status == status) return YES;
    project.status = status;
    project.updatedAt = NSDate.date;
    [ActivityManager.shared record:status == ProjectStatusCompleted ? ActivityTypeProjectCompleted : ActivityTypeProjectUpdated
                             title:project.name detail:ProjectStatusTitle(status) objectId:project.uuid];
    return [DataManager.shared save:error];
}

- (BOOL)archive:(Project *)project error:(NSError **)error {
    return [self setStatus:ProjectStatusArchived forProject:project error:error];
}

- (BOOL)restore:(Project *)project error:(NSError **)error {
    ProjectProgress p = [self progressFor:project];
    ProjectStatus target = (p.total > 0 && p.completed == p.total) ? ProjectStatusCompleted : ProjectStatusActive;
    return [self setStatus:target forProject:project error:error];
}

- (BOOL)deleteProject:(Project *)project deleteTasks:(BOOL)deleteTasks error:(NSError **)error {
    if (!project || project.isDeleted) return YES;
    NSMutableArray *taskIds = NSMutableArray.new;
    for (Task *task in [project.tasks copy]) {
        if (deleteTasks) {
            [taskIds addObject:task.uuid ?: @""];
            [DataManager.shared deleteObject:task];
        } else {
            task.project = nil;
        }
    }
    [ActivityManager.shared record:ActivityTypeProjectDeleted title:project.name detail:nil objectId:project.uuid];
    [DataManager.shared deleteObject:project];
    if (![DataManager.shared save:error]) return NO;
    for (NSString *uuid in taskIds) [ReminderManager.shared removeTaskWithId:uuid];
    return YES;
}

- (BOOL)link:(NSManagedObject *)object to:(Project *)project label:(NSString *)label error:(NSError **)error {
    Project *previous = [object valueForKey:@"project"];
    if (previous == project) return YES;
    [object setValue:project forKey:@"project"];
    previous.updatedAt = NSDate.date;
    if (project) {
        project.updatedAt = NSDate.date;
        [ActivityManager.shared record:ActivityTypeProjectUpdated title:project.name
                                detail:[NSString stringWithFormat:WSText(@"Added %@"), label] objectId:project.uuid];
    }
    return [DataManager.shared save:error];
}

- (BOOL)addNote:(Note *)note to:(Project *)project error:(NSError **)error {
    return [self link:note to:project label:note.title error:error];
}

- (BOOL)addFile:(FileItem *)file to:(Project *)project error:(NSError **)error {
    return [self link:file to:project label:file.name error:error];
}

- (BOOL)addTask:(Task *)task to:(Project *)project error:(NSError **)error {
    for (Task *sub in task.subtasks) sub.project = project;
    return [self link:task to:project label:task.title error:error];
}

@end
