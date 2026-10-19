//
//  GarageCharts.h
//  WorkSpace
//
//  Hand-drawn (Core Graphics) chart views for the Garage. iOS 15 has no Swift Charts,
//  and drawing them keeps the look consistent with the rest of the app.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Stacked monthly bars. Each stack is one bar, values bottom-up in `colors` order.
@interface GarageBarChartView : UIView
- (void)setStacks:(NSArray<NSArray<NSNumber *> *> *)stacks colors:(NSArray<UIColor *> *)colors labels:(NSArray<NSString *> *)labels;
/// Formats the max value on the axis.
@property (nonatomic, copy, nullable) NSString *(^valueFormatter)(double value);
@end

/// Ring split by value, with a centered title.
@interface GarageDonutView : UIView
- (void)setValues:(NSArray<NSNumber *> *)values colors:(NSArray<UIColor *> *)colors
            title:(nullable NSString *)title subtitle:(nullable NSString *)subtitle;
@end

/// Line with gradient fill, average guide and min / max markers.
@interface GarageLineChartView : UIView
- (void)setValues:(NSArray<NSNumber *> *)values labels:(NSArray<NSString *> *)labels unit:(NSString *)unit;
@end

/// Semi-circular gauge, green → amber → red as the value drops.
@interface GarageGaugeView : UIView
@property (nonatomic) CGFloat value;            // 0…1
@property (nonatomic, copy, nullable) NSString *caption;
@property (nonatomic) CGFloat lineWidth;
+ (UIColor *)colorForHealth:(CGFloat)health;
@end

/// Side view of a car, painted in `bodyColor`.
@interface GarageCarView : UIView
@property (nonatomic, strong) UIColor *bodyColor;
@end

NS_ASSUME_NONNULL_END
