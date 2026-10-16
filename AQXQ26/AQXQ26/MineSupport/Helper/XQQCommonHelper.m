//
//  XQQCommonHelper.m
//  QXQ
//
//  Created by Loooooo on 10/8/23.
//

#import "XQQCommonHelper.h"
#import "XQQMineServices.h"
#import <Contacts/Contacts.h>

#import "XQQODJNUpdatedVersionPopView.h"

@interface XQQCommonHelper ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@end

@implementation XQQCommonHelper

+ (instancetype)main {
    static dispatch_once_t once;
    static XQQCommonHelper *instance;
    dispatch_once(&once, ^{
        instance = [[XQQCommonHelper alloc] init];
    });
    return instance;
}
- (BOOL)isChinese {
    if (LANGUAGE == 0) { // 0 跟随系统   1 中文   2 英文
        return [self systemLanguage];
    }else if (LANGUAGE == 1) {
        return YES;
    }else {
        return NO;
    }
}
- (BOOL)systemLanguage {
    NSArray *languages = [NSUserDefaults.standardUserDefaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
//    [currentLang compare:@"zh-Hant" options:NSCaseInsensitiveSearch] == NSOrderedSame
    if ([currentLang containsString:@"zh-Hans"] || [currentLang containsString:@"zh-Hant"]) {
        return YES;
    }else {
        return NO;
    }
}
- (NSString*)currentLanguage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
    return currentLang;
}


