//
//  XQQGNRJYDIOZLoginVC.h
//  WUHOIBDK
//
//  Created by Ruby on 12/22/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQGNRJYDIOZLoginVC : XQQWJEFDOCYMainVC

//如果是因为多端登录被踢，提示原因。注意错误码kConnectionStatusKickedoff是IM服务2021.9.15之后的版本才支持，并且打开服务器端开关server.client_support_kickoff_event
@property(nonatomic, assign)BOOL isKickedOff;

//是否是密码登录
@property(nonatomic, assign)BOOL isPwdLogin;

@end

NS_ASSUME_NONNULL_END
