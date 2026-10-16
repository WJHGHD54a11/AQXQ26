//
//  XQQMKDIOFZTNoticeVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/30/24.
//

#import "XQQMKDIOFZTNoticeVC.h"
#import "XQQMKDIOFZTSystemNotiVC.h"

@interface XQQMKDIOFZTNoticeVC ()

@property (weak, nonatomic) IBOutlet UISwitch *newsMessageSW;
@property (weak, nonatomic) IBOutlet UISwitch *voiceVideoSW;
@property (weak, nonatomic) IBOutlet UISwitch *senderSW;

@property (weak, nonatomic) IBOutlet UISwitch *noDisturbSW;
@property (weak, nonatomic) IBOutlet UIView *noDisturbwsedcTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *noDisturbTimeLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *saveDraftTop;
@property (weak, nonatomic) IBOutlet UISwitch *saveDraftSW;

@property (weak, nonatomic) IBOutlet UISwitch *soundSW;
@property (weak, nonatomic) IBOutlet UISwitch *vibrationSW;


@property(nonatomic, assign) BOOL isNoDisturb;
@property(nonatomic, assign) NSInteger startMins;
@property(nonatomic, assign) NSInteger endMins;


@property (weak, nonatomic) IBOutlet UILabel *unOpenL;
@property (weak, nonatomic) IBOutlet UILabel *noticeAL;
@property (weak, nonatomic) IBOutlet UILabel *noticeBL;
@property (weak, nonatomic) IBOutlet UILabel *noticeCL;
@property (weak, nonatomic) IBOutlet UILabel *noticeDL;
@property (weak, nonatomic) IBOutlet UILabel *noticeEL;
@property (weak, nonatomic) IBOutlet UILabel *noticeFL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSystemNotiL;

@property (weak, nonatomic) IBOutlet UILabel *openL;
@property (weak, nonatomic) IBOutlet UILabel *noticeGFL;
@property (weak, nonatomic) IBOutlet UILabel *noticeHL;

@end

@implementation XQQMKDIOFZTNoticeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"NotificationSetting");
    if ([XQQCommonHelper.main isChinese]) {
        
    }else {
        _unOpenL.text = @"    When the app is not open";
        _openL.text = @"    When the app open";
        
        _noticeAL.text = @"New message notification";
        _noticeBL.text = @"Voice and video call invitation alerts";
        _noticeCL.text = @"Hide sender information";
        _noticeDL.text = @"No disturbing";
        _noticeEL.text = @"Silent time period";
        _noticeFL.text = @"Save draft";
        
        _noticeGFL.text = @"Audio";
        _noticeHL.text = @"Vibration";
        
        _waxiouvSystemNotiL.text = @"System notification";
    }
    
    // 是否全局静音   YES，当前用户全局静音；NO，没有全局静音
    _newsMessageSW.on = ![XQQMineNotify isGlobalSilent];
    // 是否实时音视频通知面打扰。服务器端2021.9.20后支持分别设置通知免打扰和实时音视频免打扰  YES，当前用户音视频不通知；NO，当前用户音视频通知
    _voiceVideoSW.on = ![XQQMineNotify isVoipNotificationSilent];
    // 是否隐藏推送详情    YES，隐藏推送详情，提示“您收到一条消息”；NO，推送显示消息摘要
    _senderSW.on = ![XQQMineNotify isHiddenNotificationDetail];
    // 是否开启草稿同步    YES，同步；NO，不同步
    _saveDraftSW.on = [XQQMineNotify isEnableSyncDraft];
        
    XQQCUserInfo *userInfo = [XQQMineProfile getMyInfo];
    XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:userInfo.extra];
    _soundSW.on = (extraInfo.sound == 1);
    _vibrationSW.on = (extraInfo.shake == 1);

    NSInteger interval = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
    _startMins = 21 * 60 - interval/60; //本地21:00
    _endMins = 7 * 60 - interval/60;  //本地7:00
    if (_endMins < 0) {
        _endMins += 24 * 60;
    }
    WS(weakself)
    [XQQMineNotify getNoDisturbingTimes:^(int startMins, int endMins) {
        weakself.startMins = startMins;
        weakself.endMins = endMins;
        weakself.isNoDisturb = YES;
    }error:^(int error_code) {
        weakself.isNoDisturb = NO;
    }];
}

