//
//  XQQMKDIOFZTMobileBindingVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/24/24.
//

#import "XQQMKDIOFZTMobileBindingVC.h"

#import "XQQGNRJYDIOZAreacodeVC.h"

@interface XQQMKDIOFZTMobileBindingVC ()<UITextFieldDelegate, XWCountryCodeControllerDelegate>
{
    NSString *_qoynruArea_name; // 手机区号
}
@property (weak, nonatomic) IBOutlet UIView *aBgView;
@property (weak, nonatomic) IBOutlet UIView *bBgView;

@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;
@property (weak, nonatomic) IBOutlet UITextField *mobileTF;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@end

@implementation XQQMKDIOFZTMobileBindingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _qoynruArea_name = @"+86";
    
    _aBgView.layer.cornerRadius = 10.0;
    _bBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _qoynruCodeTF.delegate = self;
    _mobileTF.delegate = self;
    [_qoynruCodeTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_mobileTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"SetPhoneNumber");
    
    _mobileTF.placeholder = LLLLLL(@"MobileNumbers");
    _qoynruCodeTF.placeholder = LLLLLL(@"VerificationCode");
    
    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_okButton setTitle:LLLLLL(@"Binding") forState:UIControlStateNormal];
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_mobileTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_mobileTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (_qoynruCodeTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruCodeTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    [XQQMineAccount userbindPhone:@{@"area":_qoynruArea_name, @"mobile":_mobileTF.text, @"code":_qoynruCodeTF.text} success:^ {
        [hud hideAnimated:YES];
        [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
        
        [NSNotificationCenter.defaultCenter postNotificationName:kMODITY_MOBILE_EMAIL_NOTI object:@{@"mobile":[NSString stringWithFormat:@"%@ %@",self->_qoynruArea_name, weakself.mobileTF.text]}];
        
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

- (IBAction)send:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_mobileTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_mobileTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    WS(weakself)
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"area"] = _qoynruArea_name;
    params[@"mobile"] = _mobileTF.text;
    if (_returnCode.length) {
        params[@"code"] = _returnCode;
    }
    sender.userInteractionEnabled = NO;
//    [XQQMineAPI requestUrl:@"/send_update_mobile_code_2" params:params success:^(NSDictionary * _Nonnull dict) {
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
    
    [XQQMineAccount sendMobileCodeWithScene:@{@"area":_qoynruArea_name,@"mobile":_mobileTF.text,@"scene":@"2"}
                                                 success:^ {
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

- (IBAction)area:(UIButton *)sender {
    [self.view endEditing:YES];
    XQQGNRJYDIOZAreacodeVC *vc = XQQGNRJYDIOZAreacodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.deleagete = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)returnCountryName:(NSString *)countryName code:(NSString *)code {
    _mobileTF.text = @"";
    _qoynruArea_name = UNString(@"+%@", code);
    _qoynruAreaLabel.text = _qoynruArea_name;
}


- (void)textField:(UITextField *)textField {
    if (_mobileTF.text.length >= 6 && _qoynruCodeTF.text.length >= 4) {
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
    if (_mobileTF == textField) {
        if ([_qoynruArea_name isEqualToString:@"+86"]) {
            return (length <= 11);
        }
        return (length <= 15);
    }
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

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


@end
