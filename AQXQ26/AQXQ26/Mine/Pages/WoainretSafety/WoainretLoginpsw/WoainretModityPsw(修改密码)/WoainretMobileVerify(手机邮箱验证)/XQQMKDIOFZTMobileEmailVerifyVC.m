//
//  XQQMKDIOFZTMobileEmailVerifyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/23/24.
//

#import "XQQMKDIOFZTMobileEmailVerifyVC.h"

#import "XQQMKDIOFZTLoginpswVerifyVC.h"


@interface XQQMKDIOFZTMobileEmailVerifyVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *mobileEmailLabel;

@property (weak, nonatomic) IBOutlet UIView *aBgView;
@property (weak, nonatomic) IBOutlet UIView *bBgView;

@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;
@property (weak, nonatomic) IBOutlet UITextField *pswTF;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic, strong) XQQCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *safetyL;
@property (weak, nonatomic) IBOutlet UIButton *loginPswVerificationButton;

@end

@implementation XQQMKDIOFZTMobileEmailVerifyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _aBgView.layer.cornerRadius = 10.0;
    _bBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _qoynruCodeTF.delegate = self;
    _pswTF.delegate = self;
    [_qoynruCodeTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_pswTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    self.userInfo = [XQQMineProfile getMyInfo];
    if (_isMobile) { // 手机
        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
        NSString *mobile = phones.lastObject;
        NSMutableString *star = NSMutableString.new;
        for (NSInteger i = 0; i < mobile.length-7; i ++) {
            [star appendString:@"*"];
        }
        _mobileEmailLabel.text = [NSString stringWithFormat:@"%@ %@",_userInfo.area, [mobile stringByReplacingCharactersInRange:NSMakeRange(3, mobile.length - 7) withString:UNString(@" %@ ", star)]];
    }else { // 邮箱
        NSArray *emails = [_userInfo.email componentsSeparatedByString:@"@"];
//        _mobileEmailLabel.text = UNString(@"******@%@", emails.lastObject);
        NSString *emailFront = emails.firstObject; // 类似于->Loooooo
        if (emailFront.length <= 4) {
            if (emailFront.length <= 2) {
                _mobileEmailLabel.text = _userInfo.email;
            }else {
                _mobileEmailLabel.text = [NSString stringWithFormat:@"%@**%@@%@",[emailFront substringToIndex:1], [emailFront substringFromIndex:(emailFront.length-1)], emails.lastObject];
            }
        }else {
            _mobileEmailLabel.text = [NSString stringWithFormat:@"%@****%@@%@",[emailFront substringToIndex:2], [emailFront substringFromIndex:(emailFront.length-2)], emails.lastObject];
        }
    }
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"ModityLoginPassword");
    [_sendButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_okButton setTitle:LLLLLL(@"Submit") forState:UIControlStateNormal];
    
    _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
     
    [_loginPswVerificationButton setTitle:LLLLLL(@"LoginPasswordVerification") forState:UIControlStateNormal];
    
    if ([XQQCommonHelper.main isChinese]) {
        
    }else {
        _safetyL.text = @"For account security, we need to verify your identity.";
        
        _pswTF.placeholder = @"Enter your new login password";
    }
}
 
- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (_pswTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_pswTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself) //  type -> 0邮箱 1 手机 2 旧密码
    NSDictionary *params;
    if (_isMobile) {
        params = @{@"area":self.userInfo.area, @"mobile":self.userInfo.mobile, @"code":_qoynruCodeTF.text,@"password":_pswTF.text};
        [XQQMineAPI requestUrl:@"/reset" params:params success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (UIViewController *vc in self.navigationController.viewControllers) {
                    if ([vc isKindOfClass:NSClassFromString(@"XQQMKDIOFZTSafetyVC")]) {
                        [weakself.navigationController popToViewController:vc animated:YES];
                        break;
                    }
                }
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            NSString *text = @"";
            if ([XQQCommonHelper.main isChinese]) {
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
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
    } else {
        params = @{@"email":self.userInfo.email, @"code":_qoynruCodeTF.text,@"password":_pswTF.text};
        [XQQMineAPI requestUrl:@"/resetWithEmail" params:params success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (UIViewController *vc in self.navigationController.viewControllers) {
                    if ([vc isKindOfClass:NSClassFromString(@"XQQMKDIOFZTSafetyVC")]) {
                        [weakself.navigationController popToViewController:vc animated:YES];
                        break;
                    }
                }
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            NSString *text = @"";
            if ([XQQCommonHelper.main isChinese]) {
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
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];

    }
}

- (IBAction)send:(UIButton *)sender {
    [self.view endEditing:YES];
    WS(weakself)
    sender.userInteractionEnabled = NO;
    if (_isMobile) {
        [XQQMineAccount sendMobileCodeWithScene:@{@"scene":@"1"}
                                                     success:^{
            sender.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [XQQCommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            sender.userInteractionEnabled = YES;
            NSString *text = @"";
            if ([XQQCommonHelper.main isChinese]) {
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
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
        
    }else {
        [XQQMineAccount sendEmailCodeWithScene:@{@"scene":@"1"}
                                                    success:^{
            sender.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [XQQCommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            sender.userInteractionEnabled = YES;
            NSString *text = @"";
            if ([XQQCommonHelper.main isChinese]) {
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
            [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
    }
    _qoynruCodeTF.text = @"";
}

- (IBAction)login_psw_verify:(UIButton *)sender {
    XQQMKDIOFZTLoginpswVerifyVC *vc = XQQMKDIOFZTLoginpswVerifyVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)textField:(UITextField *)textField {
    if (_qoynruCodeTF.text.length >= 4 && _pswTF.text.length >= 6) {
        if (_okButton.userInteractionEnabled) {
            return;
        }
        _okButton.userInteractionEnabled = YES;
        _okButton.backgroundColor = MAINCOLOR;
    }else {
        if (!_okButton.userInteractionEnabled) {
            return;
        }
        _okButton.userInteractionEnabled = NO;
        _okButton.backgroundColor = RGBA(0xD5D6DA);
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (_qoynruCodeTF == textField) {
        return (length <= 6);
    }
    if (_pswTF == textField) {
        return (length <= 16);
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
