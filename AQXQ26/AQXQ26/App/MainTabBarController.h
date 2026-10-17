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
};

/// 首页 · 任务 · 笔记 · 文件。Projects / Schedule / Backup open from Home.
@interface MainTabBarController : UITabBarController
- (UINavigationController *)navigationForTab:(MainTab)tab;
- (UINavigationController *)selectTab:(MainTab)tab;
@end

NS_ASSUME_NONNULL_END
