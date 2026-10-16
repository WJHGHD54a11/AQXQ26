//
//  XQQMKDIOFZTCheckInVC.m
//  WildFireChat
//

#import "XQQMKDIOFZTCheckInVC.h"
#import "XQQMineServices.h"
#import "MBProgressHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "XQQCSignTasks.h"
#import "XQQCPointsHistory.h"
#import "XQQCSign.h"

static NSString * const kWOPCheckInUserCellId = @"WOPMKDIOFZTCheckInUserCell";
static NSString * const kWOPCheckInAvatarPlaceholder = @"me_checkIn_user_avatar";
/// 签到日期统一按东八区计算，与服务端一致
static const NSInteger kWOPCheckInTimeZoneOffset = 8 * 3600;
static const NSInteger kWOPCheckInWeekDays = 7;
/// 选择用户弹窗：行高、表头高度（按钮 + 分割线 + 余量）、最大高度
static const CGFloat kWOPSelectorRowHeight = 88.0;
static const CGFloat kWOPSelectorChromeHeight = 112.0;
static const CGFloat kWOPSelectorMaxHeight = 420.0;

#pragma mark - 样式

static UIColor *WOPCheckInTitleColor(void)   { return [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0]; }
static UIColor *WOPCheckInRuleColor(void)    { return [UIColor colorWithRed:0.13 green:0.15 blue:0.15 alpha:1.0]; }
static UIColor *WOPCheckInHintColor(void)    { return [UIColor colorWithWhite:0.68 alpha:1.0]; }
static UIColor *WOPCheckInGreenColor(void)   { return [UIColor colorWithRed:0.18 green:0.86 blue:0.24 alpha:1.0]; }

static UIFont *WOPFont(CGFloat size, UIFontWeight weight) {
    return [UIFont systemFontOfSize:size weight:weight];
}

#pragma mark - 工具函数

static NSString *WOPMKDIOFZTSafeText(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

/// 任务显示名：任务名 → 创建者昵称 → fallback
static NSString *WOPCheckInTaskDisplayName(XQQCSignTask *task, NSString *fallback) {
    NSString *taskName = WOPMKDIOFZTSafeText(task.taskName);
    if (taskName.length) {
        return taskName;
    }
    NSString *creatorName = WOPMKDIOFZTSafeText(task.creatorDisplayName);
    return creatorName.length ? creatorName : fallback;
}

static void WOPCheckInSetAvatar(UIImageView *imageView, XQQCSignTask *task) {
    UIImage *placeholder = [UIImage imageNamed:kWOPCheckInAvatarPlaceholder];
    if (task.creatorPortrait.length > 0) {
        [imageView sd_setImageWithURL:[NSURL URLWithString:task.creatorPortrait] placeholderImage:placeholder options:SDWebImageScaleDownLargeImages];
    } else {
        imageView.image = placeholder;
    }
}

static UILabel *WOPMakeLabel(UIFont *font, UIColor *color, NSString *text) {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.text = text;
    return label;
}

static UIImageView *WOPMakeImageView(UIImage *image, UIViewContentMode mode) {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = mode;
    return imageView;
}

static UIView *WOPMakeView(UIColor *color) {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = color;
    return view;
}

/// 签到按钮 / 弹窗确认按钮共用的绿色拉伸背景
static UIImage *WOPCheckInButtonBackground(void) {
    return [[UIImage imageNamed:@"me_checkIn_btn_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(20, 30, 20, 30) resizingMode:UIImageResizingModeStretch];
}

/// view 四边贴合 container 的约束
static NSArray<NSLayoutConstraint *> *WOPEdgeConstraints(UIView *view, id container) {
    return @[[view.topAnchor constraintEqualToAnchor:[container topAnchor]],
             [view.leadingAnchor constraintEqualToAnchor:[container leadingAnchor]],
             [view.trailingAnchor constraintEqualToAnchor:[container trailingAnchor]],
             [view.bottomAnchor constraintEqualToAnchor:[container bottomAnchor]]];
}

static NSArray<NSLayoutConstraint *> *WOPSizeConstraints(UIView *view, CGFloat width, CGFloat height) {
    return @[[view.widthAnchor constraintEqualToConstant:width],
             [view.heightAnchor constraintEqualToConstant:height]];
}

/// 东八区的 yyyyMMdd / MM/dd 格式器，只在主线程用，缓存避免反复创建
static NSDateFormatter *WOPCheckInFormatter(NSString *format) {
    static NSMutableDictionary<NSString *, NSDateFormatter *> *cache;
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
    }
    NSDateFormatter *formatter = cache[format];
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kWOPCheckInTimeZoneOffset];
        formatter.dateFormat = format;
        cache[format] = formatter;
    }
    return formatter;
}

#pragma mark - 选择用户弹窗的 cell

@interface WOPMKDIOFZTCheckInUserCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *checkView;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation WOPMKDIOFZTCheckInUserCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.avatarView = WOPMakeImageView(nil, UIViewContentModeScaleAspectFill);
    self.avatarView.layer.cornerRadius = 26.0;
    self.avatarView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.avatarView];

    self.nameLabel = WOPMakeLabel(WOPFont(17, UIFontWeightRegular), WOPCheckInTitleColor(), nil);
    [self.contentView addSubview:self.nameLabel];

    self.checkView = WOPMakeImageView([UIImage imageNamed:@"me_checkIn_select_user"], UIViewContentModeScaleAspectFit);
    [self.contentView addSubview:self.checkView];

    self.bottomLine = WOPMakeView([UIColor colorWithWhite:0.92 alpha:1.0]);
    [self.contentView addSubview:self.bottomLine];

    UIView *content = self.contentView;
    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [self.avatarView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:34],
        [self.avatarView.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarView.trailingAnchor constant:26],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.checkView.leadingAnchor constant:-16],

        [self.checkView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-36],
        [self.checkView.centerYAnchor constraintEqualToAnchor:content.centerYAnchor],

        [self.bottomLine.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:34],
        [self.bottomLine.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-34],
        [self.bottomLine.bottomAnchor constraintEqualToAnchor:content.bottomAnchor],
        [self.bottomLine.heightAnchor constraintEqualToConstant:0.5]
    ]];
    [constraints addObjectsFromArray:WOPSizeConstraints(self.avatarView, 52, 52)];
    [constraints addObjectsFromArray:WOPSizeConstraints(self.checkView, 27, 18)];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)configWithTask:(XQQCSignTask *)task selected:(BOOL)selected {
    self.nameLabel.text = WOPCheckInTaskDisplayName(task, @"用户名称");
    WOPCheckInSetAvatar(self.avatarView, task);
    self.checkView.hidden = !selected;
}

