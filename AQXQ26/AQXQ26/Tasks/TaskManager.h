//
//  TaskManager.h
//  WorkSpace
//
//  All task mutations go through here so reminders, activity, repeat rules and
//  project progress stay consistent.
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class Task, ChecklistItem, Project, Tag, FileItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TaskFilter) {
    TaskFilterAll = 0,
    TaskFilterToday,
    TaskFilterUpcoming,
    TaskFilterOverdue,
    TaskFilterCompleted,
    TaskFilterHighPriority,
    TaskFilterProject,   // uses filterProject
    TaskFilterTag,       // uses filterTag
};

typedef NS_ENUM(NSInteger, TaskSort) {
    TaskSortDueDate = 0,
    TaskSortCreated,
    TaskSortPriority,
    TaskSortUpdated,
    TaskSortManual,
};

FOUNDATION_EXPORT NSString *TaskFilterTitle(TaskFilter filter);
FOUNDATION_EXPORT NSString *TaskSortTitle(TaskSort sort);

/// Plain value object for the edit form. Applied to a Task in one save.
@interface TaskDraft : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic, copy, nullable) NSString *notes;
@property (nonatomic, copy, nullable) NSString *category;
@property (nonatomic) TaskStatus status;
@property (nonatomic) TaskPriority priority;
@property (nonatomic) RepeatRule repeatRule;
@property (nonatomic, strong, nullable) NSDate *dueDate;
@property (nonatomic, strong, nullable) NSDate *reminderDate;
@property (nonatomic, strong, nullable) Project *project;
@property (nonatomic, strong, nullable) Task *parent;
@property (nonatomic, copy) NSArray<NSString *> *tagNames;
/// Only used on create (edit manages items in place).
@property (nonatomic, copy) NSArray<NSString *> *checklistTitles;
+ (instancetype)draftFromTask:(nullable Task *)task;
@end

@interface TaskManager : NSObject

+ (instancetype)shared;

#pragma mark Query
- (NSArray<Task *> *)tasksWithFilter:(TaskFilter)filter sort:(TaskSort)sort
                             project:(nullable Project *)project tag:(nullable Tag *)tag
                       includeSubtasks:(BOOL)includeSubtasks;
- (NSArray<Task *> *)tasksDueOn:(NSDate *)day;
- (NSUInteger)countForFilter:(TaskFilter)filter;
- (NSUInteger)countForStatus:(TaskStatus)status;
- (NSUInteger)completedCountOn:(NSDate *)day;

#pragma mark Create / edit
- (nullable Task *)createTask:(TaskDraft *)draft error:(NSError **)error;
- (BOOL)updateTask:(Task *)task with:(TaskDraft *)draft error:(NSError **)error;
- (BOOL)deleteTask:(Task *)task error:(NSError **)error;
- (nullable Task *)duplicateTask:(Task *)task error:(NSError **)error;

#pragma mark Status
/// Completing a repeating task rolls it forward to the next occurrence instead.
- (BOOL)setStatus:(TaskStatus)status forTask:(Task *)task error:(NSError **)error;
- (BOOL)toggleCompleted:(Task *)task error:(NSError **)error;
- (BOOL)setPriority:(TaskPriority)priority forTask:(Task *)task error:(NSError **)error;

#pragma mark Checklist
- (NSArray<ChecklistItem *> *)orderedChecklist:(Task *)task;
- (nullable ChecklistItem *)addChecklistItem:(NSString *)title toTask:(Task *)task error:(NSError **)error;
- (BOOL)renameChecklistItem:(ChecklistItem *)item to:(NSString *)title error:(NSError **)error;
- (BOOL)toggleChecklistItem:(ChecklistItem *)item error:(NSError **)error;
- (BOOL)deleteChecklistItem:(ChecklistItem *)item error:(NSError **)error;
- (BOOL)moveChecklistItemInTask:(Task *)task from:(NSUInteger)from to:(NSUInteger)to error:(NSError **)error;

#pragma mark Manual order
- (BOOL)moveTask:(Task *)task inList:(NSArray<Task *> *)list toIndex:(NSUInteger)index error:(NSError **)error;

#pragma mark Attachments
- (BOOL)attachFile:(FileItem *)file toTask:(Task *)task error:(NSError **)error;
- (BOOL)detachFile:(FileItem *)file fromTask:(Task *)task error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
