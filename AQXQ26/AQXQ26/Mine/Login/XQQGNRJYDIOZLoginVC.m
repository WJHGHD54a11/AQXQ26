//

//  XQQGNRJYDIOZLoginVC.m

//  WUHOIBDK

//

//  Created by Ruby on 12/22/23.

//  Copyright © 2023 WildFireChat. All rights reserved.

//

#import "XQQMineSession.h"
#import "XQQGNRJYDIOZLoginVC.h"

#import "KeyChainTool.h"


#import "XQQGNRJYDIOZRetrievePswdVC.h"

#import "XQQMKDIOFZTNumberVC.h"

#import "XQQGNRJYDIOZRegisterVC.h"

#import "XQQGNRJYDIOZAreacodeVC.h"






/// 登录方式：_*eogcsaioxType 的取值，与 xib 里两个切换按钮的 tag 一致*

typedef NS_ENUM(NSInteger, XQQLoginAccountType) {

    XQQLoginAccountTypePhone = 0,

    XQQLoginAccountTypeEmail = 1,

};

static NSString * const kXQQDefaultAreaCode = @"+86";

static const CGFloat kXQQDefaultAreaViewWidth = 55.0;

/// 区号文字宽度之外，区号视图额外占的宽度（箭头 + 间距）

static const CGFloat kXQQAreaViewExtraWidth = 27.0;

/// 输入长度上限

static const NSInteger kXQQChinaPhoneMaxLength = 11;

static const NSInteger kXQQPhoneMaxLength = 15;

static const NSInteger kXQQEmailMaxLength = 50;

static const NSInteger kXQQCodeMaxLength = 6;

static const NSInteger kXQQPasswordMaxLength = 16;

/// 登录按钮点亮所需的最短长度

static const NSInteger kXQQAccountMinLength = 6;

static const NSInteger kXQQCodeMinLength = 4;

static const NSInteger kXQQPasswordMinLength = 6;

/// 点击登录时的校验下限（验证码、密码统一按 4 位）

static const NSInteger kXQQSecretSubmitMinLength = 4;


@interface XQQGNRJYDIOZLoginVC ()<UITextFieldDelegate, UIScrollViewDelegate, XWCountryCodeControllerDelegate>

{

    NSInteger _eogcsaioxType; // 手机 or 邮箱，见 XQQLoginAccountType

    NSString *_qoynruArea_name; // 手机区号

    CGFloat _area_view_width; // 手机区号的宽度

    BOOL _isChinese;

    // 新增：登录提交状态，避免连续点击产生重复请求
    BOOL _xqqLoginRequestActive;
    NSTimeInterval _xqqLastLoginTriggerTime;

}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginTypeAButton;

@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginTypeBButton;

@property (weak, nonatomic) IBOutlet UIImageView *qoynruLoginTypeBgView;

@property (weak, nonatomic) IBOutlet UITextField *qoynruAccountTF;

@property (weak, nonatomic) IBOutlet UITextField *qoynruPasswordTF;

@property (weak, nonatomic) IBOutlet UIButton *qoynruSendcodeButton;

@property (weak, nonatomic) IBOutlet UIView *qoynruAreaView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qoynruAreaViewWidth;

@property (weak, nonatomic) IBOutlet UILabel *qoynruAreaLabel;

@property (weak, nonatomic) IBOutlet UIImageView *qoynruAccountImgView;

@property (weak, nonatomic) IBOutlet UILabel *qoynruAccountLabel;

@property (weak, nonatomic) IBOutlet UIImageView *qoynruAasswordImgView;

@property (weak, nonatomic) IBOutlet UILabel *qoynruPasswordLabel;

@property (weak, nonatomic) IBOutlet UIButton *qoynruForgetPswButton;

@property (weak, nonatomic) IBOutlet UIButton *qoynruLoginButton;

// 登录方式切换按钮。selected = YES 表示当前是密码登录（按钮上显示"验证码登录"），NO 表示验证码登录

@property (weak, nonatomic) IBOutlet UIButton *qoynruWayButton;

// 需要转语言的view

@property (weak, nonatomic) IBOutlet UILabel *qoynruNoAmountL;

