//

//  XQQMKDIOFZTProfileVC.m

//  WUHOIBDK

//

//  Created by Loooooo on 7/22/24.

//

#import "XQQMKDIOFZTProfileVC.h"

#import <MessageUI/MessageUI.h>

#import "XQQMKDIOFZTSafetyVC.h"

#import "XQQMKDIOFZTUserinfoVC.h"

#import "XQQMKDIOFZTPrivacyVC.h"

#import "XQQMKDIOFZTNoticeVC.h"

#import "XQQMKDIOFZTFontsizeVC.h"

#import "XQQMKDIOFZTLangugeVC.h"

#import "XQQMKDIOFZTAboutVC.h"

#import "XQQMKDIOFZTNormalQrcodeVC.h"

#import "XQQMKDIOFZTTextModifyVC.h"

#import "XQQMKDIOFZTUserQrcodeVC.h"

#import "XQQMKDIOFZTAvatarVC.h"

#import "XQQMKDIOFZTAppearanceVC.h"

#import "XQQMKDIOFZTUserWalletVC.h"

#import "XQQMKDIOFZTCheckInVC.h"



@interface XQQMKDIOFZTProfileVC ()

{

    BOOL _isChinese;

}

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvIconV;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvNameL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvIdL;

@property (weak, nonatomic) IBOutlet UIView *qrView;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSignL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvMbV;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvNotiL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvChatL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvPrivacyL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSecurityL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvLanguageV;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waxiouvLanguageHeigt;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvLanguageL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSkinL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvFontL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAboutL;

@property (strong, nonatomic) XQQCUserInfo *userInfo;
@property (nonatomic, assign) BOOL xqqRuntimeReady; // 新增
@property (nonatomic, assign) BOOL xqqIsNavigating; // 新增
@property (nonatomic, assign) NSInteger xqqRefreshSequence; // 新增
@property (nonatomic, assign) NSTimeInterval xqqLastActionTime; // 新增

@property IBOutlet UILabel *mywalletL;

@property IBOutlet UILabel *mycheckInL;

@end

@implementation XQQMKDIOFZTProfileVC

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.navigationController.navigationBar.subviews[0].alpha = 0.0;

    [self userdataUpdated];

    if ([NSUserDefaults.standardUserDefaults integerForKey:@"kIsReview"] == 1) {

        _waxiouvLanguageV.hidden = YES;

        _waxiouvLanguageHeigt.constant = 0.0;

    }else {

        _waxiouvLanguageV.hidden = NO;

        _waxiouvLanguageHeigt.constant = 60.0;

    }

}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    self.navigationController.navigationBar.subviews[0].alpha = 1.0;

}

- (void)viewDidLoad {

    [super viewDidLoad];

    _isChinese = [XQQCommonHelper.main isChinese];

    _waxiouvIconV.layer.cornerRadius = 35.0;

    _qrView.layer.cornerRadius = 4.0;

    _waxiouvMbV.layer.cornerRadius = 30.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:@"kUserDataUpdated" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:kUserInfoUpdated object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:kFriendListUpdated object:nil];

    [self updateADFLanguage];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateADFLanguage) name:kLanguageNoti object:nil];

}



- (void)xqqPrepareRuntimeState { // 新增
    self.xqqRuntimeReady = YES; // 新增
    self.xqqIsNavigating = NO; // 新增
    self.xqqRefreshSequence = 0; // 新增
    self.xqqLastActionTime = 0; // 新增
    _waxiouvIconV.layer.masksToBounds = YES; // 新增
    _qrView.layer.masksToBounds = YES; // 新增
    _waxiouvMbV.layer.masksToBounds = YES; // 新增
    _waxiouvSignL.numberOfLines = 2; // 新增
    _waxiouvSignL.lineBreakMode = NSLineBreakByTruncatingTail; // 新增
    [self xqqRefreshInteractionState]; // 新增
} // 新增

- (void)xqqApplyRuntimeVisibility { // 新增
    if (!self.xqqRuntimeReady) { return; } // 新增
    BOOL reviewMode = [NSUserDefaults.standardUserDefaults integerForKey:@"kIsReview"] == 1; // 新增
    _waxiouvLanguageV.hidden = reviewMode; // 新增
    _waxiouvLanguageHeigt.constant = reviewMode ? 0.0 : 60.0; // 新增
    _waxiouvLanguageL.hidden = reviewMode; // 新增
} // 新增

- (void)xqqRefreshInteractionState { // 新增
    BOOL active = self.view.window != nil; // 新增
    _waxiouvIconV.userInteractionEnabled = active; // 新增
    _qrView.userInteractionEnabled = active; // 新增
    _waxiouvMbV.userInteractionEnabled = active; // 新增
} // 新增

