//
//  XQQMKDIOFZTUserInfoBirthdayView.h
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SelectDate)(NSTimeInterval);

@interface XQQMKDIOFZTUserInfoBirthdayView : UIView
@property SelectDate selectD;

- (void)show;
- (void)setInitialDateWithTimestamp:(NSTimeInterval)timestamp;
@end

NS_ASSUME_NONNULL_END
