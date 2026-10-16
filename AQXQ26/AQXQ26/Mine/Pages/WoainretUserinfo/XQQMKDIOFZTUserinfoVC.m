//
//  XQQMKDIOFZTUserVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/14/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTUserinfoVC.h"

#import "XQQMKDIOFZTNormalQrcodeVC.h"
#import "XQQMKDIOFZTTextModifyVC.h"
#import "XQQMKDIOFZTAvatarVC.h"
#import "XQQMKDIOFZTUserInfoGenderView.h"
#import "XQQMKDIOFZTUserInfoBirthdayView.h"


@interface XQQMKDIOFZTUserinfoVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nicktzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthdayLabel;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;

@property (strong, nonatomic) UIImagePickerController *pickerController;

@property (nonatomic, strong) XQQCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *iconV;
@property (weak, nonatomic) IBOutlet UILabel *nicknameL;
@property (weak, nonatomic) IBOutlet UILabel *accountL;
@property (weak, nonatomic) IBOutlet UILabel *signL;
@property (weak, nonatomic) IBOutlet UILabel *qrL;
@property (weak, nonatomic) IBOutlet UILabel *loginTimeLabel;

@end

@implementation XQQMKDIOFZTUserinfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    if (_isChinese) {
        self.navigationItem.title = @"我的资料";
    }else {
        self.navigationItem.title = @"My Profile";
        _iconV.text = @"Avatar";
        _nicknameL.text = @"Nickname";
        _accountL.text = @"Gender";
        _qrL.text = @"Last Login time";
        
    }
    _signL.text = LLLLLL(@"Birthday");
    _iconView.layer.cornerRadius = 20.0;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userdataUpdated) name:@"kUserDataUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [self refreshUI];
}

