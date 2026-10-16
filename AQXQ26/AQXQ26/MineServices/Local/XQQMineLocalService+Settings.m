//
//  XQQMineLocalService+Settings.m
//  AQXQ26
//
//  通知设置 + 账号与安全的本地实现
//

#import "XQQMineLocalService+Private.h"

@implementation XQQMineLocalService (Notify)

- (NSString *)xqq_settingKey:(NSString *)name {
    return [NSString stringWithFormat:@"setting.%@.%@", self.currentUserId, name];
}

- (BOOL)xqq_boolSetting:(NSString *)name {
    return [[self objectForKey:[self xqq_settingKey:name]] boolValue];
}

- (void)xqq_setBool:(BOOL)value setting:(NSString *)name success:(void(^)(void))successBlock {
    [self setObject:@(value) forKey:[self xqq_settingKey:name]];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (BOOL)isGlobalSilent { return [self xqq_boolSetting:@"globalSilent"]; }
- (void)setGlobalSilent:(BOOL)silent success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self xqq_setBool:silent setting:@"globalSilent" success:successBlock];
}

- (BOOL)isVoipNotificationSilent { return [self xqq_boolSetting:@"voipSilent"]; }
- (void)setVoipNotificationSilent:(BOOL)silent success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self xqq_setBool:silent setting:@"voipSilent" success:successBlock];
}

- (BOOL)isEnableSyncDraft { return [self xqq_boolSetting:@"syncDraft"]; }
- (void)setEnableSyncDraft:(BOOL)enable success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self xqq_setBool:enable setting:@"syncDraft" success:successBlock];
}

- (BOOL)isHiddenNotificationDetail { return [self xqq_boolSetting:@"hiddenDetail"]; }
- (void)setHiddenNotificationDetail:(BOOL)hidden success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self xqq_setBool:hidden setting:@"hiddenDetail" success:successBlock];
}

- (BOOL)isUserEnableReceipt {
    id value = [self objectForKey:[self xqq_settingKey:@"receipt"]];
    return value ? [value boolValue] : YES;
}

- (void)getNoDisturbingTimes:(void (^)(int, int))resultBlock error:(void (^)(int))errorBlock {
    NSArray *range = [self objectForKey:[self xqq_settingKey:@"noDisturbing"]];
    [self after:^{
        if (range.count == 2) {
            if (resultBlock) resultBlock([range[0] intValue], [range[1] intValue]);
        } else if (errorBlock) {
            errorBlock(-1); // 与原 SDK 一致：未设置时走 error
        }
    }];
}

- (void)setNoDisturbingTimes:(int)startMins endMins:(int)endMins success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self setObject:@[@(startMins), @(endMins)] forKey:[self xqq_settingKey:@"noDisturbing"]];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)clearNoDisturbingTimes:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self setObject:nil forKey:[self xqq_settingKey:@"noDisturbing"]];
    [self after:^{ if (successBlock) successBlock(); }];
}

@end

@implementation XQQMineLocalService (Account)

- (void)xqq_succeed:(void(^)(void))successBlock {
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)sendLoginCode:(NSDictionary *)params success:(void (^)(void))successBlock error:(void (^)(NSString *))errorBlock { [self xqq_succeed:successBlock]; }
- (void)sendMobileCodeWithScene:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock { [self xqq_succeed:successBlock]; }
- (void)sendEmailCodeWithScene:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock { [self xqq_succeed:successBlock]; }
- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock { [self xqq_succeed:successBlock]; }

- (void)userbindEmail:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self userUpdate:@{@"email": param[@"email"] ?: @""} success:successBlock error:errorBlock];
}

- (void)userbindPhone:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSMutableDictionary *update = NSMutableDictionary.new;
    update[@"mobile"] = param[@"mobile"];
    update[@"area"] = param[@"area"];
    [self userUpdate:update success:successBlock error:errorBlock];
}

- (void)destroyAccount:(NSDictionary *)data success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_destroyCurrentUser];
    [self xqq_succeed:successBlock];
}

- (void)xqq_destroyCurrentUser {
    NSString *userId = self.currentUserId;
    if (userId.length == 0) return;
    // 只删当前账号的本地数据
    NSString *prefix = @"XQQMineLocal.";
    for (NSString *key in NSUserDefaults.standardUserDefaults.dictionaryRepresentation.allKeys) {
        if ([key hasPrefix:prefix] && [key containsString:userId]) {
            [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
        }
    }
}

- (void)clearAppServiceAuthInfos {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"IS_LOGIN"];
}

- (NSString *)getClientId {
    NSString *clientId = [self objectForKey:@"clientId"];
    if (!clientId) {
        clientId = NSUUID.UUID.UUIDString;
        [self setObject:clientId forKey:@"clientId"];
    }
    return clientId;
}

/// 原工程断开 IM 后由 SDK 发出连接状态变化，App 回到登录页。这里直接发通知，由宿主切换界面。
- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:XQQMineDidSignOutNotification object:nil];
    });
}

@end
