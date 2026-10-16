//
//  XQQMineLocalService+API.m
//  AQXQ26
//
//  原 XQQAppService.requestUrl 系列的本地路由。按 path 分发，返回与服务端相同结构的 {"result": ...}。
//  未列出的 path 一律成功并返回空 result，保证页面流程能走完。
//

#import "XQQMineLocalService+Private.h"
#import "XQQCUserInfo.h"
#import "MJExtension.h"
#import <UIKit/UIKit.h>

typedef id (^XQQMineRoute)(XQQMineLocalService *svc, NSDictionary *params);

@implementation XQQMineLocalService (API)

#pragma mark - 路由表

+ (NSDictionary<NSString *, XQQMineRoute> *)xqq_routes {
    static NSDictionary *routes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = @{
            // 设备登录记录
            @"/device_history":        ^id(XQQMineLocalService *s, NSDictionary *p) { return [s xqq_deviceHistory]; },
            @"/device_history_list":   ^id(XQQMineLocalService *s, NSDictionary *p) {
                return [[s xqq_deviceHistory] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", p[@"deviceId"] ?: @""]];
            },
            @"/delete_device_history": ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_deleteDevice:p[@"deviceId"]]; return nil; },
            // 设备锁（与 XQQODJNLockStatusManager 的字段一致）
            @"/device_lock/get_info":  ^id(XQQMineLocalService *s, NSDictionary *p) { return [s xqq_lockInfo]; },
            @"/device_lock/set_status":^id(XQQMineLocalService *s, NSDictionary *p) {
                NSMutableDictionary *update = [@{@"status": p[@"status"] ?: @0} mutableCopy];
                if (p[@"waitTime"]) update[@"waitTime"] = p[@"waitTime"];
                return [s xqq_updateLock:update];
            },
            @"/device_lock/update_device_number": ^id(XQQMineLocalService *s, NSDictionary *p) {
                NSString *old = p[@"oldNumber"];
                NSString *current = [s xqq_lockInfo][@"number"];
                if (old && current.length && ![old isEqualToString:current]) {
                    return [NSError errorWithDomain:@"XQQMine" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"原密码错误"}];
                }
                return [s xqq_updateLock:@{@"number": p[@"newNumber"] ?: @"", @"initNumber": @1}];
            },
            @"/device_lock/reset_device_number": ^id(XQQMineLocalService *s, NSDictionary *p) {
                return [s xqq_updateLock:@{@"number": p[@"newNumber"] ?: @"", @"initNumber": @1}];
            },
            // 历史头像：type 0 = 系统头像，1 = 我上传过的
            @"/user/headers":          ^id(XQQMineLocalService *s, NSDictionary *p) {
                NSArray *urls = [p[@"type"] isEqual:@"1"] ? ([s objectForKey:[s xqq_avatarKey]] ?: @[]) : @[];
                NSMutableArray *list = NSMutableArray.new;
                for (NSString *url in urls) [list addObject:@{@"portrait": url}];
                return list;
            },
            @"/update/avatar":         ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_recordAvatar:p[@"portrait"]]; return nil; },
            @"/user/delete/avatars":   ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_deleteAvatars:p]; return nil; },
            // 验证码校验：返回一个一次性凭证，后续 /reset 使用
            @"/validMobileCode":       ^id(XQQMineLocalService *s, NSDictionary *p) { return NSUUID.UUID.UUIDString; },
            @"/validEmailCode":        ^id(XQQMineLocalService *s, NSDictionary *p) { return NSUUID.UUID.UUIDString; },
            @"/reset":                 ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_markPasswordSet]; return nil; },
            @"/resetWithEmail":        ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_markPasswordSet]; return nil; },
            @"/updatePassword":        ^id(XQQMineLocalService *s, NSDictionary *p) { [s xqq_markPasswordSet]; return nil; },
            // 注销
            @"/destroy":               ^id(XQQMineLocalService *s, NSDictionary *p) { [s destroyAccount:p success:^{} error:^(int c, NSString *m) {}]; return nil; },
            @"/destroyWithEmail":      ^id(XQQMineLocalService *s, NSDictionary *p) { [s destroyAccount:p success:^{} error:^(int c, NSString *m) {}]; return nil; },
            // 版本检查：本地不提示更新
            @"/global_config":         ^id(XQQMineLocalService *s, NSDictionary *p) { return @{}; },
        };
    });
    return routes;
}

