//
//  RootViewController.h
//  WorkSpace
//
//  Window root. Shows a light launch view until Core Data is ready, then embeds
//  the tab bar. Reports a store failure once instead of crashing.
//

#import <UIKit/UIKit.h>
#import "MainTabBarController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RootViewController : UIViewController
@property (nonatomic, strong, readonly, nullable) MainTabBarController *tabs;
+ (nullable instancetype)current;
@end

NS_ASSUME_NONNULL_END
