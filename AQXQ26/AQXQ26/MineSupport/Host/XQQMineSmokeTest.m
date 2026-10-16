//
//  XQQMineSmokeTest.m
//  AQXQ26
//
//  仅 DEBUG：启动参数带 -XQQMineSmokeTest 时，用演示账号逐个 push「我的」全部页面，
//  打印每页是否正常加载，用于迁移后的回归检查。正常启动不会执行。
//

#if DEBUG

#import <UIKit/UIKit.h>
#import "XQQMineLocalService.h"
#import "ObjectModel.h"

@interface XQQMineSmokeTest : NSObject
@end

@implementation XQQMineSmokeTest

+ (void)load {
    if (![NSProcessInfo.processInfo.arguments containsObject:@"-XQQMineSmokeTest"]) return;
    [XQQMineLocalService.shared signInDemoUser];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self run];
    });
}

+ (NSArray<NSString *> *)pages {
    return @[@"XQQMKDIOFZTUserinfoVC", @"XQQMKDIOFZTAvatarVC", @"XQQMKDIOFZTAvatarRecordVC", @"XQQMKDIOFZTTextModifyVC",
             @"XQQMKDIOFZTUserQrcodeVC", @"XQQMKDIOFZTNormalQrcodeVC", @"XQQMKDIOFZTUserWalletVC", @"XQQMKDIOFZTCheckInVC",
             @"XQQMKDIOFZTNoticeVC", @"XQQMKDIOFZTSystemNotiVC", @"XQQMKDIOFZTPrivacyVC", @"XQQMyBlackListViewController",
             @"XQQMKDIOFZTAddmyWayVC", @"XQQMKDIOFZTLastOnlineVC", @"XQQMKDIOFZTAppearanceVC", @"XQQMKDIOFZTChatBackgroundSetVC",
             @"XQQMKDIOFZTFontsizeVC", @"XQQMKDIOFZTLangugeVC", @"XQQMKDIOFZTSafetyVC", @"XQQMKDIOFZTDeviceVC",
             @"XQQMKDIOFZTDeviceDetailsVC", @"XQQMKDIOFZTLockVC", @"XQQMKDIOFZTNumberVC", @"XQQMKDIOFZTClearChatVC",
             @"XQQMKDIOFZTDestroyVC", @"XQQMKDIOFZTLoginpswVC", @"XQQMKDIOFZTLoginpswOkVC", @"XQQMKDIOFZTLoginpswVerifyVC",
             @"XQQMKDIOFZTModityPswVC", @"XQQMKDIOFZTMobileBindingVC", @"XQQMKDIOFZTEmailBindingVC", @"XQQMKDIOFZTMobileEmailVerifyVC",
             @"XQQMKDIOFZTMobileEmailVerityVC", @"XQQMKDIOFZTAboutVC", @"XQQMKDIOFZTFeedbackVC", @"XQQMKDIOFZTWebviewVC"];
}

+ (UINavigationController *)nav {
    UIWindow *window = UIApplication.sharedApplication.delegate.window;
    UIViewController *root = window.rootViewController;
    UITabBarController *tab = [root isKindOfClass:UITabBarController.class] ? (UITabBarController *)root
                                                                           : (UITabBarController *)root.childViewControllers.firstObject;
    tab.selectedIndex = tab.viewControllers.count - 1; // Me is the last tab
    if (tab.presentedViewController) [tab dismissViewControllerAnimated:NO completion:nil];
    return (UINavigationController *)tab.selectedViewController;
}

+ (void)run {
    NSLog(@"[XQQMineSmoke] start, root=%@", NSStringFromClass([self nav].topViewController.class));
    [self step:0 failures:@[]];
}

+ (void)step:(NSUInteger)i failures:(NSArray *)failures {
    NSArray *pages = self.pages;
    if (i >= pages.count) {
        NSLog(@"[XQQMineSmoke] done total=%lu failed=%lu %@", (unsigned long)pages.count, (unsigned long)failures.count, failures);
        return;
    }
    NSString *name = pages[i];
    NSMutableArray *next = failures.mutableCopy;
    UINavigationController *nav = [self nav];
    @try {
        Class cls = NSClassFromString(name);
        UIViewController *vc = [cls new];
        if (!vc) @throw [NSException exceptionWithName:@"NoClass" reason:name userInfo:nil];
        if ([vc respondsToSelector:@selector(setModel:)]) { // 设备详情需要上一页传入设备
            DeviceHistory *device = DeviceHistory.new;
            device.id = [XQQMineAccount getClientId];
            [vc setValue:device forKey:@"model"];
        }
        [nav pushViewController:vc animated:NO];
        [vc.view layoutIfNeeded];
        NSLog(@"[XQQMineSmoke] OK %@", name);
    } @catch (NSException *e) {
        NSLog(@"[XQQMineSmoke] FAIL %@ %@: %@", name, e.name, e.reason);
        [next addObject:name];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [nav popToRootViewControllerAnimated:NO];
        [self step:i + 1 failures:next];
    });
}

@end

#endif