- (void)xqq_handle:(NSString *)url params:(id)params success:(void (^)(NSDictionary *))successBlock error:(void (^)(int, NSString *))errorBlock {
    XQQMineRoute route = [self.class xqq_routes][url];
    NSDictionary *p = [params isKindOfClass:NSDictionary.class] ? params : @{};
    if ([params isKindOfClass:NSArray.class]) p = @{@"items": params}; // 删除历史头像传的是数组，空数组表示全部
    id result = route ? route(self, p) : nil;
    [self after:^{
        if ([result isKindOfClass:NSError.class]) {
            if (errorBlock) errorBlock((int)[(NSError *)result code], [(NSError *)result localizedDescription]);
            return;
        }
        if (successBlock) successBlock(result ? @{@"code": @0, @"result": result} : @{@"code": @0});
    }];
}

- (void)requestUrl:(NSString *)url params:(id)params success:(void (^)(NSDictionary *))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_handle:url params:params success:successBlock error:errorBlock];
}

- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void (^)(NSDictionary *))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_handle:url params:params success:successBlock error:errorBlock];
}

- (void)uploadFile:(NSString *)url images:(NSArray<UIImage *> *)images progress:(void (^)(int, int))progressBlock success:(void (^)(NSString *))successBlock error:(void (^)(NSString *))errorBlock {
    NSData *data = UIImageJPEGRepresentation(images.firstObject, 0.8);
    if (!data) {
        [self after:^{ if (errorBlock) errorBlock(@"图片无效"); }];
        return;
    }
    [self uploadFile:@"image.jpg" data:data mimeType:@"image/jpeg" success:^(NSString *remoteUrl) {
        if (progressBlock) progressBlock((int)images.count, (int)images.count);
        if (successBlock) successBlock(remoteUrl);
    } progress:^(long u, long t) {} fail:^(int error_code, NSString *message) {
        if (errorBlock) errorBlock(message);
    }];
}

#pragma mark - 设备记录

- (NSString *)xqq_deviceKey { return [@"devices." stringByAppendingString:self.currentUserId]; }

- (NSArray *)xqq_deviceHistory {
    NSArray *list = [self objectForKey:self.xqq_deviceKey];
    if (!list) {
        // 首次进入时记录当前设备
        list = @[@{@"id": [self getClientId], @"deviceId": [self getClientId], @"ip": @"127.0.0.1",
                   @"type": UIDevice.currentDevice.model, @"userId": self.currentUserId,
                   @"lastLogin": @((long long)(NSDate.date.timeIntervalSince1970 * 1000))}];
        [self setObject:list forKey:self.xqq_deviceKey];
    }
    return list;
}

- (void)xqq_deleteDevice:(NSString *)deviceId {
    NSArray *list = [[self xqq_deviceHistory] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"id != %@", deviceId ?: @""]];
    [self setObject:list forKey:self.xqq_deviceKey];
}

#pragma mark - 设备锁

- (NSString *)xqq_lockKey { return [@"lock." stringByAppendingString:self.currentUserId]; }

- (NSDictionary *)xqq_lockInfo {
    NSDictionary *info = [self objectForKey:self.xqq_lockKey];
    if (!info) {
        XQQCUserInfo *me = [self getMyInfo];
        info = @{@"userId": self.currentUserId, @"mobile": me.mobile ?: @"", @"number": @"",
                 @"status": @0, @"initNumber": @0, @"waitTime": @1, @"disableUser": @0};
    }
    return info;
}

- (NSDictionary *)xqq_updateLock:(NSDictionary *)values {
    NSMutableDictionary *info = [[self xqq_lockInfo] mutableCopy];
    [info addEntriesFromDictionary:values];
    [self setObject:info forKey:self.xqq_lockKey];
    return info;
}

#pragma mark - 头像 / 密码

- (NSString *)xqq_avatarKey { return [@"avatars." stringByAppendingString:self.currentUserId]; }

- (void)xqq_recordAvatar:(NSString *)url {
    if (url.length == 0) return;
    NSMutableArray *list = [[self objectForKey:self.xqq_avatarKey] mutableCopy] ?: NSMutableArray.new;
    [list removeObject:url];
    [list insertObject:url atIndex:0];
    [self setObject:list forKey:self.xqq_avatarKey];
}

- (void)xqq_deleteAvatars:(NSDictionary *)params {
    NSArray *items = params[@"items"];
    if (items && items.count == 0) { [self setObject:nil forKey:self.xqq_avatarKey]; return; }
    id target = items ?: params[@"portraits"] ?: params[@"portrait"] ?: params[@"ids"];
    NSArray *remove = [target isKindOfClass:NSArray.class] ? target : (target ? [[target description] componentsSeparatedByString:@","] : @[]);
    NSMutableArray *list = [[self objectForKey:self.xqq_avatarKey] mutableCopy] ?: NSMutableArray.new;
    [list removeObjectsInArray:remove];
    [self setObject:list forKey:self.xqq_avatarKey];
}

- (void)xqq_markPasswordSet {
    [self userUpdate:@{@"password": @YES} success:^{} error:^(int c, NSString *m) {}];
}

@end
