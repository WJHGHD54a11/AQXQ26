//
//  NavigationController.m
//  WorkSpace
//

#import "NavigationController.h"
#import "AppThemeManager.h"

@implementation NavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBar.prefersLargeTitles = YES;
    self.view.backgroundColor = AppThemeManager.shared.background;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
        viewController.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
    [super pushViewController:viewController animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.topViewController.preferredStatusBarStyle;
}

@end
