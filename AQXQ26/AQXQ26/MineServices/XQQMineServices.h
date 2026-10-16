//
//  XQQMineServices.h
//  AQXQ26
//
//  「我的」模块的服务边界。页面只依赖这里的协议，不直接依赖 IM SDK / AppService。
//
//  分步迁移：
//    第 1 步  XQQMineLocalService      本地 UserDefaults 假数据（当前）
//    第 2 步  HTTP 实现                 搬入 AppService/AppCache/登录后，写 adapter 转发
//    第 3 步  IM 实现                   搬入 XQQChatClient 后，写 adapter 转发
//  各协议方法签名与原工程对应方法一致，adapter 只需原样转发。
//

#import <UIKit/UIKit.h>
#import "XQQMineServiceTypes.h"

@class XQQCUserInfo, XQQCGroupInfo, XQQCSign, XQQCSignTasks, XQQCPointsHistory;

NS_ASSUME_NONNULL_BEGIN

/// 退出登录 / 注销 / 断开连接后发出，宿主据此切回登录界面
FOUNDATION_EXPORT NSNotificationName const XQQMineDidSignOutNotification;
/// 清空聊天记录后发出，聊天模块迁入后据此刷新
FOUNDATION_EXPORT NSNotificationName const XQQMineDidClearMessagesNotification;

#pragma mark - 资料 / 头像 / 文件上传

/// 对应原 XQQAppCache、XQQUserDB、XQQUserService、XQQIMService(资料部分)、XQQAppService(用户部分)
@protocol XQQMineProfileService <NSObject>
// 当前登录用户（原 XQQAppCache）
- (nullable XQQCUserInfo *)getMyInfo;
- (void)saveMyInfo:(XQQCUserInfo *)user;
// 本地用户库（原 XQQUserDB）
- (nullable XQQCUserInfo *)getUserInfo:(NSString *)userId;
- (void)insertOrUpdateUserInfo:(XQQCUserInfo *)userInfo;
// 远端用户信息（原 XQQUserService / XQQAppService）
- (void)getUserInfo:(NSString *)userId refresh:(BOOL)refresh success:(void(^)(XQQCUserInfo *userInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
- (void)getUserInfo:(NSString *)userId success:(void(^)(XQQCUserInfo *userInfo))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)getUserSelf:(NSString *)userId success:(void(^)(XQQCUserInfo *userInfo))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)userUpdate:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)userExtra:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
// IM 资料（原 XQQIMService）
- (void)modifyMyInfo:(NSDictionary<NSNumber *, NSString *> *)values success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (void)uploadMedia:(NSString *)fileName mediaData:(NSData *)mediaData mediaType:(WFCCMediaType)mediaType success:(void(^)(NSString *remoteUrl))successBlock progress:(void(^)(long uploaded, long total))progressBlock error:(void(^)(int error_code))errorBlock;
// 文件上传（原 XQQAppService / XQQSRIMService）
- (void)generateUploadFile:(NSString *)fileName success:(void(^)(NSString *uploadUrl, NSString *requestUrl))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)uploadData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void(^)(NSString *remoteUrl))successBlock progress:(void(^)(long uploaded, long total))progressBlock fail:(void(^)(int error_code))errorBlock;
- (void)uploadFile:(NSString *)fileName data:(NSData *)data mimeType:(NSString *)mimeType success:(void(^)(NSString *remoteUrl))successBlock progress:(void(^)(long uploaded, long total))progressBlock fail:(void(^)(int error_code, NSString *message))errorBlock;
@end

#pragma mark - 通知设置

/// 对应原 XQQIMService 的用户设置部分
@protocol XQQMineNotifyService <NSObject>
- (BOOL)isGlobalSilent;
- (void)setGlobalSilent:(BOOL)silent success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (BOOL)isVoipNotificationSilent;
- (void)setVoipNotificationSilent:(BOOL)silent success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (BOOL)isEnableSyncDraft;
- (void)setEnableSyncDraft:(BOOL)enable success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (BOOL)isHiddenNotificationDetail;
- (void)setHiddenNotificationDetail:(BOOL)hidden success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (void)getNoDisturbingTimes:(void(^)(int startMins, int endMins))resultBlock error:(void(^)(int error_code))errorBlock;
- (void)setNoDisturbingTimes:(int)startMins endMins:(int)endMins success:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (void)clearNoDisturbingTimes:(void(^)(void))successBlock error:(void(^)(int error_code))errorBlock;
- (BOOL)isUserEnableReceipt;
@end

