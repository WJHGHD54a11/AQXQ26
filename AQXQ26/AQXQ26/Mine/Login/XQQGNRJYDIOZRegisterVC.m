//
//  XQQGNRJYDIOZRegisterVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/25/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMineSession.h"
#import "XQQGNRJYDIOZRegisterVC.h"
#import "KeyChainTool.h"

#import "XQQGNRJYDIOZProtocolVC.h"
#import "XQQGNRJYDIOZAreacodeVC.h"

#import "XQQRegisterSetAvatarVC.h"

/// 注册方式：_eogcsaioxType 的取值，与 xib 里两个切换按钮的 tag 一致
typedef NS_ENUM(NSInteger, XQQRegisterAccountType) {
    XQQRegisterAccountTypePhone = 0,
    XQQRegisterAccountTypeEmail = 1,
};

static NSString * const kXQQRegisterDefaultAreaCode = @"+86";
static const CGFloat kXQQRegisterDefaultAreaViewWidth = 55.0;
/// 区号文字宽度之外，区号视图额外占的宽度（箭头 + 间距）
static const CGFloat kXQQRegisterAreaViewExtraWidth = 27.0;

/// 输入长度上限
static const NSInteger kXQQRegisterChinaPhoneLength = 11;
static const NSInteger kXQQRegisterPhoneMaxLength = 15;
static const NSInteger kXQQRegisterEmailMaxLength = 50;
static const NSInteger kXQQRegisterCodeMaxLength = 6;

/// 账号 / 验证码的最短长度
static const NSInteger kXQQRegisterAccountMinLength = 6;
static const NSInteger kXQQRegisterCodeMinLength = 4;

static NSString * const kXQQRegisterCustomerServiceUserIdKey = @"kCustomerService_UserId";

@interface XQQGNRJYDIOZRegisterVC ()<UITextFieldDelegate, UIScrollViewDelegate, XWCountryCodeControllerDelegate>
{
    NSInteger _eogcsaioxType; // 手机 or 邮箱，见 XQQRegisterAccountType

    NSString *_qoynruArea_name; // 手机区号
    CGFloat _area_view_width; // 手机区号的宽度

    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *boxBgView;

@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterTypeAButton;
@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterTypeBButton;

@property (weak, nonatomic) IBOutlet UITextField *qoynruAccountTF;
@property (weak, nonatomic) IBOutlet UITextField *qoynruCodeTF;
@property (weak, nonatomic) IBOutlet UIImageView *qoynruAccountImgView;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAccountLabel;
@property (weak, nonatomic) IBOutlet UILabel *qoynruCodeLabel;
@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIView *qoynruAreaView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qoynruAreaViewWidth;
@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;

@property (weak, nonatomic) IBOutlet UIButton *qoynruRegisterButton;

@property (weak, nonatomic) IBOutlet UILabel *qoynruHaveAmountL;
@property (weak, nonatomic) IBOutlet UILabel *qoynruGoLoginL;

/// 勾选"已阅读并同意协议"，selected 即已勾选
@property (weak, nonatomic) IBOutlet UIButton *qoynruProtocolButton;
@property (weak, nonatomic) IBOutlet UILabel *andL;
@property (weak, nonatomic) IBOutlet UIButton *qoynruUserProtocolBtn;
@property (weak, nonatomic) IBOutlet UIButton *qoynruPrivacyProtocolBtn;

@property (weak, nonatomic) IBOutlet UIButton *qoynruCustomerBtn;

@end

@implementation XQQGNRJYDIOZRegisterVC

#pragma mark - Life cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.subviews.firstObject.alpha = 0.0;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    self.navigationController.navigationBar.subviews.firstObject.alpha = 1.0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];

    _qoynruArea_name = kXQQRegisterDefaultAreaCode;
    _area_view_width = kXQQRegisterDefaultAreaViewWidth;
    _qoynruAreaViewWidth.constant = _area_view_width;

    _scrollView.delegate = self;
    [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];

    _qoynruAccountTF.delegate = self;
    _qoynruCodeTF.delegate = self;
    [_qoynruAccountTF addTarget:self action:@selector(registerTextField:) forControlEvents:UIControlEventEditingChanged];
    [_qoynruCodeTF addTarget:self action:@selector(registerTextField:) forControlEvents:UIControlEventEditingChanged];

    // 输入满足条件前注册按钮不可点
    _qoynruRegisterButton.userInteractionEnabled = NO;

    _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_M(20);
    [self qoynruType];

    [self updateADFLanguage];
}

- (void)dealloc {
    NSLog(@"%@ --- dealloc", NSStringFromClass(self.class));
}

