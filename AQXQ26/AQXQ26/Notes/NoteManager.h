//
//  NoteManager.h
//  WorkSpace
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class Note, NoteCategory, Project, Tag;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NoteSort) {
    NoteSortUpdated = 0,
    NoteSortCreated,
    NoteSortAlphabetical,
};

FOUNDATION_EXPORT NSString *NoteSortTitle(NoteSort sort);

@interface NoteQuery : NSObject
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, strong, nullable) NoteCategory *category;
@property (nonatomic) BOOL uncategorizedOnly;
@property (nonatomic, strong, nullable) Tag *tag;
@property (nonatomic) BOOL favoritesOnly;
@property (nonatomic) NoteSort sort;
@end

@interface NoteManager : NSObject

+ (instancetype)shared;

/// Pinned notes always come first, then `query.sort`.
- (NSArray<Note *> *)notesMatching:(NoteQuery *)query;
- (NSUInteger)totalCount;

/// Empty title is allowed when there is content; title then comes from the first line.
- (nullable Note *)createNoteWithTitle:(NSString *)title content:(nullable NSString *)content
                              category:(nullable NoteCategory *)category tags:(NSArray<NSString *> *)tags
                               project:(nullable Project *)project error:(NSError **)error;
- (BOOL)updateNote:(Note *)note title:(NSString *)title content:(nullable NSString *)content
          category:(nullable NoteCategory *)category tags:(NSArray<NSString *> *)tags error:(NSError **)error;
- (BOOL)deleteNote:(Note *)note error:(NSError **)error;

- (BOOL)togglePinned:(Note *)note error:(NSError **)error;
- (BOOL)toggleFavorite:(Note *)note error:(NSError **)error;

/// First non-empty line, trimmed, max 80 chars.
+ (NSString *)derivedTitleFrom:(nullable NSString *)content;
/// Plain one-line preview for cells.
+ (NSString *)previewOf:(Note *)note;

@end

NS_ASSUME_NONNULL_END
