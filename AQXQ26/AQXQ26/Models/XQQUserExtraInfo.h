//
//  XQQUserExtraInfo.h
//  WFChatClient
//
//  Created by wtb on 2025/8/16.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQUserExtraInfo : NSObject
@property (nonatomic, copy)   NSString *sign; // 个性签名

@property (nonatomic, assign) long long lastLoginTime; // 当前时间戳(毫秒)

@property (nonatomic, assign) NSInteger disableAutoAddFriend; // 加我为朋友时是否需要验证
// 是否显示最后上线时间   0 所有人    1 仅通讯录联系人    2 不显示在线时间
@property (nonatomic, assign) NSInteger disableShowLastLoginTime;
@property (nonatomic, assign) NSInteger disableShowPhone; // 对朋友是否展示电话号码
@property (nonatomic, assign) NSInteger disableJoinToGroup; // 邀请我加入群聊是否需要验证
@property (nonatomic, assign) NSInteger disableShowInputState; // 是否展示输入状态

// 添加我的方式
@property (nonatomic, assign) NSInteger openMobileSearch; // 手机号码
@property (nonatomic, assign) NSInteger openAccountSearch; // 86ID号

// 通知设置 ---> 声音 和 震动
@property (nonatomic, assign) NSInteger sound; // 声音
@property (nonatomic, assign) NSInteger shake; // 震动

@property (nonatomic, assign) long long birthday; //生日

@property (nonatomic, assign) long long lastPull; //最后拉取时间
@property (nonatomic, assign) long long lastRead; //最后一条已读消息

@end

NS_ASSUME_NONNULL_END
