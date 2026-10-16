//
//  XQQMKDIOFZTMobileEmailVerityVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/24/24.
//

#import "XQQMKDIOFZTMobileEmailVerityVC.h"

#import "XQQMKDIOFZTMobileBindingVC.h"
#import "XQQMKDIOFZTEmailBindingVC.h"

@interface XQQMKDIOFZTMobileEmailVerityVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *mobileEmailLabel;

@property (weak, nonatomic) IBOutlet UIView *aBgView;

@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic, strong) XQQCUserInfo *userInfo;

@property (weak, nonatomic) IBOutlet UILabel *safetyL;


@end

@implementation XQQMKDIOFZTMobileEmailVerityVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userInfo = [XQQMineProfile getMyInfo];
    if (_type == 0) {
        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
        NSString *mobile = phones.lastObject;
        NSMutableString *star = NSMutableString.new;
        for (NSInteger i = 0; i < mobile.length-7; i ++) {
            [star appendString:@"*"];
        }
        _mobileEmailLabel.text = [NSString stringWithFormat:@"%@ %@",_userInfo.area, [mobile stringByReplacingCharactersInRange:NSMakeRange(3, mobile.length - 7) withString:UNString(@" %@ ", star)]];
    }else {
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
    
    _aBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _qoynruCodeTF.delegate = self;
    [_qoynruCodeTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    if (_type == 0) {
        self.navigationItem.title = LLLLLL(@"ModifyMobilePhone");
    }else {
        self.navigationItem.title = LLLLLL(@"ModifyEmail");
    }
    if ([XQQCommonHelper.main isChinese]) {
        
    }else {
        _safetyL.text = @"For the security of the account, we need to verify the identity, enter the old number verification code for verification.";
    }
    _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    
    [_okButton setTitle:LLLLLL(@"Next") forState:UIControlStateNormal];
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    NSString *url = @"";
    NSDictionary *params;
    if (_type == 0) {
        url = @"/validMobileCode";
        params = @{@"area":self.userInfo.area, @"mobile":self.userInfo.mobile, @"code":_qoynruCodeTF.text};

    }else {
        url = @"/validEmailCode";
        params = @{@"email":_userInfo.email, @"code":_qoynruCodeTF.text};
    }
    WS(weakself)
    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        if (weakself.type == 0) {
            XQQMKDIOFZTMobileBindingVC *vc = XQQMKDIOFZTMobileBindingVC.new;
            vc.returnCode = dict[@"result"];
            [weakself.navigationController pushViewController:vc animated:YES];
        }else {
            XQQMKDIOFZTEmailBindingVC *vc = XQQMKDIOFZTEmailBindingVC.new;
            vc.returnCode = dict[@"result"];
            [weakself.navigationController pushViewController:vc animated:YES];
        }
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


//- (IBAction)send:(UIButton *)sender {
//    [self.view endEditing:YES];
//    NSString *url = @"";
//    NSDictionary *params = @{};
//    if (_type == 0) {
//        url = @"/send_update_mobile_code_1";
//        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
//        params = @{@"area":_userInfo.area, @"mobile":phones.lastObject};
//    }else {
//        url = @"/send_update_email_code_1";
//        params = @{@"email":_userInfo.email};
//    }
//    WS(weakself)
//    sender.userInteractionEnabled = NO;
//    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
//        sender.userInteractionEnabled = NO;
//        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
//        [SVProgressHUD dismissWithDelay:1.0];
//        [XQQCommonHelper.main handleTimer:sender];
//    } error:^(int errCode, NSString * _Nonnull message) {
//        sender.userInteractionEnabled = YES;
//        NSString *text = @"";
//        if ([XQQCommonHelper.main isChinese]) {
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
//        [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//    }];
//    _qoynruCodeTF.text = @"";
//}

- (IBAction)send:(UIButton *)sender {
    [self.view endEditing:YES];
    NSString *url = @"";
    NSDictionary *params = @{};
    WS(weakself)
    sender.userInteractionEnabled = NO;

    if (_type == 0) {
        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
        params = @{@"area":_userInfo.area, @"mobile":phones.lastObject,@"scene":@"2"};
        
        [XQQMineAccount sendMobileCodeWithScene:params success:^ {
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
        params = @{@"email":_userInfo.email,@"scene":@"2"};
        
        [XQQMineAccount sendEmailCodeWithScene:params success:^ {
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


- (void)textField:(UITextField *)textField {
    if (_qoynruCodeTF.text.length >= 4) {
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
