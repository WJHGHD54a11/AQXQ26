//
//  XQQMineRemoteService.m
//  AQXQ26
//
//  每个方法对应原 XQQAppService 的同名接口（路径和参数保持一致）。
//

#import "XQQMineRemoteService.h"
#import "XQQMineHTTPClient.h"
#import "XQQMineLocalService.h"
#import "XQQCUserInfo.h"
#import "XQQCGroupInfo.h"
#import "XQQCSign.h"
#import "XQQCSignTasks.h"
#import "XQQCPointsHistory.h"
#import "XQQODJNLockStatusManager.h"
#import "MJExtension.h"

#define XQQ_HTTP XQQMineHTTPClient.shared

/// 原工程登录参数里的 platform（XQQNetworkService.h: Platform_iOS = 2）
static int const kPlatformiOS = 2;

@implementation XQQMineRemoteService

+ (instancetype)shared {
    static XQQMineRemoteService *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [[self alloc] init]; });
    return s;
}

+ (void)install {
    XQQMineRemoteService *remote = self.shared;
    XQQMineServiceHub.login = remote;
    XQQMineServiceHub.profile = remote;
    XQQMineServiceHub.account = remote;
    XQQMineServiceHub.relation = remote;
    XQQMineServiceHub.extra = remote;
    XQQMineServiceHub.api = remote;
    XQQMineServiceHub.notify = XQQMineLocalService.shared; // IM 用户设置，等 IM 迁移后再接
}

- (XQQMineLocalService *)local { return XQQMineLocalService.shared; }

/// 只关心成功与否的接口
- (void)post:(NSString *)path params:(id)params success:(void (^)(void))success error:(void (^)(int, NSString *))error {
    [XQQ_HTTP post:path params:params saveAuth:NO success:^(NSDictionary *d) { if (success) success(); }
           failure:^(int c, NSString *m) { if (error) error(c, m); }];
}

- (NSDictionary *)deviceParams {
    return @{@"clientId": XQQ_HTTP.deviceId, @"platform": @(kPlatformiOS), @"deviceUId": XQQ_HTTP.deviceId,
             @"deviceType": UIDevice.currentDevice.name ?: @"iPhone"};
}

#pragma mark - Login

/// 与原工程 respone: 相同：记录 userId / hasPassword / 设备锁状态
- (void)handleLogin:(NSDictionary *)dict done:(void (^)(NSString *, NSString *, NSString *, BOOL, NSString *))done {
    NSDictionary *r = [dict[@"result"] isKindOfClass:NSDictionary.class] ? dict[@"result"] : @{};
    NSString *userId = [r[@"userCode"] description];
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ud setInteger:[r[@"hasPassword"] integerValue] forKey:@"kHasPassword"];
    if (userId.length) [ud setObject:userId forKey:@"savedUserId"];
    [XQQODJNLockStatusManager.main reWriteLockInfo:@([r[@"deviceLockStatus"] integerValue]) ForKey:@"status"];
    done(userId ?: @"", [r[@"accessToken"] description] ?: @"", [r[@"websocketToken"] description] ?: @"",
         [r[@"register"] boolValue], [r[@"resetCode"] isKindOfClass:NSString.class] ? r[@"resetCode"] : @"");
}

- (void)login:(NSString *)path params:(NSDictionary *)params success:(void (^)(NSString *, NSString *, NSString *, BOOL, NSString *))success error:(void (^)(int, NSString *))error {
    NSMutableDictionary *all = [params mutableCopy];
    [all addEntriesFromDictionary:self.deviceParams];
    [XQQ_HTTP post:path params:all saveAuth:YES success:^(NSDictionary *d) { [self handleLogin:d done:success]; }
           failure:^(int c, NSString *m) { if (error) error(c, m); }];
}

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void (^)(NSString *, NSString *, NSString *, BOOL, NSString *))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self login:@"/login" params:@{@"mobile": mobile ?: @"", @"code": verifyCode ?: @"", @"area": area ?: @""} success:successBlock error:errorBlock];
}

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void (^)(NSString *, NSString *, NSString *, BOOL))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self login:@"/loginPass" params:@{@"mobile": mobile ?: @"", @"password": password ?: @"", @"area": area ?: @""}
        success:^(NSString *u, NSString *t, NSString *w, BOOL n, NSString *r) { if (successBlock) successBlock(u, t, w, n); } error:errorBlock];
}

- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void (^)(NSString *, NSString *, NSString *, BOOL, NSString *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSDictionary *p = type == 0 ? @{@"email": email ?: @"", @"password": pswCode ?: @""} : @{@"email": email ?: @"", @"code": pswCode ?: @""};
    [self login:type == 0 ? @"/loginPassWithEmail" : @"/loginWithEmail" params:p success:successBlock error:errorBlock];
}

