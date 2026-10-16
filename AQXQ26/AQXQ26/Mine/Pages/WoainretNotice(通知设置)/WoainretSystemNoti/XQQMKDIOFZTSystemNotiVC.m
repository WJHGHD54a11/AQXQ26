//
//  XQQMKDIOFZTSystemNotiVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "XQQMKDIOFZTSystemNotiVC.h"

@interface XQQMKDIOFZTSystemNotiVC ()

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAllowNotiL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvQuanxianV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvNotiQuanxL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvJiaobL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvXuanfuL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvXuanfuDescL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvAudioL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvVibrationL;

@property (weak, nonatomic) IBOutlet UISwitch *waxiouvYXTZSw;

@property (weak, nonatomic) IBOutlet UISwitch *waxiouvZMJBSw;
@property (weak, nonatomic) IBOutlet UISwitch *waxiouvXFTZSw;
@property (weak, nonatomic) IBOutlet UISwitch *waxiouvSYSw;
@property (weak, nonatomic) IBOutlet UISwitch *waxiouvZDSw;

@end

@implementation XQQMKDIOFZTSystemNotiVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"系统通知";
    }else {
        self.navigationItem.title = @"System notification";
        
        _waxiouvAllowNotiL.text = @"Allow notifications";
        
        _waxiouvNotiQuanxL.text = @"Notification permission setting";
        _waxiouvJiaobL.text = @"Table corner";
        _waxiouvXuanfuL.text = @"Suspension notice";
        _waxiouvXuanfuDescL.text = @"Allows notifications to pop up at the top of the screen";
        _waxiouvAudioL.text = @"Audio";
        _waxiouvVibrationL.text = @"Vibration";
    }
    
    XQQCUserInfo *userInfo = [XQQMineProfile getMyInfo];
    XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra];
    _waxiouvSYSw.on = (extraInfo.sound == 1);
    _waxiouvZDSw.on = (extraInfo.shake == 1);
    
    // 0730
    _waxiouvYXTZSw.on = ![NSUserDefaults.standardUserDefaults boolForKey:kIsAllowNotification];
    _waxiouvQuanxianV.hidden = !_waxiouvYXTZSw.on;
    _waxiouvZMJBSw.on = ![NSUserDefaults.standardUserDefaults boolForKey:kDesktopCornerMark];
    _waxiouvXFTZSw.on = ![NSUserDefaults.standardUserDefaults boolForKey:kSuspensionNotice];
}

- (IBAction)waxiouvYXTZ:(UISwitch *)sender {
    _waxiouvQuanxianV.hidden = !sender.on;
    [NSUserDefaults.standardUserDefaults setBool:!sender.on forKey:kIsAllowNotification];
    [NSUserDefaults.standardUserDefaults synchronize];
}


// 通知权限设置
- (IBAction)waxiouvTZQXSetting:(UISwitch *)sender {
    if ([sender isEqual:_waxiouvZMJBSw]) {
        [NSUserDefaults.standardUserDefaults setBool:!sender.on forKey:kDesktopCornerMark];
        [NSUserDefaults.standardUserDefaults synchronize];
    }else if ([sender isEqual:_waxiouvXFTZSw]) {
        [NSUserDefaults.standardUserDefaults setBool:!sender.on forKey:kSuspensionNotice];
        [NSUserDefaults.standardUserDefaults synchronize];
    }else if ([sender isEqual:_waxiouvSYSw]) {
        [self requestStateSW:sender params:@{@"sound":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_waxiouvZDSw]) {
        [self requestStateSW:sender params:@{@"shake":@(sender.on ? 1 : 0)}];
    }
}

- (void)requestStateSW:(UISwitch *)sw params:(NSDictionary *)params {
    [XQQMineProfile userExtra:params success:^ {
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}


@end
