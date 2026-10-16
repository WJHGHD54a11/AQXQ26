//
//  XQQRegisterSetAvatarVC.m
//  WildFireChat
//
//  Created by wtb on 2025/3/29.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQRegisterSetAvatarVC.h"
#import "XQQMKDIOFZTAvatarVC.h"
#import "XQQMineSession.h"
#import "SDWebImage/SDWebImage.h"

@interface XQQRegisterSetAvatarVC ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *avatarB;
@property (weak, nonatomic) IBOutlet UILabel *titleL;
@property (weak, nonatomic) IBOutlet UILabel *avatarL;
@property (weak, nonatomic) IBOutlet UILabel *nicknameL;
@property (weak, nonatomic) IBOutlet UITextField *nicknameT;
@property (weak, nonatomic) IBOutlet UILabel *nickNameTipL;
@property (weak, nonatomic) IBOutlet UIButton *finishB;
@property NSArray *avatars;
@property UIImage *selectavatar;

@end

@implementation XQQRegisterSetAvatarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDefaultData];
    [self setupUI];
}

- (void)setDefaultData {
    self.avatars = @[@"waxiouvAvatar1_0",@"waxiouvAvatar1_1",@"waxiouvAvatar1_2",
                     @"waxiouvAvatar1_3",@"waxiouvAvatar1_4",@"waxiouvAvatar1_5",
                     @"waxiouvAvatar1_6",@"waxiouvAvatar1_7",@"waxiouvAvatar1_8",@"waxiouvAvatar1_9",
                     @"waxiouvAvatar2_0",@"waxiouvAvatar2_1",@"waxiouvAvatar2_2",
                     @"waxiouvAvatar2_3",@"waxiouvAvatar2_4",@"waxiouvAvatar2_5",
                     @"waxiouvAvatar2_6",@"waxiouvAvatar2_7",@"waxiouvAvatar2_8",@"waxiouvAvatar2_9",
                     @"waxiouvAvatar3_0",@"waxiouvAvatar3_1",@"waxiouvAvatar3_2",
                     @"waxiouvAvatar3_3",@"waxiouvAvatar3_4",@"waxiouvAvatar3_5",
                     @"waxiouvAvatar3_6",@"waxiouvAvatar3_7",@"waxiouvAvatar3_8",@"waxiouvAvatar3_9"];
    
    NSUInteger randomIndex = arc4random_uniform((uint32_t)self.avatars.count);
    self.selectavatar = [UIImage imageNamed:self.avatars[randomIndex]];
    [self.avatarB setBackgroundImage:self.selectavatar forState:UIControlStateNormal];
    
}

- (void)setupUI {
    [self.finishB setTitle:LLLLLL(@"register_setavatar_done_btn") forState:UIControlStateNormal];
    self.titleL.text = LLLLLL(@"register_setavatar_title");
    self.avatarL.text = LLLLLL(@"register_setavatar_tip");
    self.nicknameL.text = LLLLLL(@"register_setavatar_nickname_title");
    self.nickNameTipL.text = LLLLLL(@"register_setavatar_nickname_tip");
    
    self.avatarB.clipsToBounds = YES;
    self.avatarB.layer.cornerRadius = 125/2;
    
    self.nicknameT.delegate = self;
    self.nicknameT.returnKeyType = UIReturnKeyDone;
    UIView *leftV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 44)];
    self.nicknameT.leftView = leftV;
    self.nicknameT.leftViewMode = UITextFieldViewModeAlways;
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#ACACAC"],
        NSFontAttributeName: [UIFont systemFontOfSize:14]
    };
    self.nicknameT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LLLLLL(@"register_setavatar_nickname_placehold") attributes:attributes];
}

- (IBAction)doneA:(UIButton *)sender {
    [self.view endEditing:YES];

    if ([self.nicknameT.text length] == 0) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"register_setavatar_nickname_placehold")];
        return;
    }
    
    if ([self.nicknameT.text length] < 4 || [self.nicknameT.text length] > 15) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"register_setavatar_nickname_tip_msg")];
        return;
    }
    
    if (self.selectavatar) {
        [self uploadServiceImg:UIImageJPEGRepresentation(self.selectavatar, 0.1)];
    } else {
        [self setNickName];
    }
}

