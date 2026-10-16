//
//  XQQMKDIOFZTDestroyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/22/24.
//

#import "XQQMKDIOFZTDestroyVC.h"
#import "KeyChainTool.h"
#import <objc/runtime.h> // 新增：发码时间挂在关联对象上


@interface XQQMKDIOFZTDestroyVC ()
{
    NSInteger _type; // 登录方式 0 手机号  1 邮箱
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *descLLL;

@property (weak, nonatomic) IBOutlet UILabel *codeL;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UIButton *destroyButton;

@end

// 新增：注销账号请求前的参数检查，只读取、不修改请求和流程，实现在文件尾部
@interface XQQMKDIOFZTDestroyVC (XQQDestroyCheck)
- (void)xqq_checkDestroyParameters; // 新增
- (void)xqq_recordCodeSent;         // 新增
@end

@implementation XQQMKDIOFZTDestroyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _sendButton.layer.cornerRadius = 5.0;
    _sendButton.layer.borderWidth = 1.0;
    _sendButton.layer.borderColor = RGBA(0x2c2c2c).CGColor;
    _destroyButton.layer.cornerRadius = 20.0;
    
    _type = [NSUserDefaults.standardUserDefaults integerForKey:kLOGIN_TYPE];
    
    _isChinese = [XQQCommonHelper.main isChinese];
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"DestroyAccount");
    _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
    [_sendButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    if (_isChinese) {
        
    }else {
        _descLLL.text = @"Dear, really want to cruel to leave us 😭😭😭!";
        _codeL.text = @"Code";
        
        [_destroyButton setTitle:@"Destruction of account" forState:UIControlStateNormal];
    }
}

- (IBAction)destroy:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    [self xqq_checkDestroyParameters]; // 新增
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    XQQCUserInfo *user = [XQQMineProfile getMyInfo];
    int platform = Platform_iOS;
    if (_type == 0) {
        [XQQMineAPI requestUrlNoLogin:@"/destroy" params:@{@"mobile":user.mobile, @"area":user.area, @"code": _qoynruCodeTF.text, @"clientId":[XQQMineAccount getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name} success:^(NSDictionary * _Nonnull dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
                [XQQMineAccount clearAppServiceAuthInfos];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
                [XQQMineAccount disconnect:NO clearSession:NO];
                [XQQMineAccount disconnect:YES clearSession:NO];
                
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"login error with code %d, message %@", errCode, message);
                [hud hideAnimated:YES];
                NSString *text = @"";
                if (self->_isChinese) {
                    text = message;
                }else {
                    if ([message containsString:@"失败"]) {
                        text = @"Failure...";
                    }else if ([message containsString:@"错误"]) {
                        text = @"Error...";
                    }else {
                        text = @"Error...";
                    }
                }
                [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
            });
        }];

    } else {
        [XQQMineAPI requestUrlNoLogin:@"/destroyWithEmail" params:@{@"email":user.email, @"code": _qoynruCodeTF.text, @"clientId":[XQQMineAccount getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name} success:^(NSDictionary * _Nonnull dict) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
                [XQQMineAccount clearAppServiceAuthInfos];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
                [XQQMineAccount disconnect:NO clearSession:NO];
                [XQQMineAccount disconnect:YES clearSession:NO];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"login error with code %d, message %@", errCode, message);
                [hud hideAnimated:YES];
                NSString *text = @"";
                if (self->_isChinese) {
                    text = message;
                }else {
                    if ([message containsString:@"失败"]) {
                        text = @"Failure...";
                    }else if ([message containsString:@"错误"]) {
                        text = @"Error...";
                    }else {
                        text = @"Error...";
                    }
                }
                [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
            });
        }];

    }
//    [XQQMineAccount destroyAccount:@{@"type":@(_type), @"code":_qoynruCodeTF.text} success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
//            [XQQMineAccount clearAppServiceAuthInfos];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            
//            //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
//            [XQQMineAccount disconnect:NO clearSession:NO];
//            [XQQMineAccount disconnect:YES clearSession:NO];
//        });
//    } error:^(int errorCode, NSString * _Nonnull message) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"login error with code %d, message %@", errorCode, message);
//            [hud hideAnimated:YES];
//            NSString *text = @"";
//            if (self->_isChinese) {
//                text = message;
//            }else {
//                if ([message containsString:@"失败"]) {
//                    text = @"Failure...";
//                }else if ([message containsString:@"错误"]) {
//                    text = @"Error...";
//                }else {
//                    text = @"Error...";
//                }
//            }
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        });
//    }];
}

