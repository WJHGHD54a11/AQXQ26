//
//  XQQMKDIOFZTNumberVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTNumberVC.h"
#import <objc/runtime.h> // 新增：输入记录挂在关联对象上

#import "XQQMKDIOFZTLockVC.h"
#import "XQQMKDIOFZTClearChatVC.h"

#import "XQQGNRJYDIOZLoginVC.h"

@interface XQQMKDIOFZTNumberVC ()
{
    NSArray<UIButton *> *_pswBtns;
    
    NSInteger _group; // 当前第几组
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *pswAButton;
@property (weak, nonatomic) IBOutlet UIButton *pswBButton;
@property (weak, nonatomic) IBOutlet UIButton *pswCButton;
@property (weak, nonatomic) IBOutlet UIButton *pswDButton;

@property (weak, nonatomic) IBOutlet UIButton *number1Btn;
@property (weak, nonatomic) IBOutlet UIButton *number2Btn;
@property (weak, nonatomic) IBOutlet UIButton *number3Btn;
@property (weak, nonatomic) IBOutlet UIButton *number4Btn;
@property (weak, nonatomic) IBOutlet UIButton *number5Btn;
@property (weak, nonatomic) IBOutlet UIButton *number6Btn;
@property (weak, nonatomic) IBOutlet UIButton *number7Btn;
@property (weak, nonatomic) IBOutlet UIButton *number8Btn;
@property (weak, nonatomic) IBOutlet UIButton *number9Btn;
@property (weak, nonatomic) IBOutlet UIButton *number0Btn;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) IBOutlet UIButton *forgetButton;

@property (nonatomic, strong) NSMutableArray *firstDatas;
@property (nonatomic, strong) NSMutableArray *secondDatas;
@property (nonatomic, assign) NSInteger currentIndex; // 当前应该输入的第几个

@property (nonatomic, assign) BOOL isReset; // 修改数字密码专属 (当数字验证通过之后·该值为YES)

@end

// 新增：数字密码输入过程的记录与检查，只读取状态、不修改输入和验证流程，实现在文件尾部
@interface XQQMKDIOFZTNumberVC (XQQLockRecord)
- (void)xqq_beginSession;                            // 新增
- (void)xqq_recordVerifyResult:(BOOL)passed;         // 新增
- (void)xqq_recordSetupMatched:(BOOL)matched number:(nullable NSString *)number; // 新增
- (void)xqq_recordEdit:(NSString *)kind;             // 新增
@end

@implementation XQQMKDIOFZTNumberVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _forgetButton.hidden = YES;
    [self naviTitle];
    
    _group = 0;
    _currentIndex = -1;
    _deleteButton.hidden = YES;
    _resetButton.hidden = YES;
    
    [_resetButton setTitle:(_isChinese ? @"重新设置" : @"Reset") forState:UIControlStateNormal];
    [_forgetButton setTitle:(_isChinese ? @"重新设置" : @"Forgot password") forState:UIControlStateNormal];
    
    _isReset = NO;
    _firstDatas = NSMutableArray.new;
    _secondDatas = NSMutableArray.new;
    
    _pswBtns = @[_pswAButton, _pswBButton, _pswCButton, _pswDButton];
    for (UIButton *btn in @[_number1Btn, _number2Btn, _number3Btn, _number4Btn,
                            _number5Btn, _number6Btn, _number7Btn, _number8Btn,
                            _number9Btn, _number0Btn]) {
        btn.layer.cornerRadius = 35.0;
    }
    [self xqq_beginSession]; // 新增
}

