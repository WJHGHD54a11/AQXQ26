//
//  XQQCUserInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQCJsonSerializer.h"
#import "MJExtension.h"
#import "XQQUserExtraInfo.h"


/**
 用户信息
 */
@interface XQQCUserInfo : XQQCJsonSerializer

/**
 用户ID
 */
@property (nonatomic, strong)NSString *userId;

/**
 名称
 */
@property (nonatomic, strong)NSString *name;

/**
 显示的名称
 */
@property (nonatomic, strong)NSString *displayName;


/**
 出生日期
 */
@property (nonatomic, strong)NSString *birthday;

/**
 性别
 */
@property (nonatomic, assign)int gender;

/**
 头像
 */
@property (nonatomic, strong)NSString *portrait;

/**
 国家码
 */
@property (nonatomic, strong)NSString *area;

/**
 是否设置密码
 */
@property (nonatomic)BOOL password;



/**
 手机号
 */
@property (nonatomic, strong)NSString *mobile;

/**
 邮箱
 */
@property (nonatomic, strong)NSString *email;

/**
 地址
 */
@property (nonatomic, strong)NSString *address;

/**
 公司信息
 */
@property (nonatomic, strong)NSString *company;

/**
 社交信息
 */
@property (nonatomic, strong)NSString *social;

/**
 扩展信息
 */
@property (nonatomic, strong)NSString *extra; //

/**
 好友备注
 */
//@property (nonatomic, strong)NSString *friendAlias;
@property (nonatomic, strong)NSString *alias;

/**
 群昵称
 */
@property (nonatomic, strong)NSString *groupAlias;

@property (nonatomic, strong)NSString *finalName;


/**
 更新时间
 */
@property (nonatomic, assign)long long updateDt;

/**
 用户类型
 */
@property (nonatomic, assign) int type;

/**
 是否被删除用户
 */
@property (nonatomic, assign) int deleted;

@property (nonatomic, assign) BOOL isSelect;

//@property (nonatomic, strong)XQQUserExtraInfo *userExtra;

- (void)cloneFrom:(XQQCUserInfo *)other;

@end