@end

#pragma mark - XQQMKDIOFZTCheckInVC

@interface XQQMKDIOFZTCheckInVC () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *userView;
@property (nonatomic, strong) UIImageView *userBgImageView;
@property (nonatomic, strong) UIImageView *userAvatarView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UIImageView *arrowView;

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *continuousLabel;
@property (nonatomic, strong) UILabel *timezoneLabel;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *dayImageViews;
@property (nonatomic, strong) NSMutableArray<UIImageView *> *dayCheckImageViews;
@property (nonatomic, strong) NSMutableArray<UILabel *> *dateLabels;
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) UILabel *walletHintLabel;
@property (nonatomic, strong) UILabel *ruleTitleLabel;
@property (nonatomic, strong) UILabel *ruleLabel;

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIView *successPanel;
@property (nonatomic, strong) UIView *selectorPanel;
@property (nonatomic, strong) UITableView *selectorTableView;

@property (nonatomic, strong) NSArray<XQQCSignTask *> *tasks;
@property (nonatomic, strong) XQQCSignTask *selectedTask;
/// 弹窗里临时选中、尚未点"确定"的任务
@property (nonatomic, strong) XQQCSignTask *pendingSelectedTask;
@property (nonatomic, strong) NSArray<NSDate *> *weekDates;
/// 正在请求任务列表或提交签到，防止重复请求
@property (nonatomic, assign) BOOL loading;

@end

@implementation XQQMKDIOFZTCheckInVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:225.0 / 255.0 green:243.0 / 255.0 blue:226.0 / 255.0 alpha:1.0];
    self.title = @"签到福利";
    self.dayImageViews = [NSMutableArray array];
    self.dayCheckImageViews = [NSMutableArray array];
    self.dateLabels = [NSMutableArray array];
    self.tasks = @[];
    [self reloadWeekDates];
    [self setupUI];
    [self loadSignTasks];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.hidden = NO;
    bar.translucent = YES;
    bar.tintColor = [UIColor blackColor];
    [bar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    bar.shadowImage = [UIImage new];
}

#pragma mark - UI

- (void)setupUI {
    [self setupContentView];
    [self setupUserView];
    [self setupCheckInCard];
    [self setupRuleView];
    [self setupMaskView];
}

- (void)setupContentView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];

    self.contentView = WOPMakeView([UIColor clearColor]);
    [self.scrollView addSubview:self.contentView];

    NSMutableArray *constraints = [NSMutableArray array];
    [constraints addObjectsFromArray:WOPEdgeConstraints(self.scrollView, self.view)];
    [constraints addObjectsFromArray:WOPEdgeConstraints(self.contentView, self.scrollView.contentLayoutGuide)];
    [constraints addObject:[self.contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor]];
    [NSLayoutConstraint activateConstraints:constraints];
}

/// 顶部当前签到用户，有多个任务时可点击切换
- (void)setupUserView {
    self.userView = WOPMakeView([UIColor clearColor]);
    self.userView.layer.cornerRadius = 29.0;
    self.userView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.userView];

    UIImage *bg = [[UIImage imageNamed:@"me_checkIn_user_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(29, 60, 29, 60) resizingMode:UIImageResizingModeStretch];
    self.userBgImageView = WOPMakeImageView(bg, UIViewContentModeScaleToFill);
    [self.userView addSubview:self.userBgImageView];

    [self.userView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showUserSelector)]];

    self.userAvatarView = WOPMakeImageView([UIImage imageNamed:kWOPCheckInAvatarPlaceholder], UIViewContentModeScaleAspectFill);
    self.userAvatarView.layer.cornerRadius = 25.0;
    self.userAvatarView.layer.masksToBounds = YES;
    [self.userView addSubview:self.userAvatarView];

    self.userNameLabel = WOPMakeLabel(WOPFont(16, UIFontWeightMedium), [UIColor colorWithRed:0.17 green:0.17 blue:0.17 alpha:1.0], @"用户名称");
    [self.userView addSubview:self.userNameLabel];

    self.arrowView = WOPMakeImageView([UIImage imageNamed:@"me_checkIn_user_arrow"], UIViewContentModeScaleAspectFit);
    [self.userView addSubview:self.arrowView];

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [self.userView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [self.userView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14.5],

        [self.userAvatarView.leadingAnchor constraintEqualToAnchor:self.userView.leadingAnchor constant:8],
        [self.userAvatarView.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor],

        [self.arrowView.trailingAnchor constraintEqualToAnchor:self.userView.trailingAnchor constant:-27],
        [self.arrowView.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor],

        [self.userNameLabel.leadingAnchor constraintEqualToAnchor:self.userAvatarView.trailingAnchor constant:16],
        [self.userNameLabel.trailingAnchor constraintEqualToAnchor:self.arrowView.leadingAnchor constant:-10],
        [self.userNameLabel.centerYAnchor constraintEqualToAnchor:self.userView.centerYAnchor]
    ]];
    [constraints addObjectsFromArray:WOPSizeConstraints(self.userView, 218, 58)];
    [constraints addObjectsFromArray:WOPEdgeConstraints(self.userBgImageView, self.userView)];
    [constraints addObjectsFromArray:WOPSizeConstraints(self.userAvatarView, 50, 50)];
    [constraints addObjectsFromArray:WOPSizeConstraints(self.arrowView, 11, 20)];
    [NSLayoutConstraint activateConstraints:constraints];
}

