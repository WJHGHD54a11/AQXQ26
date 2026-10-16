//
//  XQQGNRJYDIOZForgetPswdSetupVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/2/24.
//

#import "XQQGNRJYDIOZForgetPswdSetupVC.h"

@interface XQQGNRJYDIOZForgetPswdSetupVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *cBgView;
@property (weak, nonatomic) IBOutlet UIView *dBgView;

@property (weak, nonatomic) IBOutlet UITextField *newsPswTF;
@property (weak, nonatomic) IBOutlet UITextField *newsPswATF;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@end

@implementation XQQGNRJYDIOZForgetPswdSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"找回密码";
    }else {
        self.navigationItem.title = @"Retrieve password";
        
        _newsPswTF.placeholder = @"New password";
        _newsPswATF.placeholder = @"Confirm new password";
        
        [_okButton setTitle:LLLLLL(@"Submit") forState:UIControlStateNormal];
    }
    _cBgView.layer.cornerRadius = 20.0;
    _dBgView.layer.cornerRadius = 20.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = NO;
    
    _newsPswTF.delegate = self;
    _newsPswATF.delegate = self;
    [_newsPswTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_newsPswATF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_newsPswTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_newsPswTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (_newsPswATF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_newsPswATF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    if (![_newsPswTF.text isEqualToString:_newsPswATF.text]) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"TheTwoPasswordsDoNotMatch")];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    if (_type == 0) { // 通过手机号找回密码
        NSDictionary *params = @{@"mobile":_account, @"code":_code, @"password":_newsPswTF.text, @"area":_area};
        WS(weakself)
        [XQQMineLogin setForgetPsw:params success:^{
            [hud hideAnimated:YES];
            
            [weakself.navigationController popToRootViewControllerAnimated:YES];
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
    }else { // 通过邮箱找回密码
        WS(weakself)
        NSDictionary *params = @{@"email":_account, @"code":_code, @"password":_newsPswTF.text};
        [XQQMineAPI requestUrlNoLogin:@"/forgotWithEmail" params:params success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            
            [weakself.navigationController popToRootViewControllerAnimated:YES];
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            NSString *text = @"";
            if ([XQQCommonHelper.main isChinese]) {
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
        }];
    }
}


- (void)textField:(UITextField *)textField {
    if (_newsPswTF.text.length >= 6 && _newsPswATF.text.length >= 6) {
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
    if (_newsPswTF == textField || _newsPswATF == textField) {
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