#pragma mark - UI

- (void)updateADFLanguage {
    [_qoynruRegisterTypeAButton setTitle:LLLLLL(@"Tel") forState:UIControlStateNormal];
    [_qoynruRegisterTypeBButton setTitle:LLLLLL(@"E-mail") forState:UIControlStateNormal];

    _qoynruCodeTF.placeholder = (_isChinese ? @"请输入验证码" : @"Verification code");
    _qoynruAccountLabel.text = LLLLLL(@"MobileNumber");
    _qoynruCodeLabel.text = LLLLLL(@"Code");

    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_qoynruRegisterButton setTitle:LLLLLL(@"SignUp") forState:UIControlStateNormal];

    _qoynruHaveAmountL.text = _isChinese ? @"已有账户？" : @"Already have an account? ";
    _qoynruGoLoginL.text = _isChinese ? @"去登录" : @"To log in";

    [_qoynruProtocolButton setTitle:(_isChinese ? @"我已阅读并同意" : @"I have read and agreed to the") forState:UIControlStateNormal];
    _andL.text = (_isChinese ? @"和" : @"and");
    [_qoynruUserProtocolBtn setTitle:UNString(@"《%@》", LLLLLL(@"UserAgreement")) forState:UIControlStateNormal];
    [_qoynruPrivacyProtocolBtn setTitle:UNString(@"《%@》", LLLLLL(@"PrivacyPolicy")) forState:UIControlStateNormal];

    [_qoynruCustomerBtn setTitle:LLLLLL(@"CustomerService") forState:UIControlStateNormal];
}

/// 按手机 / 邮箱刷新输入区，并清空已输入内容
- (void)qoynruType {
    BOOL isPhone = _eogcsaioxType == XQQRegisterAccountTypePhone;
    _boxBgView.image = IMAGENAME(isPhone ? @"LoginType0" : @"LoginType1");
    _qoynruAccountLabel.text = isPhone ? LLLLLL(@"MobileNumber") : LLLLLL(@"Email");
    _qoynruAccountTF.placeholder = isPhone ? LLLLLL(@"MobileNumbers") : LLLLLL(@"Email");
    _qoynruAccountTF.keyboardType = isPhone ? UIKeyboardTypeNumberPad : UIKeyboardTypeEmailAddress;
    _qoynruAreaView.hidden = !isPhone;
    _qoynruAreaLabel.text = isPhone ? _qoynruArea_name : @"";
    _qoynruAreaViewWidth.constant = isPhone ? _area_view_width : 0.0;
    _qoynruAccountImgView.image = IMAGENAME(isPhone ? @"phoneIcon" : @"eogcsaioxEmail");
    // 当前选中的注册方式标题放大加粗（PINGFANG_* 宏自带分号，不能用在三目运算里）
    if (isPhone) {
        _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_M(20);
        _qoynruRegisterTypeBButton.titleLabel.font = PINGFANG_R(15);
    } else {
        _qoynruRegisterTypeAButton.titleLabel.font = PINGFANG_R(15);
        _qoynruRegisterTypeBButton.titleLabel.font = PINGFANG_M(20);
    }
    _qoynruRegisterTypeAButton.selected = isPhone;
    _qoynruRegisterTypeBButton.selected = !isPhone;
    _qoynruAccountTF.text = @"";
    _qoynruCodeTF.text = @"";
    [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];
    [_qoynruSendcodeButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];
}

- (void)updateRegisterButtonEnabled:(BOOL)enabled {
    if (_qoynruRegisterButton.userInteractionEnabled == enabled) {
        return;
    }
    _qoynruRegisterButton.userInteractionEnabled = enabled;
    [_qoynruRegisterButton setBackgroundImage:IMAGENAME(enabled ? @"eogcsaioxBtnS" : @"eogcsaioxBtnN") forState:UIControlStateNormal];
    [_qoynruRegisterButton setTitleColor:(enabled ? UIColor.whiteColor : MAINCOLOR) forState:UIControlStateNormal];
}

- (void)showErrorStatus:(NSString *)status {
    [SVProgressHUD showErrorWithStatus:status];
    [SVProgressHUD dismissWithDelay:1.0];
}

#pragma mark - 发送验证码

