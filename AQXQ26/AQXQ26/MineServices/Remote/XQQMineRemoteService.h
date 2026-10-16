//
//  XQQMineRemoteService.h
//  AQXQ26
//
//  第 2 步：账号 / 资料 / 关系 / 签到 / 通用接口走真实 HTTP 服务。
//  IM 相关能力（通知设置、会话、IM 资料推送）尚未迁移，仍由本地实现承担。
//

#import <Foundation/Foundation.h>
#import "XQQMineServices.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQMineRemoteService : NSObject <XQQMineLoginService, XQQMineProfileService, XQQMineAccountService,
                                            XQQMineRelationService, XQQMineExtraService, XQQMineAPIService>
+ (instancetype)shared;
/// 注册到 XQQMineServiceHub（通知设置仍用本地实现）
+ (void)install;
@end

NS_ASSUME_NONNULL_END
