//
//  XQQMKDIOFZTTextModifyVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTTextModifyVC.h"

@interface XQQMKDIOFZTTextModifyVC ()<UITextFieldDelegate,UITextViewDelegate>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *textBgView;
@property (weak, nonatomic) IBOutlet UITextField *textTF;

@property (weak, nonatomic) IBOutlet UIView *textBgBView;
@property (weak, nonatomic) IBOutlet UITextView *contentTV;

@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property  UILabel *tipL;
@property  UILabel *signNumL;

@end

// 新增：提交内容的检查记录，只读取输入、不修改输入和提交流程，实现在文件尾部
@interface XQQMKDIOFZTTextModifyVC (XQQSubmitCheck)
- (void)xqq_checkBeforeSubmit; // 新增
@end

@implementation XQQMKDIOFZTTextModifyVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    [_saveButton setTitle:LLLLLL(@"OK") forState:UIControlStateNormal];
    
    _textBgView.layer.cornerRadius = 20.0;
    _textBgBView.layer.cornerRadius = 20.0;
    _saveButton.layer.cornerRadius = 20.0;
    _textBgBView.hidden = YES;
    
    _textTF.delegate = self;
    if (_modifyType == Modify_DisplayName) {
        self.navigationItem.title = _isChinese ? @"修改昵称" : @"Modify nickname";
        _textTF.placeholder = _isChinese ? @"请输入昵称" : @"Please enter a nickname";
        [self showTip];
    }else if (_modifyType == 100) {
        self.navigationItem.title = _isChinese ? @"修改账号" : @"Modify account";
        _textTF.placeholder = _isChinese ? @"请输入账号" : @"Please enter your account number";
    }else if (_modifyType == Modify_Email) {
        self.navigationItem.title = _isChinese ? @"修改邮箱" : @"Modify email";
        _textTF.placeholder = _isChinese ? @"Please enter email" : @"";
    }else if (_modifyType == Modify_Mobile) {
        self.navigationItem.title = _isChinese ? @"修改手机号" : @"Modify phone number";
        _textTF.placeholder = _isChinese ? @"请输入手机号" : @"Please enter your phone number";
        _textTF.keyboardType = UIKeyboardTypeNumberPad;
    }else if (_modifyType == Modify_Sign) {
        self.navigationItem.title = LLLLLL(@"PersonalSignature");
        _contentTV.keyboardType = UIKeyboardTypeDefault;
        _contentTV.delegate = self;
        [self showSignNumLabel];
    }else if (_modifyType == 101) {
        self.navigationItem.title = _isChinese ? @"修改我在群中的昵称" : @"Change my nickname in the group";
        _textTF.placeholder = _isChinese ? @"请输入群昵称" : @"Please enter a group nickname";
    }else if (_modifyType == 102) {
        self.navigationItem.title = _isChinese ? @"群聊名称" : @"Group chat name";
        _textTF.placeholder = _isChinese ? @"请输入群聊名称" : @"Please enter a group chat name";
    }else if (_modifyType == Modify_FriendAlias) {
        self.navigationItem.title = _isChinese ? @"备注名" : @"Remark name";
        _textTF.placeholder = _isChinese ? @"请输入备注名" : @"Please enter a note name";
    }
        
    if (_modifyType == Modify_Sign) {
        _textBgView.hidden = YES;
        _textBgBView.hidden = NO;
        
        UILabel *placeHolderLabel = [[UILabel alloc] init];
        placeHolderLabel.text = _isChinese ? @"填写个性签名..." : @"Fill in your personal signature";
        placeHolderLabel.numberOfLines = 0;
        placeHolderLabel.textColor = UIColor.lightGrayColor;
        [placeHolderLabel sizeToFit];
        placeHolderLabel.font = PINGFANG_R(14.0);
        [_contentTV addSubview:placeHolderLabel];
        [_contentTV setValue:placeHolderLabel forKey:@"_placeholderLabel"];
        
        _contentTV.text = _defaultValue;
    }else {
        _textTF.text = _defaultValue;
    }
}