#pragma mark - 账号与安全

/// 对应原 XQQAppService 的验证码/鉴权、XQQSRIMNetworkService/XQQNetworkService 的连接管理
@protocol XQQMineAccountService <NSObject>
- (void)sendLoginCode:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendMobileCodeWithScene:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)clearAppServiceAuthInfos;
- (NSString *)getClientId;
/// 退出登录/注销时断开 IM 连接，本地实现只清会话
- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession;
- (void)sendEmailCodeWithScene:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)userbindEmail:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)userbindPhone:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
- (void)destroyAccount:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
@end

#pragma mark - 通用 HTTP（原 XQQAppService.requestUrl 系列）

/// 页面里直接按路径调用的接口：设备记录、设备锁、改密码、历史头像、投诉、注销等。
/// 本地实现按 path 路由到假数据；接 HTTP 时整体转发给 AppService 即可。
@protocol XQQMineAPIService <NSObject>
- (void)requestUrl:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)uploadFile:(NSString *)url images:(NSArray<UIImage *> *)images progress:(void(^)(int sentcount, int total))progressBlock success:(void(^)(NSString *url))successBlock error:(void(^)(NSString *errorMsg))errorBlock;
@end

#pragma mark - 好友关系 / 群资料 / 会话

/// 对应原 XQQAppService 的好友/群接口、XQQGroupDB、XQQIMService 的会话部分
@protocol XQQMineRelationService <NSObject>
- (void)friendBlackList:(void(^)(NSArray<XQQCUserInfo *> *friends))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)friendBlackCancel:(NSString *)userId success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)friendAliasUpdate:(NSString *)userId alias:(NSString *)alias success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)groupUpdate:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)groupMemberAlias:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (nullable XQQCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId;
- (void)insertOrUpdateGroupInfo:(XQQCGroupInfo *)groupInfo;
/// 清空全部聊天记录。原逻辑：遍历会话 → 删除定时任务 → 清未读 → 删除会话及消息
- (void)clearAllConversations;
/// 原 XQQIMService clearAllMessages:
- (void)clearAllMessages:(BOOL)removeConversation;
@end

#pragma mark - 签到 / 积分 / 反馈

@protocol XQQMineExtraService <NSObject>
- (void)signTasks:(void(^)(XQQCSignTasks *tasks))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)signSubmit:(NSDictionary *)param success:(void(^)(XQQCSign *sign))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)pointsHistory:(NSDictionary *)param success:(void(^)(XQQCPointsHistory *history))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
@end

#pragma mark - 登录 / 注册 / 找回密码（第 2 步新增，对应原 XQQAppService 登录部分）

@protocol XQQMineLoginService <NSObject>
- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void(^)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendRegisterMobileCode:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendRegisterEmailCode:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendLoginMobileCode:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendLoginEmailCode:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendForgetCode:(NSString *)mobile success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)setForgetPsw:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
@end

#pragma mark - 注册中心

/// 统一入口。启动时注册实现，后续换实现只改注册处。
@interface XQQMineServiceHub : NSObject
@property (class, nonatomic, strong) id<XQQMineProfileService> profile;
@property (class, nonatomic, strong) id<XQQMineNotifyService> notify;
@property (class, nonatomic, strong) id<XQQMineAccountService> account;
@property (class, nonatomic, strong) id<XQQMineRelationService> relation;
@property (class, nonatomic, strong) id<XQQMineExtraService> extra;
@property (class, nonatomic, strong) id<XQQMineAPIService> api;
@property (class, nonatomic, strong) id<XQQMineLoginService> login;
/// 未单独注册的服务，全部使用本地实现
+ (void)registerDefaultServices;
@end

#define XQQMineProfile   (XQQMineServiceHub.profile)
#define XQQMineNotify    (XQQMineServiceHub.notify)
#define XQQMineAccount   (XQQMineServiceHub.account)
#define XQQMineRelation  (XQQMineServiceHub.relation)
#define XQQMineExtra     (XQQMineServiceHub.extra)
#define XQQMineAPI       (XQQMineServiceHub.api)
#define XQQMineLogin     (XQQMineServiceHub.login)

NS_ASSUME_NONNULL_END
