//
//  XQQMineLocalService.m
//  AQXQ26
//
//  存储与公共部分。各领域实现见 XQQMineLocalService+*.m
//

#import "XQQMineLocalService+Private.h"
#import "XQQCUserInfo.h"
#import "MJExtension.h"

static NSString * const kXQQMineStorePrefix = @"XQQMineLocal.";
static NSString * const kXQQMineDemoUserId = @"demo_user_10001";

@implementation XQQMineLocalService

+ (instancetype)shared {
    static XQQMineLocalService *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

#pragma mark - 存储

- (id)objectForKey:(NSString *)key {
    return [NSUserDefaults.standardUserDefaults objectForKey:[kXQQMineStorePrefix stringByAppendingString:key]];
}

- (void)setObject:(id)obj forKey:(NSString *)key {
    NSString *fullKey = [kXQQMineStorePrefix stringByAppendingString:key];
    if (obj) {
        [NSUserDefaults.standardUserDefaults setObject:obj forKey:fullKey];
    } else {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:fullKey];
    }
}

- (NSString *)currentUserId {
    return [NSUserDefaults.standardUserDefaults stringForKey:@"savedUserId"] ?: @"";
}

- (void)after:(dispatch_block_t)block {
    if (!block) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

#pragma mark - 演示账号

- (BOOL)isSignedIn {
    return self.currentUserId.length > 0;
}

- (void)signInDemoUser {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ud setObject:kXQQMineDemoUserId forKey:@"savedUserId"];
    [ud setObject:@"demo-local-token" forKey:@"savedToken"];
    [ud setObject:@"demo" forKey:@"savedName"];
    [ud setBool:YES forKey:@"IS_LOGIN"];

    if (![self getUserInfo:kXQQMineDemoUserId]) {
        long long now = (long long)(NSDate.date.timeIntervalSince1970 * 1000);
        NSDictionary *extra = @{@"sign": @"", @"lastLoginTime": @(now), @"sound": @1, @"shake": @1,
                                @"openMobileSearch": @1, @"openAccountSearch": @1};
        XQQCUserInfo *user = XQQCUserInfo.new;
        user.userId = kXQQMineDemoUserId;
        user.name = @"10001";
        user.displayName = @"Demo";
        user.area = @"86";
        user.mobile = @"13800000000";
        user.email = @"";
        user.gender = 0;
        user.password = YES;
        user.extra = [extra mj_JSONString];
        user.updateDt = now;
        [self insertOrUpdateUserInfo:user];
        [self saveMyInfo:user];
    }
    [ud synchronize];
}

@end
