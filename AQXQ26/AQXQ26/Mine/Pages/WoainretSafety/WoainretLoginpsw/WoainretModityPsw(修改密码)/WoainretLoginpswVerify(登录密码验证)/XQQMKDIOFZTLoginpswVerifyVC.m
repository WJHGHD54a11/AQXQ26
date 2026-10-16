//
//  XQQMKDIOFZTLoginpswVerifyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/23/24.
//

#import "XQQMKDIOFZTLoginpswVerifyVC.h"

#import "XQQMKDIOFZTMobileEmailVerifyVC.h"

@interface XQQMKDIOFZTLoginpswVerifyVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *aBgView;
@property (weak, nonatomic) IBOutlet UIView *bBgView;
@property (weak, nonatomic) IBOutlet UIView *cBgView;

@property (weak, nonatomic) IBOutlet UITextField *oldPswTF;
@property (weak, nonatomic) IBOutlet UITextField *newsPswATF;
@property (weak, nonatomic) IBOutlet UITextField *newsPswBTF;

@property (weak, nonatomic) IBOutlet UIButton *okButton;


@property (weak, nonatomic) IBOutlet UILabel *safetyL;
@property (weak, nonatomic) IBOutlet UIButton *codeVerificationBtn;

@end

@implementation XQQMKDIOFZTLoginpswVerifyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _aBgView.layer.cornerRadius = 10.0;
    _bBgView.layer.cornerRadius = 10.0;
    _cBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _oldPswTF.delegate = self;
    _newsPswATF.delegate = self;
    _newsPswBTF.delegate = self;
    [_oldPswTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_newsPswATF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_newsPswBTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"ModityLoginPassword");
    [_okButton setTitle:LLLLLL(@"Submit") forState:UIControlStateNormal];
    
    if ([XQQCommonHelper.main isChinese]) {
        
    }else {
        _safetyL.text = @"For account security, we need to verify your identity.";
        
        _oldPswTF.placeholder = @"Enter your old login password";
        _newsPswATF.placeholder = @"Enter your new login password";
        _newsPswBTF.placeholder = @"Enter the new login password again";
        
        [_codeVerificationBtn setTitle:@"Captcha verification" forState:UIControlStateNormal];
    }
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_oldPswTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_oldPswTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (_newsPswATF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_newsPswATF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (_newsPswBTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_newsPswBTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (![_newsPswATF.text isEqualToString:_newsPswBTF.text]) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"TheTwoPasswordsDoNotMatch")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    
    WS(weakself)
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    [XQQMineAPI requestUrl:@"/updatePassword" params:@{@"oldPassword":_oldPswTF.text, @"newPassword":_newsPswATF.text, @"type":@(2)} success:^(NSDictionary * _Nonnull dict) {
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


- (IBAction)code_verify:(UIButton *)sender {
    XQQMKDIOFZTMobileEmailVerifyVC *vc = XQQMKDIOFZTMobileEmailVerifyVC.new;
    NSInteger login_type = [NSUserDefaults.standardUserDefaults integerForKey:kLOGIN_TYPE];
    vc.isMobile = (login_type == 0 ? YES : NO);
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)textField:(UITextField *)textField {
    if (_oldPswTF.text.length >= 6 && _newsPswATF.text.length >= 6 && _newsPswBTF.text.length >= 6) {
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
    if (_oldPswTF == textField || _newsPswATF == textField || _newsPswBTF == textField) {
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
