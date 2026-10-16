//
//  XQQMKDIOFZTLoginpswVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTLoginpswVC.h"
#import "XQQMKDIOFZTLoginpswOkVC.h"


@interface XQQMKDIOFZTLoginpswVC ()<UITextFieldDelegate>
{
    NSInteger _login_type; // 登录方式 0 手机号码    1 邮箱
    BOOL _isSendCode;
}
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@property (weak, nonatomic) IBOutlet UIView *aBgView;

@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic, strong) XQQCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *yanMingL;


@end

@implementation XQQMKDIOFZTLoginpswVC


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.userInfo = [XQQMineProfile getMyInfo];
    // 登录方式 0 手机号码    1 邮箱
    _login_type = [[NSUserDefaults standardUserDefaults] integerForKey:kLOGIN_TYPE];
    if (_login_type == 0) {
        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
        NSString *mobile = phones.lastObject;
        NSMutableString *star = NSMutableString.new;
        for (NSInteger i = 0; i < mobile.length-7; i ++) {
            [star appendString:@"*"];
        }
        _phoneLabel.text = [NSString stringWithFormat:@"%@ %@",self.userInfo.area, [mobile stringByReplacingCharactersInRange:NSMakeRange(3, mobile.length - 7) withString:UNString(@" %@ ", star)]];
    }else {
        NSArray *emails = [_userInfo.email componentsSeparatedByString:@"@"];
//        _phoneLabel.text = UNString(@"******@%@", emails.lastObject);
        NSString *emailFront = emails.firstObject; // 类似于->Loooooo
        if (emailFront.length <= 4) {
            if (emailFront.length <= 2) {
                _phoneLabel.text = _userInfo.email;
            }else {
                _phoneLabel.text = [NSString stringWithFormat:@"%@**%@@%@",[emailFront substringToIndex:1], [emailFront substringFromIndex:(emailFront.length-1)], emails.lastObject];
            }
        }else {
            _phoneLabel.text = [NSString stringWithFormat:@"%@****%@@%@",[emailFront substringToIndex:2], [emailFront substringFromIndex:(emailFront.length-2)], emails.lastObject];
        }
    }

    _isSendCode = NO;
    _aBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = false;
    
    _qoynruCodeTF.delegate = self;
    [_qoynruCodeTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"SetPassword");
    if ([XQQCommonHelper.main isChinese]) {
        _yanMingL.text = @"为了账户安全，我们需要验证身份";
    }else {
        _yanMingL.text = @"For account security, we need to verify your identity.";
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
    hud.label.text = LLLLLL(@"InValidation");
    [hud showAnimated:YES];
    
    NSString *url = @"";
    NSDictionary *params = @{};
    if (_login_type == 0) {
        url = @"/validMobileCode";
        params = @{@"area":self.userInfo.area, @"mobile":self.userInfo.mobile, @"code":_qoynruCodeTF.text};
    }else {
        url = @"/validEmailCode";
        params = @{@"email":_userInfo.email, @"code":_qoynruCodeTF.text};
    }
    WS(weakself)
    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        
        XQQMKDIOFZTLoginpswOkVC *vc = XQQMKDIOFZTLoginpswOkVC.new;
        vc.code = dict[@"result"];
        [weakself.navigationController pushViewController:vc animated:YES];
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


//- (IBAction)sendCode:(UIButton *)sender {
//    [self.view endEditing:YES];
//    NSString *url = @"";
//    NSDictionary *params = @{};
//    if (_login_type == 0) {
//        url = @"/sendMobileCode";
//        params = @{@"area":_userInfo.area, @"mobile":_userInfo.mobile,@"opt":@"1"};
//    }else {
//        url = @"/sendEmailCode";
//        params = @{@"email":_userInfo.email,@"opt":@"1"};
//    }
//    WS(weakself)
//    sender.userInteractionEnabled = NO;
//    [SVProgressHUD show];
//    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
//        [SVProgressHUD dismiss];
//        sender.userInteractionEnabled = NO;
//        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
//        [SVProgressHUD dismissWithDelay:1.0];
//        [XQQCommonHelper.main handleTimer:sender];
//    } error:^(int errCode, NSString * _Nonnull message) {
//        [SVProgressHUD dismiss];
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

- (IBAction)sendCode:(UIButton *)sender {
    [self.view endEditing:YES];
    NSString *url = @"";
    NSDictionary *params = @{};
    
    WS(weakself)
    sender.userInteractionEnabled = NO;
    [SVProgressHUD show];

    //手机号
    if (_login_type == 0) {
        [XQQMineAccount sendMobileCodeWithScene:@{@"scene":@"1"}
                                                     success:^{
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [XQQCommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
        
    }else {
        [XQQMineAccount sendEmailCodeWithScene:@{@"scene":@"1"}
                                                    success:^{
            [SVProgressHUD dismiss];
            sender.userInteractionEnabled = NO;
            [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SentSuccessfully")];
            [SVProgressHUD dismissWithDelay:1.0];
            [XQQCommonHelper.main handleTimer:sender];
        } error:^(int errCode, NSString * _Nonnull message) {
            [SVProgressHUD dismiss];
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
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