@property (weak, nonatomic) IBOutlet UILabel *qoynruGoRegisterL;

@property (weak, nonatomic) IBOutlet UIButton *qoynruCustomerBtn;

@property (weak, nonatomic) IBOutlet UIButton *qoynruEyeBtn;

@end

@implementation XQQGNRJYDIOZLoginVC

#pragma mark - 新增登录状态与输入策略

// 新增：统一刷新输入状态，避免不同入口对登录按钮状态判断不一致
- (void)xqqRefreshLoginInputState {
    BOOL accountOK = _qoynruAccountTF.text.length >= kXQQAccountMinLength;
    NSInteger secretMin = [self isPasswordMode] ? kXQQPasswordMinLength : kXQQCodeMinLength;
    BOOL secretOK = _qoynruPasswordTF.text.length >= secretMin;
    BOOL enabled = accountOK && secretOK && !_xqqLoginRequestActive;
    [self updateLoginButtonEnabled:enabled];
    // 新增：输入未达到条件时不保留登录按钮的高亮状态
    if (!enabled && _qoynruLoginButton.isHighlighted) {
        _qoynruLoginButton.highlighted = NO;
    }
}

// 新增：登录开始前建立一次提交状态，只用于当前请求生命周期，不保存到本地
- (BOOL)xqqBeginLoginSubmission {
    NSTimeInterval now = CFAbsoluteTimeGetCurrent();
    if (_xqqLoginRequestActive) {
        return NO;
    }
    if (now - _xqqLastLoginTriggerTime < 0.45) {
        return NO;
    }
    _xqqLastLoginTriggerTime = now;
    _xqqLoginRequestActive = YES;
    [self xqqRefreshLoginInputState];
    return YES;
}

// 新增：仅结束当前登录请求，不改变服务端返回结果
- (void)xqqFinishLoginSubmission {
    if (!_xqqLoginRequestActive) {
        return;
    }
    _xqqLoginRequestActive = NO;
    [self xqqRefreshLoginInputState];
}

// 新增：提交前清理账号首尾空白，避免复制粘贴造成无意义的账号格式错误
- (void)xqqPrepareAccountForSubmission {
    NSString *account = _qoynruAccountTF.text ?: @"";
    NSString *trimmed = [account stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![account isEqualToString:trimmed]) {
        _qoynruAccountTF.text = trimmed;
    }
}

