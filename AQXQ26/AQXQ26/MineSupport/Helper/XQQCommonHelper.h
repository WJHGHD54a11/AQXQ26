//
//  XQQCommonHelper.h
//  QXQ
//
//  Created by Loooooo on 10/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ImagePikerBlock)(UIImage *image);

@interface XQQCommonHelper : NSObject

+ (instancetype)main;

- (BOOL)isChinese;

- (void)handleTimer:(UIButton*)sender;

- (void)updateAppSuccess:(void(^)(BOOL isUpdate))success;
@property (nonatomic, strong) NSString *iosVersion;
@property (nonatomic, strong) NSString *iosPath;


#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendArea:(NSString *)area phone:(NSString *)phone  button:(UIButton *)btn;
#endif
// 发送邮箱验证码
#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendEmailCode:(NSString *)email  button:(UIButton *)btn;
#endif
#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendEmailCodeForForget:(NSString *)email button:(UIButton *)btn;
#endif

#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendResetCode:(NSString *)phone button:(UIButton *)btn;
#endif

#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendForgetCode:(NSString *)phone button:(UIButton *)btn;
#endif
// 忘记密码用户发送验证码2  0108
#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendForgetCode:(NSString *)phone area:(NSString *)area button:(UIButton *)btn;
#endif



// 安全锁  忘记数字密码
- (void)send_reset_device_code_button:(UIButton *)btn type:(int)type;


- (void)loyout;

#pragma mark - -------- 手机通讯录 模块  ----------


@property (nonatomic, strong) NSMutableArray *allContacts;
- (void)getMyAddressBook;
- (BOOL)isAddressBookContact:(NSString *)targetPhone;



#pragma mark - -------- 公共方法 模块  ----------

- (NSString *)onlineStatusDesc:(long long)mobileLastSeen;


- (NSString *)contactOnlineStatusDesc:(long long)mobileLastSeen;

- (NSString *)customerPlatform:(NSString *)plt;

#pragma mark - -------- 通用 模块  ----------

- (NSString *)getAudioOrVideoPath;



@property (copy,nonatomic) ImagePikerBlock imagePikerCallBack;
/**
 *  打开相册或者相机
 */
- (void)showImagePikerWithimageBlock:(ImagePikerBlock)imageBlock;







#pragma mark - 安全锁相关接口



@end

NS_ASSUME_NONNULL_END
