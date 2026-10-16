//
//  XQQMKDIOFZTSafetyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/8/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTSafetyVC.h"

#import "XQQMKDIOFZTDestroyVC.h"
#import "XQQMKDIOFZTTextModifyVC.h"
#import "XQQMKDIOFZTLoginpswVC.h"
#import "XQQMKDIOFZTLockVC.h"

#import "XQQMKDIOFZTModityPswVC.h"
#import "XQQMKDIOFZTMobileEmailVerityVC.h"
#import "XQQMKDIOFZTMobileBindingVC.h"
#import "XQQMKDIOFZTEmailBindingVC.h"
#import "XQQMKDIOFZTDeviceVC.h"
#import <objc/runtime.h> // 新增：加载开始时间挂在关联对象上

@interface XQQMKDIOFZTSafetyVC ()

@property (weak, nonatomic) IBOutlet UILabel *loginPswLabel;
@property (weak, nonatomic) IBOutlet UIImageView *loginPswRedView;

@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *phoneRedView;

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *emailRedView;

@property (nonatomic, strong) XQQCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *loginPswL;
@property (weak, nonatomic) IBOutlet UILabel *phoneL;
@property (weak, nonatomic) IBOutlet UILabel *emailL;

@property (weak, nonatomic) IBOutlet UILabel *equipmentL;
@property (weak, nonatomic) IBOutlet UILabel *safetyLockL;
@property (weak, nonatomic) IBOutlet UILabel *clearAccountL;
@property (weak, nonatomic) IBOutlet UILabel *deactivateAccountL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAccountSetL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvOtherSetL;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvLogoutBtn;

@end

// 新增：安全设置页的显示检查与操作记录，只读取、不修改界面和流程，实现在文件尾部
@interface XQQMKDIOFZTSafetyVC (XQQSafetyCheck)
- (void)xqq_checkMobileMasking;                          // 新增
- (void)xqq_checkEmailMasking;                           // 新增
- (void)xqq_recordModifyNotification:(NSNotification *)noti; // 新增
- (void)xqq_recordEvent:(NSString *)event detail:(nullable NSString *)detail; // 新增
- (void)xqq_markProfileLoadStart;                        // 新增
- (void)xqq_recordProfileLoaded;                         // 新增
@end

@implementation XQQMKDIOFZTSafetyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
//    _userInfo = [XQQMineProfile getUserInfo:savedUserId];
    
    [self xqq_markProfileLoadStart]; // 新增
    [SVProgressHUD show];
    [XQQMineProfile getUserSelf:savedUserId
                                       success:^(XQQCUserInfo * _Nonnull userInfo) {
        [self xqq_recordProfileLoaded]; // 新增
        [SVProgressHUD dismiss];
        self.userInfo = userInfo;
        
        [XQQMineProfile insertOrUpdateUserInfo:userInfo];
        [self setMobile];
        [self setEmail];
        [self setPassword];
    } error:^(int errCode, NSString * _Nonnull message) {
        [self xqq_recordEvent:@"profileLoadFailed" detail:[NSString stringWithFormat:@"code=%d", errCode]]; // 新增
    }];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:@"kUserDataUpdated" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(modityData:) name:kMODITY_MOBILE_EMAIL_NOTI object:nil];
    
    [self updateADFLanguage];
    
    _waxiouvLogoutBtn.layer.cornerRadius = 15.0;
}


//LLLLLL(@"Logout");
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"SecuritySetting");
    _loginPswL.text = LLLLLL(@"LoginPassword");
    _phoneL.text = LLLLLL(@"MobileNumbers");
    _emailL.text = LLLLLL(@"E-mail");
    _equipmentL.text = LLLLLL(@"Equipment");
    _safetyLockL.text = LLLLLL(@"SafetyLock");
    _clearAccountL.text = LLLLLL(@"ClearAccount");
    _deactivateAccountL.text = LLLLLL(@"DeactivateAccount");
    
    _waxiouvAccountSetL.text = LLLLLL(@"AccountSetting");
    _waxiouvOtherSetL.text = LLLLLL(@"OtherSetting");
    [_waxiouvLogoutBtn setTitle:LLLLLL(@"Logout") forState:UIControlStateNormal];
}

