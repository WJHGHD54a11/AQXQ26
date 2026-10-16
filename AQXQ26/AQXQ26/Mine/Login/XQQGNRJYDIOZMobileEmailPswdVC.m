//
//  XQQGNRJYDIOZMobileEmailPswdVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/26/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQGNRJYDIOZMobileEmailPswdVC.h"
#import "XQQGNRJYDIOZForgetPswdSetupVC.h"

#import "XQQGNRJYDIOZAreacodeVC.h"


@interface XQQGNRJYDIOZMobileEmailPswdVC ()<UITextFieldDelegate, XWCountryCodeControllerDelegate>
{
    NSString *_qoynruArea_name;
}
@property (weak, nonatomic) IBOutlet UIView *aView;
@property (weak, nonatomic) IBOutlet UIView *aaView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aaViewWidth;
@property (weak, nonatomic) IBOutlet UIView *bView;

@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;

@property (weak, nonatomic) IBOutlet UITextField *qoynruAccountTF;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;
@property (weak, nonatomic) IBOutlet UIButton *qoynruNextButton;

@end

@implementation XQQGNRJYDIOZMobileEmailPswdVC


- (void)viewDidLoad {
    [super viewDidLoad];
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"找回密码";
    }else {
        self.navigationItem.title = @"Retrieve password";
        
        _qoynruAccountTF.placeholder = LLLLLL(@"MobileNumber");
        _qoynruCodeTF.placeholder = LLLLLL(@"Code");
        
        [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
        [_qoynruNextButton setTitle:LLLLLL(@"Next") forState:UIControlStateNormal];
    }
    _qoynruArea_name = @"+86";
    _aView.layer.cornerRadius = 20.0;
    _bView.layer.cornerRadius = 20.0;
    _qoynruNextButton.layer.cornerRadius = 12.0;
    _qoynruNextButton.userInteractionEnabled = NO;
    
    _qoynruAccountTF.delegate = self;
    _qoynruCodeTF.delegate = self;
    [_qoynruAccountTF addTarget:self action:@selector(pswTextField:) forControlEvents:UIControlEventEditingChanged];
    [_qoynruCodeTF addTarget:self action:@selector(pswTextField:) forControlEvents:UIControlEventEditingChanged];
    
    
    if (_type == 1) {
        _aaView.hidden = YES;
        _aaViewWidth.constant = 5.0;
        _qoynruAccountTF.placeholder = LLLLLL(@"Email");
        _qoynruAccountTF.keyboardType = UIKeyboardTypeEmailAddress;
    }
}

- (IBAction)next:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruAccountTF.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:_qoynruAccountTF.placeholder];
        [SVProgressHUD dismissWithDelay:1.0];
        return ;
    }
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
    if (_type == 0) {
        url = @"/validMobileCode";
        params = @{@"area":_qoynruArea_name, @"mobile":_qoynruAccountTF.text, @"code":_qoynruCodeTF.text};
    }else {
        url = @"/validEmailCode";
        params = @{@"email":_qoynruAccountTF.text, @"code":_qoynruCodeTF.text};
    }
    WS(weakself)
    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        
        XQQGNRJYDIOZForgetPswdSetupVC *vc = XQQGNRJYDIOZForgetPswdSetupVC.new;
        vc.type = weakself.type;
        vc.code = dict[@"result"];
        vc.account = weakself.qoynruAccountTF.text;
        if (weakself.type == 0) {
            vc.area = self->_qoynruArea_name;
        }
        [weakself.navigationController pushViewController:vc animated:YES];
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

- (IBAction)code:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_type == 0) {
        if (_qoynruAccountTF.text.length <= 0) {
            [SVProgressHUD showErrorWithStatus:LLLLLL(@"MobileNumber")];
            [SVProgressHUD dismissWithDelay:1.0];
            return ;
        }
        [XQQCommonHelper.main sendForgetCode:_qoynruAccountTF.text area:_qoynruArea_name button:sender];
    }else {
        if (_qoynruAccountTF.text.length <= 0) {
            [SVProgressHUD showErrorWithStatus:LLLLLL(@"Email")];
            [SVProgressHUD dismissWithDelay:1.0];
            return ;
        }
        [XQQCommonHelper.main sendEmailCodeForForget:_qoynruAccountTF.text button:sender];
    }
    _qoynruCodeTF.text = @"";
    _qoynruNextButton.selected = NO;
    _qoynruNextButton.userInteractionEnabled = NO;
}

- (IBAction)phoneAreaCode:(UIButton *)sender { // 电话号码的区号
    [self.view endEditing:YES];
    XQQGNRJYDIOZAreacodeVC *vc = XQQGNRJYDIOZAreacodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.deleagete = self;
    [self.navigationController pushViewController:vc animated:YES];
    _qoynruAccountTF.text = @"";
}

- (void)returnCountryName:(NSString *)countryName code:(NSString *)code {
    _qoynruAccountTF.text = @"";
    _qoynruArea_name = UNString(@"+%@", code);
    _qoynruAreaLabel.text = _qoynruArea_name;
}

- (void)pswTextField:(UITextField *)textField {
    BOOL account = (_type == 0 ? _qoynruAccountTF.text.length >= 6 : _qoynruAccountTF.text.length >= 6);
    if (account && _qoynruCodeTF.text.length >= 4) {
        if (_qoynruNextButton.userInteractionEnabled) {
            return;
        }
        _qoynruNextButton.userInteractionEnabled = YES;
        _qoynruNextButton.backgroundColor = MAINCOLOR;
    }else {
        if (!_qoynruNextButton.userInteractionEnabled) {
            return;
        }
        _qoynruNextButton.userInteractionEnabled = NO;
        _qoynruNextButton.backgroundColor = RGBA(0xD5D6DA);
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (_qoynruCodeTF == textField) {
        return (length <= 6);
    }
    if (_qoynruAccountTF == textField) {
        if (_type == 0) {
            if ([_qoynruArea_name isEqualToString:@"+86"]) {
                return (length <= 11);
            }
            return (length <= 15);
        }
        return (length <= 32);
    }
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)dealloc {
    NSLog(@"%@ --- dealloc",NSStringFromClass(self.class));
}

@end
