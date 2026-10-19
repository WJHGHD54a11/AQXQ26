//
//  GarageUI.h
//  WorkSpace
//
//  Small building blocks shared by the Garage screens (cards in a vertical scroll stack).
//

#import <UIKit/UIKit.h>

@class PlanStatus, GarageTimelineEntry;

NS_ASSUME_NONNULL_BEGIN

/// Card with an optional header row ("Title ........ Action >") and a vertical content stack.
@interface GarageCard : UIView
+ (instancetype)cardWithTitle:(nullable NSString *)title action:(nullable NSString *)action handler:(nullable void (^)(void))handler;
@property (nonatomic, readonly) UIStackView *content;
@end

/// Value + caption tile.
@interface GarageStatTile : UIView
+ (instancetype)tileWithValue:(NSString *)value caption:(NSString *)caption symbol:(NSString *)symbol color:(UIColor *)color;
@end

/// Tappable row: icon bubble, title, subtitle, trailing value.
@interface GarageRow : UIControl
+ (instancetype)rowWithSymbol:(NSString *)symbol color:(UIColor *)color title:(NSString *)title
                     subtitle:(nullable NSString *)subtitle trailing:(nullable NSString *)trailing;
@property (nonatomic, copy, nullable) void (^onTap)(void);
/// Replaces the icon bubble with a small health ring.
- (void)showRing:(CGFloat)progress color:(UIColor *)color;
@property (nonatomic, strong, readonly) UILabel *trailingLabel;
@end

/// Round icon button with caption below (quick actions).
@interface GarageQuickButton : UIControl
+ (instancetype)buttonWithSymbol:(NSString *)symbol title:(NSString *)title color:(UIColor *)color handler:(void (^)(void))handler;
@end

/// Vertical scroll view whose content is a stack (screens are built from cards).
@interface GarageScrollStack : UIScrollView
@property (nonatomic, readonly) UIStackView *stack;
- (void)removeAllCards;
@end

FOUNDATION_EXPORT UIView *GarageSpacer(CGFloat height);
FOUNDATION_EXPORT UILabel *GarageLabel(NSString *_Nullable text, UIFont *font, UIColor *color, NSInteger lines);
FOUNDATION_EXPORT GarageRow *GarageRowForPlan(PlanStatus *status);
FOUNDATION_EXPORT GarageRow *GarageRowForEntry(GarageTimelineEntry *entry);
FOUNDATION_EXPORT NSString *GarageShortDate(NSDate *date);

NS_ASSUME_NONNULL_END
