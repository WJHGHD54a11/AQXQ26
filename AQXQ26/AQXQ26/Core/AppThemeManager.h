//
//  AppThemeManager.h
//  WorkSpace
//
//  Single source of truth for colors, type and spacing. All screens use these
//  instead of literal values so the visual language stays consistent.
//

#import <UIKit/UIKit.h>
#import "AppConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppThemeManager : NSObject

+ (instancetype)shared;

/// Applies UINavigationBar / UITabBar appearance. Call once at launch.
- (void)applyGlobalAppearance;

#pragma mark Colors (all adapt to light / dark)
@property (nonatomic, readonly) UIColor *accent;          // indigo
@property (nonatomic, readonly) UIColor *background;      // grouped background
@property (nonatomic, readonly) UIColor *surface;         // cards
@property (nonatomic, readonly) UIColor *surfaceRaised;   // chips, inputs inside cards
@property (nonatomic, readonly) UIColor *textPrimary;
@property (nonatomic, readonly) UIColor *textSecondary;
@property (nonatomic, readonly) UIColor *textTertiary;
@property (nonatomic, readonly) UIColor *separator;
@property (nonatomic, readonly) UIColor *success;
@property (nonatomic, readonly) UIColor *warning;
@property (nonatomic, readonly) UIColor *danger;

- (UIColor *)colorForPriority:(TaskPriority)priority;
- (UIColor *)colorForTaskStatus:(TaskStatus)status;
- (UIColor *)colorForProjectStatus:(ProjectStatus)status;
- (UIColor *)colorForScheduleKind:(ScheduleKind)kind;
- (UIColor *)colorForObjectKind:(WSObjectKind)kind;

/// Palette users can pick for projects / tags / categories.
@property (nonatomic, readonly) NSArray<NSString *> *paletteIdentifiers;
- (UIColor *)colorForIdentifier:(nullable NSString *)identifier;

#pragma mark Type (rounded system design, Dynamic Type aware)
- (UIFont *)fontLargeTitle;
- (UIFont *)fontTitle;
- (UIFont *)fontHeadline;
- (UIFont *)fontBody;
- (UIFont *)fontCallout;
- (UIFont *)fontCaption;
- (UIFont *)fontMetric;   // big numbers on dashboard tiles

#pragma mark Metrics
@property (nonatomic, readonly) CGFloat spacing;      // 16
@property (nonatomic, readonly) CGFloat spacingSmall; // 8
@property (nonatomic, readonly) CGFloat cornerRadius; // 14

/// Rounded card look: surface color + continuous corners + hairline border.
- (void)styleCard:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
