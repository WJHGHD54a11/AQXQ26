//
//  XQQMineHTTPClient.h
//  AQXQ26
//
//  精简版 HTTP：只保留与账号服务的约定（地址前缀、x-device-id / x-auth-token / authToken 头、
//  code==0 为成功、401 视为登录失效）。不依赖 AFNetworking 和 IM SDK。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^XQQMineHTTPSuccess)(NSDictionary *dict);
typedef void (^XQQMineHTTPFailure)(int errCode, NSString *message);

@interface XQQMineHTTPClient : NSObject

+ (instancetype)shared;

/// 设备 ID：钥匙串里的 UUID，首次生成后不变（原工程的 clientId / deviceUId 都用它）
- (NSString *)deviceId;

/// POST JSON。saveAuth = YES 时记录响应头里的 authToken（登录接口）。回调都在主线程。
- (void)post:(NSString *)path params:(nullable id)params saveAuth:(BOOL)saveAuth success:(XQQMineHTTPSuccess)success failure:(XQQMineHTTPFailure)failure;
- (void)get:(NSString *)path params:(nullable NSDictionary *)params success:(XQQMineHTTPSuccess)success failure:(XQQMineHTTPFailure)failure;
/// multipart 上传单张图片，字段名 file，返回 result.url
- (void)uploadImage:(NSData *)jpeg path:(NSString *)path success:(void (^)(NSString *url))success failure:(XQQMineHTTPFailure)failure;
/// 预签名地址 PUT 上传
- (void)putData:(NSData *)data toURL:(NSString *)url progress:(nullable void (^)(long uploaded, long total))progress
     completion:(void (^)(BOOL ok))completion;

- (void)clearAuth;

@end

NS_ASSUME_NONNULL_END
