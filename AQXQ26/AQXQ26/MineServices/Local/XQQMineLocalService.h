//
//  XQQMineLocalService.h
//  AQXQ26
//
//  第 1 步的本地实现：所有数据存在 UserDefaults，供「我的」页面完整操作。
//  按领域拆成多个 category，接入真实服务时可逐个领域替换。
//

#import <Foundation/Foundation.h>
#import "XQQMineServices.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQMineLocalService : NSObject

+ (instancetype)shared;

/// 演示账号登录：写入 savedUserId/savedToken 并生成演示资料（已存在则沿用）
- (void)signInDemoUser;
- (BOOL)isSignedIn;

#pragma mark - 存储（供各 category 使用）
- (nullable id)objectForKey:(NSString *)key;
- (void)setObject:(nullable id)obj forKey:(NSString *)key;
- (NSString *)currentUserId;
/// 模拟网络耗时后回到主线程
- (void)after:(dispatch_block_t)block;

@end

// 各领域实现分别在对应 category 中，替换真实服务时可逐个领域换掉
@interface XQQMineLocalService (Profile) <XQQMineProfileService>
@end
@interface XQQMineLocalService (Notify) <XQQMineNotifyService>
@end
@interface XQQMineLocalService (Account) <XQQMineAccountService>
@end
@interface XQQMineLocalService (Relation) <XQQMineRelationService>
@end
@interface XQQMineLocalService (Extra) <XQQMineExtraService>
@end
@interface XQQMineLocalService (API) <XQQMineAPIService>
@end

NS_ASSUME_NONNULL_END