// 新增：账号输入只允许当前登录方式需要的字符，密码不走此规则
- (BOOL)xqqShouldAllowAccountReplacement:(NSString *)replacement {
    if (replacement.length == 0) {
        return YES;
    }
    if ([replacement rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
        return NO;
    }
    if (_eogcsaioxType == XQQLoginAccountTypePhone) {
        NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
        return [replacement rangeOfCharacterFromSet:[digits invertedSet]].location == NSNotFound;
    }
    return [replacement rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound;
}

// 新增：密码/验证码禁止换行，但保留密码中可能合法的空格字符
- (BOOL)xqqShouldAllowSecretReplacement:(NSString *)replacement {
    if (replacement.length == 0) {
        return YES;
    }
    return [replacement rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound;
}

// 新增：模式切换后重新计算输入状态，避免旧模式状态继续控制按钮
- (void)xqqHandleLoginModeChanged {
    [self xqqRefreshLoginInputState];
}

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

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    if (self.isKickedOff) {

        self.isKickedOff = NO;

        [XQQCommonHelper.main loyout];

        [self showKickedOffAlert];

    }

}

- (void)viewDidLoad {

    [super viewDidLoad];

    _isChinese = [XQQCommonHelper.main isChinese];

    _eogcsaioxType = XQQLoginAccountTypeEmail;

    [self updateLoginTypeBackground];

    _qoynruArea_name = kXQQDefaultAreaCode;

    _area_view_width = kXQQDefaultAreaViewWidth;

    _qoynruAreaViewWidth.constant = _area_view_width;

    _qoynruSendcodeButton.hidden = YES;

    _scrollView.delegate = self;

    [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];

    _qoynruAccountTF.delegate = self;

    _qoynruPasswordTF.delegate = self;

    _qoynruPasswordTF.returnKeyType = UIReturnKeyDone;

    [_qoynruAccountTF addTarget:self action:@selector(eogcsaioxTextField:) forControlEvents:UIControlEventEditingChanged];

    [_qoynruPasswordTF addTarget:self action:@selector(eogcsaioxTextField:) forControlEvents:UIControlEventEditingChanged];

    // 输入满足条件前登录按钮不可点

    _qoynruLoginButton.userInteractionEnabled = NO;

    _qoynruLoginTypeAButton.titleLabel.font = PINGFANG_M(20);

    _qoynruWayButton.selected = YES; // 默认密码登录

    [self qoynruType];

    [self updateADFLanguage];

    // 新增：页面初始化完成后统一计算一次输入状态
    [self xqqRefreshLoginInputState];

}

- (void)dealloc {

    NSLog(@"%@ --- dealloc", NSStringFromClass(self.class));

}

#pragma mark - UI

- (void)updateADFLanguage {

    [_qoynruLoginTypeAButton setTitle:LLLLLL(@"Tel") forState:UIControlStateNormal];

    [_qoynruLoginTypeBButton setTitle:LLLLLL(@"E-mail") forState:UIControlStateNormal];

    [_qoynruForgetPswButton setTitle:[NSString stringWithFormat:@"%@?", LLLLLL(@"ForgotPassword")] forState:UIControlStateNormal];

    [_qoynruLoginButton setTitle:LLLLLL(@"SignIn") forState:UIControlStateNormal];

    [_qoynruWayButton setTitle:LLLLLL(@"PasswordLogin") forState:UIControlStateNormal];

    [_qoynruWayButton setTitle:LLLLLL(@"CodeLogin") forState:UIControlStateSelected];

    _qoynruNoAmountL.text = (_isChinese ? @"还没账户？" : @"No account? ");

    _qoynruGoRegisterL.text = (_isChinese ? @"去注册" : @"Sign up");

    [_qoynruCustomerBtn setTitle:LLLLLL(@"CustomerService") forState:UIControlStateNormal];

}

- (void)showKickedOffAlert {

    NSString *message = _isChinese ? @"您的账号已在其他手机登录" : @"Your account has been logged in on another phone.";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:LLLLLL(@"iGotIt") style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];

}

- (void)updateLoginTypeBackground {

    _qoynruLoginTypeBgView.image = IMAGENAME((UNString(@"LoginType%ld", (long)_eogcsaioxType)));

}

- (BOOL)isPasswordMode {

    return _qoynruWayButton.selected;

}

/// 根据"手机/邮箱"和"密码/验证码"刷新输入区

- (void)qoynruType {

    [self updateSecretInputForPasswordMode:[self isPasswordMode]];

    [self updateAccountInputForType:_eogcsaioxType];

}

- (void)updateSecretInputForPasswordMode:(BOOL)passwordMode {

    _qoynruSendcodeButton.hidden = passwordMode;

    _qoynruForgetPswButton.hidden = !passwordMode;

    _qoynruEyeBtn.hidden = !passwordMode;

    if (passwordMode) {

        _qoynruPasswordTF.secureTextEntry = !_qoynruEyeBtn.selected;

        _qoynruPasswordTF.placeholder = LLLLLL(@"Password");

        _qoynruPasswordTF.keyboardType = UIKeyboardTypeDefault;

        _qoynruAasswordImgView.image = IMAGENAME(@"eogcsaioxPsw");

        _qoynruPasswordLabel.text = LLLLLL(@"Password");

    } else {

        _qoynruPasswordTF.secureTextEntry = NO;

        _qoynruPasswordTF.placeholder = LLLLLL(@"VerificationCode");

        _qoynruPasswordTF.keyboardType = UIKeyboardTypeNumberPad;

        _qoynruAasswordImgView.image = IMAGENAME(@"eogcsaioxCode2");

        _qoynruPasswordLabel.text = LLLLLL(@"Code");

        [_qoynruSendcodeButton setTitle:LLLLLL(@"ObtainCode") forState:UIControlStateNormal];

        [_qoynruSendcodeButton setTitleColor:MAINCOLOR forState:UIControlStateNormal];

    }

}

- (void)updateAccountInputForType:(NSInteger)type {

    BOOL isPhone = type == XQQLoginAccountTypePhone;

    NSString *accountText = isPhone ? LLLLLL(@"MobileNumber") : LLLLLL(@"Email");

    _qoynruAccountLabel.text = accountText;

    _qoynruAccountTF.placeholder = accountText;

    _qoynruAccountTF.keyboardType = isPhone ? UIKeyboardTypeNumberPad : UIKeyboardTypeEmailAddress;

    _qoynruAreaView.hidden = !isPhone;

    _qoynruAreaViewWidth.constant = isPhone ? _area_view_width : 0.0;

    _qoynruAreaLabel.text = isPhone ? _qoynruArea_name : @"";

    _qoynruAccountImgView.image = IMAGENAME(isPhone ? @"phoneIcon" : @"eogcsaioxEmail");

    // 当前选中的登录方式标题放大加粗（PINGFANG_* 宏自带分号，不能用在三目运算里）

    if (isPhone) {

        self.qoynruLoginTypeAButton.titleLabel.font = PINGFANG_M(20);

        self.qoynruLoginTypeBButton.titleLabel.font = PINGFANG_R(15);

    } else {

        self.qoynruLoginTypeAButton.titleLabel.font = PINGFANG_R(15);

        self.qoynruLoginTypeBButton.titleLabel.font = PINGFANG_M(20);

    }

}

- (void)updateLoginButtonEnabled:(BOOL)enabled {

    if (_qoynruLoginButton.userInteractionEnabled == enabled) {

        return;

    }

    _qoynruLoginButton.userInteractionEnabled = enabled;

    [_qoynruLoginButton setTitleColor:(enabled ? UIColor.whiteColor : MAINCOLOR) forState:UIControlStateNormal];

    [_qoynruLoginButton setBackgroundImage:IMAGENAME(enabled ? @"eogcsaioxBtnS" : @"eogcsaioxBtnN") forState:UIControlStateNormal];

}

#pragma mark - Actions

- (IBAction)eogcsaioxLogin:(UIButton *)sender {

    [self.view endEditing:YES];

    if ([self isValid]) {

        return;

    }

    // 新增：有效输入也只允许一个登录请求进入网络层
    [self xqqPrepareAccountForSubmission];
    if (![self xqqBeginLoginSubmission]) {
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    hud.label.text = _isChinese ? @"登录中..." : @"Logging in...";

    [hud showAnimated:YES];

    [self login:hud];

}

// 发送验证码

- (IBAction)eogcsaioxSendCode:(UIButton *)sender {

    [self.view endEditing:YES];

    _qoynruPasswordTF.text = @"";

    if (_eogcsaioxType == XQQLoginAccountTypePhone) {

        [XQQCommonHelper.main sendArea:_qoynruArea_name phone:_qoynruAccountTF.text button:sender];

    } else {

        [XQQCommonHelper.main sendEmailCode:_qoynruAccountTF.text button:sender];

    }

}

// 密码登录 / 验证码登录切换

- (IBAction)pswOrCodeLogin:(UIButton *)sender {

    [self.view endEditing:YES];

    sender.selected = !sender.selected;

    _qoynruPasswordTF.text = @"";

    [self qoynruType];

    // 新增：切换登录方式后立即重置提交按钮状态
    [self xqqHandleLoginModeChanged];

}

// 手机 / 邮箱切换

- (IBAction)loginType:(UIButton *)sender {

    [self.view endEditing:YES];

    if (_eogcsaioxType == sender.tag) {

        return;

    }

    _eogcsaioxType = sender.tag;

    _qoynruAccountTF.text = @"";

    _qoynruPasswordTF.text = @"";

    self.qoynruLoginTypeAButton.selected = (sender.tag == XQQLoginAccountTypePhone);

    self.qoynruLoginTypeBButton.selected = (sender.tag == XQQLoginAccountTypeEmail);

    [self updateLoginTypeBackground];

    [self qoynruType];

    // 新增：切换账号类型后重新计算输入策略
    [self xqqHandleLoginModeChanged];

}

- (IBAction)eye:(UIButton *)sender {

    [self.view endEditing:YES];

    sender.selected = !sender.selected;

    _qoynruPasswordTF.secureTextEntry = !sender.selected;

}

// tag 0 注册，其余为忘记密码

- (IBAction)registerForgetPsw:(UIButton *)sender {

    [self.view endEditing:YES];

    UIViewController *vc = (sender.tag == 0) ? XQQGNRJYDIOZRegisterVC.new : XQQGNRJYDIOZRetrievePswdVC.new;

    [self.navigationController pushViewController:vc animated:YES];

}

// 手机号码的区号

- (IBAction)phoneArea:(UIButton *)sender {

    [self.view endEditing:YES];

    XQQGNRJYDIOZAreacodeVC *vc = XQQGNRJYDIOZAreacodeVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    vc.deleagete = self;

    [self.navigationController pushViewController:vc animated:YES];

}

- (void)close {

    [self.view endEditing:YES];

}

#pragma mark - XWCountryCodeControllerDelegate

- (void)returnCountryName:(NSString *)countryName code:(NSString *)code {

    _qoynruAccountTF.text = @"";

    _qoynruArea_name = UNString(@"+%@", code);

    _qoynruAreaLabel.text = _qoynruArea_name;

    UIFont *font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:15.0];

    CGSize size = [_qoynruArea_name boundingRectWithSize:CGSizeMake(WIDTH, 8000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil].size; // 原 XQQIUEHUtilities getTextDrawingSize

    _area_view_width = size.width + kXQQAreaViewExtraWidth;

    _qoynruAreaViewWidth.constant = _area_view_width;

}

#pragma mark - 输入校验

/// 返回 YES 表示校验不通过（已提示），与调用处 `if ([self isValid]) return;` 配合

- (BOOL)isValid {

    UITextField *invalidField = nil;

    if (_qoynruAccountTF.text.length <= 0) {

        invalidField = _qoynruAccountTF;

    } else if (_qoynruPasswordTF.text.length < kXQQSecretSubmitMinLength) {

        invalidField = _qoynruPasswordTF;

    }

    if (!invalidField) {

        return NO;

    }

    [SVProgressHUD showErrorWithStatus:invalidField.placeholder];

    [SVProgressHUD dismissWithDelay:1.0];

    return YES;

}

// 输入变化时刷新登录按钮可点状态

- (void)eogcsaioxTextField:(UITextField *)textField {

    // 新增：所有输入变化统一走同一状态入口
    [self xqqRefreshLoginInputState];

}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    NSInteger length = textField.text.length - range.length + string.length;

    if (textField == _qoynruAccountTF) {

        // 新增：账号输入阶段拦截无效空白，避免提交时才处理
        if (![self xqqShouldAllowAccountReplacement:string]) {
            return NO;
        }

        return length <= [self accountMaxLength];

    }

    if (textField == _qoynruPasswordTF) {

        // 新增：密码允许空格，但不允许换行进入登录请求
        if (![self xqqShouldAllowSecretReplacement:string]) {
            return NO;
        }

        return length <= ([self isPasswordMode] ? kXQQPasswordMaxLength : kXQQCodeMaxLength);

    }

    return YES;

}

- (NSInteger)accountMaxLength {

    if (_eogcsaioxType != XQQLoginAccountTypePhone) {

        return kXQQEmailMaxLength;

    }

    return [_qoynruArea_name isEqualToString:kXQQDefaultAreaCode] ? kXQQChinaPhoneMaxLength : kXQQPhoneMaxLength;

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self.view endEditing:YES];

    return YES;

}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    [self.view endEditing:YES];

}

