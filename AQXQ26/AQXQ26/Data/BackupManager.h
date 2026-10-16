//
//  BackupManager.h
//  WorkSpace
//
//  Exports Tasks, Projects, Notes (+categories), Schedules, Templates, Tags and
//  activity-free relationships to a versioned JSON file. File bytes are not
//  included; FileItem metadata is, so project/task links survive a restore.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const BackupFormatIdentifier; // "workspace.backup"
FOUNDATION_EXPORT NSInteger const BackupFormatVersion;

@interface BackupManager : NSObject

+ (instancetype)shared;

/// Builds the JSON on a background context and writes it to a temp file
/// "WorkSpace Backup yyyy-MM-dd.json". Completion on main.
- (void)exportWithCompletion:(void (^)(NSURL * _Nullable fileURL, NSError * _Nullable error))completion;

/// Counts per section for the last export, for the confirmation message.
@property (nonatomic, readonly, copy, nullable) NSDictionary<NSString *, NSNumber *> *lastExportCounts;

@end

NS_ASSUME_NONNULL_END
