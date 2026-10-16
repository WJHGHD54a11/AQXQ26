//
//  XQQMKDIOFZTLockVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTLockVC.h"

#import "XQQMKDIOFZTNumberVC.h"

#import "XQQODJNMessageBurnTimePopView.h"

@interface XQQMKDIOFZTLockVC ()
{
    NSInteger _lockSelectIndex;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UISwitch *lockSW;

@property (weak, nonatomic) IBOutlet UIView *pswBgView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (nonatomic, strong) NSMutableArray *lockTimes;


@property (weak, nonatomic) IBOutlet UILabel *descL;
@property (weak, nonatomic) IBOutlet UILabel *safetyLockL;
@property (weak, nonatomic) IBOutlet UILabel *automaticLockingL;
@property (weak, nonatomic) IBOutlet UILabel *modityL;
@property (weak, nonatomic) IBOutlet UILabel *forgotL;

@end

@implementation XQQMKDIOFZTLockVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    [self initData];
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"SafetyLock");
    _safetyLockL.text = LLLLLL(@"SafetyLock");
    
    if (_isChinese) {
        
    }else {
        _descL.text = @"After opening, when the small circle of the ball exceeds the set time in the background, the gesture password needs to be set when opening\n* For the privacy of your data, if you forget your password when launching the ball circle, you may need to clear your account's chat data in order to continue using it.";
        _automaticLockingL.text = @"Automatic locking";
        _modityL.text = @"Modify digital password";
        _forgotL.text = @"Forgot digital password";
    }
}

- (void)initData {
    LockStatus *lockStatus = XQQODJNLockStatusManager.main.lockStatus;
    
    _lockSW.on = lockStatus.status;
    _pswBgView.hidden = !_lockSW.on;
    
    BOOL isContain = NO;
    for (NSNumber *number in LOCK_TIMES) {
        if (lockStatus.waitTime == number.integerValue) {
            isContain = YES;
            break;
        }
    }
    if (isContain) {
        _lockSelectIndex = [LOCK_TIMES indexOfObject:@(lockStatus.waitTime)];
        _timeLabel.text = [NSString stringWithFormat:@"%@ %@",LLLLLL(@"Backstage"), [self tranfrom:lockStatus.waitTime]];
    }else {
        _lockSelectIndex = 0;
        _timeLabel.text = [NSString stringWithFormat:@"%@ %@",LLLLLL(@"Backstage"), [self tranfrom:[LOCK_TIMES[_lockSelectIndex] integerValue]]];
    }
}

- (IBAction)lock:(UISwitch *)sender {
    WS(weakself)
    if (sender.on) {
        NSString *title = @"开启安全锁后，如果您在启动QXQ IM时忘记了密码，需要清除账户聊天记录才能继续使用，请牢记您的安全锁密码";
        if (_isChinese) {
        }else {
            title = @"After the security lock is enabled, if you forget your password at startup and need to clear your account chat history in order to continue using it, please remember your security lock password.";
        }
        UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            sender.on = NO;
            weakself.pswBgView.hidden = YES;
        }];
        UIAlertAction *okAct = [UIAlertAction actionWithTitle:(_isChinese ? @"确定开启" : @"Open") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
            vc.type = 0;
            [vc setPswBlock:^(NSString * _Nonnull psw) {
                [weakself initData];
            }];
            [self.navigationController pushViewController:vc animated:YES];
            sender.on = NO;
        }];
        [actionSheet addAction:cancelAct];
        [actionSheet addAction:okAct];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }else {
        XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
        vc.type = 1;
        [vc setPswBlock:^(NSString * _Nonnull psw) {
            weakself.lockSW.on = NO;
            weakself.pswBgView.hidden = YES;
        }];
        [self.navigationController pushViewController:vc animated:YES];
        sender.on = YES;
    }
}

- (IBAction)modity:(UIButton *)sender {
    XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
    vc.type = 2;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)forget:(UIButton *)sender {
    XQQMKDIOFZTNumberVC *vc = XQQMKDIOFZTNumberVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)requestLockTime:(NSInteger)row {
    NSNumber *number = LOCK_TIMES[row];
    WS(weakself)
    [XQQMineAPI requestUrl:@"/device_lock/set_status" params:@{@"status":@(_lockSW.on ? 1 : 0), @"waitTime":number} success:^(NSDictionary * _Nonnull dict) {
        self->_lockSelectIndex = row;
        
        [XQQODJNLockStatusManager.main reWriteLockInfo:number ForKey:@"waitTime"];
    } error:^(int errCode, NSString * _Nonnull message) {
        weakself.timeLabel.text = [NSString stringWithFormat:@"%@ %@",LLLLLL(@"Backstage"), [weakself tranfrom:XQQODJNLockStatusManager.main.lockStatus.waitTime]];
        NSString *text = @"";
        if (self->_isChinese) {
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

- (IBAction)lockin:(UIButton *)sender { // 锁定
    XQQODJNMessageBurnTimePopView *popView = [[XQQODJNMessageBurnTimePopView alloc] init];
    WS(weakself)
    [popView setTimeBlock:^(NSInteger row) {
        [weakself requestLockTime:row];
        weakself.timeLabel.text = [NSString stringWithFormat:@"%@ %@",LLLLLL(@"Backstage"), weakself.lockTimes[row]];
    }];
    [popView showIndex:_lockSelectIndex datas:self.lockTimes];
}
// @[@1, @5, @10, @(15), @(60), @(5*60), @(12*60)]
- (NSMutableArray *)lockTimes {
    if (!_lockTimes) {
        _lockTimes = NSMutableArray.new;
        for (NSNumber *number in LOCK_TIMES) {
            [_lockTimes addObject:[self tranfrom:number.integerValue]];
        }
    }return _lockTimes;
}

- (NSString *)tranfrom:(NSInteger)min {
    NSString *value = @"";
    if (min < 60) {
        value = [NSString stringWithFormat:@"%ld%@",min, (_isChinese?@"分钟":@" min")];
    }else if (min < 24*60) {
        value = [NSString stringWithFormat:@"%ld%@",min/60, (_isChinese?@"小时":@" hour")];
    }
    return value;
}

@end
