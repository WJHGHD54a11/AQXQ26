//
//  RootViewController.m
//  WorkSpace
//

#import "RootViewController.h"
#import "CoreDataManager.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

@implementation RootViewController

+ (instancetype)current {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if ([window.rootViewController isKindOfClass:self]) return (RootViewController *)window.rootViewController;
        }
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    [CoreDataManager.shared loadStoreWithCompletion:^(NSError *error) {
        [self installTabs];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self ws_showMessage:WSText(@"Your saved data could not be opened. Changes made now will not be kept until the app is restarted.")
                               title:WSText(@"Storage Problem")];
            });
        }
    }];
}

- (void)installTabs {
    if (_tabs) return;
    _tabs = [[MainTabBarController alloc] init];
    [self addChildViewController:_tabs];
    _tabs.view.frame = self.view.bounds;
    _tabs.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tabs.view];
    [_tabs didMoveToParentViewController:self];
}

- (UIViewController *)childViewControllerForStatusBarStyle { return self.tabs; }

@end