/// 签到卡片：连续天数、本周 7 天、签到按钮
- (void)setupCheckInCard {
    self.cardView = WOPMakeView([UIColor clearColor]);
    self.cardView.layer.cornerRadius = 18.0;
    self.cardView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.cardView];

    UIImage *cardBg = [[UIImage imageNamed:@"me_checkIn_check_section_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30) resizingMode:UIImageResizingModeStretch];
    UIImageView *cardBgImageView = WOPMakeImageView(cardBg, UIViewContentModeScaleToFill);
    [self.cardView addSubview:cardBgImageView];

    self.continuousLabel = WOPMakeLabel(WOPFont(19, UIFontWeightRegular), WOPCheckInTitleColor(), nil);
    [self.cardView addSubview:self.continuousLabel];

    self.timezoneLabel = WOPMakeLabel(WOPFont(15, UIFontWeightRegular), [UIColor colorWithRed:0.34 green:0.34 blue:0.34 alpha:1.0], @"UTC + 8");
    [self.cardView addSubview:self.timezoneLabel];

    UIView *weekContainer = WOPMakeView(nil);
    [self.cardView addSubview:weekContainer];
    [self setupWeekDaysInContainer:weekContainer];

    self.checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.checkButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.checkButton.titleLabel.font = WOPFont(20, UIFontWeightSemibold);
    [self.checkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.checkButton setTitle:@"立即签到" forState:UIControlStateNormal];
    [self.checkButton setBackgroundImage:WOPCheckInButtonBackground() forState:UIControlStateNormal];
    [self.checkButton addTarget:self action:@selector(checkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.checkButton];

    self.walletHintLabel = WOPMakeLabel(WOPFont(13, UIFontWeightRegular), WOPCheckInHintColor(), @"签到奖励存入球币钱包");
    self.walletHintLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.walletHintLabel];

    UIView *card = self.cardView;
    NSMutableArray *constraints = [NSMutableArray arrayWithArray:WOPEdgeConstraints(cardBgImageView, card)];
    [constraints addObjectsFromArray:@[
        [card.topAnchor constraintEqualToAnchor:self.userView.bottomAnchor constant:34],
        [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14.5],
        [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14.5],
        [card.heightAnchor constraintEqualToConstant:304],

        [self.continuousLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:27],
        [self.continuousLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16.5],
        [self.continuousLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-32],

        [self.timezoneLabel.topAnchor constraintEqualToAnchor:self.continuousLabel.bottomAnchor constant:10],
        [self.timezoneLabel.leadingAnchor constraintEqualToAnchor:self.continuousLabel.leadingAnchor],

        [weekContainer.topAnchor constraintEqualToAnchor:card.topAnchor constant:116],
        [weekContainer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [weekContainer.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [weekContainer.heightAnchor constraintEqualToConstant:94],

        [self.checkButton.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:35],
        [self.checkButton.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-35],
        [self.checkButton.topAnchor constraintEqualToAnchor:card.topAnchor constant:226],
        [self.checkButton.heightAnchor constraintEqualToConstant:40],

        [self.walletHintLabel.topAnchor constraintEqualToAnchor:self.checkButton.bottomAnchor constant:10],
        [self.walletHintLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:30],
        [self.walletHintLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-30]
    ]];
    [NSLayoutConstraint activateConstraints:constraints];
}

/// 本周 7 天等宽排列，每天：底图 + 已签到对勾 + 日期
- (void)setupWeekDaysInContainer:(UIView *)weekContainer {
    UIView *previous = nil;
    for (NSInteger i = 0; i < kWOPCheckInWeekDays; i++) {
        UIView *dayContainer = WOPMakeView(nil);
        [weekContainer addSubview:dayContainer];

        UIImageView *imageView = WOPMakeImageView(nil, UIViewContentModeScaleAspectFit);
        [dayContainer addSubview:imageView];
        [self.dayImageViews addObject:imageView];

        UIImageView *checkImageView = WOPMakeImageView([UIImage imageNamed:@"me_checkIn_checked"], UIViewContentModeScaleAspectFit);
        checkImageView.hidden = YES;
        [dayContainer addSubview:checkImageView];
        [self.dayCheckImageViews addObject:checkImageView];

        UILabel *dateLabel = WOPMakeLabel(WOPFont(14, UIFontWeightRegular), nil, nil);
        dateLabel.textAlignment = NSTextAlignmentCenter;
        [dayContainer addSubview:dateLabel];
        [self.dateLabels addObject:dateLabel];

        NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
            [imageView.topAnchor constraintEqualToAnchor:dayContainer.topAnchor],
            [imageView.centerXAnchor constraintEqualToAnchor:dayContainer.centerXAnchor],

            [checkImageView.centerXAnchor constraintEqualToAnchor:imageView.centerXAnchor],
            [checkImageView.centerYAnchor constraintEqualToAnchor:imageView.centerYAnchor],

            [dateLabel.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:14],
            [dateLabel.leadingAnchor constraintEqualToAnchor:dayContainer.leadingAnchor],
            [dateLabel.trailingAnchor constraintEqualToAnchor:dayContainer.trailingAnchor],
            [dateLabel.bottomAnchor constraintEqualToAnchor:dayContainer.bottomAnchor],

            [dayContainer.topAnchor constraintEqualToAnchor:weekContainer.topAnchor],
            [dayContainer.bottomAnchor constraintEqualToAnchor:weekContainer.bottomAnchor],
            [dayContainer.widthAnchor constraintEqualToAnchor:weekContainer.widthAnchor multiplier:1.0 / kWOPCheckInWeekDays],
            [dayContainer.leadingAnchor constraintEqualToAnchor:(previous ? previous.trailingAnchor : weekContainer.leadingAnchor)]
        ]];
        [constraints addObjectsFromArray:WOPSizeConstraints(imageView, 42, 58)];
        [constraints addObjectsFromArray:WOPSizeConstraints(checkImageView, 30, 30)];
        if (i == kWOPCheckInWeekDays - 1) {
            [constraints addObject:[dayContainer.trailingAnchor constraintEqualToAnchor:weekContainer.trailingAnchor]];
        }
        [NSLayoutConstraint activateConstraints:constraints];
        previous = dayContainer;
    }
}

- (void)setupRuleView {
    self.ruleTitleLabel = WOPMakeLabel(WOPFont(17, UIFontWeightSemibold), WOPCheckInRuleColor(), @"签到规则:");
    [self.contentView addSubview:self.ruleTitleLabel];

    self.ruleLabel = WOPMakeLabel(WOPFont(14, UIFontWeightRegular), WOPCheckInRuleColor(), @"");
    self.ruleLabel.numberOfLines = 0;
    [self.contentView addSubview:self.ruleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.ruleTitleLabel.topAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:28],
        [self.ruleTitleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.5],
        [self.ruleTitleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15.5],

        [self.ruleLabel.topAnchor constraintEqualToAnchor:self.ruleTitleLabel.bottomAnchor constant:12],
        [self.ruleLabel.leadingAnchor constraintEqualToAnchor:self.ruleTitleLabel.leadingAnchor],
        [self.ruleLabel.trailingAnchor constraintEqualToAnchor:self.ruleTitleLabel.trailingAnchor],
        [self.ruleLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-40]
    ]];
}

