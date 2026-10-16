//
//  XQQGNRJYDIOZForgetPswdSetupVC.h
//  WUHOIBDK
//
//  Created by Ruby on 2/2/24.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface XQQGNRJYDIOZForgetPswdSetupVC : XQQWJEFDOCYMainVC

@property (nonatomic, assign) NSInteger type; // 0 手机号找回   1 邮箱找回
@property (nonatomic, strong) NSString *account;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *area;

@end

NS_ASSUME_NONNULL_END