- (void)naviTitle {
    if (self.type == 0) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }else if (self.type == 1) {
        self.navigationItem.title = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
    }else if (self.type == 2) {
        self.navigationItem.title = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
    }else if (self.type == 3) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }else if (self.type == 4 || self.type == 5 || self.type ==6) {
        self.navigationItem.title = @"";
        self.titleLabel.text = _isChinese ? @"验证数字密码" : @"Verify the digital password";
        UIButton *rightBtn = [self itemTitle:(_isChinese ? @"切换账号" : @"Switch account") action:@selector(switchAccount)];
        rightBtn.frame = CGRectMake(0.0, 0.0, 60.0, 30.0);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
        _forgetButton.hidden = NO;
        if (self.type == 5 || self.type == 6) {
            self.navigationItem.hidesBackButton = YES;
        }
    }
    self.titleLabel.textColor = RGBA(0x222222);
}

- (IBAction)number:(UIButton *)sender {
    WS(weakself)
    if (self.type == 0) {
        [self doubleSetup:sender.tag success:^(NSString *number) {
            [XQQMineAPI requestUrl:@"/device_lock/update_device_number" params:@{@"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                [XQQODJNLockStatusManager.main getLockStatusData:^(BOOL lockStatus) {
                    [weakself reset:nil];
                    if (weakself.pswBlock) {
                        weakself.pswBlock(number);
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }];
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
    }else if (self.type == 1) { // 验证数字密码。输入1次 跟服务器的值进行对比
        [self singleVerification:sender.tag success:^{
            [XQQMineAPI requestUrl:@"/device_lock/set_status" params:@{@"status":@(0)} success:^(NSDictionary * _Nonnull dict) {
                [weakself reset:nil];
                if (weakself.pswBlock) {
                    weakself.pswBlock(@"");
                }
                [XQQODJNLockStatusManager.main reWriteLockInfo:@(0) ForKey:@"status"];
                [self.navigationController popViewControllerAnimated:YES];
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
    }else if (self.type == 2) { // 修改数字密码。首先先验证数字密码，再实现2次设置
        if (_isReset == NO) {
            [self singleVerification:sender.tag success:^{
                [weakself reset:nil];
                weakself.isReset = YES;
            }];
        }else {
            [self doubleSetup:sender.tag success:^(NSString *number) {
                [XQQMineAPI requestUrl:@"/device_lock/update_device_number" params:@{@"oldNumber":XQQODJNLockStatusManager.main.lockStatus.number, @"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                    [weakself reset:nil];
                    if (weakself.pswBlock) {
                        weakself.pswBlock(number);
                    }
                    [XQQODJNLockStatusManager.main reWriteLockInfo:number ForKey:@"number"];
                    [self.navigationController popViewControllerAnimated:YES];
                } error:^(int errCode, NSString * _Nonnull message) {
                    [weakself reset:nil];
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
        }
    }else if (self.type == 3) { // 忘记数字密码，设置数字密码，输入2次
        [self doubleSetup:sender.tag success:^(NSString *number) {
            [XQQMineAPI requestUrl:@"/device_lock/reset_device_number" params:@{@"code":weakself.code, @"newNumber":number} success:^(NSDictionary * _Nonnull dict) {
                [weakself reset:nil];
                [XQQODJNLockStatusManager.main reWriteLockInfo:number ForKey:@"number"];
                if (weakself.pswBlock) {
                    weakself.pswBlock(number);
                }
                for (UIViewController *vc in self.navigationController.viewControllers) {
                    if ([vc isKindOfClass:XQQMKDIOFZTLockVC.class]) {
                        [self.navigationController popToViewController:vc animated:YES];
                        break;
                    }
                }
            } error:^(int errCode, NSString * _Nonnull message) {
                [weakself reset:nil];
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
    }else if (self.type == 4 || self.type == 5) { // window启动时判断是否开启了安全锁，如果开启了(需要验证数字密码方可进入)
        [self singleVerification:sender.tag success:^{
            if (weakself.pswBlock) {
                weakself.pswBlock(@"OK");
            }
            [weakself reset:nil];
        }];
    }else if (self.type == 6) { // 进入后台时间大于设置的时间，弹出安全锁进行验证。。跟4 和 5一样，些许不同
        [self singleVerification:sender.tag success:^{
            if (weakself.pswBlock) {
                weakself.pswBlock(@"OK");
            }
            [self.navigationController popViewControllerAnimated:NO];
            [weakself reset:nil];
        }];
    }
    
    
    
}
#pragma mark - 验证数字密码。输入1次 跟服务器的值进行对比

- (void)singleVerification:(NSInteger)num success:(void(^)(void))successBlock {
    WS(weakself)
    [_firstDatas addObject:@(num)];
    if (_firstDatas.count >= 4) { // 可以跟服务器的值进行对比、如果是正确的、就直接返回
        self.currentIndex = 3;
        self.bgView.userInteractionEnabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakself.bgView.userInteractionEnabled = YES;
            self.currentIndex = -1;
            
            NSString *first = [weakself.firstDatas componentsJoinedByString:@""];
            if (![XQQODJNLockStatusManager.main.lockStatus.number isEqualToString:first]) {
                [weakself.firstDatas removeAllObjects];
                weakself.titleLabel.text = (self->_isChinese ? @"密码错误，请重新输入..." : @"Password is wrong, please re-enter...");
                weakself.titleLabel.textColor = UIColor.systemRedColor;
                [weakself xqq_recordVerifyResult:NO]; // 新增
                [weakself shakeLabel:weakself.titleLabel];
                return;
            }
            // 验证通过、
            [weakself xqq_recordVerifyResult:YES]; // 新增
            if (successBlock) {
                successBlock();
            }
        });
    }else {
        self.currentIndex = _firstDatas.count - 1;
    }
}


#pragma mark - 输入两次密码 进行对比两次是否相同

- (void)doubleSetup:(NSInteger)num success:(void(^)(NSString *number))successBlock {
    WS(weakself)
    if (_secondDatas.count >= 4) {
        return;
    }
    if (_group == 0) {
        [_firstDatas addObject:@(num)];
        if (_firstDatas.count >= 4) {
            _group = 1; // first已经存了4个数字、可以存下一组密码了
            self.currentIndex = 3;
            self.bgView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakself.bgView.userInteractionEnabled = YES;
                weakself.currentIndex = -1;
                weakself.titleLabel.text = self->_isChinese ? @"再次输入" : @"Enter it again";
            });
        }else {
            self.currentIndex = _firstDatas.count - 1;
        }
    }else {
        if (_resetButton.hidden) {
            _resetButton.hidden = NO;
        }
        [_secondDatas addObject:@(num)];
        if (_secondDatas.count >= 4) {
            self.currentIndex = 3;
            self.bgView.userInteractionEnabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakself.bgView.userInteractionEnabled = YES;
                weakself.currentIndex = -1;
                
                NSString *first = [weakself.firstDatas componentsJoinedByString:@""];
                NSString *second = [weakself.secondDatas componentsJoinedByString:@""];
                if (![first isEqualToString:second]) {
                    self->_group = 1;
                    [weakself.secondDatas removeAllObjects];
                    weakself.titleLabel.text = (self->_isChinese ? @"与首次输入不一致，请重新输入" : @"Inconsistent with the first input, please re-enter");
                    weakself.titleLabel.textColor = UIColor.systemRedColor;
                    [weakself xqq_recordSetupMatched:NO number:nil]; // 新增
                    [weakself shakeLabel:weakself.titleLabel];
                    return;
                }
                // 两次输入的密码相同。可以请求接口将数字密码传给服务器
                [weakself xqq_recordSetupMatched:YES number:first]; // 新增
                if (successBlock) {
                    successBlock(first);
                }
            });
        }else {
            self.currentIndex = _secondDatas.count - 1;
        }
    }
}


- (void)shakeLabel:(UILabel *)label {
    [label.layer removeAllAnimations];
    
    CAKeyframeAnimation *kfa = [[CAKeyframeAnimation alloc] init];
    kfa.keyPath = @"transform.translation.x";
    kfa.values = @[@(-16.0), @(0.0), @(16.0), @(0.0), @(-16.0), @(0.0), @(16.0), @(0.0)];
    kfa.duration = 0.1;
    kfa.repeatCount = 2.0;
    [label.layer addAnimation:kfa forKey:@"shake"];
}


- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    
    if (_currentIndex == -1) {
        for (UIButton *btn in _pswBtns) {
            btn.selected = NO;
        }
        _deleteButton.hidden = YES;
    }else {
        _pswBtns[_currentIndex].selected = YES;
        _deleteButton.hidden = NO;
    }
}

- (IBAction)delete:(UIButton *)sender {
    [self xqq_recordEdit:@"delete"]; // 新增
    if (_group == 0) {
        if (_currentIndex >= 0) {
            _pswBtns[_currentIndex].selected = NO;
            [_firstDatas removeLastObject];
            _currentIndex = _currentIndex - 1;
        }
    }else {
        if (_currentIndex >= 0) {
            _pswBtns[_currentIndex].selected = NO;
            [_secondDatas removeLastObject];
            _currentIndex = _currentIndex - 1;
        }
    }
    if (_currentIndex < 0) {
        _deleteButton.hidden = YES;
    }
}

- (void)setIsReset:(BOOL)isReset {
    _isReset = isReset;
    if (_isReset) {
        self.navigationItem.title = _isChinese ? @"设置数字密码" : @"Set a digital password";
        self.titleLabel.text = _isChinese ? @"输入数字密码" : @"Enter digital code";
    }
}

- (IBAction)reset:(UIButton *)sender {
    [self xqq_recordEdit:(sender ? @"resetTap" : @"resetAuto")]; // 新增
    _group = 0;
    self.currentIndex = -1;
    [self naviTitle];
    [_firstDatas removeAllObjects];
    [_secondDatas removeAllObjects];
    _isReset = NO;
    
    _resetButton.hidden = YES;
}




#pragma mark - 以下方法仅type=4 或者 5时 或者 6 才会触发

- (void)switchAccount { // 切换账号
    if (self.type == 4) {
        if (self.pswBlock) {
            self.pswBlock(@"ACCOUNT");
        }
    }else if (self.type == 5) {
        [self.navigationController popViewControllerAnimated:NO];
    }else if (self.type == 6) { // 进登录界面
        [self.navigationController popViewControllerAnimated:NO];
        if (self.pswBlock) {
            self.pswBlock(@"ACCOUNT");
        }
    }
}

- (IBAction)forget:(UIButton *)sender { // 忘记数字密码
    XQQMKDIOFZTClearChatVC *vc = XQQMKDIOFZTClearChatVC.new;
    vc.type = self.type;
    WS(weakself)
    [vc setClearBlock:^{ // type 5 不会走这儿
        if (weakself.pswBlock) {
            weakself.pswBlock(@"FORGET");
        }
    }];
    [self.navigationController pushViewController:vc animated:YES];
}

@end

#pragma mark - 新增：数字密码输入记录与检查

// 新增：记录挂在关联对象上，日志只在 Debug 下输出，不影响输入、验证和回调。
// 这是安全锁页面，日志和记录里一律不保存、不输出密码本身，只记次数、结果和弱密码类型
static const void *kXQQLockRecordKey = &kXQQLockRecordKey; // 新增

@implementation XQQMKDIOFZTNumberVC (XQQLockRecord)

// 新增：页面类型名，和 .h 里 type 的说明对应
- (NSString *)xqq_typeName {
    switch (self.type) {
        case 0:  return @"set";
        case 1:  return @"verifyToDisable";
        case 2:  return @"modify";
        case 3:  return @"forgetReset";
        case 4:  return @"launchLock";
        case 5:  return @"loginLock";
        case 6:  return @"backgroundLock";
        default: return [NSString stringWithFormat:@"type%ld", (long)self.type];
    }
}

// 新增：本页的记录：进入时间、验证失败 / 成功次数、两次输入不一致次数、删除和重置次数
- (NSMutableDictionary<NSString *, id> *)xqq_lockState {
    NSMutableDictionary<NSString *, id> *state = objc_getAssociatedObject(self, kXQQLockRecordKey);
    if (!state) {
        state = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kXQQLockRecordKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return state;
}

// 新增：某个计数加 1，返回加完后的值
- (NSUInteger)xqq_increment:(NSString *)key {
    NSMutableDictionary<NSString *, id> *state = [self xqq_lockState];
    NSUInteger value = [state[key] unsignedIntegerValue] + 1;
    state[key] = @(value);
    return value;
}

// 新增：进入页面时调用，记下时间
- (void)xqq_beginSession {
    [self xqq_lockState][@"start"] = @(CACurrentMediaTime());
}

// 新增：从进入页面到现在过了多少秒
- (NSTimeInterval)xqq_elapsed {
    return CACurrentMediaTime() - [[self xqq_lockState][@"start"] doubleValue];
}

// 新增：验证数字密码有了结果时调用（输满 4 位、0.5 秒后比对完）：
// 记下第几次失败 / 成功。原来输错没有次数限制，可以一直试，这里只记录不限制
- (void)xqq_recordVerifyResult:(BOOL)passed {
    NSString *key = passed ? @"verifyPassed" : @"verifyFailed";
    [self xqq_increment:key];
#ifdef DEBUG
    NSLog(@"[NumberLock] %@ verify %@ #%@ failedSoFar=%@ after %.1fs", [self xqq_typeName],
          passed ? @"passed" : @"failed", [self xqq_lockState][key], [self xqq_lockState][@"verifyFailed"] ?: @0, [self xqq_elapsed]);
#endif
}

// 新增：设置数字密码时两次输入比对完调用：不一致时计数；一致时检查是不是弱密码。
// number 只在这里用来判断强弱，不保存、不输出
- (void)xqq_recordSetupMatched:(BOOL)matched number:(nullable NSString *)number {
    if (!matched) {
        [self xqq_increment:@"setupMismatch"];
    }
#ifdef DEBUG
    NSLog(@"[NumberLock] %@ setup matched=%d mismatchSoFar=%@ weakness=%@ after %.1fs", [self xqq_typeName], matched,
          [self xqq_lockState][@"setupMismatch"] ?: @0, matched ? [self xqq_weaknessOfNumber:number] : @"-", [self xqq_elapsed]);
#endif
}

// 新增：4 位数字密码的弱密码类型：全相同（1111）、连续递增 / 递减（1234 / 4321）、两位重复（1212）；都不是返回 none
- (NSString *)xqq_weaknessOfNumber:(nullable NSString *)number {
    if (number.length != 4) {
        return @"unknown";
    }
    unichar d[4];
    [number getCharacters:d range:NSMakeRange(0, 4)];
    if (d[0] == d[1] && d[1] == d[2] && d[2] == d[3]) {
        return @"allSame";
    }
    BOOL ascending = YES, descending = YES;
    for (NSInteger i = 1; i < 4; i++) {
        ascending = ascending && (d[i] == d[i - 1] + 1);
        descending = descending && (d[i] == d[i - 1] - 1);
    }
    if (ascending || descending) {
        return ascending ? @"ascending" : @"descending";
    }
    return (d[0] == d[2] && d[1] == d[3]) ? @"repeatPair" : @"none";
}

// 新增：点删除、点"重新设置"或流程里自动重置时调用，计数
- (void)xqq_recordEdit:(NSString *)kind {
    [self xqq_increment:kind];
#ifdef DEBUG
    NSLog(@"[NumberLock] %@ %@ #%@", [self xqq_typeName], kind, [self xqq_lockState][kind]);
#endif
}

@end