/// 弹窗共用的半透明遮罩，点击关闭弹窗
- (void)setupMaskView {
    self.maskView = WOPMakeView([UIColor colorWithWhite:0 alpha:0.55]);
    self.maskView.hidden = YES;
    [self.view addSubview:self.maskView];
    [self.maskView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissModalViews)]];
    [NSLayoutConstraint activateConstraints:WOPEdgeConstraints(self.maskView, self.view)];
}

#pragma mark - Data

- (void)loadSignTasks {
    if (self.loading) {
        return;
    }
    self.loading = YES;
    MBProgressHUD *hud = [self showLoadingHUD];
    __weak typeof(self) weakSelf = self;
    [XQQMineExtra signTasks:^(XQQCSignTasks * _Nonnull tasks) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            [strongSelf xqqFinishLoadingIfNeeded];
            strongSelf.tasks = tasks.tasks ?: @[];
            // 之前选中的任务不在新列表里（或还没选过）时默认选第一个，由 xqqNormalizeCheckInState 处理
            [strongSelf xqqRefreshCheckInState];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            [strongSelf xqqFinishLoadingIfNeeded];
            [strongSelf showTextHUD:(message.length ? message : @"获取签到信息失败")];
            [strongSelf xqqRefreshCheckInState];
        });
    }];
}

/// 优先用 progress；没有时取近 7 天汇总里的已签天数
- (NSInteger)continuousDaysForTask:(XQQCSignTask *)task {
    NSInteger days = [task.progress integerValue];
    if (days <= 0 && task.recent7DaySummary.count > 0) {
        days = [task.recent7DaySummary.firstObject.signedDays integerValue];
    }
    return MAX(days, 0);
}

- (void)refreshWeekDaysWithSignedKeys:(NSSet<NSString *> *)signedDateKeys {
    NSDateFormatter *formatter = WOPCheckInFormatter(@"MM/dd");
    UIColor *signedColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    for (NSInteger i = 0; i < self.weekDates.count && i < self.dayImageViews.count; i++) {
        NSDate *date = self.weekDates[i];
        BOOL signedDay = [signedDateKeys containsObject:[self dayKeyForDate:date]];
        self.dayImageViews[i].image = [UIImage imageNamed:(signedDay ? @"me_checkIn_checked_bg" : @"me_checkIn_uncheck")];
        self.dayCheckImageViews[i].hidden = !signedDay;
        UILabel *label = self.dateLabels[i];
        label.text = [formatter stringFromDate:date];
        label.textColor = signedDay ? signedColor : WOPCheckInHintColor();
    }
}

#pragma mark - Actions

- (void)checkButtonAction {
    if (![self xqqHasValidCheckInTask] || self.loading) {
        return;
    }
    self.loading = YES;
    MBProgressHUD *hud = [self showLoadingHUD];
    __weak typeof(self) weakSelf = self;
    [XQQMineExtra signSubmit:@{@"taskId" : self.selectedTask.taskId} success:^(XQQCSign * _Nonnull sign) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            [strongSelf xqqFinishLoadingIfNeeded];
            [strongSelf showSuccessPanelWithPoints:[sign.earnedPoints integerValue]];
            [strongSelf loadSignTasks];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [hud hideAnimated:YES];
            [strongSelf xqqFinishLoadingIfNeeded];
            [strongSelf showTextHUD:(message.length ? message : @"签到失败")];
            [strongSelf loadSignTasks];
        });
    }];
}

- (void)showUserSelector {
    if (self.tasks.count <= 1 || [self xqqHasVisibleModalView]) {
        return;
    }
    self.maskView.hidden = NO;
    // 弹窗初始选中当前任务
    [self xqqPrepareSelector];
    [self xqqRemoveExistingSelectorPanel];
    [self setupSelectorPanel];
    [self xqqRefreshSelectorSelection];
}

- (void)confirmUserSelection {
    [self xqqValidateSelectorState];
    if (self.pendingSelectedTask) {
        self.selectedTask = self.pendingSelectedTask;
        [self xqqRefreshCheckInState];
    }
    [self dismissModalViews];
}