- (void)sendRegisterMobileCode:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/sendRegisterMobileCode" params:param success:s error:e]; }
- (void)sendRegisterEmailCode:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e  { [self post:@"/sendRegisterEmailCode" params:param success:s error:e]; }
- (void)sendLoginMobileCode:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e    { [self post:@"/sendLoginMobileCode" params:param success:s error:e]; }
- (void)sendLoginEmailCode:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e     { [self post:@"/sendLoginEmailCode" params:param success:s error:e]; }
- (void)setForgetPsw:(NSDictionary *)params success:(void (^)(void))s error:(void (^)(int, NSString *))e          { [self post:@"/forgot" params:params success:s error:e]; }

- (void)sendResetCode:(NSString *)phoneNumber success:(void (^)(void))s error:(void (^)(NSString *))e {
    [self post:@"/send_reset_code" params:phoneNumber.length ? @{@"mobile": phoneNumber} : @{} success:s error:^(int c, NSString *m) { if (e) e(m); }];
}

- (void)sendForgetCode:(NSString *)mobile success:(void (^)(void))s error:(void (^)(NSString *))e {
    [self post:@"/send_forgot_password_code" params:mobile.length ? @{@"mobile": mobile} : @{} success:s error:^(int c, NSString *m) { if (e) e(m); }];
}

#pragma mark - Profile

/// 服务端返回 userExtra 字典，本地按原工程约定转成 JSON 字符串存进 extra
- (XQQCUserInfo *)userFrom:(id)dic {
    if (![dic isKindOfClass:NSDictionary.class]) return nil;
    XQQCUserInfo *user = [XQQCUserInfo mj_objectWithKeyValues:dic];
    if ([dic[@"userExtra"] isKindOfClass:NSDictionary.class]) user.extra = [dic[@"userExtra"] mj_JSONString];
    return user;
}

- (void)cacheAndBroadcast:(XQQCUserInfo *)user {
    if (!user.userId.length) return;
    [self.local insertOrUpdateUserInfo:user];
    [NSNotificationCenter.defaultCenter postNotificationName:kUserInfoUpdated object:nil userInfo:@{@"userInfoList": @[user]}];
}

- (XQQCUserInfo *)getMyInfo { return [self.local getMyInfo]; }
- (void)saveMyInfo:(XQQCUserInfo *)user { [self.local saveMyInfo:user]; }
- (XQQCUserInfo *)getUserInfo:(NSString *)userId { return [self.local getUserInfo:userId]; }
- (void)insertOrUpdateUserInfo:(XQQCUserInfo *)userInfo { [self.local insertOrUpdateUserInfo:userInfo]; }

- (void)fetchUser:(NSString *)path userId:(NSString *)userId success:(void (^)(XQQCUserInfo *))success error:(void (^)(int, NSString *))error {
    [XQQ_HTTP post:path params:@{@"id": userId ?: @""} saveAuth:NO success:^(NSDictionary *d) {
        XQQCUserInfo *user = [self userFrom:d[@"result"]];
        if (!user) { if (error) error(-1, @"error"); return; }
        [self.local insertOrUpdateUserInfo:user];
        if (success) success(user);
    } failure:^(int c, NSString *m) { if (error) error(c, m); }];
}

- (void)getUserInfo:(NSString *)userId success:(void (^)(XQQCUserInfo *))s error:(void (^)(int, NSString *))e { [self fetchUser:@"/user/info" userId:userId success:s error:e]; }
- (void)getUserSelf:(NSString *)userId success:(void (^)(XQQCUserInfo *))s error:(void (^)(int, NSString *))e { [self fetchUser:@"/user/self" userId:userId success:s error:e]; }
- (void)getUserInfo:(NSString *)userId refresh:(BOOL)refresh success:(void (^)(XQQCUserInfo *))s error:(void (^)(int, NSString *))e {
    XQQCUserInfo *cached = refresh ? nil : [self.local getUserInfo:userId];
    if (cached) { if (s) s(cached); return; }
    [self fetchUser:@"/user/info" userId:userId success:s error:e];
}

/// 资料修改成功后重新拉一次自己，保证本地缓存和服务器一致
- (void)refreshMeThen:(void (^)(void))done {
    NSString *uid = self.local.currentUserId;
    [self fetchUser:@"/user/self" userId:uid success:^(XQQCUserInfo *u) { [self cacheAndBroadcast:u]; if (done) done(); }
              error:^(int c, NSString *m) { if (done) done(); }];
}