- (IBAction)eogcsaioxSendCode:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_qoynruAccountTF.text.length <= 0) {
        [self showErrorStatus:_qoynruAccountTF.placeholder];
        return;
    }
    // 请求期间禁止重复点击，失败后恢复；成功后由倒计时接管
    sender.userInteractionEnabled = NO;
    [SVProgressHUD show];

    void(^success)(void) = ^{
        [SVProgressHUD dismiss];
        sender.userInteractionEnabled = NO;
        [self.view makeToast:LLLLLL(@"SentSuccessfully") duration:1.0 position:CSToastPositionCenter];
        [XQQCommonHelper.main handleTimer:sender];
    };
    void(^failure)(int errCode, NSString *message) = ^(int errCode, NSString *message) {
        [SVProgressHUD dismiss];
        sender.userInteractionEnabled = YES;
        [self.view makeToast:[self localizedSendCodeError:message] duration:1.0 position:CSToastPositionCenter];
    };

    // opt 0 表示注册场景的验证码
    if (_eogcsaioxType == XQQRegisterAccountTypePhone) {
        [XQQMineLogin sendRegisterMobileCode:@{@"area": _qoynruArea_name,
                                                                 @"mobile": _qoynruAccountTF.text,
                                                                 @"opt": @"0"}
                                                       success:success error:failure];
    } else {
        [XQQMineLogin sendRegisterEmailCode:@{@"email": _qoynruAccountTF.text,
                                                                @"opt": @"0"}
                                                      success:success error:failure];
    }
    _qoynruCodeTF.text = @"";
}

/// 服务端只返回中文提示，英文环境按关键词粗略翻译
- (NSString *)localizedSendCodeError:(NSString *)message {
    if (_isChinese) {
        return message;
    }
    return [message containsString:@"失败"] ? @"Failure..." : @"Error...";
}

- (NSString *)localizedRegisterError:(NSString *)message {
    if (_isChinese) {
        return message;
    }
    return [message containsString:@"验证码错误"] ? @"Verification code error" : @"Error...";
}

#pragma mark - 注册

- (IBAction)registerAccount:(UIButton *)sender {
    [self.view endEditing:YES];
    if ([self isValid]) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = _isChinese ? @"注册中..." : @"Under registration...";
    [hud showAnimated:YES];
    [self registerAcc:hud];
}

- (void)registerAcc:(MBProgressHUD *)hud {
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"clientId"] = [XQQMineAccount getClientId];
    params[@"platform"] = @(Platform_iOS);
    params[@"deviceUId"] = [KeyChainTool readData:kUUIDStringValue];
    params[@"deviceType"] = UIDevice.currentDevice.name;

    NSString *url = nil;
    if (_eogcsaioxType == XQQRegisterAccountTypePhone) {
        url = @"/register";
        params[@"area"] = _qoynruArea_name;
        params[@"mobile"] = _qoynruAccountTF.text;
    } else {
        url = @"/registerWithEmail";
        params[@"email"] = _qoynruAccountTF.text;
    }
    params[@"code"] = _qoynruCodeTF.text;

    WS(weakself)
    [XQQMineAPI requestUrl:url params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        [SVProgressHUD showSuccessWithStatus:(self->_isChinese ? @"注册成功..." : @"Registered successfully...")];
        [SVProgressHUD dismissWithDelay:1.0];
        [weakself registerAccountSuccess:dict];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        [weakself.view makeToast:[self localizedRegisterError:message] duration:1.0 position:CSToastPositionCenter];
    }];
}

/// 注册成功：保存登录信息、准备本地数据、绑定推送、连接 IM，然后进入设置头像页。
/// 返回的 result 与登录接口一致，这里用 userCode / accessToken / websocketToken / hasPassword
- (void)registerAccountSuccess:(NSDictionary *)dict {
    NSDictionary *result = dict[@"result"];
    NSString *userId = result[@"userCode"];
    NSString *token = result[@"accessToken"];
    NSString *websocketToken = result[@"websocketToken"];
    NSString *hasPassword = result[@"hasPassword"];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:@"savedToken"];
    [defaults setObject:userId forKey:@"savedUserId"];
    [defaults setObject:websocketToken forKey:@"savedwebsocketToken"];
    [defaults setInteger:hasPassword.integerValue forKey:@"kHasPassword"];
    [defaults setInteger:_eogcsaioxType forKey:kLOGIN_TYPE]; // 登录方式 0 手机号码    1 邮箱
    [defaults synchronize];

    // 原工程：准备本地 IM 数据、绑定推送、连接 IM。IM 未迁移，改为统一收尾（XQQMineSession）。
    [XQQMineProfile getUserInfo:userId success:^(XQQCUserInfo * _Nonnull userInfo) {
        [XQQMineSession finishLoginWithUser:userInfo];
    } error:^(int errCode, NSString * _Nonnull message) {
    }];

    [self setAvatar];
}

- (void)setAvatar {
    [self.navigationController pushViewController:[XQQRegisterSetAvatarVC new] animated:YES];
}

#pragma mark - 输入校验

