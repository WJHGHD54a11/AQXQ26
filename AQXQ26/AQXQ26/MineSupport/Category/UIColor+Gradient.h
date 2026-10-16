//
//  UIColor+Gradient.h
//  UNI Z META
//
//  Created by Loooooo on 9/4/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, GradientColorDirection) {
    GradientColorDirectionLevel,//水平渐变
    GradientColorDirectionVertical,//竖直渐变
    GradientColorDirectionDownDiagonalLine,//向上对角线渐变
    GradientColorDirectionUpwardDiagonalLine,//向下对角线渐变
};

@interface UIColor (Gradient)

/// 设置渐变色
/// @param size 需要渐变的大小
/// @param direction 渐变的方向
/// @param startcolor 渐变的开始颜色
/// @param endColor 渐变的结束颜色
+ (instancetype)gradientColorWithSize:(CGSize)size
                            direction:(GradientColorDirection)direction
                           startColor:(UIColor *)startcolor
                             endColor:(UIColor *)endColor;

/// 颜色的透明度
- (UIColor *)alpha:(float)alpha;




@end

NS_ASSUME_NONNULL_END
