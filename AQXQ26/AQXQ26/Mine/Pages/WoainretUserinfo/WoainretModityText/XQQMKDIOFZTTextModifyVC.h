//
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQMKDIOFZTTextModifyVC : XQQWJEFDOCYMainVC

/**
 修改信息内容的类型

 - Modify_DisplayName: 修改显示名 = 0
 - Modify_Portrait: 修改头像
 - Modify_Gender: 修改性别
 - Modify_Mobile: 修改手机号
 - Modify_Email: 修改邮箱
 - Modify_Address: 修改地址
 - Modify_Company: 修改公司信息
 - Modify_Social: 修改社交信息
 - Modify_Extra: 修改扩展信息
 
 - Modify_FriendAlias = 9, // 1228新增
 
 - Modify_Sign: 修改个性签名
 
 
 - 修改账号：100
 - 修改我在本群昵称：101
 - 修改群聊名称：102
 */
@property(nonatomic, assign) ModifyMyInfoType modifyType;

@property (nonatomic, copy) NSString *defaultValue;

// modifyType = 101时 该字段有值 会话的groupId。 modifyType = 102
@property (nonatomic, copy) NSString *groupId;
// modifyType = Modify_FriendAlias时 该字段有值
@property (nonatomic, copy) NSString *userId;

@property(nonatomic, copy)void (^onModified)(NSString *value);

@end

NS_ASSUME_NONNULL_END