- (void)dismissModalViews {
    [self xqqCloseAllModalViews];
}

#pragma mark - Modal

- (void)showSuccessPanelWithPoints:(NSInteger)points {
    // 移除旧的成功弹窗并显示遮罩
    [self xqqPrepareSuccessPanel];

    UIView *panel = WOPMakeView([UIColor clearColor]);
    self.successPanel = panel;
    [self.view addSubview:panel];

    UIImageView *panelBgImageView = WOPMakeImageView([UIImage imageNamed:@"me_checkIn_alert_bg"], UIViewContentModeScaleToFill);
    [panel addSubview:panelBgImageView];

    UILabel *titleLabel = WOPMakeLabel(WOPFont(21, UIFontWeightSemibold), WOPCheckInTitleColor(), @"签到成功");
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:titleLabel];

    UILabel *pointsLabel = WOPMakeLabel(WOPFont(42, UIFontWeightSemibold), [UIColor colorWithRed:1.0 green:0.62 blue:0.08 alpha:1.0],
                                        [NSString stringWithFormat:@"+%ld", (long)points]);
    pointsLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:pointsLabel];

    UILabel *hintLabel = WOPMakeLabel(WOPFont(16, UIFontWeightRegular), [UIColor colorWithWhite:0.66 alpha:1.0], @"明天继续签到领取奖励");
    hintLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:hintLabel];

    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    confirmButton.titleLabel.font = WOPFont(18, UIFontWeightSemibold);
    [confirmButton setTitle:@"确认" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmButton setBackgroundImage:WOPCheckInButtonBackground() forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(dismissModalViews) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:confirmButton];

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:WOPEdgeConstraints(panelBgImageView, panel)];
    [constraints addObjectsFromArray:@[
        [panel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [panel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:24],
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:45],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-45],
        [panel.heightAnchor constraintEqualToConstant:370],

        [titleLabel.topAnchor constraintEqualToAnchor:panel.topAnchor constant:132],
        [titleLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [titleLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],

        [pointsLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:18],
        [pointsLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [pointsLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],

        [hintLabel.topAnchor constraintEqualToAnchor:pointsLabel.bottomAnchor constant:26],
        [hintLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:20],
        [hintLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-20],

        [confirmButton.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:30],
        [confirmButton.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-30],
        [confirmButton.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-34],
        [confirmButton.heightAnchor constraintEqualToConstant:44]
    ]];
    [NSLayoutConstraint activateConstraints:constraints];
}

/// 底部"选择用户"弹窗，高度随任务数变化
- (void)setupSelectorPanel {
    UIView *panel = WOPMakeView([UIColor whiteColor]);
    panel.layer.cornerRadius = 18.0;
    panel.layer.masksToBounds = YES;
    self.selectorPanel = panel;
    [self.view addSubview:panel];

    UIButton *cancelButton = [self selectorButtonWithTitle:@"取消" color:[UIColor colorWithWhite:0.62 alpha:1.0] action:@selector(dismissModalViews)];
    [panel addSubview:cancelButton];

    UILabel *titleLabel = WOPMakeLabel(WOPFont(20, UIFontWeightSemibold), nil, @"选择用户");
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:titleLabel];

    UIButton *confirmButton = [self selectorButtonWithTitle:@"确定" color:WOPCheckInGreenColor() action:@selector(confirmUserSelection)];
    [panel addSubview:confirmButton];

    UIView *line = WOPMakeView([UIColor colorWithWhite:0.90 alpha:1.0]);
    [panel addSubview:line];

    self.selectorTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.selectorTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectorTableView.backgroundColor = [UIColor whiteColor];
    self.selectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.selectorTableView.rowHeight = kWOPSelectorRowHeight;
    self.selectorTableView.delegate = self;
    self.selectorTableView.dataSource = self;
    [self.selectorTableView registerClass:[WOPMKDIOFZTCheckInUserCell class] forCellReuseIdentifier:kWOPCheckInUserCellId];
    [panel addSubview:self.selectorTableView];

    CGFloat panelHeight = MIN(kWOPSelectorMaxHeight, kWOPSelectorChromeHeight + self.tasks.count * kWOPSelectorRowHeight);

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [panel.heightAnchor constraintEqualToConstant:panelHeight],
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [panel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [cancelButton.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:18],
        [cancelButton.topAnchor constraintEqualToAnchor:panel.topAnchor constant:16],

        [titleLabel.centerXAnchor constraintEqualToAnchor:panel.centerXAnchor],
        [titleLabel.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],

        [confirmButton.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-18],
        [confirmButton.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],

        [line.topAnchor constraintEqualToAnchor:panel.topAnchor constant:75.5],
        [line.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [line.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [line.heightAnchor constraintEqualToConstant:0.5],

        [self.selectorTableView.topAnchor constraintEqualToAnchor:line.bottomAnchor],
        [self.selectorTableView.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor],
        [self.selectorTableView.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor],
        [self.selectorTableView.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor]
    ]];
    [constraints addObjectsFromArray:WOPSizeConstraints(cancelButton, 70, 44)];
    [constraints addObjectsFromArray:WOPSizeConstraints(confirmButton, 70, 44)];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (UIButton *)selectorButtonWithTitle:(NSString *)title color:(UIColor *)color action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.font = [UIFont systemFontOfSize:16];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:color forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Date

/// 本周一到周日（东八区）
- (void)reloadWeekDates {
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:kWOPCheckInTimeZoneOffset];
    calendar.firstWeekday = 2; // 周一为一周第一天
    NSDate *startOfWeek = nil;
    NSTimeInterval interval = 0;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear startDate:&startOfWeek interval:&interval forDate:[NSDate date]];

    NSMutableArray *dates = [NSMutableArray arrayWithCapacity:kWOPCheckInWeekDays];
    for (NSInteger i = 0; i < kWOPCheckInWeekDays; i++) {
        NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:i toDate:startOfWeek options:0];
        if (date) {
            [dates addObject:date];
        }
    }
    self.weekDates = dates;
}

