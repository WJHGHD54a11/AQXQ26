//
//  AppRouter.m
//  WorkSpace
//

#import "AppRouter.h"
#import "RootViewController.h"
#import "DataManager.h"
#import "WSUIKit.h"
#import "Task.h"
#import "Project.h"
#import "Note.h"
#import "FileItem.h"
#import "Schedule.h"
#import "TaskDetailViewController.h"
#import "TaskEditViewController.h"
#import "ProjectDetailViewController.h"
#import "ProjectEditViewController.h"
#import "NoteDetailViewController.h"
#import "NoteEditViewController.h"
#import "FileDetailViewController.h"
#import "FileImportManager.h"
#import "ScheduleDetailViewController.h"
#import "ScheduleEditViewController.h"

@implementation AppRouter

+ (instancetype)shared {
    static AppRouter *router;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ router = [[self alloc] init]; });
    return router;
}

#pragma mark - Details

- (UIViewController *)detailFor:(NSManagedObject *)object {
    if (!object || object.isDeleted || !object.managedObjectContext) return nil;
    if ([object isKindOfClass:Task.class])     return [[TaskDetailViewController alloc] initWithTask:(Task *)object];
    if ([object isKindOfClass:Project.class])  return [[ProjectDetailViewController alloc] initWithProject:(Project *)object];
    if ([object isKindOfClass:Note.class])     return [[NoteDetailViewController alloc] initWithNote:(Note *)object];
    if ([object isKindOfClass:FileItem.class]) return [[FileDetailViewController alloc] initWithFile:(FileItem *)object];
    if ([object isKindOfClass:Schedule.class]) return [[ScheduleDetailViewController alloc] initWithSchedule:(Schedule *)object];
    return nil;
}

- (BOOL)open:(NSManagedObject *)object from:(UIViewController *)from {
    UIViewController *detail = [self detailFor:object];
    if (!detail) {
        [from ws_toast:WSText(@"This item no longer exists.")];
        return NO;
    }
    if ([detail isKindOfClass:WSFormViewController.class]) {
        [from presentViewController:[(WSFormViewController *)detail embeddedInNavigation] animated:YES completion:nil];
        return YES;
    }
    UINavigationController *nav = from.navigationController ?: [from isKindOfClass:UINavigationController.class] ? (UINavigationController *)from : nil;
    if (nav) {
        [nav pushViewController:detail animated:YES];
    } else {
        UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:detail];
        detail.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose primaryAction:[UIAction actionWithHandler:^(UIAction *a) {
            [wrapper dismissViewControllerAnimated:YES completion:nil];
        }]];
        [from presentViewController:wrapper animated:YES completion:nil];
    }
    return YES;
}

- (BOOL)openKind:(WSObjectKind)kind uuid:(NSString *)uuid from:(UIViewController *)from {
    return [self open:[DataManager.shared objectOfKind:kind uuid:uuid] from:from];
}

- (void)openFromNotificationKind:(NSString *)kind uuid:(NSString *)uuid {
    MainTabBarController *tabs = RootViewController.current.tabs;
    if (!tabs) return;
    BOOL isTask = [kind isEqualToString:@"task"];
    WSObjectKind objectKind = isTask ? WSObjectKindTask : WSObjectKindSchedule;
    UINavigationController *nav = [tabs selectTab:isTask ? MainTabTasks : MainTabHome];
    [nav popToRootViewControllerAnimated:NO];
    [self openKind:objectKind uuid:uuid from:nav.topViewController];
}

#pragma mark - Editors

- (void)perform:(WSQuickAction)action from:(UIViewController *)from {
    switch (action) {
        case WSQuickActionNewTask:
            [self presentNewTaskFrom:from project:nil parent:nil];
            break;
        case WSQuickActionNewNote: {
            NoteEditViewController *editor = [[NoteEditViewController alloc] initWithNote:nil category:nil project:nil];
            __weak UIViewController *weakFrom = from;
            editor.onSaved = ^(Note *note) {
                [weakFrom ws_toast:WSText(@"Note saved")];
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            [from presentViewController:nav animated:YES completion:nil];
            break;
        }
        case WSQuickActionNewProject: {
            ProjectEditViewController *editor = [[ProjectEditViewController alloc] initWithProject:nil];
            [from presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
            break;
        }
        case WSQuickActionNewSchedule: {
            ScheduleEditViewController *editor = [[ScheduleEditViewController alloc] initWithSchedule:nil day:nil];
            [from presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
            break;
        }
        case WSQuickActionImportFile: {
            __weak UIViewController *weakFrom = from;
            [FileImportManager.shared presentPickerFrom:from project:nil task:nil folder:nil completion:^(FileImportResult *result) {
                [self reportImport:result on:weakFrom];
            }];
            break;
        }
    }
}

- (void)reportImport:(FileImportResult *)result on:(UIViewController *)vc {
    if (!vc) return;
    if (result.failedNames.count) {
        NSString *message = [NSString stringWithFormat:WSText(@"Imported %lu. Could not import: %@"),
                             (unsigned long)result.imported.count, [result.failedNames componentsJoinedByString:@", "]];
        [vc ws_showMessage:message title:WSText(@"Import")];
    } else if (result.imported.count) {
        [vc ws_toast:[NSString stringWithFormat:WSText(@"%lu file(s) imported"), (unsigned long)result.imported.count]];
    }
}

- (void)presentNewTaskFrom:(UIViewController *)from project:(Project *)project parent:(Task *)parent {
    TaskEditViewController *editor = [[TaskEditViewController alloc] initWithTask:nil project:project parent:parent];
    [from presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
}

@end
