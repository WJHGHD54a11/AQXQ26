//
//  AppDelegate.m
//  WorkSpace
//

#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "ReminderManager.h"
#import "AppThemeManager.h"
#import "XQQMineServices.h"
#import "XQQMineRemoteService.h"
#import "XQQMineSession.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CoreDataManager.shared loadStoreWithCompletion:^(NSError *error) {}];
    [AppThemeManager.shared applyGlobalAppearance];
    [ReminderManager.shared activate];
    // Me / Login use the real account service; IM-only parts stay local until IM is migrated.
    [XQQMineRemoteService install];
    // Sessions created by the step-1 local demo login can't talk to the real server.
    if ([[NSUserDefaults.standardUserDefaults stringForKey:@"savedToken"] isEqualToString:@"demo-local-token"]) [XQQMineSession clear];
    [XQQMineServiceHub registerDefaultServices];
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
    config.delegateClass = NSClassFromString(@"SceneDelegate");
    return config;
}

@end