/// 已签到日期集合（yyyyMMdd）。有积分或状态表示已签（状态为空也算）的记录才计入
- (NSSet<NSString *> *)signedDateKeysForTask:(XQQCSignTask *)task {
    NSMutableSet *set = [NSMutableSet set];
    for (XQQCSignTaskSignRecord *record in task.signRecords) {
        NSString *key = [self dayKeyForTimestampString:record.dateTimestamp];
        if (key.length == 0) {
            continue;
        }
        if ([record.points integerValue] > 0 || [self isSignedStatus:record.status]) {
            [set addObject:key];
        }
    }
    return set;
}

- (BOOL)isSignedStatus:(NSString *)rawStatus {
    NSString *status = [rawStatus lowercaseString];
    return status.length == 0
        || [status containsString:@"sign"]
        || [status containsString:@"success"]
        || [status isEqualToString:@"1"]
        || [status isEqualToString:@"done"];
}

/// 时间戳兼容秒和毫秒
- (NSString *)dayKeyForTimestampString:(NSString *)timestampString {
    long long value = [timestampString longLongValue];
    if (value <= 0) {
        return @"";
    }
    if (value > 1000000000000LL) {
        value = value / 1000;
    }
    return [self dayKeyForDate:[NSDate dateWithTimeIntervalSince1970:value]];
}

- (NSString *)dayKeyForDate:(NSDate *)date {
    return [WOPCheckInFormatter(@"yyyyMMdd") stringFromDate:date];
}

/// "已连续签到 N 天"，N 用主题绿
- (NSAttributedString *)continuousText:(NSInteger)days {
    NSString *dayString = [NSString stringWithFormat:@"%ld", (long)days];
    NSString *text = [NSString stringWithFormat:@"已连续签到 %@ 天", dayString];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName : WOPFont(19, UIFontWeightRegular), NSForegroundColorAttributeName : WOPCheckInTitleColor()}];
    NSRange range = [text rangeOfString:dayString];
    if (range.location != NSNotFound) {
        [attr addAttributes:@{NSForegroundColorAttributeName : WOPCheckInGreenColor()} range:range];
    }
    return attr;
}

#pragma mark - HUD

- (MBProgressHUD *)showLoadingHUD {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    return hud;
}

- (void)showTextHUD:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message ?: @"";
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.0];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WOPMKDIOFZTCheckInUserCell *cell = [tableView dequeueReusableCellWithIdentifier:kWOPCheckInUserCellId forIndexPath:indexPath];
    XQQCSignTask *task = self.tasks[indexPath.row];
    XQQCSignTask *selectedTask = self.pendingSelectedTask ?: self.selectedTask;
    [cell configWithTask:task selected:(task == selectedTask)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQCSignTask *task = [self xqqTaskAtIndexPath:indexPath];
    if (!task) {
        return;
    }
    self.pendingSelectedTask = task;
    [self xqqRefreshSelectorSelection];
}

#pragma mark - 稳定性与状态保护

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self xqqNormalizeCheckInState];
    [self xqqUpdateCheckInAccessibility];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self xqqCloseAllModalViews];

    // 页面已离开窗口：清理临时选择并隐藏加载框
    if (self.view.window == nil) {
        [self xqqCleanupCheckInResources];
    }
}

/// 保证任务选择状态始终有效
- (void)xqqNormalizeCheckInState {
    if (!self.tasks) {
        self.tasks = @[];
    }

    if (self.tasks.count == 0) {
        self.selectedTask = nil;
        self.pendingSelectedTask = nil;
        return;
    }

    if (!self.selectedTask || ![self.tasks containsObject:self.selectedTask]) {
        self.selectedTask = self.tasks.firstObject;
    }

    if (self.pendingSelectedTask &&
        ![self.tasks containsObject:self.pendingSelectedTask]) {
        self.pendingSelectedTask = self.selectedTask;
    }
}

/// 当前是否存在有效签到任务
- (BOOL)xqqHasValidCheckInTask {
    XQQCSignTask *task = self.selectedTask;

    if (!task) {
        return NO;
    }

    if (![task.taskId isKindOfClass:[NSString class]]) {
        return NO;
    }

    return task.taskId.length > 0;
}

/// 当前任务今天是否已经签到
- (BOOL)xqqTodayAlreadySigned {
    if (!self.selectedTask) {
        return NO;
    }

    NSSet<NSString *> *keys = [self signedDateKeysForTask:self.selectedTask];

    if (keys.count == 0) {
        return NO;
    }

    NSString *todayKey = [self dayKeyForDate:[NSDate date]];

    if (todayKey.length == 0) {
        return NO;
    }

    return [keys containsObject:todayKey];
}

/// 统一刷新签到按钮状态
- (void)xqqRefreshCheckButtonState {
    if (!self.checkButton) {
        return;
    }

    // 有任务就按"已签 / 未签"显示；taskId 是否有效在点击时再判断（见 checkButtonAction）
    BOOL hasTask = self.selectedTask != nil;
    BOOL signedToday = hasTask && [self xqqTodayAlreadySigned];

    BOOL enabled = hasTask && !signedToday;

    self.checkButton.enabled = enabled;
    self.checkButton.alpha = enabled ? 1.0 : 0.65;

    NSString *title = @"暂无签到活动";

    if (hasTask) {
        title = signedToday ? @"今日已签到" : @"立即签到";
    }

    [self.checkButton setTitle:title forState:UIControlStateNormal];
}