- (void)setNickName {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];

    NSString *text = self.nicknameT.text;
    WS(weakself)
    [XQQMineProfile userUpdate:@{@"displayName":text} success:^{
        [hud hideAnimated:YES];
        
        // 原工程：切换到主 TabBar。这里改为统一收尾，关闭登录流程。
        XQQCUserInfo *me = [XQQMineProfile getMyInfo];
        if (me) [XQQMineSession finishLoginWithUser:me];

    } error:^(int error_code, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        
        BOOL isChinese = [XQQCommonHelper.main isChinese];
        hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (isChinese ? @"未修改成功！" : @"Not modified successfully") : (isChinese ? @"更新失败！" : @"Update failed!"));
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];

    }];
    
    
//    [XQQMineProfile modifyMyInfo:@{@(0):text} success:^{
//        [hud hideAnimated:YES];
//        
//        XQQWJEFDOCYTabBarVC *tabBarVC = XQQWJEFDOCYTabBarVC.new;
//        [UIApplication sharedApplication].delegate.window.rootViewController =  tabBarVC;
//
//    } error:^(int error_code) { // WFCCErrorCode
//        [hud hideAnimated:YES];
//        
//        BOOL isChinese = [XQQCommonHelper.main isChinese];
//        hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//        hud.mode = MBProgressHUDModeText;
//        hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (isChinese ? @"未修改成功！" : @"Not modified successfully") : (isChinese ? @"更新失败！" : @"Update failed!"));
//        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//        [hud hideAnimated:YES afterDelay:1.f];
//    }];

}

- (IBAction)selectAvatarA:(UIButton *)sender {
    XQQMKDIOFZTAvatarVC *vc = [[XQQMKDIOFZTAvatarVC alloc] init];
    vc.isRegister = YES;
    [vc setSetBlock:^(NSString * url) {
        self.selectavatar = nil;
        [self.avatarB sd_setBackgroundImageWithURL:[NSURL URLWithString:url] forState:UIControlStateNormal];
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)uploadServiceImg:(NSData *)imgData { // 这一步是更改本地的头像  必须上传至服务器，再通过IM进行更改
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    WS(weakself)
    [XQQMineProfile generateUploadFile:@"avatar"
                                              success:^(NSString * _Nonnull uploadUrl, NSString * _Nonnull requestUrl) {
        [XQQMineProfile uploadData:imgData
                                              url:uploadUrl
                                        remoteUrl:requestUrl
                                          success:^(NSString * _Nonnull remoteUrl) {
            
          dispatch_async(dispatch_get_main_queue(), ^{
              [hud hideAnimated:YES];
              [weakself modityAvatarWithIM:remoteUrl];
          });
        } progress:^(long uploaded, long total) {
            
        } fail:^(int error_code) {
            
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
          dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LLLLLL(@"UploadFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
    
//      [XQQMineProfile uploadMedia:nil mediaData:imgData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
//          dispatch_async(dispatch_get_main_queue(), ^{
//              [hud hideAnimated:YES];
//              [weakself modityAvatarWithIM:remoteUrl];
//          });
//      } progress:^(long uploaded, long total) {
//      } error:^(int error_code) {
//          dispatch_async(dispatch_get_main_queue(), ^{
//            [hud hideAnimated:YES];
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = LLLLLL(@"UploadFailure");
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        });
//    }];
}

- (void)modityAvatarWithIM:(NSString *)remoteUrl {
    WS(weakself)
    [XQQMineProfile userUpdate:@{@"portrait":remoteUrl}
                                      success:^{
        [self setNickName];
    } error:^(int errCode, NSString * _Nonnull message) {
        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:1.0 position:CSToastPositionCenter];
    }];
//    [XQQMineAPI requestUrl:@"/update/avatar" params:@{@"portrait":remoteUrl} success:^(NSDictionary * _Nonnull dict) {
//        [self setNickName];
//    } error:^(int errCode, NSString * _Nonnull message) {
//        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:1.0 position:CSToastPositionCenter];
//    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end
