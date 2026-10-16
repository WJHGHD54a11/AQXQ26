//
//  WSUIKit.h
//  WorkSpace
//
//  Small building blocks shared by every screen: empty state, alerts,
//  section header, pill label, progress ring and list-cell configuration.
//

#import <UIKit/UIKit.h>
#import "AppThemeManager.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Empty state

@interface WSEmptyStateView : UIView
+ (instancetype)viewWithSymbol:(NSString *)symbol title:(NSString *)title message:(nullable NSString *)message
                   actionTitle:(nullable NSString *)actionTitle action:(nullable void (^)(void))action;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *message;
@end

#pragma mark - Pill

/// Rounded tinted label for status / priority / tag.
@interface WSPillLabel : UILabel
- (void)setText:(nullable NSString *)text color:(UIColor *)color;
@end

#pragma mark - Progress ring

@interface WSProgressRing : UIView
@property (nonatomic) CGFloat progress;   // 0...1
@property (nonatomic, strong) UIColor *tintColorForRing;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) BOOL showsPercentage;
@end

#pragma mark - Section header

@interface WSSectionHeaderView : UICollectionReusableView
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UIButton *actionButton;
@property (nonatomic, copy, nullable) void (^onAction)(void);
- (void)setTitle:(NSString *)title action:(nullable NSString *)action;
@end

#pragma mark - Chip bar

/// Horizontally scrolling single-selection chips (filters on list screens).
@interface WSChipBar : UIView
/// Replaces chips; `selectedIndex` is highlighted. Trailing `accessory` (e.g. "Manage") is optional.
- (void)setTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex;
@property (nonatomic, readonly) NSInteger selectedIndex;
@property (nonatomic, copy, nullable) void (^onSelect)(NSInteger index);
@property (nonatomic, copy, nullable) NSString *accessoryTitle;
@property (nonatomic, copy, nullable) void (^onAccessory)(void);
@end

#pragma mark - Helpers

@interface UIViewController (WSAlerts)
- (void)ws_showError:(nullable NSError *)error;
- (void)ws_showMessage:(NSString *)message title:(nullable NSString *)title;
- (void)ws_confirm:(NSString *)title message:(nullable NSString *)message destructive:(NSString *)action handler:(void (^)(void))handler;
/// Single text field prompt. Empty input is rejected with a shake + keeps the alert open.
- (void)ws_promptTitle:(NSString *)title message:(nullable NSString *)message placeholder:(nullable NSString *)placeholder
                  text:(nullable NSString *)text action:(NSString *)action handler:(void (^)(NSString *text))handler;
- (void)ws_toast:(NSString *)text;
/// Share sheet anchored to `source` (bar button or view).
- (void)ws_share:(NSArray *)items from:(nullable id)source;
@end

@interface UIImage (WSSymbols)
+ (nullable UIImage *)ws_symbol:(NSString *)name;
+ (nullable UIImage *)ws_symbol:(NSString *)name pointSize:(CGFloat)size weight:(UIImageSymbolWeight)weight;
@end

/// Standard cell background for list cells (inset grouped card look).
FOUNDATION_EXPORT UIBackgroundConfiguration *WSListBackground(void);
/// Compositional list layout used by list screens (inset grouped, swipe actions provided by the caller).
FOUNDATION_EXPORT UICollectionViewCompositionalLayout *WSListLayout(UICollectionLayoutListSwipeActionsConfigurationProvider _Nullable trailing,
                                                                    UICollectionLayoutListSwipeActionsConfigurationProvider _Nullable leading,
                                                                    BOOL headers);

NS_ASSUME_NONNULL_END