- (void)userdataUpdated {
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    [XQQMineProfile getUserInfo:savedUserId refresh:YES success:^(XQQCUserInfo * _Nonnull userInfo) {
        self.userInfo = userInfo;
        [XQQMineProfile insertOrUpdateUserInfo:userInfo];
        [self setMobile];
        [self setEmail];
        [self setPassword];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [self xqq_recordEvent:@"profileRefreshFailed" detail:[NSString stringWithFormat:@"code=%d", errorCode]]; // 新增
    }];
}
- (void)setMobile {
    [self xqq_checkMobileMasking]; // 新增
    if (_userInfo.mobile.length > 0) {
        _phoneRedView.hidden = YES;
        
        NSArray *phones = [_userInfo.mobile componentsSeparatedByString:@" "];
        NSString *mobile = phones.lastObject;
        NSMutableString *star = NSMutableString.new;
        for (NSInteger i = 0; i < mobile.length-7; i ++) {
            [star appendString:@"*"];
        }
        _phoneLabel.text = [NSString stringWithFormat:@"%@ %@",self.userInfo.area, [mobile stringByReplacingCharactersInRange:NSMakeRange(3, mobile.length - 7) withString:UNString(@" %@ ", star)]];
    }else {
        _phoneLabel.text = LLLLLL(@"NotYetBound");
        _phoneRedView.hidden = NO;
    }
}
- (void)setEmail {
    [self xqq_checkEmailMasking]; // 新增
    if (_userInfo.email.length > 0) {
        _emailRedView.hidden = YES;
        NSArray *emails = [_userInfo.email componentsSeparatedByString:@"@"];
        NSString *emailFront = emails.firstObject; // 类似于->Loooooo
        if (emailFront.length <= 4) {
            if (emailFront.length <= 2) {
                _emailLabel.text = _userInfo.email;
            }else {
                _emailLabel.text = [NSString stringWithFormat:@"%@**%@@%@",[emailFront substringToIndex:1], [emailFront substringFromIndex:(emailFront.length-1)], emails.lastObject];
            }
        }else {
            _emailLabel.text = [NSString stringWithFormat:@"%@****%@@%@",[emailFront substringToIndex:2], [emailFront substringFromIndex:(emailFront.length-2)], emails.lastObject];
        }
    }else {
        _emailLabel.text = LLLLLL(@"NotYetBound");
        _emailRedView.hidden = NO;
    }
}
- (void)setPassword {
    if (self.userInfo.password) {
        _loginPswLabel.text = LLLLLL(@"AlreadySet");
        _loginPswRedView.hidden = YES;
    }else {
        _loginPswLabel.text = LLLLLL(@"NotSet");
        _loginPswRedView.hidden = NO;
    }
}
- (void)modityData:(NSNotification *)noti {
    [self xqq_recordModifyNotification:noti]; // 新增
    if ([noti.object[@"mobile"] length]) {
        _userInfo.mobile = noti.object[@"mobile"];
        self.userInfo.area = [_userInfo.mobile componentsSeparatedByString:@" "][0];
        [self setMobile];
    }
    if ([noti.object[@"email"] length]) {
        _userInfo.email = noti.object[@"email"];
        [self setEmail];
    }
    if ([noti.object[@"loginPsw"] integerValue] == 1) {
        [self setPassword];
    }
}

- (IBAction)loginPsw:(UIButton *)sender {
    if (_userInfo.password) { // 已设置了密码
        XQQMKDIOFZTModityPswVC *vc = XQQMKDIOFZTModityPswVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }else { // 未设置密码
        XQQMKDIOFZTLoginpswVC *vc = XQQMKDIOFZTLoginpswVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)phone:(UIButton *)sender {
    if (_userInfo.mobile.length > 0) {
        XQQMKDIOFZTMobileEmailVerityVC *vc = XQQMKDIOFZTMobileEmailVerityVC.new;
        vc.type = 0;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        XQQMKDIOFZTMobileBindingVC *vc = XQQMKDIOFZTMobileBindingVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }
//    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
//    vc.modifyType = Modify_Mobile;
//    vc.defaultValue = (_userInfo.mobile.length > 0) ? _userInfo.mobile : @"";
//    WS(weakself)
//    [vc setOnModified:^(NSString * _Nonnull value) {
//        weakself.phoneLabel.text = value;
//    }];
//    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)email:(UIButton *)sender {
    if (_userInfo.email.length > 0) {
        XQQMKDIOFZTMobileEmailVerityVC *vc = XQQMKDIOFZTMobileEmailVerityVC.new;
        vc.type = 1;
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        XQQMKDIOFZTEmailBindingVC *vc = XQQMKDIOFZTEmailBindingVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }
//    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
//    vc.modifyType = Modify_Email;
//    vc.defaultValue = (_userInfo.email.length > 0) ? _userInfo.email : @"";
//    WS(weakself)
//    [vc setOnModified:^(NSString * _Nonnull value) {
//        weakself.emailLabel.text = value;
//        weakself.emailRedView.hidden = YES;
//    }];
//    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)device:(UIButton *)sender {
    XQQMKDIOFZTDeviceVC *vc = XQQMKDIOFZTDeviceVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)safetyLock:(UIButton *)sender {
    XQQMKDIOFZTLockVC *vc = XQQMKDIOFZTLockVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)clearAccount:(UIButton *)sender {
    XQQMKDIOFZTDestroyVC *destroyVC = XQQMKDIOFZTDestroyVC.new;
    [self.navigationController pushViewController:destroyVC animated:YES];
}

//删除所有消息
- (IBAction)waxiouvClearAccount:(UIButton *)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Record_save_time_alert_title") message:LLLLLL(@"Delete_all_message_alert_info") preferredStyle:UIAlertControllerStyleAlert];
    [actionSheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // 原逻辑：遍历全部会话 → 删除定时删除任务 → 清未读 → 删除会话及消息，已收进 clearAllConversations
        [self xqq_recordEvent:@"clearAllMessages" detail:nil]; // 新增
        [XQQMineRelation clearAllConversations];
       
    }]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (IBAction)waxiouvLogout:(UIButton *)sender {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"Quit") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionLogout = [UIAlertAction actionWithTitle:LLLLLL(@"Logout") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self xqq_recordEvent:@"logout" detail:nil]; // 新增
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedwebsocketToken"];
        [XQQMineAccount clearAppServiceAuthInfos];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [XQQCommonHelper.main loyout];
        //退出后就不需要推送了，第一个参数为YES
        //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
        [XQQMineAccount disconnect:YES clearSession:NO];
        [XQQMineAccount disconnect:YES clearSession:NO];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastLoadRemoteMessageTs"];
    }];
    
    UIAlertAction *actionDestroy = [UIAlertAction actionWithTitle:LLLLLL(@"DestroyAccount") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        XQQMKDIOFZTDestroyVC *destroyVC = [[XQQMKDIOFZTDestroyVC alloc] init];
        [self.navigationController pushViewController:destroyVC animated:YES];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionLogout];
    [actionSheet addAction:actionDestroy];
    [actionSheet addAction:actionCancel];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
}



- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}


@end

#pragma mark - 新增：显示检查与操作记录

// 新增：以下检查只在 Debug 下输出日志，不修改界面和流程。
// 涉及手机号、邮箱，日志里只打长度和检查结果，不打内容
@implementation XQQMKDIOFZTSafetyVC (XQQSafetyCheck)

// 新增：统一的日志出口
- (void)xqq_recordEvent:(NSString *)event detail:(nullable NSString *)detail {
#ifdef DEBUG
    NSLog(@"[Safety] %@%@", event, detail.length ? [@" " stringByAppendingString:detail] : @"");
#endif
}

// 新增：setMobile 打码前检查手机号。打码逻辑取空格后最后一段，保留前 3 位和后 4 位：
// - 这一段不足 7 位时，mobile.length - 7 按无符号数算会变成极大值，for 循环停不下来，
//   接着 NSMakeRange 越界崩溃（资料里的手机号格式异常时会发生）
// - 没有空格分隔区号时，界面上"区号"位置显示的是整段号码
- (void)xqq_checkMobileMasking {
    NSString *mobile = self.userInfo.mobile;
    if (mobile.length == 0) {
        return;
    }
    NSString *number = [mobile componentsSeparatedByString:@" "].lastObject;
    BOOL willCrash = number.length < 7;
    BOOL hasArea = [mobile containsString:@" "];
    BOOL areaLooksLikeNumber = self.userInfo.area.length >= 7;
    if (willCrash || !hasArea || areaLooksLikeNumber) {
        [self xqq_recordEvent:@"mobileMaskIssue"
                       detail:[NSString stringWithFormat:@"numberLength=%lu willCrash=%d hasArea=%d areaLength=%lu",
                               (unsigned long)number.length, willCrash, hasArea, (unsigned long)self.userInfo.area.length]];
    }
}

// 新增：setEmail 打码前检查邮箱：没有 @ 时 firstObject 和 lastObject 是同一段，
// 显示成"前两位****后两位@整个邮箱"，等于没打码；多个 @ 时 @ 后面只显示最后一段
- (void)xqq_checkEmailMasking {
    NSString *email = self.userInfo.email;
    if (email.length == 0) {
        return;
    }
    NSUInteger atCount = [email componentsSeparatedByString:@"@"].count - 1;
    if (atCount != 1) {
        [self xqq_recordEvent:@"emailMaskIssue"
                       detail:[NSString stringWithFormat:@"length=%lu atCount=%lu shownUnmasked=%d",
                               (unsigned long)email.length, (unsigned long)atCount, atCount == 0]];
    }
}

// 新增：从绑定 / 修改页回来的通知：记下带回了哪些字段。
// 手机号不含空格时，modityData: 会把整段号码当成区号，界面上显示出完整号码
- (void)xqq_recordModifyNotification:(NSNotification *)noti {
    NSDictionary *info = [noti.object isKindOfClass:NSDictionary.class] ? noti.object : nil;
    NSString *mobile = info[@"mobile"];
    NSString *detail = [NSString stringWithFormat:@"keys=%@ mobileHasArea=%@",
                        [info.allKeys componentsJoinedByString:@","] ?: @"",
                        mobile.length ? ([mobile containsString:@" "] ? @"yes" : @"no") : @"-"];
    [self xqq_recordEvent:@"modifyNotification" detail:detail];
}

// 新增：进入页面拉取自己的资料：记下开始时间
- (void)xqq_markProfileLoadStart {
    objc_setAssociatedObject(self, @selector(xqq_markProfileLoadStart), @(CACurrentMediaTime()), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 新增：资料返回后记下耗时。失败时原来的回调是空的，加载框不会收起，
// 失败会由 profileLoadFailed 记下
- (void)xqq_recordProfileLoaded {
    NSNumber *start = objc_getAssociatedObject(self, @selector(xqq_markProfileLoadStart));
    [self xqq_recordEvent:@"profileLoaded"
                   detail:start ? [NSString stringWithFormat:@"%.0fms", (CACurrentMediaTime() - start.doubleValue) * 1000.0] : nil];
}

@end
