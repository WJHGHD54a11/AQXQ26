//
//  XQQMKDIOFZTClearChatVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/7/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTClearChatVC.h"

@interface XQQMKDIOFZTClearChatVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *forgotL;
@property (weak, nonatomic) IBOutlet UILabel *forgotDescL;

@property (weak, nonatomic) IBOutlet UIButton *clearButton;

@end

@implementation XQQMKDIOFZTClearChatVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _clearButton.layer.cornerRadius = 25.0;
    
    _isChinese = [XQQCommonHelper.main isChinese];
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    if (_isChinese) {
        self.navigationItem.title = @"忘记数字密码";
    }else {
        self.navigationItem.title = @"Forgot digital password";
        _forgotL.text = @"Forgot your digital password?";
        _forgotDescL.text = @"If you forget the security lock password, you will need to clear the chat data of your current account and log in to your account again.";
        
        [_clearButton setTitle:@"Clear data" forState:UIControlStateNormal];
    }
}

- (IBAction)clear:(UIButton *)sender {
    WS(weakself)
    NSString *title = @"再次确定后将会清除当前账户的所有聊天数据";
    if (_isChinese) {
    }else {
        title = @"Once confirmed, all chat data of the current account will be cleared.";
    }
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *okAct = [UIAlertAction actionWithTitle:LLLLLL(@"OK") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [NSUserDefaults.standardUserDefaults setInteger:100 forKey:UNString(@"isEnableClear%@", [NSUserDefaults.standardUserDefaults stringForKey:@"savedUserId"])]; // 记录是否可以清除聊天数据  在登录的地方  会话链接成功后进行清除、
        [NSUserDefaults.standardUserDefaults synchronize];
        
        [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"status"];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = LLLLLL(@"OperationInProgress");
        [hud showAnimated:YES];

        [XQQMineAPI requestUrl:@"/device_lock/set_status" params:@{@"status":@(0)} success:^(NSDictionary * _Nonnull dict) {
            [hud hideAnimated:YES];
            [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"status"];
            if (weakself.type == 4) {
                if (weakself.clearBlock) {
                    weakself.clearBlock();
                }
            }else if (weakself.type == 5) {
                for (UIViewController *vc in self.navigationController.viewControllers) {
                    if ([vc isKindOfClass:NSClassFromString(@"XQQGNRJYDIOZLoginVC")]) {
                        [self.navigationController popToViewController:vc animated:YES];
                        break;
                    }
                }
            }else if (weakself.type == 6) {
                if (weakself.clearBlock) {
                    weakself.clearBlock();
                }
            }
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
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
    }];
    [actionSheet addAction:cancelAct];
    [actionSheet addAction:okAct];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

@end
