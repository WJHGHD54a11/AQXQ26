//
//  ImportManager.h
//  WorkSpace
//
//  Restores a WorkSpace JSON backup. Validates format/version and each record,
//  merges by uuid (existing rows are updated when the backup copy is newer,
//  never duplicated), and reports what happened.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImportReport : NSObject
@property (nonatomic) NSUInteger created;
@property (nonatomic) NSUInteger updated;
@property (nonatomic) NSUInteger skipped;      // identical or older than local copy
@property (nonatomic) NSUInteger invalid;      // missing required fields / wrong types
/// Per section: "tasks" → @[created, updated]
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSNumber *> *> *sections;
- (NSString *)summary;
@end

@interface ImportManager : NSObject

+ (instancetype)shared;

/// Reads the file (security scoped if needed), imports on a background context,
/// saves once, then reschedules reminders. Completion on main.
- (void)importBackupAt:(NSURL *)url completion:(void (^)(ImportReport * _Nullable report, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
