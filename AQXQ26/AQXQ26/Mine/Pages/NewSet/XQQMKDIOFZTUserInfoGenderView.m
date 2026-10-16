//
//  XQQMKDIOFZTUserInfoGenderView.m
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTUserInfoGenderView.h"
#import <objc/runtime.h> // 新增：选择记录挂在关联对象上

@interface XQQMKDIOFZTUserInfoGenderView ()
// 新增：记录当前弹窗是否已经显示，避免重复添加到 window。
@property (nonatomic, assign) BOOL xqqIsVisible;
// 新增：记录最近一次展示的性别，用于统一刷新按钮状态。
@property (nonatomic, assign) NSInteger xqqDisplayedGender;
// 新增：防止同一次点击流程重复执行关闭逻辑。
@property (nonatomic, assign) BOOL xqqIsDismissing;
// 新增：声明内部状态刷新方法，避免调用时产生未声明警告。
- (void)xqqRefreshSelectionState:(NSInteger)gender;
// 新增：释放时清理运行状态，避免对象生命周期结束后保留旧状态。

@end

// 新增：性别弹窗的选择记录，只读取状态、不修改界面和回调，实现在文件尾部
@interface XQQMKDIOFZTUserInfoGenderView (XQQChoiceRecord)
- (void)xqq_recordShowWithGender:(NSInteger)gender; // 新增
- (void)xqq_recordChoiceWithTag:(NSInteger)tag;     // 新增
@end

