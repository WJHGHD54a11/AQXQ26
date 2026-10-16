//
//  NoteCategoryManager.h
//  WorkSpace
//
//  User-defined note categories. Deleting one moves its notes to "Uncategorized".
//

#import <Foundation/Foundation.h>

@class NoteCategory;

NS_ASSUME_NONNULL_BEGIN

@interface NoteCategoryManager : NSObject

+ (instancetype)shared;

- (NSArray<NoteCategory *> *)allCategories;
- (NSUInteger)noteCountIn:(nullable NoteCategory *)category; // nil = uncategorized

- (nullable NoteCategory *)createCategory:(NSString *)name color:(nullable NSString *)color error:(NSError **)error;
- (BOOL)updateCategory:(NoteCategory *)category name:(NSString *)name color:(nullable NSString *)color error:(NSError **)error;
- (BOOL)deleteCategory:(NoteCategory *)category error:(NSError **)error;
- (BOOL)moveCategory:(NoteCategory *)category toIndex:(NSUInteger)index error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
