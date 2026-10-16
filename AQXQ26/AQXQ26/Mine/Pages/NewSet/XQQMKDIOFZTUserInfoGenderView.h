//
//  XQQMKDIOFZTUserInfoGenderView.h
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^SelectGender)(NSInteger);

@interface XQQMKDIOFZTUserInfoGenderView : UIView

@property NSInteger gender;
@property UIView *whiteV;
@property SelectGender selectB;

- (void)show:(NSInteger)gender;
- (void)dismis;
@end

NS_ASSUME_NONNULL_END
