//
//  MainTabBarController.m
//  WorkSpace
//

#import "MainTabBarController.h"
#import "NavigationController.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"
#import "DashboardViewController.h"
#import "TaskListViewController.h"
#import "FileListViewController.h"
#import "NoteListViewController.h"
#import "XQQMKDIOFZTProfileVC.h"
#import "TaskManager.h"
#import "XQQMineServices.h"
#import "XQQMineSession.h"
#import "XQQGNRJYDIOZLoginVC.h"

@interface MainTabBarController () <UITabBarControllerDelegate>
@property (nonatomic) BOOL presentingLogin;
/// Tab to go back to when the user closes the Me login without signing in.
@property (nonatomic) NSUInteger tabBeforeMe;
@end

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *theme = AppThemeManager.shared;

    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    appearance.backgroundColor = theme.surface;
    self.tabBar.standardAppearance = appearance;
    self.tabBar.scrollEdgeAppearance = appearance;
    self.tabBar.tintColor = theme.accent;

    NSArray *roots = @[DashboardViewController.new, TaskListViewController.new, NoteListViewController.new,
                       FileListViewController.new, XQQMKDIOFZTProfileVC.new];
    NSArray *titles = @[WSText(@"Home"), WSText(@"Tasks"), WSText(@"Notes"), WSText(@"Files"), WSText(@"Me")];
    NSArray *symbols = @[@"square.grid.2x2", @"checkmark.circle", @"note.text", @"doc", @"person.crop.circle"];
    NSMutableArray *navs = NSMutableArray.new;
    for (NSUInteger i = 0; i < roots.count; i++) {
        UIViewController *root = roots[i];
        root.title = titles[i];
        // The Me module keeps its own navigation look, so it gets a plain navigation controller.
        UINavigationController *nav = i == MainTabMe ? [[UINavigationController alloc] initWithRootViewController:root]
                                                     : [[NavigationController alloc] initWithRootViewController:root];
        NSString *selected = [symbols[i] stringByAppendingString:@".fill"];
        nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:titles[i] image:[UIImage ws_symbol:symbols[i]]
                                               selectedImage:[UIImage ws_symbol:selected] ?: [UIImage ws_symbol:symbols[i]]];
        [navs addObject:nav];
    }
    self.viewControllers = navs;

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshBadge) name:WSDataDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshBadge) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self refreshBadge];

    // Me module (migrated from QXQ): its login is still a local placeholder.
    self.delegate = self;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(meDidSignOut) name:XQQMineDidSignOutNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(meDidSignIn) name:XQQMineDidSignInNotification object:nil];
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if (self.selectedIndex != MainTabMe) self.tabBeforeMe = self.selectedIndex;
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if (self.selectedIndex == MainTabMe && !XQQMineSession.isSignedIn) [self presentMeLogin];
}

- (void)closeMeLogin {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.selectedIndex == MainTabMe) {
        self.selectedIndex = self.tabBeforeMe == MainTabMe ? MainTabHome : self.tabBeforeMe;
    }
}

- (void)meDidSignIn {
    if (self.presentedViewController) [self dismissViewControllerAnimated:YES completion:nil];
}

/// Logout / account deletion / expired token: clear the session, back to Me root, ask to sign in again.
- (void)meDidSignOut {
    [XQQMineSession clear];
    [[self navigationForTab:MainTabMe] popToRootViewControllerAnimated:NO];
    if (self.selectedIndex == MainTabMe) [self presentMeLogin];
}

- (void)presentMeLogin {
    if (self.presentingLogin || self.presentedViewController) return;
    self.presentingLogin = YES;
    XQQGNRJYDIOZLoginVC *login = XQQGNRJYDIOZLoginVC.new;
    // Signing in is only needed for the account features in Me; the rest of the app works without it.
    __weak typeof(self) weakSelf = self;
    UIBarButtonItem *close = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose primaryAction:[UIAction actionWithHandler:^(UIAction *a) {
        [weakSelf closeMeLogin];
    }]];
    close.accessibilityLabel = WSText(@"Close");
    login.navigationItem.leftBarButtonItem = close;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{ self.presentingLogin = NO; }];
}

/// Overdue count on the Tasks tab.
- (void)refreshBadge {
    NSUInteger overdue = [TaskManager.shared countForFilter:TaskFilterOverdue];
    self.viewControllers[MainTabTasks].tabBarItem.badgeValue = overdue ? [NSString stringWithFormat:@"%lu", (unsigned long)overdue] : nil;
    self.viewControllers[MainTabTasks].tabBarItem.badgeColor = AppThemeManager.shared.danger;
}

- (UINavigationController *)navigationForTab:(MainTab)tab {
    return (UINavigationController *)self.viewControllers[tab];
}

- (UINavigationController *)selectTab:(MainTab)tab {
    if (self.presentedViewController) [self dismissViewControllerAnimated:NO completion:nil];
    self.selectedIndex = tab;
    return [self navigationForTab:tab];
}

@end
