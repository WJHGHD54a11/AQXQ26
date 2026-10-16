//
//  Task.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Task+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class ChecklistItem, FileItem, Project, Tag;

NS_ASSUME_NONNULL_BEGIN

@interface Task : NSManagedObject

+ (NSFetchRequest<Task *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *detail;
@property (nonatomic, nullable, copy) NSString *notes;
@property (nonatomic, nullable, copy) NSString *category;
@property (nonatomic, assign) TaskStatus status;
@property (nonatomic, assign) TaskPriority priority;
@property (nonatomic, assign) RepeatRule repeatRule;
@property (nonatomic, assign) double sortIndex;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) NSDate *dueDate;
@property (nonatomic, nullable, strong) NSDate *reminderDate;
@property (nonatomic, nullable, strong) NSDate *completedAt;
@property (nonatomic, nullable, strong) NSDate *lastOpenedAt;

@property (nonatomic, nullable, strong) Project *project;
@property (nonatomic, nullable, strong) Task *parent;
@property (nonatomic, nullable, strong) NSSet<Task *> *subtasks;
@property (nonatomic, nullable, strong) NSSet<ChecklistItem *> *checklistItems;
@property (nonatomic, nullable, strong) NSSet<Tag *> *tags;
@property (nonatomic, nullable, strong) NSSet<FileItem *> *attachments;

@end

@interface Task (CoreDataGeneratedSubtasks)
- (void)addSubtasksObject:(Task *)value;
- (void)removeSubtasksObject:(Task *)value;
- (void)addSubtasks:(NSSet<Task *> *)values;
- (void)removeSubtasks:(NSSet<Task *> *)values;
@end

@interface Task (CoreDataGeneratedChecklistItems)
- (void)addChecklistItemsObject:(ChecklistItem *)value;
- (void)removeChecklistItemsObject:(ChecklistItem *)value;
- (void)addChecklistItems:(NSSet<ChecklistItem *> *)values;
- (void)removeChecklistItems:(NSSet<ChecklistItem *> *)values;
@end

@interface Task (CoreDataGeneratedTags)
- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet<Tag *> *)values;
- (void)removeTags:(NSSet<Tag *> *)values;
@end

@interface Task (CoreDataGeneratedAttachments)
- (void)addAttachmentsObject:(FileItem *)value;
- (void)removeAttachmentsObject:(FileItem *)value;
- (void)addAttachments:(NSSet<FileItem *> *)values;
- (void)removeAttachments:(NSSet<FileItem *> *)values;
@end

NS_ASSUME_NONNULL_END