- (IBAction)send:(UIButton *)sender {
    [self.view endEditing:YES];
    [self xqq_recordCodeSent]; // 新增
    _qoynruCodeTF.text = @"";
    sender.userInteractionEnabled = NO;
    [sender setTitle:(_isChinese ? @"短信发送中" : @"Sending...") forState:UIControlStateNormal];
    WS(weakself)
    XQQCUserInfo *user = [XQQMineProfile getMyInfo];
    if (_type == 0) {
        [SVProgressHUD show];
//        [XQQMineAccount sendLoginCode:@{@"mobile":user.mobile, @"area":user.area} success:^{
//            [SVProgressHUD dismiss];
//            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            [XQQCommonHelper.main handleTimer:sender];
//            
//        } error:^(NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
//            NSString *text = @"";
//            if (self->_isChinese) {
//                text = message;
//            }else {
//                if ([message containsString:@"失败"]) {
//                    text = @"Failure...";
//                }else if ([message containsString:@"错误"]) {
//                    text = @"Error...";
//                }else {
//                    text = @"Error...";
//                }
//            }
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [XQQMineAccount sendMobileCodeWithScene:@{@"scene":@"3"}
                                                       success:^{
            [SVProgressHUD dismiss];
            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            [XQQCommonHelper.main handleTimer:sender];
            
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
            NSString *text = @"";
            if (self->_isChinese) {
                text = message;
            }else {
                if ([message containsString:@"失败"]) {
                    text = @"Failure...";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];

    } else {
        [SVProgressHUD show];
//        [XQQMineAPI requestUrlNoLogin:@"/sendEmailCode" params:@{@"email":user.email} success:^(NSDictionary * _Nonnull dict) {
//            [SVProgressHUD dismiss];
//            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//            [XQQCommonHelper.main handleTimer:sender];
//            
//        } error:^(int errCode, NSString * _Nonnull message) {
//            [SVProgressHUD dismiss];
//            sender.userInteractionEnabled = YES;
//            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
//            NSString *text = @"";
//            if (self->_isChinese) {
//                text = message;
//            }else {
//                if ([message containsString:@"失败"]) {
//                    text = @"Failure...";
//                }else if ([message containsString:@"错误"]) {
//                    text = @"Error...";
//                }else {
//                    text = @"Error...";
//                }
//            }
//            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//        }];
        
        [XQQMineAccount sendEmailCodeWithScene:@{@"scene":@"3"}
                                                    success:^ {
            [SVProgressHUD dismiss];
            [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
            [XQQCommonHelper.main handleTimer:sender];
            
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = YES;
            [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
            NSString *text = @"";
            if (self->_isChinese) {
                text = message;
            }else {
                if ([message containsString:@"失败"]) {
                    text = @"Failure...";
                }else if ([message containsString:@"错误"]) {
                    text = @"Error...";
                }else {
                    text = @"Error...";
                }
            }
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
    }
//    [XQQMineAccount sendDestroyAccountCode:@{@"type":@(_type)} success:^{
//        [weakself.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
//        [XQQCommonHelper.main handleTimer:sender];
//    } error:^(int errorCode, NSString * _Nonnull message) {
//        sender.userInteractionEnabled = YES;
//        [sender setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
//        NSString *text = @"";
//        if (self->_isChinese) {
//            text = message;
//        }else {
//            if ([message containsString:@"失败"]) {
//                text = @"Failure...";
//            }else if ([message containsString:@"错误"]) {
//                text = @"Error...";
//            }else {
//                text = @"Error...";
//            }
//        }
//        [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//    }];
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end

#pragma mark - 新增：注销请求参数检查

// 新增：以下检查只在 Debug 下执行和输出日志，不修改请求参数和注销流程。
// 参数里有手机号、邮箱、验证码和设备 ID，日志只打"是否为空"和长度，不打内容
static const void *kXQQDestroyCodeSentKey = &kXQQDestroyCodeSentKey; // 新增

@implementation XQQMKDIOFZTDestroyVC (XQQDestroyCheck)

// 新增：点"获取验证码"时记下时间，注销时可以看出距离发码过了多久（验证码一般有有效期）
- (void)xqq_recordCodeSent {
    objc_setAssociatedObject(self, kXQQDestroyCodeSentKey, @(CACurrentMediaTime()), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 新增：注销请求用字典字面量拼参数，任何一个值为 nil 都会在拼字典时直接崩溃
// （例如本地资料里没有手机号 / 区号 / 邮箱，或钥匙串里读不到设备 ID）。
// 这里在发请求前逐个检查，Debug 下能提前看到是哪一项为空；不改变原来的行为
- (void)xqq_checkDestroyParameters {
#ifdef DEBUG
    XQQCUserInfo *user = [XQQMineProfile getMyInfo];
    NSMutableDictionary<NSString *, id> *values = [NSMutableDictionary dictionary];
    if (_type == 0) {
        values[@"mobile"] = user.mobile ?: NSNull.null;
        values[@"area"] = user.area ?: NSNull.null;
    } else {
        values[@"email"] = user.email ?: NSNull.null;
    }
    values[@"clientId"] = [XQQMineAccount getClientId] ?: NSNull.null;
    values[@"deviceUId"] = [KeyChainTool readData:kUUIDStringValue] ?: NSNull.null;
    values[@"deviceType"] = UIDevice.currentDevice.name ?: NSNull.null;

    NSMutableArray<NSString *> *missing = [NSMutableArray array];
    [values enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if (value == NSNull.null) { [missing addObject:key]; }
    }];
    NSString *code = _qoynruCodeTF.text ?: @"";
    BOOL codeNumeric = [code rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound;
    NSNumber *sentAt = objc_getAssociatedObject(self, kXQQDestroyCodeSentKey);
    NSLog(@"[Destroy] type=%@ missing=%@ willCrash=%d codeLength=%lu codeNumeric=%d sinceCodeSent=%@",
          _type == 0 ? @"mobile" : @"email", missing, missing.count > 0, (unsigned long)code.length, codeNumeric,
          sentAt ? [NSString stringWithFormat:@"%.0fs", CACurrentMediaTime() - sentAt.doubleValue] : @"never");
#endif
}

@end
