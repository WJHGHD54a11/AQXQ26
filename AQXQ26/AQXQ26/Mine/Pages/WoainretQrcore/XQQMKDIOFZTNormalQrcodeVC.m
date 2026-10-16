//
//  XQQMKDIOFZTNormalQrcodeVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/14/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTNormalQrcodeVC.h"


@interface XQQMKDIOFZTNormalQrcodeVC ()
{
    NSString *_qrStr;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *qrcodeBgView;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (weak, nonatomic) IBOutlet UILabel *grouptzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *qrcodeView;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@property (weak, nonatomic) IBOutlet UIButton *saoButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;


@property (nonatomic, strong) XQQCUserInfo *userInfo;
@property (nonatomic, strong) XQQCGroupInfo *groupInfo;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation XQQMKDIOFZTNormalQrcodeVC


- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    if (_isChinese) {
    }else {
        [_saoButton setTitle:@"Sweep" forState:UIControlStateNormal];
        [_saveButton setTitle:@"Save picture" forState:UIControlStateNormal];
    }
    
    _grouptzboeuNameLabel.text = @"";
    if (_qrType == QRType_User) {
        self.navigationItem.title = _isChinese ? @"我的二维码" : @"My QR code";
        _qrStr = [NSString stringWithFormat:@"wildfirechat://user/%@", self.target];
        _descLabel.text = _isChinese ? @"打开App扫码加我为好友" : @"Open the App and scan the code to add me as a friend";
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        self.userInfo = [XQQMineProfile getUserInfo:userId];
    }else if (_qrType == QRType_Group) {
        self.navigationItem.title = _isChinese ? @"群组二维码" : @"Group QR code";
        self.groupInfo = [XQQMineRelation getGroupInfoFromDB:self.target];

        
        _qrStr = [NSString stringWithFormat:@"wildfirechat://group/%@", self.target];
        _descLabel.text = _isChinese ? @"打开App扫码入群" : @"Open the App and scan the code into the group";
        _grouptzboeuNameLabel.text = self.groupInfo.name;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    }else if (_qrType == QRType_Conference) {
        self.navigationItem.title = _isChinese ? @"会议二维码" : @"Conference QR code";
        _descLabel.text = _isChinese ? @"打开App扫码进入会议室" : @"Open the App and scan the code to enter the conference room";
        
        _qrStr = self.conferenceUrl;
    }
    
    _iconView.layer.cornerRadius = 36.0;
    _saoButton.layer.cornerRadius = 18.0;
    _saveButton.layer.cornerRadius = 18.0;
    _saveButton.layer.borderWidth = 1.0;
    _saveButton.layer.borderColor = MAINCOLOR.CGColor;
    
//    _qrcodeView.image = [LBXScanNative createQRWithString:_qrStr QRSize:_qrcodeView.bounds.size];
    _qrcodeView.image = [LBXScanNative logolOrQRImage:_qrStr logolImage:_iconView.image];
}

- (void)setUserInfo:(XQQCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[UIImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
}

- (void)setGroupInfo:(XQQCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    
//    if (groupInfo.portrait.length) {
        [_iconView sd_setImageWithURL:URL(groupInfo.portrait) placeholderImage:IMAGENAME(@"groupIcon") options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        _grouptzboeuNameLabel.text = _groupInfo.name;
//    } else {
//        NSString *filePath = [XQQCUtilities getGroupGridPortrait:groupInfo.target width:50 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
//            return [UIImage imageNamed:@"groupIcon"];
//        }];
//        [self.iconView sd_setImageWithURL:[NSURL URLWithString:filePath] placeholderImage:[UIImage imageNamed:@"groupIcon"]];
//    }
}


- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([self.target isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            break;
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<XQQCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (XQQCGroupInfo *groupInfo in groupInfoList) {
        if ([self.target isEqualToString:groupInfo.target]) {
            self.groupInfo = groupInfo;
            break;
        }
    }
}

- (IBAction)sao:(UIButton *)sender {
    if (gXQQQrCodeDelegate) { // 走的delegate方法
        [gXQQQrCodeDelegate scanQrCode:self.navigationController];
    }
}

- (IBAction)save:(UIButton *)sender {
    if (_target.length <= 0) {
        [SVProgressHUD showErrorWithStatus:(_isChinese ? @"请等待数据加载" : @"Please wait for the data to load")];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
//    UIGraphicsBeginImageContext(self.qrcodeBgView.bounds.size);
//    [self.qrcodeBgView.layer renderInContext:UIGraphicsGetCurrentContext()];
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
    UIImage *image = [self shotShareImageFromView:self.qrcodeBgView];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    indicator.center = self.view.center;
    _indicatorView = indicator;
    [[UIApplication sharedApplication].keyWindow addSubview:indicator];
    [indicator startAnimating];
}

/** 1、截取屏幕上指定view的内容 */
- (UIImage *)shotShareImageFromView:(UIView *)view {
    //高清方法
    //第一个参数表示区域大小 第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    CGSize size = CGSizeMake(view.layer.bounds.size.width, view.layer.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, ([UIScreen mainScreen].scale));
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [_indicatorView removeFromSuperview];

    if (error) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"SaveFailure")];
        [SVProgressHUD dismissWithDelay:1.0];
    } else {
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SaveSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
    }
}



- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
