//
//  XQQMKDIOFZTModityPswVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/23/24.
//

#import "XQQMKDIOFZTModityPswVC.h"

#import "XQQMKDIOFZTMobileEmailVerifyVC.h"
#import "XQQMKDIOFZTLoginpswVerifyVC.h"

@interface XQQMKDIOFZTModityPswVC ()

@property (weak, nonatomic) IBOutlet UIView *aBgView;
@property (weak, nonatomic) IBOutlet UIView *bBgView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bViewTop;


@property (weak, nonatomic) IBOutlet UILabel *phoneVerificationL;
@property (weak, nonatomic) IBOutlet UILabel *emailVerificationL;
@property (weak, nonatomic) IBOutlet UILabel *loginPswVerificationL;

@end

@implementation XQQMKDIOFZTModityPswVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    XQQCUserInfo *userInfo = [XQQMineProfile getMyInfo];
    if (userInfo.mobile.length > 0 && userInfo.email.length > 0) {
        // 如果该账号手机号和邮箱都存在 -> 三种修改方式
    }else {
        if (userInfo.mobile.length > 0) {
            _bBgView.hidden = YES;
        }else {
            _aBgView.hidden = YES;
        }
        _bViewTop.constant = 0.0;
    }
    
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"ModityLoginPassword");
    
    _phoneVerificationL.text = LLLLLL(@"MobileNumberVerification");
    _emailVerificationL.text = LLLLLL(@"EmailVerification");
    _loginPswVerificationL.text = LLLLLL(@"LoginPasswordVerification");
}

- (IBAction)modify_type:(UIButton *)sender {
    if (sender.tag <= 1) {
        XQQMKDIOFZTMobileEmailVerifyVC *vc = XQQMKDIOFZTMobileEmailVerifyVC.new;
        vc.isMobile = (sender.tag == 0 ? YES : NO);
        [self.navigationController pushViewController:vc animated:YES];
    }else {
        XQQMKDIOFZTLoginpswVerifyVC *vc = XQQMKDIOFZTLoginpswVerifyVC.new;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
