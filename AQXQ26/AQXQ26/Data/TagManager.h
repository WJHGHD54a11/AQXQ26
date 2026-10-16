//
//  TagManager.h
//  WorkSpace
//

#import <Foundation/Foundation.h>

@class Tag;

NS_ASSUME_NONNULL_BEGIN

@interface TagManager : NSObject

+ (instancetype)shared;

- (NSArray<Tag *> *)allTags;
- (nullable Tag *)tagNamed:(NSString *)name;
/// Returns the existing tag with that name (case-insensitive) or creates one.
- (Tag *)tagNamedOrCreate:(NSString *)name;
/// Resolves names into tags, skipping blanks and duplicates.
- (NSSet<Tag *> *)tagsForNames:(NSArray<NSString *> *)names;

- (nullable Tag *)createTag:(NSString *)name color:(nullable NSString *)color error:(NSError **)error;
- (BOOL)renameTag:(Tag *)tag to:(NSString *)name color:(nullable NSString *)color error:(NSError **)error;
/// Removes the tag; tasks/projects/notes stay (relationship is Nullify).
- (BOOL)deleteTag:(Tag *)tag error:(NSError **)error;

/// Number of tasks + projects + notes using the tag.
- (NSUInteger)usageCountForTag:(Tag *)tag;

/// "Design, Q4" ← sorted tag names.
+ (NSString *)joinedNames:(nullable NSSet<Tag *> *)tags;

@end

NS_ASSUME_NONNULL_END
