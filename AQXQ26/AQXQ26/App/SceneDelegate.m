//
//  SceneDelegate.m
//  WorkSpace
//

#import "SceneDelegate.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "AppRouter.h"
#import "ImportManager.h"
#import "FileImportManager.h"
#import "WSUIKit.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.rootViewController = [[RootViewController alloc] init];
    window.tintColor = AppThemeManager.shared.accent;
    [window makeKeyAndVisible];
    self.window = window;
    ((AppDelegate *)UIApplication.sharedApplication.delegate).window = window;

    if (connectionOptions.URLContexts.count) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self handleURLContexts:connectionOptions.URLContexts]; });
    }
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    [self handleURLContexts:URLContexts];
}

/// "Open in WorkSpace" from Files / Mail: backups are restored, anything else is imported as a file.
- (void)handleURLContexts:(NSSet<UIOpenURLContext *> *)contexts {
    UIViewController *top = RootViewController.current.tabs ?: self.window.rootViewController;
    NSMutableArray *files = NSMutableArray.new;
    for (UIOpenURLContext *context in contexts) {
        NSURL *url = context.URL;
        if (!url.isFileURL) continue;
        if ([url.pathExtension.lowercaseString isEqualToString:@"json"]) {
            [ImportManager.shared importBackupAt:url completion:^(ImportReport *report, NSError *error) {
                if (error) [top ws_showError:error];
                else [top ws_showMessage:report.summary title:WSText(@"Backup Imported")];
            }];
        } else {
            [files addObject:url];
        }
    }
    if (files.count) {
        [FileImportManager.shared importURLs:files project:nil task:nil folder:nil completion:^(FileImportResult *result) {
            if (result.imported.count) [top ws_toast:[NSString stringWithFormat:WSText(@"%lu files imported"), (unsigned long)result.imported.count]];
        }];
    }
}

@end
