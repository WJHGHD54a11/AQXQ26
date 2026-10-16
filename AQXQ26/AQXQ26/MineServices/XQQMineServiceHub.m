//
//  XQQMineServiceHub.m
//  AQXQ26
//

#import "XQQMineServices.h"
#import "XQQMineLocalService.h"

NSString *kUserInfoUpdated = @"kUserInfoUpdated";
NSString *kGroupInfoUpdated = @"kGroupInfoUpdated";
NSString *kFriendListUpdated = @"kFriendListUpdated";
NSNotificationName const XQQMineDidSignOutNotification = @"XQQMineDidSignOutNotification";
NSNotificationName const XQQMineDidClearMessagesNotification = @"XQQMineDidClearMessagesNotification";

static id<XQQMineProfileService> sProfile;
static id<XQQMineNotifyService> sNotify;
static id<XQQMineAccountService> sAccount;
static id<XQQMineRelationService> sRelation;
static id<XQQMineExtraService> sExtra;
static id<XQQMineAPIService> sAPI;
static id<XQQMineLoginService> sLogin;

@implementation XQQMineServiceHub

+ (void)registerDefaultServices {
    XQQMineLocalService *local = XQQMineLocalService.shared;
    if (!sProfile) sProfile = local;
    if (!sNotify) sNotify = local;
    if (!sAccount) sAccount = local;
    if (!sRelation) sRelation = local;
    if (!sExtra) sExtra = local;
    if (!sAPI) sAPI = local;
}

// 未注册时兜底到本地实现，避免页面拿到 nil 静默失效
+ (id<XQQMineProfileService>)profile { if (!sProfile) [self registerDefaultServices]; return sProfile; }
+ (id<XQQMineNotifyService>)notify { if (!sNotify) [self registerDefaultServices]; return sNotify; }
+ (id<XQQMineAccountService>)account { if (!sAccount) [self registerDefaultServices]; return sAccount; }
+ (id<XQQMineRelationService>)relation { if (!sRelation) [self registerDefaultServices]; return sRelation; }
+ (id<XQQMineExtraService>)extra { if (!sExtra) [self registerDefaultServices]; return sExtra; }
+ (id<XQQMineAPIService>)api { if (!sAPI) [self registerDefaultServices]; return sAPI; }
/// 登录没有本地假实现，未注册时为 nil（页面调用会无响应），启动时必须注册远端实现
+ (id<XQQMineLoginService>)login { return sLogin; }
+ (void)setLogin:(id<XQQMineLoginService>)login { sLogin = login; }

+ (void)setProfile:(id<XQQMineProfileService>)profile { sProfile = profile; }
+ (void)setNotify:(id<XQQMineNotifyService>)notify { sNotify = notify; }
+ (void)setAccount:(id<XQQMineAccountService>)account { sAccount = account; }
+ (void)setRelation:(id<XQQMineRelationService>)relation { sRelation = relation; }
+ (void)setExtra:(id<XQQMineExtraService>)extra { sExtra = extra; }
+ (void)setApi:(id<XQQMineAPIService>)api { sAPI = api; }

@end
