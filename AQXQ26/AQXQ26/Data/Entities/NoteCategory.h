//
//  NoteCategory.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in NoteCategory+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class Note;

NS_ASSUME_NONNULL_BEGIN

@interface NoteCategory : NSManagedObject

+ (NSFetchRequest<NoteCategory *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *colorIdentifier;
@property (nonatomic, assign) int32_t sortIndex;
@property (nonatomic, strong) NSDate *createdAt;

@property (nonatomic, nullable, strong) NSSet<Note *> *notes;

@end

@interface NoteCategory (CoreDataGeneratedNotes)
- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;
@end

NS_ASSUME_NONNULL_END
