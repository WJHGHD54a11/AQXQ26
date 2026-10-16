//
//  MainTabBarController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MainTab) {
    MainTabHome = 0,
    MainTabTasks,
    MainTabNotes,
    MainTabFiles,
    MainTabMe,
};

/// 首页 · 任务 · 笔记 · 文件 · 我的。Projects / Schedule / Backup open from Home.
/// The Me tab hosts the module migrated from QXQ; more QXQ modules will be added as tabs later.
@interface MainTabBarController : UITabBarController
- (UINavigationController *)navigationForTab:(MainTab)tab;
- (UINavigationController *)selectTab:(MainTab)tab;
@end

NS_ASSUME_NONNULL_END