#pragma mark - 登录

- (void)login:(MBProgressHUD *)hud {

    WS(weakself)

    void(^errorBlock)(int errCode, NSString *message) = ^(int errCode, NSString *message) {

        dispatch_async(dispatch_get_main_queue(), ^{

            [hud hideAnimated:YES];

            [weakself xqqFinishLoginSubmission];
            // 新增：失败后恢复输入能力，允许用户直接修改后再次提交
            [weakself.view makeToast:[self localizedLoginError:message] duration:1.2 position:CSToastPositionCenter];

        });

    };

    void(^successBlock)(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode) = ^(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser, NSString *resetCode) {

        [hud hideAnimated:YES];

        [self xqqFinishLoginSubmission];
        // 新增：成功回调先结束提交状态，再沿用原有成功处理
        [self handleLoginSuccessWithUserId:userId token:token websocketToken:websocketToken];

    };

    NSString *account = _qoynruAccountTF.text;

    NSString *secret = _qoynruPasswordTF.text;

    BOOL passwordMode = [self isPasswordMode];

    if (_eogcsaioxType == XQQLoginAccountTypePhone) {

        if (passwordMode) {

            [XQQMineLogin loginWithMobile:account password:secret area:_qoynruArea_name success:^(NSString *userId, NSString *token, NSString *websocketToken, BOOL newUser) {

                successBlock(userId, token, websocketToken, newUser, nil);

            } error:errorBlock];

        } else {

            [XQQMineLogin loginWithMobile:account verifyCode:secret area:_qoynruArea_name success:successBlock error:errorBlock];

        }

    } else {

        // 邮箱登录：type 0 密码，1 验证码

        [XQQMineLogin loginWithEmail:account pswCode:secret type:(passwordMode ? 0 : 1) success:successBlock error:errorBlock];

    }

}

