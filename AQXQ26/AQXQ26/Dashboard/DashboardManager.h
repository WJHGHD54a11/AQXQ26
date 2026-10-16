//
//  DashboardManager.h
//  WorkSpace
//
//  Builds one immutable snapshot of everything the Dashboard shows.
//  All numbers come from count / aggregate queries, never fixed values.
//

#import <Foundation/Foundation.h>

@class Task, Schedule, Project, Activity, Note, FileItem;

NS_ASSUME_NONNULL_BEGIN

@interface DashboardSnapshot : NSObject
// Today
@property (nonatomic, copy) NSArray<Task *> *todayTasks;         // open, due today or overdue (max 6)
@property (nonatomic, copy) NSArray<Schedule *> *todaySchedules; // today (max 6)
@property (nonatomic) NSUInteger dueTodayCount;
@property (nonatomic) NSUInteger completedTodayCount;
// Task summary
@property (nonatomic) NSUInteger totalTasks;
@property (nonatomic) NSUInteger todoTasks;
@property (nonatomic) NSUInteger inProgressTasks;
@property (nonatomic) NSUInteger completedTasks;
@property (nonatomic) NSUInteger overdueTasks;
// Project summary
@property (nonatomic) NSUInteger activeProjects;
@property (nonatomic) NSUInteger completedProjects;
@property (nonatomic) double overallProgress;
@property (nonatomic, copy) NSArray<Project *> *topProjects;     // current projects (max 4)
// Recent
@property (nonatomic, copy) NSArray<Note *> *recentNotes;
@property (nonatomic, copy) NSArray<FileItem *> *recentFiles;
@property (nonatomic, copy) NSArray<Project *> *recentProjects;
// Activity
@property (nonatomic, copy) NSArray<Activity *> *activities;     // max 6
@end

@interface DashboardManager : NSObject

+ (instancetype)shared;
- (DashboardSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
