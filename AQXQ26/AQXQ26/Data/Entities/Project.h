//
//  Project.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Project+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class FileItem, Note, Tag, Task;

NS_ASSUME_NONNULL_BEGIN

@interface Project : NSManagedObject

+ (NSFetchRequest<Project *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *detail;
@property (nonatomic, assign) ProjectStatus status;
@property (nonatomic, assign) TaskPriority priority;
@property (nonatomic, nullable, copy) NSString *colorIdentifier;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, nullable, strong) NSDate *startDate;
@property (nonatomic, nullable, strong) NSDate *dueDate;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) NSDate *lastOpenedAt;

@property (nonatomic, nullable, strong) NSSet<Task *> *tasks;
@property (nonatomic, nullable, strong) NSSet<Note *> *notes;
@property (nonatomic, nullable, strong) NSSet<FileItem *> *files;
@property (nonatomic, nullable, strong) NSSet<Tag *> *tags;

@end

@interface Project (CoreDataGeneratedTasks)
- (void)addTasksObject:(Task *)value;
- (void)removeTasksObject:(Task *)value;
- (void)addTasks:(NSSet<Task *> *)values;
- (void)removeTasks:(NSSet<Task *> *)values;
@end

@interface Project (CoreDataGeneratedNotes)
- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;
@end

@interface Project (CoreDataGeneratedFiles)
- (void)addFilesObject:(FileItem *)value;
- (void)removeFilesObject:(FileItem *)value;
- (void)addFiles:(NSSet<FileItem *> *)values;
- (void)removeFiles:(NSSet<FileItem *> *)values;
@end

@interface Project (CoreDataGeneratedTags)
- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet<Tag *> *)values;
- (void)removeTags:(NSSet<Tag *> *)values;
@end

NS_ASSUME_NONNULL_END
