//
//  UIView+Extension.m
//  WUHOIBDK
//
//  Created by Loooooo on 10/31/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)





- (void)exChangeOutDur {
    CAKeyframeAnimation * animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.duration = 0.35;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    
    NSMutableArray *values = [NSMutableArray array];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 0.9)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: @"easeInEaseOut"];
    
    [self.layer addAnimation:animation forKey:nil];
}

@end
