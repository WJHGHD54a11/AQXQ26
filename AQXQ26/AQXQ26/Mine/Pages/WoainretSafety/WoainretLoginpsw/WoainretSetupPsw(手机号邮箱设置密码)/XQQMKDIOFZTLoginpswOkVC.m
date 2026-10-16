//
//  XQQMKDIOFZTLoginpswOkVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTLoginpswOkVC.h"

@interface XQQMKDIOFZTLoginpswOkVC ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *aBgView;
@property (weak, nonatomic) IBOutlet UIView *bBgView;

@property (weak, nonatomic) IBOutlet UITextField *newsPswTF;
@property (weak, nonatomic) IBOutlet UITextField *newsPswATF;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic, strong) XQQCUserInfo *userInfo;

@end


@implementation XQQMKDIOFZTLoginpswOkVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _aBgView.layer.cornerRadius = 10.0;
    _bBgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 12.0;
    _okButton.userInteractionEnabled = false;
    
    _newsPswTF.delegate = self;
    _newsPswATF.delegate = self;
    [_newsPswTF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    [_newsPswATF addTarget:self action:@selector(textField:) forControlEvents:UIControlEventEditingChanged];
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [XQQMineProfile getMyInfo];    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"SetLoginPassword");
    
    _newsPswTF.placeholder = LLLLLL(@"EnterLoginPassword");
    _newsPswATF.placeholder = LLLLLL(@"ModityLoginPassword");
    [_okButton setTitle:LLLLLL(@"Submit") forState:UIControlStateNormal];
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
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    // 登录方式 0 手机号码    1 邮箱
    NSInteger login_type = [[NSUserDefaults standardUserDefaults] integerForKey:kLOGIN_TYPE];
    if (login_type == 0) {
        NSMutableDictionary *params = NSMutableDictionary.new;
        params[@"area"] = self.userInfo.area;
        params[@"mobile"] = self.userInfo.mobile;
        params[@"code"] = _code;
        params[@"password"] = _newsPswTF.text;

        WS(weakself)
        [XQQMineAPI requestUrl:@"/reset" params:params success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"kHasPassword"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [NSNotificationCenter.defaultCenter postNotificationName:kMODITY_MOBILE_EMAIL_NOTI object:@{@"loginPsw":@(1)}];
            for (UIViewController *vc in self.navigationController.viewControllers) {
                if ([vc isKindOfClass:NSClassFromString(@"XQQMKDIOFZTSafetyVC")]) {
                    [weakself.navigationController popToViewController:vc animated:YES];
                    break;
                }
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
    } else {
        NSMutableDictionary *params = NSMutableDictionary.new;
        params[@"email"] = self.userInfo.email;
        params[@"code"] = _code;
        params[@"password"] = _newsPswTF.text;
        
        WS(weakself)
        [XQQMineAPI requestUrl:@"/resetWithEmail" params:params success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"kHasPassword"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [NSNotificationCenter.defaultCenter postNotificationName:kMODITY_MOBILE_EMAIL_NOTI object:@{@"loginPsw":@(1)}];
            for (UIViewController *vc in self.navigationController.viewControllers) {
                if ([vc isKindOfClass:NSClassFromString(@"XQQMKDIOFZTSafetyVC")]) {
                    [weakself.navigationController popToViewController:vc animated:YES];
                    break;
                }
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

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
@end
