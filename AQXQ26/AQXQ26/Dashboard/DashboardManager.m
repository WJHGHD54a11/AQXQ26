//
//  DashboardManager.m
//  WorkSpace
//

#import "DashboardManager.h"
#import "DataManager.h"
#import "TaskManager.h"
#import "ProjectManager.h"
#import "ScheduleManager.h"
#import "ActivityManager.h"
#import "RecentManager.h"
#import "Task.h"
#import "Note.h"
#import "FileItem.h"

@implementation DashboardSnapshot
@end

@implementation DashboardManager

+ (instancetype)shared {
    static DashboardManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [[self alloc] init]; });
    return manager;
}

- (DashboardSnapshot *)snapshot {
    DashboardSnapshot *s = [[DashboardSnapshot alloc] init];
    TaskManager *tasks = TaskManager.shared;
    ProjectManager *projects = ProjectManager.shared;
    NSDate *now = NSDate.date;

    NSArray *today = [tasks tasksWithFilter:TaskFilterToday sort:TaskSortPriority project:nil tag:nil includeSubtasks:YES];
    s.todayTasks = [self first:6 of:today];
    s.dueTodayCount = [[today filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(Task *t, NSDictionary *b) {
        return [NSCalendar.currentCalendar isDateInToday:t.dueDate];
    }]] count];
    s.completedTodayCount = [tasks completedCountOn:now];
    s.todaySchedules = [self first:6 of:[ScheduleManager.shared schedulesIn:ScheduleScopeToday day:nil kind:nil]];

    s.todoTasks = [tasks countForStatus:TaskStatusToDo];
    s.inProgressTasks = [tasks countForStatus:TaskStatusInProgress];
    s.completedTasks = [tasks countForStatus:TaskStatusCompleted];
    s.totalTasks = s.todoTasks + s.inProgressTasks + s.completedTasks + [tasks countForStatus:TaskStatusCancelled];
    s.overdueTasks = [tasks countForFilter:TaskFilterOverdue];

    s.activeProjects = [projects countForStatus:ProjectStatusActive];
    s.completedProjects = [projects countForStatus:ProjectStatusCompleted];
    s.overallProgress = [projects overallProgress];
    s.topProjects = [self first:4 of:[projects projectsInScope:ProjectListScopeCurrent]];

    RecentManager *recent = RecentManager.shared;
    s.recentNotes = [self recentOrNewest:WSObjectKindNote limit:4];
    s.recentFiles = [self recentOrNewest:WSObjectKindFile limit:4];
    s.recentProjects = [recent recentOfKind:WSObjectKindProject limit:4];

    s.activities = [ActivityManager.shared recentActivities:6];
    return s;
}

- (NSArray *)first:(NSUInteger)n of:(NSArray *)list {
    return list.count > n ? [list subarrayWithRange:NSMakeRange(0, n)] : list;
}

/// Recently opened first; topped up with the newest items so a fresh install still shows content.
- (NSArray *)recentOrNewest:(WSObjectKind)kind limit:(NSUInteger)limit {
    NSMutableArray *items = [[RecentManager.shared recentOfKind:kind limit:limit] mutableCopy];
    if (items.count >= limit) return items;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:WSObjectKindEntityName(kind)];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:kind == WSObjectKindFile ? @"modifiedAt" : @"updatedAt" ascending:NO]];
    request.fetchLimit = limit * 2;
    for (id item in [DataManager.shared fetch:request]) {
        if (items.count >= limit) break;
        if (![items containsObject:item]) [items addObject:item];
    }
    return items;
}

@end