- (void)xqqRefreshProfileTextState { // 新增
    if (!self.userInfo) { return; } // 新增
    NSString *name = self.userInfo.displayName.length > 0 ? self.userInfo.displayName : self.userInfo.name; // 新增
    NSString *userId = self.userInfo.name.length > 0 ? self.userInfo.name : self.userInfo.userId; // 新增
    NSString *sign = [XQQUserExtraInfo mj_objectWithKeyValues:self.userInfo.extra].sign; // 新增
    _waxiouvNameL.text = name.length > 0 ? name : (_isChinese ? @"未设置昵称" : @"No name"); // 新增
    _waxiouvIdL.text = userId ?: @""; // 新增
    _waxiouvSignL.text = sign.length > 0 ? sign : (_isChinese ? @"这个用户很懒，暂无签名~" : @"This user is lazy and has no signature"); // 新增
    _waxiouvNameL.accessibilityValue = _waxiouvNameL.text; // 新增
    _waxiouvIdL.accessibilityValue = _waxiouvIdL.text; // 新增
    _waxiouvSignL.accessibilityValue = _waxiouvSignL.text; // 新增
} // 新增

- (void)xqqRefreshProfileLayoutState { // 新增
    CGFloat iconHeight = CGRectGetHeight(_waxiouvIconV.bounds); // 新增
    if (iconHeight > 0.0) { _waxiouvIconV.layer.cornerRadius = MIN(35.0, iconHeight * 0.5); } // 新增
    CGFloat cardHeight = CGRectGetHeight(_waxiouvMbV.bounds); // 新增
    if (cardHeight > 0.0) { _waxiouvMbV.layer.cornerRadius = MIN(30.0, cardHeight * 0.5); } // 新增
    CGFloat qrHeight = CGRectGetHeight(_qrView.bounds); // 新增
    if (qrHeight > 0.0) { _qrView.layer.cornerRadius = MIN(4.0, qrHeight * 0.5); } // 新增
    _waxiouvIconV.layer.masksToBounds = YES; // 新增
    _waxiouvMbV.layer.masksToBounds = YES; // 新增
    _qrView.layer.masksToBounds = YES; // 新增
} // 新增

- (void)xqqRefreshCompleteProfileState { // 新增
    if (!self.xqqRuntimeReady) { return; } // 新增
    [self xqqRefreshProfileTextState]; // 新增
    [self xqqRefreshProfileLayoutState]; // 新增
    [self xqqRefreshInteractionState]; // 新增
    [self xqqApplyRuntimeVisibility]; // 新增
} // 新增

- (BOOL)xqqCanPerformAction { // 新增
    NSTimeInterval now = NSDate.date.timeIntervalSince1970; // 新增
    if (now - self.xqqLastActionTime < 0.25) { return NO; } // 新增
    self.xqqLastActionTime = now; // 新增
    return YES; // 新增
} // 新增

- (BOOL)xqqBeginNavigation { // 新增
    if (self.xqqIsNavigating) { return NO; } // 新增
    if (![self xqqCanPerformAction]) { return NO; } // 新增
    self.xqqIsNavigating = YES; // 新增
    return YES; // 新增
} // 新增

- (void)dealloc { // 新增
    [[NSNotificationCenter defaultCenter] removeObserver:self]; // 新增
} // 新增

- (void)updateADFLanguage {

    _waxiouvNotiL.text = LLLLLL(@"NotificationSetting");

    _waxiouvChatL.text = LLLLLL(@"ChatSetting");

    _waxiouvPrivacyL.text = LLLLLL(@"PrivacySetting");

    _waxiouvSecurityL.text = LLLLLL(@"SecuritySetting");

    _waxiouvLanguageL.text = LLLLLL(@"Language");

    _waxiouvSkinL.text = LLLLLL(@"Appearance");

    _waxiouvFontL.text = LLLLLL(@"FontSize");

    _waxiouvAboutL.text = LLLLLL(@"About");

    _mywalletL.text = LLLLLL(@"MyWallet");

    _mycheckInL.text = LLLLLL(@"MyCheckIn");

//    for (NSInteger i = 0; i < self.tabBarController.viewControllers.count; i ++) {

//        NSString *title = @[LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"Community"), LLLLLL(@"Call"), LLLLLL(@"Mine"), @"", @"", @""][i];

//        UINavigationController *navc = self.tabBarController.viewControllers[i];

//        navc.title = title;

//    }

    // 新增：只在原工程的五个 tab 宿主里改 tab 标题，WorkSpace 宿主的 tab 由它自己管理
    if (![self.tabBarController isKindOfClass:NSClassFromString(@"XQQMineTabBarVC")]) return;
    for (NSInteger i = 0; i < self.tabBarController.viewControllers.count; i ++) {

        NSString *title = @[LLLLLL(@"Vault"), LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"ToolboxTab"), LLLLLL(@"Mine"), @"", @"", @""][i]; // 与 XQQWJEFDOCYTabBarVC 的 tab 顺序一致

        UINavigationController *navc = self.tabBarController.viewControllers[i];

        navc.title = title;

    }

}

