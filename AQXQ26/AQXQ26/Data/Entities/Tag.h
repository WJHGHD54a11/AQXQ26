//
//  Tag.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Tag+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class Note, Project, Task;

NS_ASSUME_NONNULL_BEGIN

@interface Tag : NSManagedObject

+ (NSFetchRequest<Tag *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *colorIdentifier;
@property (nonatomic, strong) NSDate *createdAt;

@property (nonatomic, nullable, strong) NSSet<Task *> *tasks;
@property (nonatomic, nullable, strong) NSSet<Project *> *projects;
@property (nonatomic, nullable, strong) NSSet<Note *> *notes;

@end

@interface Tag (CoreDataGeneratedTasks)
- (void)addTasksObject:(Task *)value;
- (void)removeTasksObject:(Task *)value;
- (void)addTasks:(NSSet<Task *> *)values;
- (void)removeTasks:(NSSet<Task *> *)values;
@end

@interface Tag (CoreDataGeneratedProjects)
- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet<Project *> *)values;
- (void)removeProjects:(NSSet<Project *> *)values;
@end

@interface Tag (CoreDataGeneratedNotes)
- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;
@end

NS_ASSUME_NONNULL_END