- (IBAction)save:(UIButton *)sender {
    [self.view endEditing:YES];
    [self xqq_checkBeforeSubmit]; // 新增
    if (_modifyType == Modify_DisplayName) {
        if (_textTF.text.length < 4 || _textTF.text.length > 15) {
            [SVProgressHUD showErrorWithStatus:LLLLLL(@"register_setavatar_nickname_tip_msg")];
            return;
        }
    }
    if (_modifyType == Modify_Sign) {
        
    }else {
        if (_modifyType == 101 || _modifyType == Modify_FriendAlias) { // 该值可以为空
            
        }else {
            if (_textTF.text.length <= 0) {
                [SVProgressHUD showErrorWithStatus:_textTF.placeholder];
                [SVProgressHUD dismissWithDelay:1.0];
                return;
            }
            if (_modifyType == 100) { // 修改账户名
                if (_textTF.text.length <= 2) {
                    [SVProgressHUD showErrorWithStatus:_isChinese ? @"请输入3位及以上字符" : @"Please enter 3 characters or more"];
                    [SVProgressHUD dismissWithDelay:1.0];
                    return;
                }
            }
        }
    }

    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    
    WS(weakself)
    if (_modifyType == 100) { // 修改账户名
        [XQQMineProfile changeName:_textTF.text success:^{
            [hud hideAnimated:YES];
            weakself.onModified(self.textTF.text);
            [weakself.navigationController popViewControllerAnimated:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
        } error:^(int errorCode, NSString * _Nonnull message) {
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
            [weakself.view makeToast:text duration:1.0 position:CSToastPositionCenter];
//            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = message;
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
        }];
    }else if (_modifyType == 101) { // 修改群昵称
        NSString *myuserid = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
        [XQQMineRelation groupMemberAlias:@{@"gid":_groupId, @"uid":myuserid, @"alias": _textTF.text} success:^{
            [hud hideAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshCallHistory" object:nil];
            weakself.onModified(weakself.textTF.text);
            [weakself.navigationController popViewControllerAnimated:YES];

        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:(self->_isChinese ? @"群昵称修改失败" : @"Failed to modify the group nickname") duration:1.0 position:CSToastPositionCenter];

        }];
//        [XQQMineRelation modifyGroupAlias:_groupId alias:_textTF.text notifyLines:@[@(0)] notifyContent:nil success:^{
//            [hud hideAnimated:YES];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshCallHistory" object:nil];
//            weakself.onModified(weakself.textTF.text);
//            [weakself.navigationController popViewControllerAnimated:YES];
//        } error:^(int error_code) {
//            [hud hideAnimated:YES];
//            [weakself.view makeToast:(self->_isChinese ? @"群昵称修改失败" : @"Failed to modify the group nickname") duration:1.0 position:CSToastPositionCenter];
//        }];
    }else if (_modifyType == 102) { // 修改群聊名称
        [XQQMineRelation groupUpdate:@{@"gid": _groupId, @"name":_textTF.text}
                                           success:^{
            [hud hideAnimated:YES];
            XQQCGroupInfo *groupInfo = [XQQMineRelation getGroupInfoFromDB:weakself.groupId];
            groupInfo.name = weakself.textTF.text;
            [XQQMineRelation insertOrUpdateGroupInfo:groupInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated object:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.onModified(weakself.textTF.text);
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            [weakself.view makeToast:(self->_isChinese ? @"群昵称修改失败" : @"Failed to modify the group nickname") duration:1.0 position:CSToastPositionCenter];
        }];
//        [XQQMineRelation modifyGroupInfo:_groupId type:Modify_Group_Name newValue:_textTF.text notifyLines:@[@(0)] notifyContent:nil success:^{
//            [hud hideAnimated:YES];
//              dispatch_async(dispatch_get_main_queue(), ^{
//                  weakself.onModified(weakself.textTF.text);
//                  [weakself.navigationController popViewControllerAnimated:YES];
//              });
//          } error:^(int error_code) {
//              [hud hideAnimated:YES];
//              [weakself.view makeToast:(self->_isChinese ? @"群昵称修改失败" : @"Failed to modify the group nickname") duration:1.0 position:CSToastPositionCenter];
//          }];
    }else if (_modifyType == Modify_Sign) { // 修改个性签名
        [XQQMineProfile userExtra:@{@"sign":_contentTV.text} success:^ {
            [hud hideAnimated:YES];
            weakself.onModified(weakself.contentTV.text);
            [weakself.navigationController popViewControllerAnimated:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
        } error:^(int errCode, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            
            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = (errCode == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];
    }else if (_modifyType == Modify_FriendAlias) {
        
        [XQQMineRelation friendAliasUpdate:self.userId
                                                   alias:_textTF.text
                                                 success:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoUpdated object:self.userId];
            [hud hideAnimated:YES];
            weakself.onModified(weakself.textTF.text);
            [weakself.navigationController popViewControllerAnimated:YES];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshCallHistory" object:nil];
        } error:^(int error_code, NSString * _Nonnull message) {
            [hud hideAnimated:YES];
            
            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];

        }];
        
//        [XQQIMService.sharedWFCIMService setFriend:self.userId alias:_textTF.text success:^{
//            [hud hideAnimated:YES];
//            weakself.onModified(weakself.textTF.text);
//            [weakself.navigationController popViewControllerAnimated:YES];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshCallHistory" object:nil];
//        } error:^(int error_code) {
//            [hud hideAnimated:YES];
//            
//            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        }];
        
    }else {
        NSString *text = (_modifyType == Modify_Sign) ? _contentTV.text : _textTF.text;
        NSDictionary *params = @{@"displayName":text};
        if (_modifyType == Modify_DisplayName) {
            [XQQMineProfile userUpdate:params
                                              success:^{
                [hud hideAnimated:YES];
                weakself.onModified(text);
                [weakself.navigationController popViewControllerAnimated:YES];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
            } error:^(int error_code, NSString * _Nonnull message) {
                [hud hideAnimated:YES];
                
                hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            }];

        }
//        [XQQMineProfile modifyMyInfo:@{@(self.modifyType):text} success:^{
//            [hud hideAnimated:YES];
//            weakself.onModified(text);
//            [weakself.navigationController popViewControllerAnimated:YES];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
//        } error:^(int error_code) { // WFCCErrorCode
//            [hud hideAnimated:YES];
//            
//            hud = [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = (error_code == ERROR_CODE_NOT_MODIFIED ? (self->_isChinese ? @"未修改成功！" : @"Not modified successfully") : (self->_isChinese ? @"更新失败！" : @"Update failed!"));
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        }];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger length = textField.text.length - range.length + string.length;
    if (_modifyType == Modify_DisplayName) {
        return (length <= 15);
    }else if (_modifyType == 100) {
        return (length <= 12);
    }else if (_modifyType == Modify_Email) {
        return (length <= 20);
    }else if (_modifyType == Modify_Mobile) {
        return (length <= 11);
    }else if (_modifyType == Modify_FriendAlias) {
        return (length <= 30);
    } else if (_modifyType == Modify_Sign) {
        self.signNumL.text = [NSString stringWithFormat:@"%ld/%d",(long)length,50];
        return (length <= 50);
    }
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSInteger length = textView.text.length - range.length + text.length;
    if (_modifyType == Modify_Sign) {
        self.signNumL.text = [NSString stringWithFormat:@"%ld/%d",(long)length,50];
        return (length <= 50);
    }
    return YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showTip {
    if (!self.tipL) {
        self.tipL = [UILabel new];
        self.tipL.text = LLLLLL(@"register_setavatar_nickname_tip");
        self.tipL.textColor = [UIColor colorWithHexString:@"#989898"];
        self.tipL.font = [UIFont systemFontOfSize:11];
        self.tipL.numberOfLines = 0;
        self.tipL.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:self.tipL];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.tipL.leadingAnchor constraintEqualToAnchor:self.textTF.leadingAnchor],
            [self.tipL.trailingAnchor constraintEqualToAnchor:self.textTF.trailingAnchor],
            [self.tipL.topAnchor constraintEqualToAnchor:self.textTF.bottomAnchor constant:10]
        ]];
    }
}

