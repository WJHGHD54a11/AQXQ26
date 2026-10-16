//
//  XQQODJNLockStatusManager.m
//  QXQ
//
//  Created by Loooooo on 10/8/23.
//

#import "XQQODJNLockStatusManager.h"


#define kNormalKey  UNString(@"kLockStatusData%@", [NSUserDefaults.standardUserDefaults stringForKey:@"savedUserId"])

@implementation XQQODJNLockStatusManager

+ (instancetype)main {
    static dispatch_once_t once;
    static XQQODJNLockStatusManager *instance;
    dispatch_once(&once, ^{
        instance = [[XQQODJNLockStatusManager alloc] init];
    }); return instance;
}


/**
 写入信息
 */
- (void)writeLockInfo:(id)dic {
    if (dic == nil) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNormalKey];
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic requiringSecureCoding:YES error:nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dic];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kNormalKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.lockStatus = [LockStatus mj_objectWithKeyValues:dic];
//    NSLog(@"backgroundTime====%lld",self.lockStatus.backgroundTime);
}
/**
 修改信息
 @param value  信息数值
 @param key 个人信息的Key
 */
- (void)reWriteLockInfo:(id)value ForKey:(NSString *)key {
    NSData *obj = [[NSUserDefaults standardUserDefaults] objectForKey:kNormalKey];
//    NSDictionary *dic = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSDictionary class] fromData:obj error:nil];
    NSDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dic];
    [dict setValue:value forKey:key];
    [self writeLockInfo:dict];
}

/**
 清除与用户信息
 */
- (void)cleanLockInfo {
    //清除单例
    self.lockStatus = [[LockStatus alloc] init];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNormalKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark -- setting and getting

- (LockStatus *)lockStatus {
    if (!_lockStatus) {
        NSData *obj = [[NSUserDefaults standardUserDefaults] objectForKey:kNormalKey];
//        NSDictionary *dic = [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class fromData:obj error:nil];
        NSDictionary *dic = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
        _lockStatus = [LockStatus mj_objectWithKeyValues:dic];
    }return _lockStatus;
}


/**
 获取信息数据
 */
- (void)getLockStatusData:(GetLockStatusBlock)block {
    WS(weakself)
    [XQQMineAPI requestUrl:@"/device_lock/get_info" params:@{} success:^(NSDictionary * _Nonnull dict) {
        NSDictionary *result = dict[@"result"];
        NSString *status = dict[@"result"][@"status"];
        if (result != nil && result.count) {
            [weakself writeLockInfo:result];
        }
        if (block) {
            block((status.integerValue == 1 ? YES : NO));
        }
    } error:^(int errCode, NSString * _Nonnull message) {
        if (block) {
            block(NO);
        }
    }];
}




@end

@implementation LockStatus

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundTime = 0;
    }
    return self;
}

@end
