//
//  Note.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in Note+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class NoteCategory, Project, Tag;

NS_ASSUME_NONNULL_BEGIN

@interface Note : NSManagedObject

+ (NSFetchRequest<Note *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, nullable, copy) NSString *content;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isPinned;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, nullable, strong) NSDate *lastOpenedAt;

@property (nonatomic, nullable, strong) NoteCategory *category;
@property (nonatomic, nullable, strong) Project *project;
@property (nonatomic, nullable, strong) NSSet<Tag *> *tags;

@end

@interface Note (CoreDataGeneratedTags)
- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet<Tag *> *)values;
- (void)removeTags:(NSSet<Tag *> *)values;
@end

NS_ASSUME_NONNULL_END
