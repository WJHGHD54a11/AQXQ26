//
//  AppDelegate.m
//  WorkSpace
//

#import "AppDelegate.h"
#import "CoreDataManager.h"
#import "ReminderManager.h"
#import "AppThemeManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [CoreDataManager.shared loadStoreWithCompletion:^(NSError *error) {}];
    [AppThemeManager.shared applyGlobalAppearance];
    [ReminderManager.shared activate];
    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                              options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
    config.delegateClass = NSClassFromString(@"SceneDelegate");
    return config;
}

@end
