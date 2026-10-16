//
//  ActivityManager.h
//  WorkSpace
//

#import <Foundation/Foundation.h>
#import "AppConstants.h"

@class Activity;

NS_ASSUME_NONNULL_BEGIN

@interface ActivityManager : NSObject

+ (instancetype)shared;

/// Inserts an activity row into the current context. It is persisted by the caller's save.
- (void)record:(NSString *)type title:(NSString *)title detail:(nullable NSString *)detail objectId:(nullable NSString *)objectId;

- (NSArray<Activity *> *)recentActivities:(NSUInteger)limit;
/// kind == nil → all kinds. day == nil → any day.
- (NSFetchRequest *)requestForKind:(nullable NSNumber *)kind day:(nullable NSDate *)day;
- (NSArray<Activity *> *)activitiesForObjectIds:(NSArray<NSString *> *)objectIds limit:(NSUInteger)limit;

- (BOOL)deleteActivity:(Activity *)activity error:(NSError **)error;
/// Deletes every activity matching the filter (or all).
- (BOOL)clearKind:(nullable NSNumber *)kind day:(nullable NSDate *)day error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
