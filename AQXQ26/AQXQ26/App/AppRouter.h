//
//  AppRouter.h
//  WorkSpace
//
//  One place that knows which screen shows which object, so Dashboard,
//  Search, Activity, notifications and detail cross-links all open the same
//  screens the same way.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class Project, Task;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WSQuickAction) {
    WSQuickActionNewTask = 0,
    WSQuickActionNewNote,
    WSQuickActionNewProject,
    WSQuickActionNewSchedule,
    WSQuickActionImportFile,
};

@interface AppRouter : NSObject

+ (instancetype)shared;

/// Detail screen for any WorkSpace object (nil for kinds without one).
- (nullable UIViewController *)detailFor:(NSManagedObject *)object;

/// Pushes the detail on `from`'s navigation controller. Returns NO when the object is gone.
- (BOOL)open:(nullable NSManagedObject *)object from:(UIViewController *)from;
- (BOOL)openKind:(WSObjectKind)kind uuid:(NSString *)uuid from:(UIViewController *)from;

/// Runs from the notification handler: switches to the right tab and pushes the detail.
- (void)openFromNotificationKind:(NSString *)kind uuid:(NSString *)uuid;

/// Modal editors.
- (void)perform:(WSQuickAction)action from:(UIViewController *)from;
- (void)presentNewTaskFrom:(UIViewController *)from project:(nullable Project *)project parent:(nullable Task *)parent;

@end

NS_ASSUME_NONNULL_END