/// 统一刷新顶部用户选择区域
- (void)xqqRefreshUserSelectorState {
    if (!self.userView) {
        return;
    }

    BOOL canSwitch = self.tasks.count > 1;

    self.arrowView.hidden = !canSwitch;
    self.userView.userInteractionEnabled = canSwitch;

    if (self.selectedTask) {
        self.userNameLabel.text =
        WOPCheckInTaskDisplayName(self.selectedTask, @"暂无活动用户");

        WOPCheckInSetAvatar(self.userAvatarView, self.selectedTask);
    } else {
        self.userNameLabel.text = @"暂无活动用户";
        WOPCheckInSetAvatar(self.userAvatarView, nil);
    }
}

/// 统一刷新连续签到文字
- (void)xqqRefreshContinuousState {
    if (!self.continuousLabel) {
        return;
    }

    NSInteger days = [self continuousDaysForTask:self.selectedTask];

    self.continuousLabel.attributedText = [self continuousText:days];
}

/// 统一刷新日期区域
- (void)xqqRefreshWeekState {
    NSSet<NSString *> *keys =
    [self signedDateKeysForTask:self.selectedTask];

    [self refreshWeekDaysWithSignedKeys:keys];

    [self xqqUpdateWeekAccessibilityWithSignedKeys:keys];
}

/// 统一刷新当前页面内容（页面唯一的刷新入口）
- (void)xqqRefreshCheckInState {
    [self xqqNormalizeCheckInState];
    [self xqqEnsureWeekDates];

    if (self.ruleLabel) {
        NSString *rewardDesc =
        WOPMKDIOFZTSafeText(self.selectedTask.rewardDesc);

        self.ruleLabel.text =
        rewardDesc.length ? rewardDesc : @"暂无签到规则";
    }

    // 用户名、头像、切换箭头都在这里刷新，避免重复设置头像
    [self xqqRefreshUserSelectorState];
    [self xqqRefreshContinuousState];
    [self xqqRefreshWeekState];
    [self xqqRefreshCheckButtonState];
    [self xqqUpdateCheckInAccessibility];
}

/// 安全取得任务
- (XQQCSignTask *)xqqTaskAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }

    if (indexPath.section != 0) {
        return nil;
    }

    if (indexPath.row < 0 ||
        indexPath.row >= (NSInteger)self.tasks.count) {
        return nil;
    }

    id object = self.tasks[indexPath.row];

    if (![object isKindOfClass:[XQQCSignTask class]]) {
        return nil;
    }

    return (XQQCSignTask *)object;
}

/// 安全取得当前弹窗选择任务
- (XQQCSignTask *)xqqCurrentPendingTask {
    XQQCSignTask *task = self.pendingSelectedTask;

    if (task && [self.tasks containsObject:task]) {
        return task;
    }

    if (self.selectedTask &&
        [self.tasks containsObject:self.selectedTask]) {
        return self.selectedTask;
    }

    return self.tasks.firstObject;
}

/// 更新选择器选中状态
- (void)xqqRefreshSelectorSelection {
    if (!self.selectorTableView) {
        return;
    }

    [self.selectorTableView reloadData];

    XQQCSignTask *task = [self xqqCurrentPendingTask];

    if (!task) {
        return;
    }

    NSUInteger index = [self.tasks indexOfObject:task];

    if (index == NSNotFound) {
        return;
    }

    if (index >= self.tasks.count) {
        return;
    }

    NSIndexPath *indexPath =
    [NSIndexPath indexPathForRow:(NSInteger)index inSection:0];

    if (indexPath.row < [self.selectorTableView numberOfRowsInSection:0]) {
        [self.selectorTableView selectRowAtIndexPath:indexPath
                                             animated:NO
                                       scrollPosition:UITableViewScrollPositionNone];
    }
}

/// 安全关闭所有弹窗
- (void)xqqCloseAllModalViews {
    self.pendingSelectedTask = nil;

    if (self.successPanel) {
        [self.successPanel removeFromSuperview];
        self.successPanel = nil;
    }

    if (self.selectorPanel) {
        [self.selectorPanel removeFromSuperview];
        self.selectorPanel = nil;
    }

    self.selectorTableView.delegate = nil;
    self.selectorTableView.dataSource = nil;
    self.selectorTableView = nil;

    if (self.maskView) {
        self.maskView.hidden = YES;
    }
}

/// 检查弹窗是否正在显示
- (BOOL)xqqHasVisibleModalView {
    if (self.successPanel &&
        !self.successPanel.hidden &&
        self.successPanel.superview) {
        return YES;
    }

    if (self.selectorPanel &&
        !self.selectorPanel.hidden &&
        self.selectorPanel.superview) {
        return YES;
    }

    return NO;
}

/// 更新签到页面 Accessibility
- (void)xqqUpdateCheckInAccessibility {
    if (self.userView) {
        self.userView.isAccessibilityElement = YES;
        self.userView.accessibilityTraits =
        self.tasks.count > 1
        ? UIAccessibilityTraitButton
        : UIAccessibilityTraitStaticText;

        NSString *name =
        WOPCheckInTaskDisplayName(self.selectedTask,
                                  @"暂无活动用户");

        self.userView.accessibilityLabel =
        self.tasks.count > 1
        ? [NSString stringWithFormat:@"当前用户，%@，点击切换", name]
        : [NSString stringWithFormat:@"当前用户，%@", name];
    }

    if (self.userNameLabel) {
        self.userNameLabel.isAccessibilityElement = NO;
    }

    if (self.arrowView) {
        self.arrowView.isAccessibilityElement = NO;
    }

    if (self.checkButton) {
        self.checkButton.isAccessibilityElement = YES;
        self.checkButton.accessibilityTraits =
        self.checkButton.enabled
        ? UIAccessibilityTraitButton
        : UIAccessibilityTraitNotEnabled;

        self.checkButton.accessibilityLabel =
        self.checkButton.currentTitle ?: @"签到";
    }

    if (self.continuousLabel) {
        self.continuousLabel.isAccessibilityElement = YES;
        self.continuousLabel.accessibilityLabel =
        [NSString stringWithFormat:@"连续签到 %ld 天",
         (long)[self continuousDaysForTask:self.selectedTask]];
    }

    if (self.timezoneLabel) {
        self.timezoneLabel.isAccessibilityElement = YES;
        self.timezoneLabel.accessibilityLabel = @"签到日期时区，UTC 加 8";
    }

    if (self.ruleTitleLabel) {
        self.ruleTitleLabel.isAccessibilityElement = YES;
        self.ruleTitleLabel.accessibilityLabel = @"签到规则";
    }

    if (self.ruleLabel) {
        self.ruleLabel.isAccessibilityElement = YES;
        self.ruleLabel.accessibilityLabel =
        self.ruleLabel.text ?: @"暂无签到规则";
    }
}

