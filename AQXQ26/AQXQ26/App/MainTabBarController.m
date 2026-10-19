//
//  MainTabBarController.m
//  WorkSpace
//

#import "MainTabBarController.h"
#import "NavigationController.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"
#import "DashboardViewController.h"
#import "NotebookNavigationController.h"
#import "TripsViewController.h"
#import "TaskManager.h"
#import "GarageViewController.h"

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

    NSArray *roots = @[DashboardViewController.new, GarageViewController.new, TripsViewController.new, NSNull.null];
    NSArray *titles = @[WSText(@"Home"), WSText(@"Garage"), WSText(@"Trips"), WSText(@"Notebook")];
    NSArray *symbols = @[@"square.grid.2x2", @"car", @"map", @"square.stack"];
    NSMutableArray *navs = NSMutableArray.new;
    for (NSUInteger i = 0; i < roots.count; i++) {
        UINavigationController *nav;
        if (i == MainTabNotebook) {
            nav = [[NotebookNavigationController alloc] init];
        } else {
            UIViewController *root = roots[i];
            root.title = titles[i];
            nav = [[NavigationController alloc] initWithRootViewController:root];
        }
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
    self.viewControllers[MainTabNotebook].tabBarItem.badgeValue = overdue ? [NSString stringWithFormat:@"%lu", (unsigned long)overdue] : nil;
    self.viewControllers[MainTabNotebook].tabBarItem.badgeColor = AppThemeManager.shared.danger;
}

- (UINavigationController *)navigationForTab:(MainTab)tab {
    return (UINavigationController *)self.viewControllers[tab];
}

- (UINavigationController *)selectTab:(MainTab)tab {
    if (self.presentedViewController) [self dismissViewControllerAnimated:NO completion:nil];
    self.selectedIndex = tab;
    return [self navigationForTab:tab];
}

- (UINavigationController *)selectNotebookSection:(NSInteger)section {
    NotebookNavigationController *nav = (NotebookNavigationController *)[self selectTab:MainTabNotebook];
    if ([nav isKindOfClass:NotebookNavigationController.class]) [nav showSection:section];
    return nav;
}

@end
