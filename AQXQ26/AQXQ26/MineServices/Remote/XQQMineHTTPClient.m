//
//  XQQMineHTTPClient.m
//  AQXQ26
//

#import "XQQMineHTTPClient.h"
#import "XQQMineServerConfig.h"
#import "XQQMineServices.h"
#import "KeyChainTool.h"

static NSString * const kAuthTokenDefaultsKey = @"WFC_APPSERVER_AUTH_TOKEN";   // 与原工程同名，老数据可直接沿用
static NSString * const kAuthHeader = @"authToken";

@interface XQQMineHTTPClient () <NSURLSessionTaskDelegate>
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, void (^)(long, long)> *progressHandlers;
@end

@implementation XQQMineHTTPClient

+ (instancetype)shared {
    static XQQMineHTTPClient *client;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ client = [[self alloc] init]; });
    return client;
}

- (instancetype)init {
    if ((self = [super init])) {
        NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
        config.timeoutIntervalForRequest = 30;
        config.connectionProxyDictionary = @{}; // 与原工程一致：不走系统代理
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        _progressHandlers = NSMutableDictionary.new;
    }
    return self;
}

- (NSString *)deviceId {
    NSString *uuid = [KeyChainTool readData:kUUIDStringValue];
    if (![uuid isKindOfClass:NSString.class] || uuid.length == 0) {
        uuid = NSUUID.UUID.UUIDString;
        [KeyChainTool saveData:uuid withIdentifier:kUUIDStringValue];
    }
    return uuid;
}

- (void)clearAuth {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:kAuthTokenDefaultsKey];
    for (NSHTTPCookie *c in [NSHTTPCookieStorage.sharedHTTPCookieStorage cookiesForURL:[NSURL URLWithString:XQQMineAppServerAddress]]) {
        [NSHTTPCookieStorage.sharedHTTPCookieStorage deleteCookie:c];
    }
}

- (NSMutableURLRequest *)requestFor:(NSString *)path method:(NSString *)method {
    NSURL *url = [NSURL URLWithString:[XQQMineAppServerAddress stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = method;
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.deviceId forHTTPHeaderField:@"x-device-id"];
    NSString *token = [NSUserDefaults.standardUserDefaults stringForKey:@"savedToken"];
    if (token.length) [request setValue:token forHTTPHeaderField:@"x-auth-token"];
    NSString *auth = [NSUserDefaults.standardUserDefaults stringForKey:kAuthTokenDefaultsKey];
    if (auth.length) [request setValue:auth forHTTPHeaderField:kAuthHeader];
    return request;
}

/// 统一解析：网络错误 / 非 JSON / code != 0 都走 failure；401 额外广播登录失效
- (void)run:(NSURLRequest *)request saveAuth:(BOOL)saveAuth success:(XQQMineHTTPSuccess)success failure:(XQQMineHTTPFailure)failure {
    [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *dict = nil;
        if (data.length) {
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json isKindOfClass:NSDictionary.class]) dict = json;
        }
        if (saveAuth && [response isKindOfClass:NSHTTPURLResponse.class]) {
            NSString *auth = ((NSHTTPURLResponse *)response).allHeaderFields[kAuthHeader];
            if (auth.length) [NSUserDefaults.standardUserDefaults setObject:auth forKey:kAuthTokenDefaultsKey];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!dict) {
                failure(-1, error.localizedDescription ?: @"网络异常，请稍后再试");
                return;
            }
            int code = [dict[@"code"] intValue];
            if (code == 0) { success(dict); return; }
            if (code == 401) {
                [NSNotificationCenter.defaultCenter postNotificationName:XQQMineDidSignOutNotification object:nil];
            }
            failure(code, [dict[@"message"] isKindOfClass:NSString.class] ? dict[@"message"] : @"error");
        });
    }] resume];
}

- (void)post:(NSString *)path params:(id)params saveAuth:(BOOL)saveAuth success:(XQQMineHTTPSuccess)success failure:(XQQMineHTTPFailure)failure {
    NSMutableURLRequest *request = [self requestFor:path method:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (params && [NSJSONSerialization isValidJSONObject:params]) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    }
    [self run:request saveAuth:saveAuth success:success failure:failure];
}

- (void)get:(NSString *)path params:(NSDictionary *)params success:(XQQMineHTTPSuccess)success failure:(XQQMineHTTPFailure)failure {
    NSURLComponents *c = [NSURLComponents componentsWithString:[XQQMineAppServerAddress stringByAppendingString:path]];
    NSMutableArray *items = NSMutableArray.new;
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *k, id v, BOOL *stop) {
        [items addObject:[NSURLQueryItem queryItemWithName:k value:[v description]]];
    }];
    if (items.count) c.queryItems = items;
    NSMutableURLRequest *request = [self requestFor:path method:@"GET"];
    request.URL = c.URL;
    [self run:request saveAuth:NO success:success failure:failure];
}

- (void)uploadImage:(NSData *)jpeg path:(NSString *)path success:(void (^)(NSString *))success failure:(XQQMineHTTPFailure)failure {
    NSString *boundary = [@"Boundary-" stringByAppendingString:NSUUID.UUID.UUIDString];
    NSMutableURLRequest *request = [self requestFor:path method:@"POST"];
    [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
    NSMutableData *body = NSMutableData.new;
    [body appendData:[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"file\"; filename=\"image.png\"\r\nContent-Type: image/jpeg\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:jpeg];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody = body;
    [self run:request saveAuth:NO success:^(NSDictionary *dict) {
        NSString *url = [dict[@"result"] isKindOfClass:NSDictionary.class] ? dict[@"result"][@"url"] : nil;
        if (url.length) success(url); else failure(-1, @"上传失败");
    } failure:failure];
}

- (void)putData:(NSData *)data toURL:(NSString *)url progress:(void (^)(long, long))progress completion:(void (^)(BOOL))completion {
    NSURL *target = [NSURL URLWithString:url];
    if (!target) { completion(NO); return; }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:target];
    request.HTTPMethod = @"PUT";
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionUploadTask *task = [self.session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        NSInteger status = [r isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)r).statusCode : 0;
        dispatch_async(dispatch_get_main_queue(), ^{ completion(!e && status >= 200 && status < 300); });
    }];
    if (progress) {
        @synchronized (self.progressHandlers) { self.progressHandlers[@(task.taskIdentifier)] = progress; }
    }
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    void (^handler)(long, long);
    @synchronized (self.progressHandlers) { handler = self.progressHandlers[@(task.taskIdentifier)]; }
    if (handler) dispatch_async(dispatch_get_main_queue(), ^{ handler((long)totalBytesSent, (long)totalBytesExpectedToSend); });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized (self.progressHandlers) { [self.progressHandlers removeObjectForKey:@(task.taskIdentifier)]; }
}

@end