/// 返回 YES 表示校验不通过（已提示），与调用处 `if ([self isValid]) return;` 配合
- (BOOL)isValid {
    NSString *error = nil;
    if (_qoynruAccountTF.text.length <= 0) {
        error = _qoynruAccountTF.placeholder;
    } else if (_eogcsaioxType == XQQRegisterAccountTypePhone && _qoynruAccountTF.text.length < kXQQRegisterAccountMinLength) {
        error = _isChinese ? @"手机号码格式有误" : @"The mobile number format is incorrect";
    } else if (_qoynruCodeTF.text.length < kXQQRegisterCodeMinLength) {
        error = _qoynruCodeTF.placeholder;
    } else if (!_qoynruProtocolButton.selected) {
        error = _isChinese ? @"请您阅读协议" : @"Please read the agreement";
    }
    if (!error) {
        return NO;
    }
    [self showErrorStatus:error];
    return YES;
}

// 输入变化时刷新注册按钮可点状态；+86 手机号要求满 11 位
- (void)registerTextField:(UITextField *)textField {
    NSInteger accountMin = kXQQRegisterAccountMinLength;
    if (_eogcsaioxType == XQQRegisterAccountTypePhone && [_qoynruArea_name isEqualToString:kXQQRegisterDefaultAreaCode]) {
        accountMin = kXQQRegisterChinaPhoneLength;
    }
    BOOL accountOK = _qoynruAccountTF.text.length >= accountMin;
    BOOL codeOK = _qoynruCodeTF.text.length >= kXQQRegisterCodeMinLength;
    [self updateRegisterButtonEnabled:(accountOK && codeOK)];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (textField == _qoynruAccountTF) {
        return length <= [self accountMaxLength];
    }
    if (textField == _qoynruCodeTF) {
        return length <= kXQQRegisterCodeMaxLength;
    }
    return YES;
}

- (NSInteger)accountMaxLength {
    if (_eogcsaioxType != XQQRegisterAccountTypePhone) {
        return kXQQRegisterEmailMaxLength;
    }
    return [_qoynruArea_name isEqualToString:kXQQRegisterDefaultAreaCode] ? kXQQRegisterChinaPhoneLength : kXQQRegisterPhoneMaxLength;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)close {
    [self.view endEditing:YES];
}

#pragma mark - Actions

// 手机 / 邮箱切换
- (IBAction)loginType:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_eogcsaioxType == sender.tag) {
        return;
    }
    _eogcsaioxType = sender.tag;
    [self qoynruType];
}

// 手机号码的区号
- (IBAction)phoneArea:(UIButton *)sender {
    [self.view endEditing:YES];
    XQQGNRJYDIOZAreacodeVC *vc = XQQGNRJYDIOZAreacodeVC.new;
    vc.hidesBottomBarWhenPushed = YES;
    vc.deleagete = self;
    [self.navigationController pushViewController:vc animated:YES];
}

// 已有账号，返回登录页
- (IBAction)login:(UIButton *)sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

// 勾选 / 取消勾选协议
- (IBAction)eogcsaioxProtocol:(UIButton *)sender {
    [self.view endEditing:YES];
    sender.selected = !sender.selected;
}

// 查看用户协议 / 隐私政策，按钮 tag 决定打开哪一份
- (IBAction)protocolDetails:(UIButton *)sender {
    [self.view endEditing:YES];
    XQQGNRJYDIOZProtocolVC *vc = XQQGNRJYDIOZProtocolVC.new;
    vc.eogcsaioxType = sender.tag;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - XWCountryCodeControllerDelegate

- (void)returnCountryName:(NSString *)countryName code:(NSString *)code {
    _qoynruAccountTF.text = @"";
    _qoynruArea_name = UNString(@"+%@", code);
    _qoynruAreaLabel.text = _qoynruArea_name;

    UIFont *font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];
    CGSize size = [_qoynruArea_name boundingRectWithSize:CGSizeMake(WIDTH, 8000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil].size; // 原 XQQIUEHUtilities getTextDrawingSize
    _area_view_width = size.width + kXQQRegisterAreaViewExtraWidth;
    _qoynruAreaViewWidth.constant = _area_view_width;
}

#pragma mark - 客服

// 未登录也能联系客服：用设备信息注册一个临时账号连上 IM，再进入客服会话
- (IBAction)customerService:(UIButton *)sender {

    // 客服会话依赖消息模块（IM），第一版尚未迁移
    NSString *text = _isChinese ? @"在线客服将在后续版本开放" : @"Customer service will be available in a later version";
    [self.view makeToast:text duration:1.5 position:CSToastPositionCenter];

}

@end