/// 服务端只返回中文提示，英文环境按关键词粗略翻译

- (NSString *)localizedLoginError:(NSString *)message {

    if (_isChinese) {

        return message;

    }

    if ([message containsString:@"验证码错误"]) {

        return @"Verification code error";

    }

    if ([message containsString:@"封禁"] && ![message containsString:@"错误"]) {

        return @"The user is blocked...";

    }

    return @"Error...";

}

- (void)handleLoginSuccessWithUserId:(NSString *)userId token:(NSString *)token websocketToken:(NSString *)websocketToken {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:token forKey:@"savedToken"];

    [defaults setObject:userId forKey:@"savedUserId"];

    [defaults setObject:websocketToken forKey:@"savedwebsocketToken"];

    [defaults setInteger:_eogcsaioxType forKey:kLOGIN_TYPE]; // 登录方式 0 手机号码    1 邮箱

    [defaults synchronize];

    [XQQMineProfile getUserInfo:userId success:^(XQQCUserInfo * _Nonnull userInfo) {

        [XQQMineProfile saveMyInfo:userInfo];

        [self enterMainVcCheckingLock];

    } error:^(int errCode, NSString * _Nonnull message) {

    }];

}

/// 开了安全锁先进数字密码页，验证通过再进主页

- (void)enterMainVcCheckingLock {

    LockStatus *lock = XQQODJNLockStatusManager.main.lockStatus;

    if (lock.status != 1) {

        [self enterMainVc];

        return;

    }

    [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"backgroundTime"];

    XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;

    vc.type = 5; // 5 跟 4一样的。只是有一点区别

    WS(weakself)

    [vc setPswBlock:^(NSString * _Nonnull psw) {

        // 这里只会回调 OK；ACCOUNT（切换账号）和 FORGET（清除聊天数据）在该页自行处理

        if ([psw isEqualToString:@"OK"]) {

            [weakself enterMainVc];

        }

    }];

    [self.navigationController pushViewController:vc animated:NO];

}

- (void)enterMainVc {

    // 原工程：连接 IM、按需清空聊天记录、切换到主 TabBar。IM 未迁移，改为统一收尾后关闭登录页。
    XQQCUserInfo *me = [XQQMineProfile getMyInfo];
    if (me) [XQQMineSession finishLoginWithUser:me];

}

#pragma mark - 客服

// 未登录也能联系客服：用设备信息注册一个临时账号连上 IM，再进入客服会话

- (IBAction)customerService:(UIButton *)sender {

    // 客服会话依赖消息模块（IM），第一版尚未迁移
    NSString *text = _isChinese ? @"在线客服将在后续版本开放" : @"Customer service will be available in a later version";
    [self.view makeToast:text duration:1.5 position:CSToastPositionCenter];

}

@end