- (IBAction)actionSW:(UISwitch *)sender {
    WS(weakself)
    if ([sender isEqual:_newsMessageSW]) { // 新消息通知
        if (sender.on) {
            [XQQMineNotify setGlobalSilent:!sender.on success:^{
            }error:^(int error_code) {
            }];
        }else { // 关闭时 弹出提示窗
            sender.on = !sender.on;
            
            BOOL isChinese = [XQQCommonHelper.main isChinese];
            UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:(isChinese ? @"关闭通知" : @"Closure notice") message:(isChinese ? @"关闭系统通知权限将会错过消息通知" : @"Disabling the system notification permission will result in loss of message notifications") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }];
            UIAlertAction *actionLogout = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [XQQMineNotify setGlobalSilent:!sender.on success:^{
                }error:^(int error_code) {
                }];
                sender.on = !sender.on;
            }];
            [actionSheet addAction:actionCancel];
            [actionSheet addAction:actionLogout];
            [self presentViewController:actionSheet animated:YES completion:nil];
        }
    }else if ([sender isEqual:_voiceVideoSW]) { // 语音和视频通话邀请提醒
        [XQQMineNotify setVoipNotificationSilent:!sender.on success:^{
        }error:^(int error_code) {
        }];
    }else if ([sender isEqual:_senderSW]) { // 隐藏发送人信息
        [XQQMineNotify setHiddenNotificationDetail:!sender.on success:^{
        } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.senderSW.on = !weakself.senderSW.on;
            });
        }];
    }else if ([sender isEqual:_saveDraftSW]) { // 同步草稿
        [XQQMineNotify setEnableSyncDraft:sender.on success:^{
        }error:^(int error_code) {
        }];
    }else if ([sender isEqual:_noDisturbSW]) { // 免打扰
        if (sender.on) {
            [XQQMineNotify setNoDisturbingTimes:(int)_startMins endMins:(int)_endMins success:^{ // 修改免打扰时间
                weakself.isNoDisturb = YES;
            }error:^(int error_code) {
                weakself.isNoDisturb = NO;
            }];
        }else {
            [XQQMineNotify clearNoDisturbingTimes:^{ // 取消免打扰时间
                weakself.isNoDisturb = NO;
            }error:^(int error_code) {
                weakself.isNoDisturb = NO;
            }];
        }
    }else if ([sender isEqual:_soundSW]) { // 声音

        [self requestStateSW:sender params:@{@"sound":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_soundSW]) { // 震动
        
        [self requestStateSW:sender params:@{@"shake":@(sender.on ? 1 : 0)}];
    }
}

- (void)requestStateSW:(UISwitch *)sw params:(NSDictionary *)params {
    [XQQMineProfile userExtra:params success:^ {
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}

- (IBAction)noDisturbTime:(UIButton *)sender {
    XQQOHJNSelectNoDisturbingTimeVC *vc = XQQOHJNSelectNoDisturbingTimeVC.new;
    vc.startMins = _startMins;
    vc.endMins = _endMins;
    WS(weakself)
    vc.onSelectTime = ^(NSInteger startMins, NSInteger endMins) {
        weakself.startMins = startMins;
        weakself.endMins = endMins;
        
        [XQQMineNotify setNoDisturbingTimes:(int)weakself.startMins endMins:(int)weakself.endMins success:^{
            weakself.isNoDisturb = YES;
        } error:^(int error_code) {
        }];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)waxiouvSystemNoti:(UIButton *)sender {
    XQQMKDIOFZTSystemNotiVC *vc = XQQMKDIOFZTSystemNotiVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}




- (void)setIsNoDisturb:(BOOL)isNoDisturb {
    _isNoDisturb = isNoDisturb;
    
    if (_isNoDisturb) {
        _noDisturbSW.on = YES;
        _noDisturbwsedcTimeLabel.hidden = NO;
        NSInteger interval = [NSTimeZone.systemTimeZone secondsFromGMTForDate:NSDate.date];
        _noDisturbTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld-%02ld:%02ld", (_startMins/60+interval/3600)%24, _startMins%60, (_endMins/60+interval/3600)%24, _endMins%60];
        _saveDraftTop.constant = 50.0;
    }else {
        _noDisturbSW.on = NO;
        _noDisturbwsedcTimeLabel.hidden = YES;
        _saveDraftTop.constant = 0.0;
    }
}

@end