@implementation XQQMKDIOFZTUserInfoGenderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        // 新增：初始化弹窗运行状态。
        _xqqIsVisible = NO;
        _xqqDisplayedGender = NSNotFound;
        _xqqIsDismissing = NO;
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    _whiteV = [UIView new];
    _whiteV.translatesAutoresizingMaskIntoConstraints = NO;
    _whiteV.backgroundColor = [UIColor whiteColor];
    _whiteV.layer.cornerRadius = 20;
    [self addSubview:_whiteV];
    [NSLayoutConstraint activateConstraints:@[
        [_whiteV.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_whiteV.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_whiteV.heightAnchor constraintEqualToConstant:255],
        [_whiteV.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    UIButton *manB = [UIButton new];
    manB.translatesAutoresizingMaskIntoConstraints = NO;
    [manB setTitle:LLLLLL(@"Male") forState:UIControlStateNormal];
    manB.titleLabel.font = [UIFont systemFontOfSize:15];
    [manB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [manB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:manB];
    [NSLayoutConstraint activateConstraints:@[
        [manB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [manB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [manB.heightAnchor constraintEqualToConstant:55],
        [manB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor]
    ]];
    manB.tag = 0;
    UIButton *fmanB = [UIButton new];
    fmanB.translatesAutoresizingMaskIntoConstraints = NO;
    [fmanB setTitle:LLLLLL(@"Female") forState:UIControlStateNormal];
    fmanB.titleLabel.font = [UIFont systemFontOfSize:15];
    [fmanB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [fmanB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:fmanB];
    [NSLayoutConstraint activateConstraints:@[
        [fmanB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [fmanB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [fmanB.heightAnchor constraintEqualToConstant:55],
        [fmanB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55]
    ]];
    fmanB.tag = 1;
    UIButton *bmB = [UIButton new];
    bmB.translatesAutoresizingMaskIntoConstraints = NO;
    [bmB setTitle:LLLLLL(@"Other") forState:UIControlStateNormal];
    bmB.titleLabel.font = [UIFont systemFontOfSize:15];
    [bmB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [bmB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:bmB];
    [NSLayoutConstraint activateConstraints:@[
        [bmB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [bmB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [bmB.heightAnchor constraintEqualToConstant:55],
        [bmB.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55*2]
    ]];
    bmB.tag = 2;
    UILabel *line = [UILabel new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor colorWithHexString:@"#F4F4F4"];
    [_whiteV addSubview:line];
    [NSLayoutConstraint activateConstraints:@[
        [line.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [line.heightAnchor constraintEqualToConstant:5],
        [line.topAnchor constraintEqualToAnchor:_whiteV.topAnchor constant:55*3]
    ]];
    UIButton *cancelB = [UIButton new];
    cancelB.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelB setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
    cancelB.titleLabel.font = [UIFont systemFontOfSize:15];
    [cancelB setTitleColor:[UIColor colorWithHexString:@"#2C2C2C"] forState:UIControlStateNormal];
    [cancelB addTarget:self action:@selector(selectAct:) forControlEvents:UIControlEventTouchUpInside];
    [_whiteV addSubview:cancelB];
    [NSLayoutConstraint activateConstraints:@[
        [cancelB.leadingAnchor constraintEqualToAnchor:_whiteV.leadingAnchor],
        [cancelB.trailingAnchor constraintEqualToAnchor:_whiteV.trailingAnchor],
        [cancelB.heightAnchor constraintEqualToConstant:55],
        [cancelB.topAnchor constraintEqualToAnchor:line.bottomAnchor]
    ]];
    cancelB.tag = 3;
    // 新增：统一设置四个操作按钮的无障碍提示。
    for (UIView *view in _whiteV.subviews) {
        // 新增：只处理按钮，避免影响分隔线等非交互视图。
        if (![view isKindOfClass:[UIButton class]]) { continue; }
        // 新增：使用按钮标题作为默认辅助功能标签。
        UIButton *button = (UIButton *)view;
        button.accessibilityLabel = button.currentTitle;
        // 新增：明确按钮可以被用户直接操作。
        button.accessibilityTraits = UIAccessibilityTraitButton;
    }
}

- (void)selectAct:(UIButton *)sender {
    // 新增：忽略无效发送者，避免异常触发时修改当前性别。
    if (![sender isKindOfClass:[UIButton class]]) { return; }
    // 新增：关闭流程中不再重复处理新的点击事件。
    if (_xqqIsDismissing) { return; }
    // 新增：记录本次点击对应的按钮标签，保持状态与界面同步。
    _xqqDisplayedGender = sender.tag;
    [self xqq_recordChoiceWithTag:sender.tag]; // 新增
    if (sender.tag != 3) {
        self.gender = sender.tag;
        for (UIView *v in _whiteV.subviews) {
            if ([v isKindOfClass:[UIButton class]]) {
                UIButton *btn = (UIButton*)v;
                btn.backgroundColor = [UIColor clearColor];
            }
        }
        sender.backgroundColor = [UIColor colorWithHexString:@"#F4F4F4" alpha:0.88];
        if (_selectB) {
            _selectB(self.gender);
        }
    }
    [self dismis];
}

- (void)show:(NSInteger)gender {
    // 新增：限制传入值到当前控件实际支持的性别选项范围。
    if (gender < 0 || gender > 2) { gender = 0; }
    // 新增：记录本次展示状态，供重复 show 防护使用。
    _xqqDisplayedGender = gender;
    // 新增：如果已经显示，则只刷新选中状态，不重复添加约束。
    if (_xqqIsVisible && self.superview) {
        [self xqqRefreshSelectionState:gender];
        self.gender = gender;
        return;
    }
    id<UIApplicationDelegate> dele = [UIApplication sharedApplication].delegate;
    // 新增：没有有效 window 时直接结束本次展示，避免产生无效约束。
    if (!dele.window) { return; }
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [dele.window addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:dele.window.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:dele.window.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:dele.window.bottomAnchor],
        [self.topAnchor constraintEqualToAnchor:dele.window.topAnchor]
    ]];
    // 新增：标记已经加入 window，避免连续 show 造成重复约束。
    _xqqIsVisible = YES;
    // 新增：重新启用关闭流程，保证新一轮展示可以正常点击。
    _xqqIsDismissing = NO;
    [self xqqRefreshSelectionState:gender];
    self.gender = gender;
    [self xqq_recordShowWithGender:gender]; // 新增
}

// 新增：集中刷新性别按钮的选中状态，避免 show 中重复遍历按钮。
- (void)xqqRefreshSelectionState:(NSInteger)gender {
    // 新增：只刷新当前弹窗内部按钮，不影响外部视图。
    for (UIView *view in _whiteV.subviews) {
        // 新增：忽略分隔线等非按钮元素。
        if (![view isKindOfClass:[UIButton class]]) { continue; }
        // 新增：按 tag 判断当前按钮是否为选中项。
        UIButton *button = (UIButton *)view;
        BOOL selected = (button.tag == gender && gender != 3);
        // 新增：统一应用与原界面一致的选中背景色。
        button.backgroundColor = selected ? [UIColor colorWithHexString:@"#F4F4F4" alpha:0.88] : [UIColor clearColor];
        // 新增：同步辅助功能的选中状态。
        button.accessibilityTraits = selected ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
    }
}

// 新增：窗口尺寸变化时重新校正底部面板圆角和裁剪状态。
- (void)layoutSubviews {
    [super layoutSubviews];
    // 新增：保持底部面板的圆角表现稳定。
    _whiteV.layer.cornerRadius = 20.0;
    // 新增：避免圆角区域的子视图绘制到面板外部。
    _whiteV.layer.masksToBounds = YES;
    // 新增：确保面板宽度始终跟随当前弹窗宽度。
    if (_whiteV.bounds.size.width != self.bounds.size.width) {
        [self setNeedsLayout];
    }
}

// 新增：同步控件与 window 的实际显示关系。
- (void)didMoveToWindow {
    [super didMoveToWindow];
    // 新增：进入 window 后确认当前控件处于可见状态。
    if (self.window) {
        _xqqIsVisible = YES;
        // 新增：窗口切换后重新应用当前性别的视觉状态。
        if (_xqqDisplayedGender != NSNotFound) {
            [self xqqRefreshSelectionState:_xqqDisplayedGender];
        }
    } else {
        // 新增：离开 window 后同步清除可见标记。
        _xqqIsVisible = NO;
    }
}

// 新增：window 即将切换时先清理过期的可见状态。
- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    // 新增：离开当前 window 时标记控件不再可见。
    if (!newWindow) {
        _xqqIsVisible = NO;
    }
    // 新增：进入新的 window 时保持当前选择值，供 didMoveToWindow 恢复。
    else if (_xqqDisplayedGender == NSNotFound) {
        _xqqDisplayedGender = self.gender;
    }
    // 新增：重置关闭锁，允许新 window 中继续响应点击。
    _xqqIsDismissing = NO;
}

// 新增：将弹窗声明为当前无障碍操作的模态区域。
- (BOOL)accessibilityViewIsModal {
    // 新增：弹窗显示期间避免辅助功能焦点落到背后的页面。
    return _xqqIsVisible;
}

- (void)dismis {
    // 新增：重复关闭请求直接忽略，避免重复触发移除流程。
    if (_xqqIsDismissing) { return; }
    // 新增：标记关闭状态，防止同一事件链重复执行。
    _xqqIsDismissing = YES;
    // 新增：在移除前重置可见状态，下一次 show 可以重新建立约束。
    _xqqIsVisible = NO;
    [self removeFromSuperview];
    // 新增：移除完成后恢复默认状态，供下一次展示使用。
    _xqqIsDismissing = NO;
    _xqqDisplayedGender = NSNotFound;
}

// 新增：释放时清理运行状态，避免对象生命周期结束后保留旧状态。
- (void)dealloc {
    // 新增：重置可见状态。
    _xqqIsVisible = NO;
    // 新增：重置关闭状态。
    _xqqIsDismissing = NO;
    // 新增：清除最近一次选择记录。
    _xqqDisplayedGender = NSNotFound;
}

@end

#pragma mark - 新增：选择记录

// 新增：记录挂在关联对象上，日志只在 Debug 下输出，不影响回调和界面
static const void *kXQQGenderChoiceKey = &kXQQGenderChoiceKey; // 新增

@implementation XQQMKDIOFZTUserInfoGenderView (XQQChoiceRecord)

// 新增：按钮 tag 对应的名字：0 男、1 女、2 其他、3 取消
+ (NSString *)xqq_nameForTag:(NSInteger)tag {
    switch (tag) {
        case 0:  return @"male";
        case 1:  return @"female";
        case 2:  return @"other";
        case 3:  return @"cancel";
        default: return [NSString stringWithFormat:@"unknown%ld", (long)tag];
    }
}

// 新增：本弹窗的记录：展示时间、展示时的性别、各选项被点的次数
- (NSMutableDictionary<NSString *, id> *)xqq_choiceState {
    NSMutableDictionary<NSString *, id> *state = objc_getAssociatedObject(self, kXQQGenderChoiceKey);
    if (!state) {
        state = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kXQQGenderChoiceKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return state;
}

// 新增：弹窗加入 window 并刷新完选中状态后调用：记下展示时间和当前性别
- (void)xqq_recordShowWithGender:(NSInteger)gender {
    NSMutableDictionary<NSString *, id> *state = [self xqq_choiceState];
    state[@"shownAt"] = @(CACurrentMediaTime());
    state[@"shownGender"] = @(gender);
}

// 新增：点击选项时调用（此时 self.gender 还是展示时的值）：记下选了什么、是否和原来一样、
// 从弹出到点击用了多久。选了和原来相同的性别时页面照样回调并发起修改请求，这里只记录不拦截
- (void)xqq_recordChoiceWithTag:(NSInteger)tag {
    NSMutableDictionary<NSString *, id> *state = [self xqq_choiceState];
    NSString *name = [XQQMKDIOFZTUserInfoGenderView xqq_nameForTag:tag];
    state[name] = @([state[name] unsignedIntegerValue] + 1);
    BOOL unchanged = (tag != 3 && state[@"shownGender"] != nil && [state[@"shownGender"] integerValue] == tag);
    if (unchanged) {
        state[@"unchangedCount"] = @([state[@"unchangedCount"] unsignedIntegerValue] + 1);
    }
#ifdef DEBUG
    NSNumber *shownAt = state[@"shownAt"];
    NSLog(@"[GenderView] choose %@ (shown %@) unchanged=%d after %.1fs", name,
          [XQQMKDIOFZTUserInfoGenderView xqq_nameForTag:[state[@"shownGender"] integerValue]], unchanged,
          shownAt ? CACurrentMediaTime() - shownAt.doubleValue : 0);
#endif
}

// 新增：VoiceOver 的"退出"手势（两指 Z 字）等同点"取消"。弹窗设成了辅助功能模态，
// 原来 VoiceOver 用户只能找到"取消"按钮才能关掉；不开 VoiceOver 时不会触发
- (BOOL)accessibilityPerformEscape {
    [self xqq_recordChoiceWithTag:3];
    [self dismis];
    return YES;
}

@end