/// 更新一周日期 Accessibility
- (void)xqqUpdateWeekAccessibilityWithSignedKeys:(NSSet<NSString *> *)signedKeys {
    NSDateFormatter *formatter = WOPCheckInFormatter(@"MM/dd");

    for (NSInteger i = 0;
         i < (NSInteger)self.weekDates.count &&
         i < (NSInteger)self.dateLabels.count;
         i++) {

        UILabel *label = self.dateLabels[i];

        if (!label) {
            continue;
        }

        NSDate *date = self.weekDates[i];

        if (!date) {
            continue;
        }

        NSString *key = [self dayKeyForDate:date];
        BOOL signedDay = key.length > 0 &&
        [signedKeys containsObject:key];

        label.isAccessibilityElement = YES;

        NSString *dateText =
        [formatter stringFromDate:date] ?: @"";

        label.accessibilityLabel =
        signedDay
        ? [NSString stringWithFormat:@"%@，已签到", dateText]
        : [NSString stringWithFormat:@"%@，未签到", dateText];
    }
}

/// 重新检查日期数组是否完整
- (void)xqqEnsureWeekDates {
    if (self.weekDates.count == kWOPCheckInWeekDays) {
        return;
    }

    [self reloadWeekDates];
}

/// 防止加载状态异常导致按钮永久不可点击
- (void)xqqFinishLoadingIfNeeded {
    if (!self.loading) {
        [self xqqRefreshCheckButtonState];
        return;
    }

    self.loading = NO;
    [self xqqRefreshCheckButtonState];
}

/// HUD 安全清理
- (void)xqqHideAllHUD {
    if (!self.isViewLoaded) {
        return;
    }

    [MBProgressHUD hideHUDForView:self.view animated:NO];
}

/// 检查选择器数据状态
- (void)xqqValidateSelectorState {
    if (self.tasks.count <= 1) {
        self.pendingSelectedTask = nil;

        if (self.selectorPanel) {
            [self.selectorPanel removeFromSuperview];
            self.selectorPanel = nil;
        }

        self.selectorTableView = nil;

        if (self.maskView) {
            self.maskView.hidden = YES;
        }

        return;
    }

    XQQCSignTask *task = [self xqqCurrentPendingTask];

    if (!task) {
        self.pendingSelectedTask = self.tasks.firstObject;
    }
}

/// 防止签到成功弹窗重复创建
- (void)xqqRemoveExistingSuccessPanel {
    if (!self.successPanel) {
        return;
    }

    [self.successPanel removeFromSuperview];
    self.successPanel = nil;
}

/// 防止重复创建用户选择弹窗
- (void)xqqRemoveExistingSelectorPanel {
    if (!self.selectorPanel) {
        return;
    }

    [self.selectorPanel removeFromSuperview];
    self.selectorPanel = nil;

    self.selectorTableView = nil;
}

/// 选择器显示前统一准备状态
- (void)xqqPrepareSelector {
    [self xqqNormalizeCheckInState];

    if (self.tasks.count <= 1) {
        return;
    }

    XQQCSignTask *task = [self xqqCurrentPendingTask];

    self.pendingSelectedTask = task ?: self.tasks.firstObject;
}

/// 成功弹窗显示前清理旧状态
- (void)xqqPrepareSuccessPanel {
    [self xqqRemoveExistingSuccessPanel];

    if (self.maskView) {
        self.maskView.hidden = NO;
    }
}

/// 页面销毁前的轻量清理
- (void)xqqCleanupCheckInResources {
    self.pendingSelectedTask = nil;

    if (self.selectorTableView) {
        self.selectorTableView.delegate = nil;
        self.selectorTableView.dataSource = nil;
    }

    [self xqqHideAllHUD];
}

#pragma mark - UITableView Safe Handling

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.selectorTableView) {
        return kWOPSelectorRowHeight;
    }

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView
willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView != self.selectorTableView) {
        return;
    }

    XQQCSignTask *task = [self xqqTaskAtIndexPath:indexPath];

    if (!task) {
        return;
    }

    XQQCSignTask *selectedTask = [self xqqCurrentPendingTask];

    cell.accessibilityTraits =
    task == selectedTask
    ? UIAccessibilityTraitButton | UIAccessibilityTraitSelected
    : UIAccessibilityTraitButton;

    NSString *name =
    WOPCheckInTaskDisplayName(task, @"用户名称");

    cell.accessibilityLabel =
    task == selectedTask
    ? [NSString stringWithFormat:@"%@，已选择", name]
    : name;
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView != self.selectorTableView) {
        return;
    }

    if (indexPath.row >= (NSInteger)self.tasks.count) {
        return;
    }
}

#pragma mark - Safe Dealloc

- (void)dealloc {
    if (_selectorTableView) {
        _selectorTableView.delegate = nil;
        _selectorTableView.dataSource = nil;
    }

    _scrollView.delegate = nil;

    _dayImageViews = nil;
    _dayCheckImageViews = nil;
    _dateLabels = nil;
    _weekDates = nil;
    _tasks = nil;
    _selectedTask = nil;
    _pendingSelectedTask = nil;
}

@end
