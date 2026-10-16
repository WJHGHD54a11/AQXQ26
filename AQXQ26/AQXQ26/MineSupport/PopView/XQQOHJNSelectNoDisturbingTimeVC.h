//
//  XQQOHJNSelectNoDisturbingTimeVC.h
//  WFChatUIKit
//
//  Created by dali on 2020/10/27.
//  Copyright © 2020 Wildfirechat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQOHJNSelectNoDisturbingTimeVC : UIViewController
@property(nonatomic, assign) NSInteger startMins;
@property(nonatomic, assign) NSInteger endMins;

@property(nonatomic, strong)void (^onSelectTime)(NSInteger startMins, NSInteger endMins);
@end

NS_ASSUME_NONNULL_END
