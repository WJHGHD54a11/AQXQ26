//
//  XQQMineLocalService+Profile.m
//  AQXQ26
//
//  资料 / 头像 / 上传的本地实现
//

#import "XQQMineLocalService+Private.h"
#import "XQQCUserInfo.h"
#import "MJExtension.h"

@implementation XQQMineLocalService (Profile)

#pragma mark - 读写用户

- (NSString *)xqq_userKey:(NSString *)userId {
    return [@"user." stringByAppendingString:userId ?: @""];
}

- (XQQCUserInfo *)getUserInfo:(NSString *)userId {
    if (userId.length == 0) return nil;
    NSDictionary *dict = [self objectForKey:[self xqq_userKey:userId]];
    return dict ? [XQQCUserInfo mj_objectWithKeyValues:dict] : nil;
}

- (void)insertOrUpdateUserInfo:(XQQCUserInfo *)userInfo {
    if (userInfo.userId.length == 0) return;
    [self setObject:[userInfo mj_keyValues] forKey:[self xqq_userKey:userInfo.userId]];
}

- (XQQCUserInfo *)getMyInfo {
    return [self getUserInfo:self.currentUserId];
}

- (void)saveMyInfo:(XQQCUserInfo *)user {
    [self insertOrUpdateUserInfo:user];
}

/// 修改当前用户并广播，与原工程收到 IM 推送后的行为一致
- (void)xqq_updateMe:(void(^)(XQQCUserInfo *me))change {
    XQQCUserInfo *me = [self getMyInfo];
    if (!me) return;
    change(me);
    me.updateDt = (long long)(NSDate.date.timeIntervalSince1970 * 1000);
    [self insertOrUpdateUserInfo:me];
    [NSNotificationCenter.defaultCenter postNotificationName:kUserInfoUpdated object:nil userInfo:@{@"userInfoList": @[me]}];
}

- (void)xqq_mergeExtra:(NSDictionary *)values into:(XQQCUserInfo *)me {
    NSMutableDictionary *extra = [NSMutableDictionary dictionaryWithDictionary:[me.extra mj_JSONObject] ?: @{}];
    [extra addEntriesFromDictionary:values];
    me.extra = [extra mj_JSONString];
}

#pragma mark - 远端用户信息（本地直接返回）

- (void)getUserInfo:(NSString *)userId refresh:(BOOL)refresh success:(void (^)(XQQCUserInfo *))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self getUserInfo:userId success:successBlock error:errorBlock];
}

- (void)getUserInfo:(NSString *)userId success:(void (^)(XQQCUserInfo *))successBlock error:(void (^)(int, NSString *))errorBlock {
    XQQCUserInfo *user = [self getUserInfo:userId];
    [self after:^{
        if (user) {
            if (successBlock) successBlock(user);
        } else if (errorBlock) {
            errorBlock(-1, @"用户不存在");
        }
    }];
}

- (void)getUserSelf:(NSString *)userId success:(void (^)(XQQCUserInfo *))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self getUserInfo:userId success:successBlock error:errorBlock];
}

#pragma mark - 修改资料

- (void)userUpdate:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_updateMe:^(XQQCUserInfo *me) {
        // 只接受模型上存在的字段，其余忽略
        NSDictionary *props = [XQQCUserInfo.new mj_keyValues];
        [param enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if ([key isKindOfClass:NSString.class] && (props[key] || [me respondsToSelector:NSSelectorFromString(key)])) {
                [me setValue:obj forKey:key];
            }
        }];
    }];
    if ([param[@"portrait"] length]) [self xqq_recordAvatar:param[@"portrait"]];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)userExtra:(NSDictionary *)param success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_updateMe:^(XQQCUserInfo *me) { [self xqq_mergeExtra:param into:me]; }];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)changeName:(NSString *)newName success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self xqq_updateMe:^(XQQCUserInfo *me) { me.name = newName; }];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)modifyMyInfo:(NSDictionary<NSNumber *,NSString *> *)values success:(void (^)(void))successBlock error:(void (^)(int))errorBlock {
    [self xqq_updateMe:^(XQQCUserInfo *me) {
        [values enumerateKeysAndObjectsUsingBlock:^(NSNumber *type, NSString *value, BOOL *stop) {
            switch (type.integerValue) {
                case Modify_DisplayName: me.displayName = value; break;
                case Modify_Portrait:    me.portrait = value; break;
                case Modify_Gender:      me.gender = value.intValue; break;
                case Modify_Mobile:      me.mobile = value; break;
                case Modify_Email:       me.email = value; break;
                case Modify_Address:     me.address = value; break;
                case Modify_Company:     me.company = value; break;
                case Modify_Social:      me.social = value; break;
                case Modify_Extra:       me.extra = value; break;
                case Modify_Sign:        [self xqq_mergeExtra:@{@"sign": value ?: @""} into:me]; break;
                default: break;
            }
        }];
    }];
    [self after:^{ if (successBlock) successBlock(); }];
}

#pragma mark - 上传（写到本地 Caches，返回 file:// 地址）

- (NSString *)xqq_saveLocalFile:(NSData *)data name:(NSString *)fileName {
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"XQQMineUploads"];
    [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *ext = fileName.pathExtension.length ? fileName.pathExtension : @"jpg";
    NSString *path = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", NSUUID.UUID.UUIDString, ext]];
    [data writeToFile:path atomically:YES];
    return [NSURL fileURLWithPath:path].absoluteString;
}

- (void)uploadMedia:(NSString *)fileName mediaData:(NSData *)mediaData mediaType:(WFCCMediaType)mediaType success:(void (^)(NSString *))successBlock progress:(void (^)(long, long))progressBlock error:(void (^)(int))errorBlock {
    NSString *url = [self xqq_saveLocalFile:mediaData name:fileName];
    [self after:^{
        if (progressBlock) progressBlock((long)mediaData.length, (long)mediaData.length);
        if (successBlock) successBlock(url);
    }];
}

- (void)generateUploadFile:(NSString *)fileName success:(void (^)(NSString *, NSString *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSString *token = NSUUID.UUID.UUIDString;
    [self after:^{ if (successBlock) successBlock(token, token); }];
}

- (void)uploadData:(NSData *)data url:(NSString *)url remoteUrl:(NSString *)remoteUrl success:(void (^)(NSString *))successBlock progress:(void (^)(long, long))progressBlock fail:(void (^)(int))errorBlock {
    NSString *fileUrl = [self xqq_saveLocalFile:data name:@"upload.jpg"];
    [self after:^{
        if (progressBlock) progressBlock((long)data.length, (long)data.length);
        if (successBlock) successBlock(fileUrl);
    }];
}

- (void)uploadFile:(NSString *)fileName data:(NSData *)data mimeType:(NSString *)mimeType success:(void (^)(NSString *))successBlock progress:(void (^)(long, long))progressBlock fail:(void (^)(int, NSString *))errorBlock {
    NSString *fileUrl = [self xqq_saveLocalFile:data name:fileName];
    [self after:^{ if (successBlock) successBlock(fileUrl); }];
}

@end
