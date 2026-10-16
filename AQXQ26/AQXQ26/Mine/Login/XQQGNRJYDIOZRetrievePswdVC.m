//
//  XQQGNRJYDIOZRetrievePswdVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/26/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQGNRJYDIOZRetrievePswdVC.h"
#import "XQQGNRJYDIOZMobileEmailPswdVC.h"

@interface XQQGNRJYDIOZRetrievePswdVC ()

@property (weak, nonatomic) IBOutlet UILabel *qoynruPhoneBackL;
@property (weak, nonatomic) IBOutlet UILabel *qoynruEmailBackL;

@end

@implementation XQQGNRJYDIOZRetrievePswdVC

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"找回密码";
    }else {
        self.navigationItem.title = @"Retrieve password";
        _qoynruPhoneBackL.text = @"Phone number retrieval";
        _qoynruEmailBackL.text = @"Email retrieval";
    }
}

- (IBAction)act:(UIButton *)sender {
    XQQGNRJYDIOZMobileEmailPswdVC *vc = XQQGNRJYDIOZMobileEmailPswdVC.new;
    vc.type = sender.tag;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
