//
//  XQQMineTabBarVC.m
//  AQXQ26
//

#import "XQQMineTabBarVC.h"
#import "XQQMKDIOFZTProfileVC.h"
#import "XQQGNRJYDIOZLoginVC.h"
#import "XQQMineLocalService.h"
#import "UIImage+ERCategory.h"

/// 未迁移模块的占位页
@interface XQQMinePendingVC : XQQWJEFDOCYMainVC
@end

@implementation XQQMinePendingVC
- (void)viewDidLoad {
    [super viewDidLoad];
    UILabel *label = UILabel.new;
    label.text = LLLLLL(@"MineModulePending");
    label.textColor = RGBA(0x999999);
    label.font = [UIFont systemFontOfSize:15];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
    ]];
}
@end

@interface XQQMineTabBarVC ()
@property (nonatomic, assign) BOOL xqq_presentingLogin;
@end

@implementation XQQMineTabBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [XQQMineServiceHub registerDefaultServices];

    [UITabBar.appearance setUnselectedItemTintColor:RGBA(0xD0D0D0)];
    [UITabBar.appearance setTintColor:MAINCOLOR];

    // 图标资源沿用原序号：EGSIX0 消息、1 通讯录、2 保管箱、3 工具箱、4 我的
    NSArray<NSNumber *> *iconIndexes = @[@2, @0, @1, @3, @4];
    NSArray *vcs = @[XQQMinePendingVC.new, XQQMinePendingVC.new, XQQMinePendingVC.new, XQQMinePendingVC.new, XQQMKDIOFZTProfileVC.new];
    NSMutableArray *navs = NSMutableArray.new;
    for (NSInteger i = 0; i < vcs.count; i++) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vcs[i]];
        UIImage *normal = [IMAGENAME(UNString(@"EGSIX%ldA", (long)iconIndexes[i].integerValue)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIImage *selected = [IMAGENAME(UNString(@"EGSIX%ldAA", (long)iconIndexes[i].integerValue)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:nil image:normal selectedImage:selected];
        [navs addObject:nav];
    }
    self.viewControllers = navs;
    self.selectedIndex = vcs.count - 1; // 第一步只有「我的」，启动直接停在这里
    [self refreshTabTitles];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshTabTitles) name:kLanguageNoti object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(xqq_didSignOut) name:XQQMineDidSignOutNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!XQQMineLocalService.shared.isSignedIn) {
        [self xqq_presentLogin];
    }
}

- (void)refreshTabTitles {
    NSArray *titles = @[LLLLLL(@"Vault"), LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"ToolboxTab"), LLLLLL(@"Mine")];
    for (NSInteger i = 0; i < self.viewControllers.count && i < titles.count; i++) {
        self.viewControllers[i].title = titles[i];
        self.viewControllers[i].tabBarItem.title = titles[i];
    }
}

// 退出/注销会连续触发两次 disconnect，这里只处理一次
- (void)xqq_didSignOut {
    for (UINavigationController *nav in self.viewControllers) {
        if ([nav isKindOfClass:UINavigationController.class]) [nav popToRootViewControllerAnimated:NO];
    }
    [self xqq_presentLogin];
}

- (void)xqq_presentLogin {
    if (self.xqq_presentingLogin || self.presentedViewController) return;
    self.xqq_presentingLogin = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:XQQGNRJYDIOZLoginVC.new];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:^{
        self.xqq_presentingLogin = NO;
    }];
}

@end