- (void)userUpdate:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e {
    [self post:@"/user/update" params:param success:^{ [self refreshMeThen:s]; } error:e];
}
- (void)userExtra:(NSDictionary *)param success:(void (^)(void))s error:(void (^)(int, NSString *))e {
    [self post:@"/user/extra" params:param success:^{ [self refreshMeThen:s]; } error:e];
}
- (void)changeName:(NSString *)newName success:(void (^)(void))s error:(void (^)(int, NSString *))e {
    [self post:@"/change_name" params:@{@"newName": newName ?: @""} success:^{ [self refreshMeThen:s]; } error:e];
}

/// 原工程走 IM 修改资料；这里改为对应的 HTTP 字段（IM 迁移后可切回）
- (void)modifyMyInfo:(NSDictionary<NSNumber *,NSString *> *)values success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    NSMutableDictionary *update = NSMutableDictionary.new, *extra = NSMutableDictionary.new;
    [values enumerateKeysAndObjectsUsingBlock:^(NSNumber *type, NSString *value, BOOL *stop) {
        switch (type.integerValue) {
            case Modify_DisplayName: update[@"displayName"] = value; break;
            case Modify_Portrait:    update[@"portrait"] = value; break;
            case Modify_Gender:      update[@"gender"] = @(value.intValue); break;
            case Modify_Mobile:      update[@"mobile"] = value; break;
            case Modify_Email:       update[@"email"] = value; break;
            case Modify_Address:     update[@"address"] = value; break;
            case Modify_Company:     update[@"company"] = value; break;
            case Modify_Social:      update[@"social"] = value; break;
            case Modify_Sign:        extra[@"sign"] = value; break;
            default: break;
        }
    }];
    void (^fail)(int, NSString *) = ^(int c, NSString *m) { if (errorBlock) errorBlock(c); };
    void (^afterUpdate)(void) = ^{
        if (extra.count) [self userExtra:extra success:successBlock error:fail];
        else if (successBlock) successBlock();
    };
    if (update.count) [self userUpdate:update success:afterUpdate error:fail];
    else afterUpdate();
}

- (void)generateUploadFile:(NSString *)fileName success:(void (^)(NSString *, NSString *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP post:@"/generateUploadFile/json" params:@{@"fileName": fileName ?: @"file"} saveAuth:NO success:^(NSDictionary *d) {
        NSDictionary *r = [d[@"result"] isKindOfClass:NSDictionary.class] ? d[@"result"] : @{};
        if (s) s(r[@"uploadUrl"], r[@"requestUrl"]);
    } failure:^(int c, NSString *m) { if (e) e(c, m); }];
}

- (void)uploadData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void (^)(NSString *))s progress:(void (^)(long, long))p fail:(void (^)(int))f {
    [XQQ_HTTP putData:data toURL:url progress:p completion:^(BOOL ok) {
        if (ok) { if (s) s(remoteUrl); } else if (f) f(-1);
    }];
}

/// 预签名上传：先申请地址，再 PUT
- (void)uploadMedia:(NSString *)fileName mediaData:(NSData *)mediaData mediaType:(WFCCMediaType)mediaType success:(void (^)(NSString *))s progress:(void (^)(long, long))p error:(void (^)(int))e {
    NSString *name = fileName.length ? fileName : [NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"jpg"];
    [self generateUploadFile:name success:^(NSString *uploadUrl, NSString *requestUrl) {
        [self uploadData:mediaData url:uploadUrl remoteUrl:requestUrl success:s progress:p fail:e];
    } error:^(int c, NSString *m) { if (e) e(c); }];
}

- (void)uploadFile:(NSString *)fileName data:(NSData *)data mimeType:(NSString *)mimeType success:(void (^)(NSString *))s progress:(void (^)(long, long))p fail:(void (^)(int, NSString *))f {
    [self uploadMedia:fileName mediaData:data mediaType:Media_Type_FILE success:s progress:p error:^(int c) { if (f) f(c, @"上传失败"); }];
}

#pragma mark - Account

- (void)sendLoginCode:(NSDictionary *)params success:(void (^)(void))s error:(void (^)(NSString *))e {
    [self post:@"/sendMobileCode" params:params success:s error:^(int c, NSString *m) { if (e) e(m); }];
}
- (void)sendMobileCodeWithScene:(NSDictionary *)p success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/sendMobileCodeWithScene" params:p success:s error:e]; }
- (void)sendEmailCodeWithScene:(NSDictionary *)p success:(void (^)(void))s error:(void (^)(int, NSString *))e  { [self post:@"/sendEmailCodeWithScene" params:p success:s error:e]; }
- (void)userbindEmail:(NSDictionary *)p success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/user/bind/email" params:p success:^{ [self refreshMeThen:s]; } error:e]; }
- (void)userbindPhone:(NSDictionary *)p success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/user/bind/phone" params:p success:^{ [self refreshMeThen:s]; } error:e]; }
- (void)sendDestroyAccountCode:(NSDictionary *)d success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/send_destroy_code" params:d success:s error:e]; }
- (void)destroyAccount:(NSDictionary *)d success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/destroy" params:d success:s error:e]; }

