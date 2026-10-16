//
//  XQQMKDIOFZTAboutVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/24/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTAboutVC.h"

#import "XQQMKDIOFZTWebviewVC.h"
#import "XQQMKDIOFZTFeedbackVC.h"
#import "XQQGNRJYDIOZProtocolVC.h"

@interface XQQMKDIOFZTAboutVC ()

@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvJCGXL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvYHFWXYL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvYSZCL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvFLSML;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvGWL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvSYBZL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvYJFKL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvSJQLL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvWebsiteL;

@end

@implementation XQQMKDIOFZTAboutVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _logoView.layer.cornerRadius = 20.0;
    
    [self updateADFLanguage];
    
    _versionLabel.text = UNString(@"V%@", VersionNUM);
}

- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"About");
    _nameLabel.text = LLLLLL(@"CFBundleName");
    
    _waxiouvYHFWXYL.text = LLLLLL(@"UserAgreement");
    _waxiouvYSZCL.text = LLLLLL(@"PrivacyPolicy");
    
    _waxiouvGWL.text = LLLLLL(@"OfficialWebsite");
    _waxiouvSYBZL.text = LLLLLL(@"UseHelp");
    _waxiouvYJFKL.text = LLLLLL(@"Feedback");
    _waxiouvSJQLL.text = LLLLLL(@"ClearCache");
    
    if ([XQQCommonHelper.main isChinese]) {
    }else {
        _waxiouvJCGXL.text = @"Check for updates";
        _waxiouvFLSML.text = @"Legal statement";
    }
    
    NSString *websiteUrl = [NSUserDefaults.standardUserDefaults objectForKey:([XQQCommonHelper.main isChinese] ? kWebsiteUrlChinese : kWebsiteUrlEnglish)];
    if (websiteUrl.length > 0) {
        _waxiouvWebsiteL.text = websiteUrl;
    }else {
        _waxiouvWebsiteL.text = LLLLLL(@"OFFICIAL_WEBSITE");
    }
}

- (IBAction)version:(UIButton *)sender {
    WS(weakself)
    [XQQCommonHelper.main updateAppSuccess:^(BOOL isUpdate) {
        if (!isUpdate) {
            [self.view makeToast:LLLLLL(@"NoNewVersionAvailable") duration:1 position:CSToastPositionCenter];
        }else {
            weakself.versionLabel.text = UNString(@"V%@", XQQCommonHelper.main.iosVersion);
        }
    }];
}

// 0  QXQ官网    1 使用帮助  2 用户服务协议  3 隐私协议  4 法律申明
- (IBAction)waxiouvServicePrivateFalvs:(UIButton *)sender {
    if (sender.tag == 0) { // 用户服务协议
//        XQQGNRJYDIOZProtocolVC *vc = XQQGNRJYDIOZProtocolVC.new;
//        vc.eogcsaioxType = 0;
//        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 1) { // 隐私政策
//        XQQGNRJYDIOZProtocolVC *vc = XQQGNRJYDIOZProtocolVC.new;
//        vc.eogcsaioxType = 1;
//        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 2) { // 法律申明
        
    }
    XQQMKDIOFZTWebviewVC *vc = XQQMKDIOFZTWebviewVC.new;
    vc.type = sender.tag + 2;
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)waxiouvGWUserFeedbackClears:(UIButton *)sender {
    if (sender.tag <= 1) {
        XQQMKDIOFZTWebviewVC *vc = XQQMKDIOFZTWebviewVC.new;
        vc.type = sender.tag;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 2) {
        XQQMKDIOFZTFeedbackVC *vc = XQQMKDIOFZTFeedbackVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 3) {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:LLLLLL(@"ClearCache") message:([XQQCommonHelper.main isChinese] ? @"该操作会将缓存数据全部清除，且无法恢复，是否继续？" : @"This operation will clear all cached data and cannot be restored. Do you want to continue?") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        WS(weakself)
        UIAlertAction *actionClear = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
            hud.label.text = LLLLLL(@"OperationInProgress");
            [hud showAnimated:YES];
            WS(weakself)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [XQQMineRelation clearAllMessages:YES];
                [hud hideAnimated:YES];
                [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
            });
        }];
        [actionSheet addAction:actionCancel];
        [actionSheet addAction:actionClear];
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}




- (IBAction)share:(UIButton *)sender {
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[_logoView.image, LLLLLL(@"CFBundleName")] applicationActivities:nil];
    [self presentViewController:avc animated:YES completion:nil];
}

@end
