//
//  XQQMineSession.h
//  AQXQ26
//
//  登录 / 注册成功后的统一收尾，替代原工程里的 IM 连接、按用户切换消息库、跳转 TabBar。
//  IM 迁移后在 -finishLogin 里补上连接 IM 即可，登录页不用再改。
//

#import <Foundation/Foundation.h>

@class XQQCUserInfo;

NS_ASSUME_NONNULL_BEGIN

/// 登录完成（资料已缓存）后发出，宿主据此关闭登录页
FOUNDATION_EXPORT NSNotificationName const XQQMineDidSignInNotification;

@interface XQQMineSession : NSObject

+ (BOOL)isSignedIn;

/// 保存 token 等登录信息（原 handleLoginSuccess 前半段）
+ (void)saveUserId:(NSString *)userId token:(NSString *)token websocketToken:(nullable NSString *)websocketToken loginType:(NSInteger)loginType;

/// 缓存个人资料、拉取设备锁配置，然后广播 XQQMineDidSignInNotification
+ (void)finishLoginWithUser:(XQQCUserInfo *)user;

/// 清掉登录信息（退出 / 401）
+ (void)clear;

@end

NS_ASSUME_NONNULL_END