- (void)clearAppServiceAuthInfos {
    [XQQ_HTTP clearAuth];
    [self.local clearAppServiceAuthInfos];
}
- (NSString *)getClientId { return XQQ_HTTP.deviceId; }
/// 没有 IM 连接可断；只广播退出，宿主据此回到登录页
- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession { [self.local disconnect:disablePush clearSession:clearSession]; }

#pragma mark - Relation

- (void)friendBlackList:(void (^)(NSArray<XQQCUserInfo *> *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP post:@"/friend/black/list" params:nil saveAuth:NO success:^(NSDictionary *d) {
        NSMutableArray *users = NSMutableArray.new;
        for (id row in [d[@"result"] isKindOfClass:NSArray.class] ? d[@"result"] : @[]) {
            XQQCUserInfo *u = [self userFrom:row];
            if (u) [users addObject:u];
        }
        if (s) s(users);
    } failure:^(int c, NSString *m) { if (e) e(c, m); }];
}
- (void)friendBlackCancel:(NSString *)userId success:(void (^)(void))s error:(void (^)(int, NSString *))e {
    [self post:@"/friend/black/cancel" params:@{@"id": userId ?: @""} success:s error:e];
}
- (void)friendAliasUpdate:(NSString *)userId alias:(NSString *)alias success:(void (^)(void))s error:(void (^)(int, NSString *))e {
    [self post:@"/friend/alias/update" params:@{@"userId": userId ?: @"", @"alias": alias ?: @""} success:s error:e];
}
- (void)groupUpdate:(NSDictionary *)params success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/group/update" params:params success:s error:e]; }
- (void)groupMemberAlias:(NSDictionary *)params success:(void (^)(void))s error:(void (^)(int, NSString *))e { [self post:@"/group/member/alias" params:params success:s error:e]; }
// 群资料、会话仍是本地数据（群聊 / 消息模块未迁移）
- (XQQCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId { return [self.local getGroupInfoFromDB:groupId]; }
- (void)insertOrUpdateGroupInfo:(XQQCGroupInfo *)groupInfo { [self.local insertOrUpdateGroupInfo:groupInfo]; }
- (void)clearAllConversations { [self.local clearAllConversations]; }
- (void)clearAllMessages:(BOOL)removeConversation { [self.local clearAllMessages:removeConversation]; }

#pragma mark - Extra

- (void)signTasks:(void (^)(XQQCSignTasks *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP get:@"/sign/tasks" params:nil success:^(NSDictionary *d) { if (s) s([XQQCSignTasks mj_objectWithKeyValues:d[@"result"]]); }
          failure:^(int c, NSString *m) { if (e) e(c, m); }];
}
- (void)signSubmit:(NSDictionary *)param success:(void (^)(XQQCSign *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP post:@"/sign/submit" params:param saveAuth:NO success:^(NSDictionary *d) { if (s) s([XQQCSign mj_objectWithKeyValues:d[@"result"]]); }
           failure:^(int c, NSString *m) { if (e) e(c, m); }];
}
- (void)pointsHistory:(NSDictionary *)param success:(void (^)(XQQCPointsHistory *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP get:@"/points/history" params:param success:^(NSDictionary *d) { if (s) s([XQQCPointsHistory mj_objectWithKeyValues:d[@"result"]]); }
          failure:^(int c, NSString *m) { if (e) e(c, m); }];
}

#pragma mark - API

- (void)requestUrl:(NSString *)url params:(id)params success:(void (^)(NSDictionary *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP post:url params:params saveAuth:YES success:^(NSDictionary *d) { if (s) s(d); } failure:^(int c, NSString *m) { if (e) e(c, m); }];
}
- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void (^)(NSDictionary *))s error:(void (^)(int, NSString *))e {
    [XQQ_HTTP post:url params:params saveAuth:NO success:^(NSDictionary *d) { if (s) s(d); } failure:^(int c, NSString *m) { if (e) e(c, m); }];
}
- (void)uploadFile:(NSString *)url images:(NSArray<UIImage *> *)images progress:(void (^)(int, int))p success:(void (^)(NSString *))s error:(void (^)(NSString *))e {
    NSData *jpeg = UIImageJPEGRepresentation(images.firstObject, 0.8);
    if (!jpeg) { if (e) e(@"图片无效"); return; }
    [XQQ_HTTP uploadImage:jpeg path:url success:^(NSString *u) { if (p) p(1, 1); if (s) s(u); } failure:^(int c, NSString *m) { if (e) e(m); }];
}

@end
