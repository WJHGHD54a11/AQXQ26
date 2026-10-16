//
//  AppDelegate.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : UIResponder <UIApplicationDelegate>

/// Mirrors the scene window. The migrated Me module presents overlays through
/// `[UIApplication sharedApplication].delegate.window`.
@property (nonatomic, strong, nullable) UIWindow *window;

@end

NS_ASSUME_NONNULL_END