- (void)showSignNumLabel {
    if (!self.signNumL) {
        self.signNumL = [UILabel new];
        self.signNumL.textColor = [UIColor colorWithHexString:@"#888888"];
        self.signNumL.backgroundColor = [UIColor colorWithHexString:@"#F6F6F6"];
        self.signNumL.font = [UIFont systemFontOfSize:11];
        self.signNumL.clipsToBounds = YES;
        self.signNumL.layer.cornerRadius = 10;
        self.signNumL.textAlignment = NSTextAlignmentCenter;
        self.signNumL.translatesAutoresizingMaskIntoConstraints = NO;
        self.signNumL.text = @"0/50";
        [self.view addSubview:self.signNumL];
        
        [NSLayoutConstraint activateConstraints:@[
            [self.signNumL.leadingAnchor constraintEqualToAnchor:self.contentTV.leadingAnchor],
            [self.signNumL.heightAnchor constraintEqualToConstant:24],
            [self.signNumL.widthAnchor constraintEqualToConstant:40],
            [self.signNumL.topAnchor constraintEqualToAnchor:self.contentTV.bottomAnchor constant:20]
        ]];
    }
}


@end

#pragma mark - 新增：提交内容检查

// 新增：点"确定"时检查要提交的内容，只在 Debug 下执行并输出日志，不拦截、不修改提交。
// 输入的可能是手机号、邮箱等个人信息，日志里只打长度和各项检查结果，不打内容
@implementation XQQMKDIOFZTTextModifyVC (XQQSubmitCheck)

