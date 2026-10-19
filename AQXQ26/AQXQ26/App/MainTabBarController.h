//
//  MainTabBarController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MainTab) {
    MainTabHome = 0,
    MainTabGarage,
    MainTabTrips,
    MainTabNotebook,   // 记事: tasks · notes · files
};

/// 首页 · 爱车 · 行程 · 记事（任务 / 笔记 / 文件）。Projects / Schedule / Backup open from Home.
@interface MainTabBarController : UITabBarController
- (UINavigationController *)navigationForTab:(MainTab)tab;
- (UINavigationController *)selectTab:(MainTab)tab;
/// Switches to 记事 and shows Tasks / Notes / Files (0 / 1 / 2).
- (UINavigationController *)selectNotebookSection:(NSInteger)section;
@end

NS_ASSUME_NONNULL_END