- (void)refreshUI {
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    _userInfo = [XQQMineProfile getUserInfo:savedUserId];
    
    [_iconView sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    _nicktzboeuNameLabel.text = _userInfo.displayName;
    _genderLabel.text = @[LLLLLL(@"Male"),LLLLLL(@"Female"),LLLLLL(@"Other")][_userInfo.gender];
    if ([XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].birthday == 0) {
        _birthdayLabel.text = LLLLLL(@"Notperfect");
    } else {
        _birthdayLabel.text = [UNString(@"%lld", [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].birthday) timeIntervalDateFormat:@"yyyy-MM-dd"];
    }
    NSString *logintime = [UNString(@"%lld", [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].lastLoginTime) timeIntervalDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    _loginTimeLabel.text = logintime;
    //    _signLabel.text = [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].sign;
}

- (void)userdataUpdated {
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    [XQQMineProfile getUserInfo:savedUserId
                              refresh:YES
                              success:^(XQQCUserInfo * _Nonnull userInfo) {
        self.userInfo = userInfo;
        [self refreshUI];
    } error:^(int errorCode, NSString * _Nonnull message) {
        
    }];

}

- (IBAction)userinfoAct:(UIButton *)sender {
    if (sender.tag == 0) { // 头像
//        WS(weakself)
//        [XQQCommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
//            [weakself modityIconData:UIImageJPEGRepresentation(image, 0.01)];
//        }];
        XQQMKDIOFZTAvatarVC *vc = XQQMKDIOFZTAvatarVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 1) { // 昵称
        XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
        vc.modifyType = Modify_DisplayName;
        vc.defaultValue = _nicktzboeuNameLabel.text;
        WS(weakself)
        [vc setOnModified:^(NSString * _Nonnull value) {
            weakself.nicktzboeuNameLabel.text = value;
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 2) { // 账号
        XQQMKDIOFZTUserInfoGenderView *genderV = [[XQQMKDIOFZTUserInfoGenderView alloc] init];
        [genderV show:_userInfo.gender];
        [genderV setSelectB:^(NSInteger index) {
            [self update:Modify_Gender value:index];
        }];
        
//        [self.view makeToast:(_isChinese ? @"暂不提供更改" : @"Changes are not provided yet") duration:1.0 position:CSToastPositionCenter];
//        XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
//        vc.modifyType = 100;
//        vc.defaultValue = _qoynruAccountLabel.text;
//        WS(weakself)
//        [vc setOnModified:^(NSString * _Nonnull value) {
//            weakself.qoynruAccountLabel.text = value;
//        }];
//        [self.navigationController pushViewController:vc animated:YES];
    }else if (sender.tag == 3) { // 二维码
        
        /**

        XQQMKDIOFZTNormalQrcodeVC *vc = XQQMKDIOFZTNormalQrcodeVC.new;
        vc.qrType = 0;
        vc.target = _userInfo.userId;
        [self.navigationController pushViewController:vc animated:YES];
         
         **/

    }else if (sender.tag ==4) { // 个性签名
        
        XQQMKDIOFZTUserInfoBirthdayView *birV = [XQQMKDIOFZTUserInfoBirthdayView new];
        [birV show];
        [birV setInitialDateWithTimestamp:[XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra].birthday];
        [birV setSelectD:^(NSTimeInterval time) {
            [self updateBirthday:time];
        }];

        /**

        XQQMKDIOFZTTextModifyVC *vc = XQQMKDIOFZTTextModifyVC.new;
        vc.modifyType = Modify_Sign;
//        vc.defaultValue = _signLabel.text;
        WS(weakself)
        [vc setOnModified:^(NSString * _Nonnull value) {
//            weakself.signLabel.text = value;
        }];
        [self.navigationController pushViewController:vc animated:YES];
         
         **/

    }
}

- (void)update:(ModifyMyInfoType)modifyType value:(NSInteger)value {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    NSDictionary *param;
    if (modifyType == Modify_Gender) {
        param = @{@"gender": [NSString stringWithFormat:@"%ld",(long)value]};
    }
    
    [XQQMineProfile userUpdate:param
                                      success:^{
        [hud hideAnimated:YES];
        self->_userInfo.gender = value;
        weakself.genderLabel.text = @[LLLLLL(@"Male"),LLLLLL(@"Female"),LLLLLL(@"Other")][self->_userInfo.gender];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
    } error:^(int error_code, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        
        hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];

    }];

//    [XQQMineProfile modifyMyInfo:@{@(modifyType):[NSString stringWithFormat:@"%ld",(long)value]} success:^{
//        [hud hideAnimated:YES];
//        self->_userInfo.gender = value;
//        weakself.genderLabel.text = @[LLLLLL(@"Male"),LLLLLL(@"Female"),LLLLLL(@"Other")][self->_userInfo.gender];
//  
//    } error:^(int error_code) { // WFCCErrorCode
//        [hud hideAnimated:YES];
//        
//        hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//    }];
}

- (void)updateBirthday:(long long)birthday {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    [XQQMineProfile userExtra:@{@"birthday":UNString(@"%lld",(long long)birthday)} success:^ {
        [hud hideAnimated:YES];
        
        NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
        [XQQMineProfile getUserInfo:savedUserId refresh:YES success:^(XQQCUserInfo * _Nonnull userInfo) {
            weakself.userInfo = userInfo;
        } error:^(int errorCode, NSString * _Nonnull message) {
            
        }];
        weakself.birthdayLabel.text = [UNString(@"%lld", birthday) timeIntervalDateFormat:@"yyyy-MM-dd"];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        
        hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = (errCode == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];

}

- (void)modityIconData:(NSData *)imgData {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
      [XQQMineProfile uploadMedia:nil mediaData:imgData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
          [XQQMineProfile modifyMyInfo:@{@(Modify_Portrait):remoteUrl} success:^{
            dispatch_async(dispatch_get_main_queue(), ^{
              [weakself.iconView sd_setImageWithURL:URL(remoteUrl) placeholderImage:weakself.iconView.image options:SDWebImageScaleDownLargeImages
                                            context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
                
                [hud hideAnimated:YES];
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"SuccessfulOperation");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
            });
          } error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = LLLLLL(@"OperationFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            });
          }];
          } progress:^(long uploaded, long total) {
        } error:^(int error_code) {
          dispatch_async(dispatch_get_main_queue(), ^{
              [hud hideAnimated:YES];
              MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
              hud.mode = MBProgressHUDModeText;
              hud.label.text = LLLLLL(@"UploadFailure");
              hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
              [hud hideAnimated:YES afterDelay:1.f];
          });
    }];
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
