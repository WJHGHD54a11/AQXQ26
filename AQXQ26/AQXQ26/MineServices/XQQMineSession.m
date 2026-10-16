//
//  XQQMineSession.m
//  AQXQ26
//

#import "XQQMineSession.h"
#import "XQQMineServices.h"
#import "XQQODJNLockStatusManager.h"
#import "XQQCUserInfo.h"

NSNotificationName const XQQMineDidSignInNotification = @"XQQMineDidSignInNotification";

@implementation XQQMineSession

+ (BOOL)isSignedIn {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    return [ud stringForKey:@"savedUserId"].length > 0 && [ud stringForKey:@"savedToken"].length > 0;
}

+ (void)saveUserId:(NSString *)userId token:(NSString *)token websocketToken:(NSString *)websocketToken loginType:(NSInteger)loginType {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ud setObject:token forKey:@"savedToken"];
    [ud setObject:userId forKey:@"savedUserId"];
    if (websocketToken) [ud setObject:websocketToken forKey:@"savedwebsocketToken"];
    [ud setInteger:loginType forKey:@"LOGIN_TYPE"];
    [ud setBool:YES forKey:@"IS_LOGIN"];
    [ud synchronize];
}

+ (void)finishLoginWithUser:(XQQCUserInfo *)user {
    [XQQMineProfile saveMyInfo:user];
    [XQQMineProfile insertOrUpdateUserInfo:user];
    [XQQODJNLockStatusManager.main getLockStatusData:^(BOOL locked) {}];
    [NSNotificationCenter.defaultCenter postNotificationName:XQQMineDidSignInNotification object:nil];
    [NSNotificationCenter.defaultCenter postNotificationName:@"kUserDataUpdated" object:nil];
}

+ (void)clear {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    for (NSString *key in @[@"savedName", @"savedToken", @"savedUserId", @"savedwebsocketToken", @"IS_LOGIN"]) [ud removeObjectForKey:key];
    [XQQMineAccount clearAppServiceAuthInfos];
}

@end
