//
//  ProjectManager.h
//  WorkSpace
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class Project, Task, Note, FileItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ProjectListScope) {
    ProjectListScopeCurrent = 0,  // Planning, Active, Paused
    ProjectListScopeCompleted,
    ProjectListScopeArchived,
    ProjectListScopeAll,
};

@interface ProjectDraft : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic) ProjectStatus status;
@property (nonatomic) TaskPriority priority;
@property (nonatomic, strong, nullable) NSDate *startDate;
@property (nonatomic, strong, nullable) NSDate *dueDate;
@property (nonatomic, copy) NSString *colorIdentifier;
@property (nonatomic, copy) NSArray<NSString *> *tagNames;
/// Created as top-level tasks on create only (used by project templates).
@property (nonatomic, copy) NSArray<NSString *> *defaultTaskTitles;
+ (instancetype)draftFromProject:(nullable Project *)project;
@end

/// Task counts derived from the project's own tasks (cancelled tasks don't count).
typedef struct {
    NSUInteger total;
    NSUInteger completed;
    NSUInteger overdue;
    double fraction;
} ProjectProgress;

@interface ProjectManager : NSObject

+ (instancetype)shared;

- (NSArray<Project *> *)projectsInScope:(ProjectListScope)scope;
- (NSUInteger)countForStatus:(ProjectStatus)status;
- (ProjectProgress)progressFor:(Project *)project;
/// Average progress across current projects that have tasks.
- (double)overallProgress;

- (NSArray<Task *> *)tasksFor:(Project *)project;
- (NSArray<Note *> *)notesFor:(Project *)project;
- (NSArray<FileItem *> *)filesFor:(Project *)project;

- (nullable Project *)createProject:(ProjectDraft *)draft error:(NSError **)error;
- (BOOL)updateProject:(Project *)project with:(ProjectDraft *)draft error:(NSError **)error;
- (BOOL)setStatus:(ProjectStatus)status forProject:(Project *)project error:(NSError **)error;
- (BOOL)archive:(Project *)project error:(NSError **)error;
/// Back to Active (or Completed if every task is done).
- (BOOL)restore:(Project *)project error:(NSError **)error;
/// Removes the project. Tasks are kept and moved to "No Project" unless deleteTasks is YES.
- (BOOL)deleteProject:(Project *)project deleteTasks:(BOOL)deleteTasks error:(NSError **)error;

- (BOOL)addNote:(Note *)note to:(nullable Project *)project error:(NSError **)error;
- (BOOL)addFile:(FileItem *)file to:(nullable Project *)project error:(NSError **)error;
- (BOOL)addTask:(Task *)task to:(nullable Project *)project error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