// 新增：修改类型的名字，和 .h 里的说明对应
- (NSString *)xqq_modifyTypeName {
    switch ((NSInteger)self.modifyType) {
        case Modify_DisplayName: return @"displayName";
        case Modify_Mobile:      return @"mobile";
        case Modify_Email:       return @"email";
        case Modify_FriendAlias: return @"friendAlias";
        case Modify_Sign:        return @"sign";
        case 100:                return @"account";
        case 101:                return @"groupAlias";
        case 102:                return @"groupName";
        default:                 return [NSString stringWithFormat:@"type%ld", (long)self.modifyType];
    }
}

// 新增：检查项：
// - 字符数：长度限制按 UTF-16 计，一个 emoji 占 2 个以上，昵称"4~15 个字符"对 emoji 实际更少
// - 没有修改：和进入页面时的原值相同，照样会发一次修改请求
// - 只有空格 / 首尾有空格：长度检查能通过，但显示出来是空白或多出空格
// - 格式：手机号是否全是数字、邮箱是否含 @ 和 .
- (void)xqq_checkBeforeSubmit {
#ifdef DEBUG
    NSString *text = (self.modifyType == Modify_Sign ? self.contentTV.text : self.textTF.text) ?: @"";
    __block NSUInteger composed = 0;
    [text enumerateSubstringsInRange:NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString *sub, NSRange r, NSRange er, BOOL *stop) { composed += 1; }];
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL formatOK = YES;
    if (self.modifyType == Modify_Mobile) {
        formatOK = text.length > 0 && [text rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location == NSNotFound;
    } else if (self.modifyType == Modify_Email) {
        NSRange at = [text rangeOfString:@"@"];
        formatOK = at.location != NSNotFound && at.location > 0 && [[text substringFromIndex:at.location] containsString:@"."];
    }
    NSLog(@"[TextModify] submit %@ utf16=%lu chars=%lu unchanged=%d blank=%d edgeSpace=%d formatOK=%d",
          [self xqq_modifyTypeName], (unsigned long)text.length, (unsigned long)composed,
          [text isEqualToString:self.defaultValue ?: @""], text.length > 0 && trimmed.length == 0,
          trimmed.length > 0 && trimmed.length != text.length, formatOK);
#endif
}

@end