// 登录模块专用的验证码方法，依赖原 AppService 的登录接口；迁移登录模块时把 XQQ_MINE_HAS_LOGIN_MODULE 置 1
#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendArea:(NSString *)area phone:(NSString *)phone  button:(UIButton *)btn {
    if (phone.length <= 0) {
        [SVProgressHUD showErrorWithStatus:([self isChinese]?@"请输入手机号":@"Please enter your phone number")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (phone.length < 6) {
        [SVProgressHUD showErrorWithStatus:([self isChinese]?@"手机号码格式有误":@"The mobile number format is incorrect")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    WS(weakself)
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"mobile"] = phone;
    if (area.length) {
        params[@"area"] = area;
    }
    params[@"opt"] = @"1";
    btn.userInteractionEnabled = NO;
//    [XQQAppService.sharedAppService sendLoginCode:params success:^{
//        btn.userInteractionEnabled = NO;
//        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
//        [SVProgressHUD dismissWithDelay:1.0];
//        [weakself handleTimer:btn];
//    } error:^(NSString * _Nonnull message) {
//        btn.userInteractionEnabled = YES;
//        [SVProgressHUD showErrorWithStatus:message];
//        [SVProgressHUD dismissWithDelay:1.0];
//    }];
    
    [XQQMineLogin sendLoginMobileCode:params success:^{
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(int errCode, NSString * _Nonnull message) {
        btn.userInteractionEnabled = YES;
        [SVProgressHUD showErrorWithStatus:message];
        [SVProgressHUD dismissWithDelay:1.0];
    }];
}
// 注册登录专用
- (void)sendEmailCode:(NSString *)email button:(UIButton *)btn {
    if (email.length <= 0) {
        [SVProgressHUD showErrorWithStatus:([self isChinese]?@"请输入邮箱地址":@"Please enter email")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    // 本地邮箱格式校验
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    if (![emailPredicate evaluateWithObject:email]) {
        [SVProgressHUD showErrorWithStatus:([self isChinese]?@"邮箱格式不正确":@"Invalid email format")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    WS(weakself)
    btn.userInteractionEnabled = NO;
//    [XQQMineAPI requestUrlNoLogin:@"/sendEmailCode" params:@{@"email":email,@"opt":@"1"} success:^(NSDictionary * _Nonnull dict) {
//        btn.userInteractionEnabled = NO;
//        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
//        [SVProgressHUD dismissWithDelay:1.0];
//        [weakself handleTimer:btn];
//    } error:^(int errCode, NSString * _Nonnull message) {
//        btn.userInteractionEnabled = YES;
//        NSString *text = @"";
//        if ([weakself isChinese]) {
//            text = message;
//        }else {
//            if ([message containsString:@"验证码错误"]) {
//                text = @"Verification code error";
//            }else if ([message containsString:@"错误"]) {
//                text = @"Error...";
//            }else {
//                text = @"Error...";
//            }
//        }
//        [SVProgressHUD showErrorWithStatus:text];
//        [SVProgressHUD dismissWithDelay:1.0];
//    }];
    
    [XQQMineLogin sendLoginEmailCode:@{@"email":email,@"opt":@"1"} success:^ {
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(int errCode, NSString * _Nonnull message) {
        btn.userInteractionEnabled = YES;
        NSString *text = @"";
        if ([weakself isChinese]) {
            text = message;
        }else {
            if ([message containsString:@"验证码错误"]) {
                text = @"Verification code error";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [SVProgressHUD showErrorWithStatus:text];
        [SVProgressHUD dismissWithDelay:1.0];
    }];

}
// 忘记邮箱登录密码 用于找回其登录密码
- (void)sendEmailCodeForForget:(NSString *)email button:(UIButton *)btn {
    if (email.length <= 0) {
        [SVProgressHUD showErrorWithStatus:([self isChinese]?@"请输入邮箱地址":@"Please enter email")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    WS(weakself)
    btn.userInteractionEnabled = NO;
    [XQQMineAPI requestUrlNoLogin:@"/sendEmailCode" params:@{@"email":email,@"opt":@"1"} success:^(NSDictionary * _Nonnull dict) {
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(int errCode, NSString * _Nonnull message) {
        btn.userInteractionEnabled = YES;
        NSString *text = @"";
        if ([weakself isChinese]) {
            text = message;
        }else {
            if ([message containsString:@"验证码错误"]) {
                text = @"Verification code error";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [SVProgressHUD showErrorWithStatus:text];
        [SVProgressHUD dismissWithDelay:1.0];
    }];
}
#endif
- (void)loyout {
    [XQQMineAPI requestUrl:@"/logout" params:@{} success:^(NSDictionary * _Nonnull dict) {
        
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}
#if XQQ_MINE_HAS_LOGIN_MODULE
- (void)sendResetCode:(NSString *)phone button:(UIButton *)btn {
    WS(weakself)
    btn.userInteractionEnabled = NO;
    [XQQMineLogin sendResetCode:phone success:^{
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(NSString * _Nonnull message) {
        btn.userInteractionEnabled = YES;
        [SVProgressHUD showErrorWithStatus:message];
        [SVProgressHUD dismissWithDelay:1.0];
    }];
}
// 忘记密码用户发送验证码
- (void)sendForgetCode:(NSString *)phone button:(UIButton *)btn {
    WS(weakself)
    btn.userInteractionEnabled = NO;
    [XQQMineLogin sendForgetCode:phone success:^{
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(NSString * _Nonnull message) {
        btn.userInteractionEnabled = YES;
        [SVProgressHUD showErrorWithStatus:message];
        [SVProgressHUD dismissWithDelay:1.0];
    }];
}
// 忘记密码用户发送验证码2  0108
- (void)sendForgetCode:(NSString *)phone area:(NSString *)area button:(UIButton *)btn {
    WS(weakself)
    btn.userInteractionEnabled = NO;
    [SVProgressHUD show];
    [XQQMineAPI requestUrlNoLogin:@"/sendMobileCode" params:@{@"mobile":phone, @"area":area} success:^(NSDictionary * _Nonnull dict) {
        [SVProgressHUD dismiss];
        btn.userInteractionEnabled = NO;
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself handleTimer:btn];
    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
        btn.userInteractionEnabled = YES;
        NSString *text = @"";
        if ([weakself isChinese]) {
            text = message;
        }else {
            if ([message containsString:@"验证码错误"]) {
                text = @"Verification code error";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [SVProgressHUD showErrorWithStatus:text];
        [SVProgressHUD dismissWithDelay:1.0];
    }];
}


#endif
- (void)send_reset_device_code_button:(UIButton *)btn type:(int)type {
    WS(weakself)
    btn.userInteractionEnabled = NO;
//    [XQQMineAPI requestUrlNoLogin:@"/device_lock/send_reset_device_code" params:@{} success:^(NSDictionary * _Nonnull dict) {
//        btn.userInteractionEnabled = NO;
//        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
//        [SVProgressHUD dismissWithDelay:1.0];
//        [weakself handleTimer:btn];
//    } error:^(int errCode, NSString * _Nonnull message) {
//        btn.userInteractionEnabled = YES;
//        NSString *text = @"";
//        if ([weakself isChinese]) {
//            text = message;
//        }else {
//            if ([message containsString:@"验证码错误"]) {
//                text = @"Verification code error";
//            }else if ([message containsString:@"错误"]) {
//                text = @"Error...";
//            }else {
//                text = @"Error...";
//            }
//        }
//        [SVProgressHUD showErrorWithStatus:text];
//        [SVProgressHUD dismissWithDelay:1.0];
//    }];
    
    
    if (type == 0) {
        [XQQMineAccount sendMobileCodeWithScene:@{@"scene":@"3"} success:^ {
            btn.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [weakself handleTimer:btn];
        } error:^(int errCode, NSString * _Nonnull message) {
            btn.userInteractionEnabled = YES;
            NSString *text = @"";
            if ([weakself isChinese]) {
                text = message;
            }else {
                if ([message containsString:@"验证码错误"]) {
                    text = @"Verification code error";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [SVProgressHUD showErrorWithStatus:text];
            [SVProgressHUD dismissWithDelay:1.0];
        }];

    } else {
        [XQQMineAccount sendEmailCodeWithScene:@{@"scene":@"3"} success:^{
            btn.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [weakself handleTimer:btn];
        } error:^(int errCode, NSString * _Nonnull message) {
            btn.userInteractionEnabled = YES;
            NSString *text = @"";
            if ([weakself isChinese]) {
                text = message;
            }else {
                if ([message containsString:@"验证码错误"]) {
                    text = @"Verification code error";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [SVProgressHUD showErrorWithStatus:text];
            [SVProgressHUD dismissWithDelay:1.0];
        }];

    }

}

- (void)updateAppSuccess:(void(^)(BOOL isUpdate))success {
    WS(weakself)
    [XQQMineAPI requestUrlNoLogin:@"/global_config" params:@{} success:^(NSDictionary * _Nonnull dict) {
        NSArray *versions = dict[@"result"][@"version"];
        if (versions.count <= 0) {
            return;
        }
        NSDictionary *version1Dic = versions.firstObject;
        NSString *links = version1Dic[@"links"];
        if (links.length) {
            [weakself saveLinks:links];
        }
        NSString *versionNum = version1Dic[@"iosVersion"];
        NSString *iosInfo = @"";
        if ([version1Dic[@"iosInfo"] isKindOfClass:NSNull.class]) {
            iosInfo = @"";
        }else {
            iosInfo = version1Dic[@"iosInfo"];
        }
        NSString *iosPath = version1Dic[@"iosPath"];
        BOOL force = [version1Dic[@"force"] boolValue];
        NSInteger isReview = [version1Dic[@"isReview"] integerValue];
        NSInteger isIosTips = [version1Dic[@"isIosTips"] integerValue]; // 0 不提示 1 提示
        
        [NSUserDefaults.standardUserDefaults setInteger:isReview forKey:@"kIsReview"];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        weakself.iosVersion = version1Dic[@"iosVersion"];
        weakself.iosPath = iosPath;
        
        if (isReview == 1 || isIosTips == 0) {
            success ? success(NO) : nil;
            return;
        }
        NSString *localFixedVersion = VersionNUM;
        if (localFixedVersion.length > 0 &&
            versionNum.length > 0 &&
            [localFixedVersion compare:versionNum options:NSNumericSearch] != NSOrderedAscending) {
            success ? success(NO) : nil;
            return;
        }
        
        XQQODJNUpdatedVersionPopView *popView = [[XQQODJNUpdatedVersionPopView alloc] init];
        popView.isForce = force;
//        [popView showVersion:versionNum info:iosInfo download:iosPath];
        success ? success(YES) : nil;
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}
- (void)saveLinks:(NSString *)links {
    NSDictionary *resultDic = links.mj_JSONObject;
//    NSLog(@"resultDic======%@",resultDic);
    if (resultDic.count > 0) {
        if (resultDic[@"zh"] != nil) {
            [NSUserDefaults.standardUserDefaults setObject:resultDic[@"zh"] forKey:kWebsiteUrlChinese];
        }
        if (resultDic[@"en"] != nil) {
            [NSUserDefaults.standardUserDefaults setObject:resultDic[@"en"] forKey:kWebsiteUrlEnglish];
        }
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}
- (void)exit {
    UIWindow *window = ShareAppDelegate.window;
    [UIView animateWithDuration:0.35 animations:^{
        window.alpha = 0.0;
        window.frame = CGRectMake(CGRectGetWidth(window.frame)/2, CGRectGetHeight(window.frame)/2,1,1);
    } completion:^(BOOL finished) {
        exit(0);
    }];
}

- (NSString *)getAudioOrVideoPath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"EGAudioVideo"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}



- (NSString *)onlineStatusDesc:(long long)mobileLastSeen {
    NSString *strSeenTime = nil;
    long long duration = [[[NSDate alloc] init] timeIntervalSince1970] - (mobileLastSeen/1000);
    int days = (int)(duration / 86400);
    if (days >= 1) {
//        strSeenTime = [NSString stringWithFormat:@"%d天前", days];
        strSeenTime = [UNString(@"%lld", mobileLastSeen) timeIntervalDateFormat:@"yyyy-MM-dd"];
    } else {
        int hours = (int)(duration/3600);
        if(hours) {
            strSeenTime = [NSString stringWithFormat:@"%d%@",hours, ([self isChinese]?@"小时前":@" hours ago")];
        } else {
            int mins = (int)(duration/60);
            if(mins) {
                strSeenTime = [NSString stringWithFormat:@"%d%@",mins, ([self isChinese]?@"分前":@" minutes ago")];
            } else {
                strSeenTime = [NSString stringWithFormat:@""];
            }
        }
    }
    return strSeenTime;
}

- (NSString *)contactOnlineStatusDesc:(long long)mobileLastSeen {
    // 毫秒转秒
    NSTimeInterval time = mobileLastSeen / 1000.0;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    
    // 当前时间
    NSDate *now = [NSDate date];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger yearOfDate = [calendar component:NSCalendarUnitYear fromDate:date];
    NSInteger yearOfNow  = [calendar component:NSCalendarUnitYear fromDate:now];
    
    NSString *format = nil;
    if (yearOfDate == yearOfNow) {
        format = @"MM-dd HH:mm";
    } else {
        format = @"yyyy-MM-dd HH:mm";
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = format;
    
    return [formatter stringFromDate:date];
}

//0 未知, 1 Android, 2 iOS, 3 Windows, 4 Mac, 5 Web, 6 小程序, 7 Linux, 8 iPad, 9 Android-Pad
- (NSString *)customerPlatform:(NSString *)plt {
    NSString *platformStr;
    int platform = [plt intValue];
    if (platform == 1) {
        platformStr = @"Android";
    } else if (platform == 2) {
        platformStr = @"iPhone";
    } else if (platform == 3) {
        platformStr = @"Windows";
    } else if(platform == 4) {
        platformStr = @"Mac";
    } else if(platform == 7) {
        platformStr = @"Linux";
    } else if(platform == 5) {
        platformStr = @"Web";
    } else if(platform == 6) {
        platformStr = @"小程序已登录";
    } else if(platform == 8) {
        platformStr = @"iPad";
    } else if(platform == 9) {
        platformStr = @"Android pad";
    }
    return platformStr;
}


#pragma mark - 图片选择器
- (void)showImagePikerWithimageBlock:(ImagePikerBlock)imageBlock {
    self.imagePikerCallBack = imageBlock;
    WS(weakself)
    BOOL isChinese = [self isChinese];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:(isChinese?@"请选择...":@"Please select...") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photographicAction = [UIAlertAction actionWithTitle:(isChinese?@"拍照":@"Take a picture") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself openSystemPhotoAlbum:UIImagePickerControllerSourceTypeCamera];
    }];
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:(isChinese?@"从手机相册中选择":@"Open the album") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself openSystemPhotoAlbum:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:photographicAction];
    [alertController addAction:photoAction];
    [alertController addAction:cancelAction];
    [[self myViewController] presentViewController:alertController animated:YES completion:nil];
}
- (void)openSystemPhotoAlbum:(UIImagePickerControllerSourceType)sourceType {
    UIViewController *vc = [self myViewController];
    if (sourceType == UIImagePickerControllerSourceTypeCamera && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Tips") message:([self isChinese]?@"该设备不支持拍照！":@"The device does not support taking pictures!") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [actionSheet addAction:cancelAct];
        [vc presentViewController:actionSheet animated:YES completion:nil];
        return;
    }
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Tips") message:([self isChinese]?@"请在iPhone的”设置-隐私-相机“选项中允许零阅使用相机权限":@"Please allow zero access to the camera in the Settings - Privacy - Camera option on your iPhone") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [actionSheet addAction:cancelAct];
        [vc presentViewController:actionSheet animated:YES completion:nil];
        return;
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.sourceType = sourceType;
    pickerController.allowsEditing = YES;
    pickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [vc presentViewController:pickerController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *img = info[UIImagePickerControllerEditedImage];
    WS(weakself)
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.imagePikerCallBack) {
            weakself.imagePikerCallBack(img);
        }
    });
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark 获取当前屏幕显示的viewcontroller
- (UIViewController *)myViewController {
    // 定义一个变量存放当前屏幕显示的viewcontroller
    UIViewController *result = nil;
    // 得到当前应用程序的主要窗口
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    // windowLevel是在 Z轴 方向上的窗口位置，默认值为UIWindowLevelNormal
    if (window.windowLevel != UIWindowLevelNormal)    {
        // 获取应用程序所有的窗口
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)        {
            // 找到程序的默认窗口（正在显示的窗口）
            if (tmpWin.windowLevel == UIWindowLevelNormal)            {
                // 将关键窗口赋值为默认窗口
                window = tmpWin;
                break;
            }
        }
    }
    // 获取窗口的当前显示视图
    UIView *frontView = [[window subviews] objectAtIndex:0];
    // 获取视图的下一个响应者，UIView视图调用这个方法的返回值为UIViewController或它的父视图
    id nextResponder = [frontView nextResponder];
    // 判断显示视图的下一个响应者是否为一个UIViewController的类对象
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        result = nextResponder;
    } else {
        result = window.rootViewController;
    }
    return result;

}
/**
 *  验证码倒计时
 */                           
- (void)handleTimer:(UIButton*)sender {
//    __block int timeout = 60; //倒计时时间
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
//    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
//    dispatch_source_set_event_handler(_timer, ^{
//        if(timeout <= 0) { //倒计时结束，关闭
//            dispatch_source_cancel(_timer);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //设置界面的按钮显示 根据自己需求设置
//                [sender setTitle:@"重新获取" forState:UIControlStateNormal];
//                [sender setTitleColor:RGBA(0xff4845) forState:UIControlStateNormal];
//                sender.backgroundColor = [UIColor clearColor];
//                sender.userInteractionEnabled = YES;
//            });
//        }else {
//            int seconds = timeout % 61;
//            NSString *strTime = [NSString stringWithFormat:@"%.2d", seconds];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //设置界面的按钮显示 根据自己需求设置
//                [sender setTitle:[NSString stringWithFormat:@"%@s",strTime] forState:UIControlStateNormal];
//                [sender setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
//                sender.userInteractionEnabled = NO;
//                sender.backgroundColor = [UIColor clearColor];
//            });
//            timeout --;
//        }
//    });
//    dispatch_resume(_timer);
    
    __block int timeout = 60; //倒计时时间
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (timeout <= 0) {
            [sender setTitle:LLLLLL(@"Reacquire") forState:UIControlStateNormal];
            [sender setTitleColor:RGBA(0xff4845) forState:UIControlStateNormal];
            sender.backgroundColor = [UIColor clearColor];
            sender.userInteractionEnabled = YES;
            if (timer != nil) {
                [timer invalidate];
                timer = nil;
            }
        }else {
            [sender setTitle:UNString(@"%.2ds", timeout % 61) forState:UIControlStateNormal];
            [sender setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
            sender.userInteractionEnabled = NO;
            sender.backgroundColor = UIColor.clearColor;
        }
        timeout--;
    }];
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
    timer.fireDate = NSDate.distantPast;
}






#pragma mark - 手机通讯录相关


// 该手机号是否是通讯录的好友
- (BOOL)isAddressBookContact:(NSString *)targetPhone {
    if (self.allContacts.count <= 0) {
        return NO;
    }
    for (NSString *phone in self.allContacts) {
        if ([targetPhone isEqualToString:phone]) {
            return YES;
        }
    }
    return NO;
}

- (NSMutableArray *)allContacts {
    if (!_allContacts) {
        _allContacts = NSMutableArray.new;
    }return _allContacts;
}

- (void)getMyAddressBook {
    [self.allContacts removeAllObjects];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactPhoneNumbersKey]];
        WS(weakself)
        [CNContactStore.new enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                for (CNLabeledValue *labelValue in contact.phoneNumbers) {
                    CNPhoneNumber *phoneNumber = labelValue.value;
                    NSString *phoneValue = phoneNumber.stringValue;
                    phoneValue = [phoneValue stringByReplacingOccurrencesOfString:@"+86" withString:@""];
                    phoneValue = [phoneValue stringByReplacingOccurrencesOfString:@"-" withString:@""];
                    phoneValue = [phoneValue stringByReplacingOccurrencesOfString:@" " withString:@""];
                    
                    [weakself.allContacts addObject:phoneValue];
                }
//                NSLog(@"allContacts====%@",weakself.allContacts);
            });
        }];
    });
}


@end
