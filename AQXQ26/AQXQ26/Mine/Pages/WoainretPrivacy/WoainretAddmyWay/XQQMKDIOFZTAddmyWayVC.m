//
//  XQQMKDIOFZTAddmyWayVC.m
//  WUHOIBDK
//
//  Created by Ruby on 1/30/24.
//

#import "XQQMKDIOFZTAddmyWayVC.h"

@interface XQQMKDIOFZTAddmyWayVC ()

@property (weak, nonatomic) IBOutlet UISwitch *mobileSW;

@property (weak, nonatomic) IBOutlet UISwitch *idSW;

@property (nonatomic, strong) XQQCUserInfo *userInfo;


@property (weak, nonatomic) IBOutlet UILabel *descL;
@property (weak, nonatomic) IBOutlet UILabel *phoneL;

@end

@implementation XQQMKDIOFZTAddmyWayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"添加我的方式";
    }else {
        self.navigationItem.title = @"Add my way";
        _descL.text = @"    You can find me in the following ways";
    }
    _phoneL.text = LLLLLL(@"MobileNumbers");
    
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [XQQMineProfile getMyInfo];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            break;
        }
    }
}
- (void)setUserInfo:(XQQCUserInfo *)userInfo {
    _userInfo = userInfo;
    XQQUserExtraInfo *extraInfo = [XQQUserExtraInfo mj_objectWithKeyValues:_userInfo.extra];
    
    _mobileSW.on = (extraInfo.openMobileSearch == 1);
    
    _idSW.on = (extraInfo.openAccountSearch == 1);
}

- (IBAction)actionSW:(UISwitch *)sender {
    if ([sender isEqual:_mobileSW]) {
        [self requestStateSW:sender params:@{@"openMobileSearch":@(sender.on ? 1 : 0)}];
    }else if ([sender isEqual:_idSW]) {
        [self requestStateSW:sender params:@{@"openAccountSearch":@(sender.on ? 1 : 0)}];
    }
}

- (void)requestStateSW:(UISwitch *)sw params:(NSDictionary *)params {
    [XQQMineProfile userExtra:params success:^ {
    } error:^(int errCode, NSString * _Nonnull message) {
//        if (sw) {
//            sw.on = !sw.on;
//        }
    }];
}

@end
