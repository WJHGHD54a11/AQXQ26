//
//  QXQ
//
//  Created by Loooooo on 10/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^GetLockStatusBlock)(BOOL lockStatus);

@class LockStatus;
@interface XQQODJNLockStatusManager : NSObject

+ (instancetype)main;


/**
 安全锁状态数据模型
 */
@property (nonatomic, strong) LockStatus *lockStatus;

/**
 写入信息
 */
- (void)writeLockInfo:(id)dic;

/**
 修改信息
 @param value 个人信息数值
 @param key 个人信息的Key
 */
- (void)reWriteLockInfo:(id)value ForKey:(NSString *)key;

/**
 清除信息
 */
- (void)cleanLockInfo;

/**
 获取用户信息数据
 */
- (void)getLockStatusData:(GetLockStatusBlock)block;

@end


@interface LockStatus : NSObject

@property (nonatomic, copy)   NSString *userId; // 用户ID
@property (nonatomic, copy)   NSString *mobile; // 用户注册时的手机号，用于判断是否是手机注册
@property (nonatomic, copy)   NSString *number; // 如果initNumber为true，此处返回的是设置的密码，如果init为false，此处返回空

@property (nonatomic, assign)   NSInteger status; // 当前设备锁状态true是开启
@property (nonatomic, assign)   NSInteger initNumber; // 如果为false则表示重来没有设置过密码
@property (nonatomic, assign)   NSInteger waitTime; // 锁定等待时间(单位分钟)
@property (nonatomic, assign)   NSInteger disableUser; // 是否在错误到达一定次数后注销用户

#pragma mark -------------------以下是自增的字段-------------------

@property (nonatomic, assign)  long long backgroundTime; // 程序进入后台的开始时间 单位秒

@end


NS_ASSUME_NONNULL_END
