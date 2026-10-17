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
#import "TaskManager.h"

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
                       FileListViewController.new];
    NSArray *titles = @[WSText(@"Home"), WSText(@"Tasks"), WSText(@"Notes"), WSText(@"Files")];
    NSArray *symbols = @[@"square.grid.2x2", @"checkmark.circle", @"note.text", @"doc"];
    NSMutableArray *navs = NSMutableArray.new;
    for (NSUInteger i = 0; i < roots.count; i++) {
        UIViewController *root = roots[i];
        root.title = titles[i];
        UINavigationController *nav = [[NavigationController alloc] initWithRootViewController:root];
        NSString *selected = [symbols[i] stringByAppendingString:@".fill"];
        nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:titles[i] image:[UIImage ws_symbol:symbols[i]]
                                               selectedImage:[UIImage ws_symbol:selected] ?: [UIImage ws_symbol:symbols[i]]];
        [navs addObject:nav];
    }
    self.viewControllers = navs;

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshBadge) name:WSDataDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshBadge) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self refreshBadge];
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