- (void)userdataUpdated {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    if (userId.length == 0) { // 新增
        self.userInfo = nil; // 新增
        _waxiouvNameL.text = @""; // 新增
        _waxiouvIdL.text = @""; // 新增
        _waxiouvSignL.text = @""; // 新增
        return; // 新增
    } // 新增
    NSInteger requestSequence = ++self.xqqRefreshSequence; // 新增
    [XQQMineProfile getUserInfo:userId
                                           success:^(XQQCUserInfo * _Nonnull userInfo) {
        dispatch_async(dispatch_get_main_queue(), ^{ // 新增
            if (requestSequence != self.xqqRefreshSequence) { return; } // 新增
            if (!userInfo) { return; } // 新增
            self.userInfo = userInfo;
            [XQQMineProfile insertOrUpdateUserInfo:userInfo];
            [XQQMineProfile saveMyInfo:userInfo];
            [self xqqRefreshCompleteProfileState]; // 新增
        }); // 新增
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{ // 新增
            if (requestSequence != self.xqqRefreshSequence) { return; } // 新增
            [self xqqRefreshInteractionState]; // 新增
        }); // 新增
    }];
}

- (void)setUserInfo:(XQQCUserInfo *)userInfo {

    _userInfo = userInfo;

    [_waxiouvIconV sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages

                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}

];

    _waxiouvNameL.text = userInfo.displayName;

    _waxiouvIdL.text = userInfo.name;

    NSString *waxiouvSign = [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].sign;

    _waxiouvSignL.text = (waxiouvSign.length > 0 ? waxiouvSign : (_isChinese ? @"这个用户很懒，暂无签名~" : @"This user is lazy and has no signature"));

}

- (IBAction)waxiouvUserinfo:(UIButton *)sender {
    if (![self xqqBeginNavigation]) { return; } // 新增

    XQQMKDIOFZTUserinfoVC *vc = XQQMKDIOFZTUserinfoVC.new;

//    XQQMKDIOFZTAvatarVC *vc = XQQMKDIOFZTAvatarVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)waxiouvCopyId:(UIButton *)sender {

    if (_waxiouvIdL.text.length <= 0) {

        return;

    }

    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;

    pasteboard.string = _waxiouvIdL.text;

    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];

    [SVProgressHUD dismissWithDelay:1.0];

}

- (IBAction)waxiouvQr:(UIButton *)sender {
    if (![self xqqBeginNavigation]) { return; } // 新增

    XQQMKDIOFZTUserQrcodeVC *vc = XQQMKDIOFZTUserQrcodeVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)waxiouvSign:(UIButton *)sender {
    if (![self xqqBeginNavigation]) { return; } // 新增

    XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    vc.modifyType = Modify_Sign;

    vc.defaultValue = _waxiouvSignL.text;

    WS(weakself)

    [vc setOnModified:^(NSString * _Nonnull value) {

        weakself.waxiouvSignL.text = value;

    }];

    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)waxiouvItemAct:(UIButton *)sender {

    if (sender.tag == 0) { // 通知设置

        XQQMKDIOFZTNoticeVC *vc = XQQMKDIOFZTNoticeVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 1) { // 聊天设置

    }else if (sender.tag == 2) { // 隐私设置

        XQQMKDIOFZTPrivacyVC *vc = XQQMKDIOFZTPrivacyVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 3) { // 安全设置

        XQQMKDIOFZTSafetyVC *vc = XQQMKDIOFZTSafetyVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 4) { // 语言

        XQQMKDIOFZTLangugeVC *vc = XQQMKDIOFZTLangugeVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 5) { // 外观

        XQQMKDIOFZTAppearanceVC *vc = XQQMKDIOFZTAppearanceVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 6) { // 字体

        XQQMKDIOFZTFontsizeVC *vc = XQQMKDIOFZTFontsizeVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }else if (sender.tag == 7) { // 关于

        XQQMKDIOFZTAboutVC *vc = XQQMKDIOFZTAboutVC.new;

        vc.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:vc animated:YES];

    }

//    XQQMKDIOFZTNormalVC *vc = XQQMKDIOFZTNormalVC.new; / 通用

//    vc.hidesBottomBarWhenPushed = YES;

//    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)walletA:(UIButton *)sender {
    if (![self xqqBeginNavigation]) { return; } // 新增

    XQQMKDIOFZTUserWalletVC *vc = XQQMKDIOFZTUserWalletVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    [self.navigationController pushViewController:vc animated:YES];

}

- (IBAction)checkInA:(UIButton *)sender {
    if (![self xqqBeginNavigation]) { return; } // 新增

    XQQMKDIOFZTCheckInVC *vc = XQQMKDIOFZTCheckInVC.new;

    vc.hidesBottomBarWhenPushed = YES;

    [self.navigationController pushViewController:vc animated:YES];

}

@end
