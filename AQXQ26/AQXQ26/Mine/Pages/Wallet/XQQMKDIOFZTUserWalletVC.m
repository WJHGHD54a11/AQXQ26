//
//  XQQMKDIOFZTUserWalletVC.m
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTUserWalletVC.h"
#import "XQQMineServices.h"
#import "MBProgressHUD.h"
#import "XQQCSignTasks.h"
#import "XQQCPointsHistory.h"
#import "XQQCSign.h"
#import <objc/runtime.h> // 新增：统计状态挂在关联对象上

static NSString *WOPMKDIOFZTWalletSafeText(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

@interface WOPMKDIOFZTWalletMonthSection : NSObject
@property (nonatomic, copy) NSString *monthTitle;
@property (nonatomic, assign) double income;
@property (nonatomic, assign) double expense;
@property (nonatomic, strong) NSArray<XQQCPointsHistoryRecord *> *records;
@end

@implementation WOPMKDIOFZTWalletMonthSection
@end

@interface WOPMKDIOFZTWalletRecordCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, assign) BOOL firstCell;
@property (nonatomic, assign) BOOL lastCell;
@end

@implementation WOPMKDIOFZTWalletRecordCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    [self.contentView addSubview:self.cardView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    [self.cardView addSubview:self.titleLabel];
    
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.font = [UIFont systemFontOfSize:11];
    self.timeLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    [self.cardView addSubview:self.timeLabel];
    
    self.amountLabel = [[UILabel alloc] init];
    self.amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.amountLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.amountLabel.textColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.amountLabel.textAlignment = NSTextAlignmentRight;
    [self.cardView addSubview:self.amountLabel];
    
    self.idLabel = [[UILabel alloc] init];
    self.idLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.idLabel.font = [UIFont systemFontOfSize:11];
    self.idLabel.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    self.idLabel.textAlignment = NSTextAlignmentRight;
    [self.cardView addSubview:self.idLabel];
    
    self.lineView = [[UIView alloc] init];
    self.lineView.translatesAutoresizingMaskIntoConstraints = NO;
    self.lineView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.cardView addSubview:self.lineView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:17.5],
        [self.cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-17.5],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:21],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:14.5],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.amountLabel.leadingAnchor constant:-12],
        
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.timeLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.idLabel.leadingAnchor constant:-8],
        
        [self.amountLabel.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [self.amountLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-28],
        [self.amountLabel.widthAnchor constraintGreaterThanOrEqualToConstant:82],
        
        [self.idLabel.centerYAnchor constraintEqualToAnchor:self.timeLabel.centerYAnchor],
        [self.idLabel.trailingAnchor constraintEqualToAnchor:self.amountLabel.trailingAnchor],
        [self.idLabel.widthAnchor constraintEqualToConstant:118],
        
        [self.lineView.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:28],
        [self.lineView.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-28],
        [self.lineView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
        [self.lineView.heightAnchor constraintEqualToConstant:0.5]
    ]];
}

- (void)configWithRecord:(XQQCPointsHistoryRecord *)record first:(BOOL)first last:(BOOL)last dateText:(NSString *)dateText {
    self.firstCell = first;
    self.lastCell = last;
    NSString *changeType = WOPMKDIOFZTWalletSafeText(record.changeType);
    NSString *recordId = WOPMKDIOFZTWalletSafeText(record.id).length ? WOPMKDIOFZTWalletSafeText(record.id) : WOPMKDIOFZTWalletSafeText(record.taskId);
    self.titleLabel.text = [self titleForChangeType:changeType];
    double value = [record.changeValue doubleValue];
    self.amountLabel.text = value >= 0 ? [NSString stringWithFormat:@"+%.2f", value] : [NSString stringWithFormat:@"%.2f", value];
    self.timeLabel.text = dateText.length ? dateText : @"--";
    self.idLabel.text = recordId.length ? [NSString stringWithFormat:@"ID:%@", recordId] : @"";
    self.lineView.hidden = last;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self updateCardCornerMask];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateCardCornerMask];
}

- (void)updateCardCornerMask {
    self.cardView.layer.mask = nil;
    if (!self.firstCell && !self.lastCell) {
        self.cardView.layer.cornerRadius = 0;
        self.cardView.layer.masksToBounds = NO;
        if (@available(iOS 11.0, *)) {
            self.cardView.layer.maskedCorners = 0;
        }
        return;
    }
    
    self.cardView.layer.cornerRadius = 10.0;
    self.cardView.layer.masksToBounds = YES;
    if (@available(iOS 11.0, *)) {
        CACornerMask corners = 0;
        if (self.firstCell) {
            corners |= kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
        if (self.lastCell) {
            corners |= kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        }
        self.cardView.layer.maskedCorners = corners;
        return;
    }
    
    if (CGRectIsEmpty(self.cardView.bounds)) {
        return;
    }
    UIRectCorner corners = 0;
    if (self.firstCell) {
        corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
    }
    if (self.lastCell) {
        corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
    }
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.cardView.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(10.0, 10.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.cardView.bounds;
    maskLayer.path = path.CGPath;
    self.cardView.layer.mask = maskLayer;
}

- (NSString *)titleForChangeType:(NSString *)changeType {
    if ([changeType isEqualToString:@"SIGN_IN"]) {
        return @"签到";
    }
    if ([changeType isEqualToString:@"RE_SIGN"]) {
        return @"补签";
    }
    if ([changeType isEqualToString:@"ADMIN_ADJUST"]) {
        return @"系统";
    }
    return @"系统";
}

@end

@interface XQQMKDIOFZTUserWalletVC () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIImageView *walletCardView;
@property (nonatomic, strong) UILabel *balanceLabel;
@property (nonatomic, strong) UIButton *allButton;
@property (nonatomic, strong) UIButton *incomeButton;
@property (nonatomic, strong) UIButton *expenseButton;
@property (nonatomic, strong) UIButton *packetButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSArray<UIButton *> *filterButtons;
@property (nonatomic, strong) NSArray<XQQCPointsHistoryRecord *> *records;
@property (nonatomic, strong) NSArray<WOPMKDIOFZTWalletMonthSection *> *monthSections;
@property (nonatomic, assign) NSInteger selectedFilterIndex;
@property (nonatomic, assign) BOOL loading;
@end

// 新增：钱包数据的核对与统计，只读取数据、不修改界面，实现在文件尾部
@interface XQQMKDIOFZTUserWalletVC (XQQWalletDiagnostics)
- (void)xqq_beginLoad;                                                     // 新增
- (void)xqq_finishLoadWithTasks:(nullable XQQCSignTasks *)tasks
                        history:(nullable XQQCPointsHistory *)history
                   errorMessage:(nullable NSString *)errorMessage;        // 新增
- (void)xqq_recordFilterChangeFrom:(NSInteger)oldIndex to:(NSInteger)newIndex; // 新增
- (void)xqq_recordSectionsBuiltFromRecords:(NSArray<XQQCPointsHistoryRecord *> *)records; // 新增
- (void)xqq_verifyMonthSections;                                           // 新增
@end

@implementation XQQMKDIOFZTUserWalletVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的钱包";
    self.navigationItem.title = @"我的钱包";
    self.view.backgroundColor = [UIColor whiteColor];
    self.records = @[];
    self.monthSections = @[];
    [self setupUI];
    [self loadWalletData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
}

#pragma mark - UI

- (void)setupUI {
    [self setupHeaderCard];
    [self setupFilterView];
    [self setupTableView];
}

- (void)setupHeaderCard {
    self.walletCardView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_wallet_head_bg"]];
    self.walletCardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.walletCardView.userInteractionEnabled = YES;
    self.walletCardView.contentMode = UIViewContentModeScaleToFill;
    self.walletCardView.layer.cornerRadius = 14.0;
    self.walletCardView.layer.masksToBounds = YES;
    [self.view addSubview:self.walletCardView];
    
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_wallet_icon"]];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.walletCardView addSubview:iconView];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"球币钱包";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.walletCardView addSubview:titleLabel];
    
    UILabel *balanceTitleLabel = [[UILabel alloc] init];
    balanceTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    balanceTitleLabel.text = @"余额";
    balanceTitleLabel.textColor = [UIColor whiteColor];
    balanceTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    [self.walletCardView addSubview:balanceTitleLabel];
    
    self.balanceLabel = [[UILabel alloc] init];
    self.balanceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.balanceLabel.text = @"0.00";
    self.balanceLabel.textColor = [UIColor whiteColor];
    self.balanceLabel.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBold];
    [self.walletCardView addSubview:self.balanceLabel];
    
    UIImageView *dateView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_wallet_rili_bg"]];
    dateView.translatesAutoresizingMaskIntoConstraints = NO;
    dateView.contentMode = UIViewContentModeScaleToFill;
    dateView.userInteractionEnabled = NO;
    [self.walletCardView addSubview:dateView];
    
    UIImageView *calendarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_checkIn_rili"]];
    calendarView.translatesAutoresizingMaskIntoConstraints = NO;
    calendarView.contentMode = UIViewContentModeScaleAspectFit;
    [dateView addSubview:calendarView];
    
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.walletCardView.topAnchor constraintEqualToAnchor:safe.topAnchor constant:24],
        [self.walletCardView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        [self.walletCardView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [self.walletCardView.heightAnchor constraintEqualToConstant:130],
        
        [iconView.leadingAnchor constraintEqualToAnchor:self.walletCardView.leadingAnchor constant:16],
        [iconView.topAnchor constraintEqualToAnchor:self.walletCardView.topAnchor constant:19],
        [iconView.widthAnchor constraintEqualToConstant:46],
        [iconView.heightAnchor constraintEqualToConstant:46],
        
        [titleLabel.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:10],
        [titleLabel.centerYAnchor constraintEqualToAnchor:iconView.centerYAnchor],
        
        [balanceTitleLabel.leadingAnchor constraintEqualToAnchor:self.walletCardView.leadingAnchor constant:16],
        [balanceTitleLabel.bottomAnchor constraintEqualToAnchor:self.walletCardView.bottomAnchor constant:-19],
        
        [self.balanceLabel.leadingAnchor constraintEqualToAnchor:self.walletCardView.leadingAnchor constant:65],
        [self.balanceLabel.bottomAnchor constraintEqualToAnchor:self.walletCardView.bottomAnchor constant:-19],

        [dateView.trailingAnchor constraintEqualToAnchor:self.walletCardView.trailingAnchor constant:0],
        [dateView.topAnchor constraintEqualToAnchor:self.walletCardView.topAnchor constant:24],
        [dateView.widthAnchor constraintEqualToConstant:54],
        [dateView.heightAnchor constraintEqualToConstant:30],
        
        [calendarView.centerXAnchor constraintEqualToAnchor:dateView.centerXAnchor],
        [calendarView.centerYAnchor constraintEqualToAnchor:dateView.centerYAnchor],
        [calendarView.widthAnchor constraintEqualToConstant:22],
        [calendarView.heightAnchor constraintEqualToConstant:23.5]
    ]];
}

- (void)setupFilterView {
    UILabel *detailLabel = [[UILabel alloc] init];
    detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    detailLabel.text = @"明细";
    detailLabel.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    detailLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.view addSubview:detailLabel];
    
    self.allButton = [self createFilterButton:@"全部" selected:YES];
    self.incomeButton = [self createFilterButton:@"收入" selected:NO];
    self.expenseButton = [self createFilterButton:@"支出" selected:NO];
    self.packetButton = [self createFilterButton:@"红包" selected:NO];
    self.filterButtons = @[self.allButton, self.incomeButton, self.expenseButton, self.packetButton];
    
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:self.filterButtons];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillEqually;
    stackView.spacing = 10;
    [self.view addSubview:stackView];
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.refreshButton.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.refreshButton.layer.cornerRadius = 17.5;
    self.refreshButton.layer.masksToBounds = YES;
    [self.refreshButton setImage:[UIImage imageNamed:@"me_wallet_refresh"] forState:UIControlStateNormal];
    [self.refreshButton addTarget:self action:@selector(refreshButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.refreshButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [detailLabel.topAnchor constraintEqualToAnchor:self.walletCardView.bottomAnchor constant:23],
        [detailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:18],
        
        [stackView.topAnchor constraintEqualToAnchor:detailLabel.bottomAnchor constant:16.5],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:17.5],
        [stackView.widthAnchor constraintEqualToConstant:65*4+30],
        [stackView.heightAnchor constraintEqualToConstant:35],
        
        [self.refreshButton.centerYAnchor constraintEqualToAnchor:stackView.centerYAnchor],
        [self.refreshButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-18],
        [self.refreshButton.widthAnchor constraintEqualToConstant:35],
        [self.refreshButton.heightAnchor constraintEqualToConstant:35]
    ]];
}

- (UIButton *)createFilterButton:(NSString *)title selected:(BOOL)selected {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.layer.cornerRadius = 17.5;
    button.layer.masksToBounds = YES;
    button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(filterButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self updateFilterButton:button selected:selected];
    return button;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 72.0;
    self.tableView.sectionHeaderHeight = 74.0;
    self.tableView.estimatedRowHeight = 72.0;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[WOPMKDIOFZTWalletRecordCell class] forCellReuseIdentifier:@"WOPMKDIOFZTWalletRecordCell"];
    [self.view addSubview:self.tableView];
    
    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyLabel.text = @"暂无明细";
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.font = [UIFont systemFontOfSize:15];
    self.emptyLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    self.emptyLabel.hidden = YES;
    [self.view addSubview:self.emptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.allButton.bottomAnchor constant:18],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        
        [self.emptyLabel.topAnchor constraintEqualToAnchor:self.tableView.topAnchor constant:80],
        [self.emptyLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:35],
        [self.emptyLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-35]
    ]];
}

#pragma mark - Action

- (void)refreshButtonAction {
    [self loadWalletData];
}

- (void)filterButtonAction:(UIButton *)sender {
    NSInteger index = [self.filterButtons indexOfObject:sender];
    if (index == NSNotFound || index == self.selectedFilterIndex) {
        return;
    }
    [self xqq_recordFilterChangeFrom:self.selectedFilterIndex to:index]; // 新增
    self.selectedFilterIndex = index;
    for (NSInteger i = 0; i < self.filterButtons.count; i++) {
        [self updateFilterButton:self.filterButtons[i] selected:i == index];
    }
    [self rebuildSections];
}

#pragma mark - Data

- (void)loadWalletData {
    if (self.loading) {
        return;
    }
    self.loading = YES;
    [self showLoadingHUD];
    [self xqq_beginLoad]; // 新增
    
    dispatch_group_t group = dispatch_group_create();
    __block XQQCSignTasks *tasks = nil;
    __block XQQCPointsHistory *history = nil;
    __block NSString *errorMessage = nil;
    
    dispatch_group_enter(group);
    [XQQMineExtra signTasks:^(XQQCSignTasks * _Nonnull result) {
        tasks = result;
        dispatch_group_leave(group);
    } error:^(int errCode, NSString * _Nonnull message) {
        errorMessage = message.length ? message : @"获取钱包余额失败";
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [XQQMineExtra pointsHistory:@{@"pageNo": @1, @"pageSize": @100} success:^(XQQCPointsHistory * _Nonnull result) {
        history = result;
        dispatch_group_leave(group);
    } error:^(int errCode, NSString * _Nonnull message) {
        errorMessage = message.length ? message : @"获取钱包明细失败";
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        self.loading = NO;
        [self hideLoadingHUD];
        [self xqq_finishLoadWithTasks:tasks history:history errorMessage:errorMessage]; // 新增
        if (tasks) {
            self.balanceLabel.text = [self moneyTextFromValue:[tasks.totalPoints doubleValue] forceSign:NO];
        }
        if (history) {
            self.records = history.records ?: @[];
            [self rebuildSections];
        }
        if (errorMessage.length && !history && !tasks) {
            [self showTextHUD:errorMessage];
        }
    });
}

- (void)rebuildSections {
    NSArray<XQQCPointsHistoryRecord *> *filteredRecords = [self filteredRecords];
    [self xqq_recordSectionsBuiltFromRecords:filteredRecords]; // 新增
    NSMutableDictionary<NSString *, NSMutableArray<XQQCPointsHistoryRecord *> *> *recordMap = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *monthOrder = [NSMutableArray array];
    
    for (XQQCPointsHistoryRecord *record in filteredRecords) {
        NSString *month = [self monthTextFromTimestamp:record.createTimestamp];
        if (!month.length) {
            month = @"未知月份";
        }
        if (!recordMap[month]) {
            recordMap[month] = [NSMutableArray array];
            [monthOrder addObject:month];
        }
        [recordMap[month] addObject:record];
    }
    
    NSMutableArray<WOPMKDIOFZTWalletMonthSection *> *sections = [NSMutableArray array];
    for (NSString *month in monthOrder) {
        WOPMKDIOFZTWalletMonthSection *section = [[WOPMKDIOFZTWalletMonthSection alloc] init];
        section.monthTitle = month;
        section.records = recordMap[month];
        double income = 0;
        double expense = 0;
        for (XQQCPointsHistoryRecord *record in section.records) {
            double value = [record.changeValue doubleValue];
            if (value >= 0) {
                income += value;
            } else {
                expense += fabs(value);
            }
        }
        section.income = income;
        section.expense = expense;
        [sections addObject:section];
    }
    self.monthSections = sections;
    [self xqq_verifyMonthSections]; // 新增
    self.emptyLabel.hidden = self.monthSections.count > 0;
    [self.tableView reloadData];
}

- (NSArray<XQQCPointsHistoryRecord *> *)filteredRecords {
    if (self.selectedFilterIndex == 0) {
        return self.records ?: @[];
    }
    NSMutableArray<XQQCPointsHistoryRecord *> *result = [NSMutableArray array];
    for (XQQCPointsHistoryRecord *record in self.records) {
        double value = [record.changeValue doubleValue];
        if (self.selectedFilterIndex == 1 && value >= 0) {
            [result addObject:record];
        } else if (self.selectedFilterIndex == 2 && value < 0) {
            [result addObject:record];
        } else if (self.selectedFilterIndex == 3 && [self isPacketRecord:record]) {
            [result addObject:record];
        }
    }
    return result;
}

- (BOOL)isPacketRecord:(XQQCPointsHistoryRecord *)record {
    NSString *type = WOPMKDIOFZTWalletSafeText(record.changeType).lowercaseString ?: @"";
    return [type containsString:@"red"] || [type containsString:@"packet"];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.monthSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.monthSections[section].records.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 74.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WOPMKDIOFZTWalletMonthSection *sectionModel = self.monthSections[section];
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor whiteColor];
    
    UILabel *monthLabel = [[UILabel alloc] init];
    monthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    monthLabel.text = sectionModel.monthTitle;
    monthLabel.textColor = [UIColor colorWithWhite:0.16 alpha:1.0];
    monthLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [header addSubview:monthLabel];
    
    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"me_wallet_date_down"]];
    arrowView.translatesAutoresizingMaskIntoConstraints = NO;
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    [header addSubview:arrowView];
    
    UILabel *incomeLabel = [[UILabel alloc] init];
    incomeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    incomeLabel.text = [NSString stringWithFormat:@"收入  %.2f", sectionModel.income];
    incomeLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    incomeLabel.font = [UIFont systemFontOfSize:15];
    [header addSubview:incomeLabel];
    
    UILabel *expenseLabel = [[UILabel alloc] init];
    expenseLabel.translatesAutoresizingMaskIntoConstraints = NO;
    expenseLabel.text = [NSString stringWithFormat:@"支出  %.2f", sectionModel.expense];
    expenseLabel.textColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    expenseLabel.font = [UIFont systemFontOfSize:15];
    [header addSubview:expenseLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [monthLabel.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:18],
        [monthLabel.topAnchor constraintEqualToAnchor:header.topAnchor constant:6],
        
        [arrowView.leadingAnchor constraintEqualToAnchor:monthLabel.trailingAnchor constant:10],
        [arrowView.centerYAnchor constraintEqualToAnchor:monthLabel.centerYAnchor],
        [arrowView.widthAnchor constraintEqualToConstant:18],
        [arrowView.heightAnchor constraintEqualToConstant:18],
        
        [incomeLabel.leadingAnchor constraintEqualToAnchor:monthLabel.leadingAnchor],
        [incomeLabel.topAnchor constraintEqualToAnchor:monthLabel.bottomAnchor constant:14],
        
        [expenseLabel.leadingAnchor constraintEqualToAnchor:incomeLabel.trailingAnchor constant:50],
        [expenseLabel.centerYAnchor constraintEqualToAnchor:incomeLabel.centerYAnchor]
    ]];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WOPMKDIOFZTWalletRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WOPMKDIOFZTWalletRecordCell" forIndexPath:indexPath];
    WOPMKDIOFZTWalletMonthSection *section = self.monthSections[indexPath.section];
    XQQCPointsHistoryRecord *record = section.records[indexPath.row];
    BOOL first = indexPath.row == 0;
    BOOL last = indexPath.row == section.records.count - 1;
    [cell configWithRecord:record first:first last:last dateText:[self dateTextFromTimestamp:record.createTimestamp]];
    return cell;
}

#pragma mark - Format

- (void)updateFilterButton:(UIButton *)button selected:(BOOL)selected {
    button.backgroundColor = selected ? [UIColor clearColor] : [UIColor colorWithWhite:0.96 alpha:1.0];
    button.layer.borderWidth = selected ? 1.0 : 0;
    button.layer.borderColor = [UIColor colorWithRed:0.23 green:0.86 blue:0.30 alpha:1.0].CGColor;
    [button setTitleColor:selected ? [UIColor colorWithRed:0.23 green:0.86 blue:0.30 alpha:1.0] : [UIColor colorWithWhite:0.16 alpha:1.0] forState:UIControlStateNormal];
}

- (NSString *)moneyTextFromValue:(double)value forceSign:(BOOL)forceSign {
    if (forceSign && value >= 0) {
        return [NSString stringWithFormat:@"+%.2f", value];
    }
    return [NSString stringWithFormat:@"%.2f", value];
}

- (NSDate *)dateFromTimestamp:(NSString *)timestamp {
    if (![timestamp isKindOfClass:[NSString class]] || timestamp.length == 0) {
        return nil;
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([timestamp rangeOfCharacterFromSet:nonDigits].location == NSNotFound) {
        NSTimeInterval time = [timestamp doubleValue];
        if (time > 1000000000000) {
            time = time / 1000.0;
        }
        return [NSDate dateWithTimeIntervalSince1970:time];
    }
    NSArray<NSString *> *formats = @[@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS", @"yyyy-MM-dd'T'HH:mm:ss", @"yyyy-MM-dd HH:mm:ss"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    for (NSString *format in formats) {
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:timestamp];
        if (date) {
            return date;
        }
    }
    return nil;
}

- (NSString *)dateTextFromTimestamp:(NSString *)timestamp {
    NSDate *date = [self dateFromTimestamp:timestamp];
    if (!date) {
        return timestamp ?: @"";
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy.MM.dd HH:mm:ss";
    return [formatter stringFromDate:date];
}

- (NSString *)monthTextFromTimestamp:(NSString *)timestamp {
    NSDate *date = [self dateFromTimestamp:timestamp];
    if (!date) {
        return @"";
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy/MM";
    return [formatter stringFromDate:date];
}

#pragma mark - HUD

- (void)showLoadingHUD {
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
}

- (void)hideLoadingHUD {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)showTextHUD:(NSString *)text {
    if (!text.length) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    [hud hideAnimated:YES afterDelay:1.5];
}

@end


#pragma mark - 新增：钱包数据核对与统计

// 新增：以下代码只读取接口返回的数据和页面已有的状态，结果记在关联对象里，
// 不修改任何界面和数据；日志只在 Debug 下输出
static const void *kXQQWalletDiagnosticsKey = &kXQQWalletDiagnosticsKey; // 新增
static const double kXQQWalletAmountTolerance = 0.005;                  // 新增：金额比较允许的误差（显示保留两位小数）

@implementation XQQMKDIOFZTUserWalletVC (XQQWalletDiagnostics)

// 新增：本页的统计状态，懒加载后挂在关联对象上
- (NSMutableDictionary<NSString *, id> *)xqq_walletState {
    NSMutableDictionary<NSString *, id> *state = objc_getAssociatedObject(self, kXQQWalletDiagnosticsKey);
    if (!state) {
        state = [NSMutableDictionary dictionary];
        state[@"filterUsage"] = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kXQQWalletDiagnosticsKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return state;
}

// 新增：筛选项的名字，和页面上"全部 / 收入 / 支出 / 红包"四个按钮的顺序一致
+ (NSString *)xqq_filterNameAtIndex:(NSInteger)index {
    switch (index) {
        case 0:  return @"all";
        case 1:  return @"income";
        case 2:  return @"expense";
        case 3:  return @"packet";
        default: return [NSString stringWithFormat:@"unknown%ld", (long)index];
    }
}

// 新增：记录里的金额字符串能否解析成数字（"abc"、空串会被 doubleValue 当成 0，显示为 +0.00）
+ (BOOL)xqq_isNumericAmount:(nullable NSString *)text {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        return NO;
    }
    NSScanner *scanner = [NSScanner scannerWithString:[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]];
    double value = 0;
    return [scanner scanDouble:&value] && scanner.isAtEnd;
}

// 新增：loadWalletData 开始请求时调用，记下开始时间和累计请求次数
- (void)xqq_beginLoad {
    NSMutableDictionary<NSString *, id> *state = [self xqq_walletState];
    state[@"loadStart"] = @(CACurrentMediaTime());
    state[@"loadCount"] = @([state[@"loadCount"] unsignedIntegerValue] + 1);
}

// 新增：两个请求都返回后调用：记下耗时、哪个请求失败，并核对返回的余额和明细
- (void)xqq_finishLoadWithTasks:(nullable XQQCSignTasks *)tasks
                        history:(nullable XQQCPointsHistory *)history
                   errorMessage:(nullable NSString *)errorMessage {
    NSMutableDictionary<NSString *, id> *state = [self xqq_walletState];
    CFTimeInterval cost = CACurrentMediaTime() - [state[@"loadStart"] doubleValue];
    state[@"lastLoadMs"] = @(round(cost * 1000.0));
    state[@"lastBalanceOK"] = @(tasks != nil);
    state[@"lastHistoryOK"] = @(history != nil);
    if (!tasks || !history) {
        state[@"partialFailureCount"] = @([state[@"partialFailureCount"] unsignedIntegerValue] + 1);
    }

    NSDictionary<NSString *, id> *report = history ? [self xqq_auditRecords:history.records ?: @[] total:history.total] : @{};
    state[@"lastAudit"] = report;
    if (tasks && history) {
        state[@"balanceMatchesLatest"] = @([self xqq_balance:tasks.totalPoints matchesLatestOf:history.records]);
    }
#ifdef DEBUG
    NSLog(@"[Wallet] load #%@ %@ms balanceOK=%d historyOK=%d error=%@ audit=%@ balanceMatchesLatest=%@",
          state[@"loadCount"], state[@"lastLoadMs"], tasks != nil, history != nil,
          errorMessage.length ? @"yes" : @"no", report, state[@"balanceMatchesLatest"] ?: @"-");
#endif
}

// 新增：核对一页明细：
// - 条数：本页条数与接口给的总数（total > 本页条数说明只显示了前 100 条）
// - 数据问题：金额不是数字、时间解析不出来（会归到"未知月份"）、ID 重复、未知的变动类型
// - 余额连续性：按时间从新到旧，相邻两条应满足 上一条变动后余额 = 这一条变动后余额 - 这一条的变动值
// - 合计：全部收入、全部支出
- (NSDictionary<NSString *, id> *)xqq_auditRecords:(NSArray<XQQCPointsHistoryRecord *> *)records total:(int)total {
    NSUInteger badAmount = 0, badTime = 0, duplicateId = 0, unknownType = 0, balanceBreak = 0, outOfOrder = 0;
    double income = 0, expense = 0;
    NSMutableSet<NSString *> *seenIds = [NSMutableSet set];
    NSSet<NSString *> *knownTypes = [NSSet setWithArray:@[@"SIGN_IN", @"RE_SIGN", @"ADMIN_ADJUST"]];

    for (NSUInteger i = 0; i < records.count; i++) {
        XQQCPointsHistoryRecord *record = records[i];
        if (![XQQMKDIOFZTUserWalletVC xqq_isNumericAmount:record.changeValue]) {
            badAmount += 1;
        }
        double value = [record.changeValue doubleValue];
        if (value >= 0) {
            income += value;
        } else {
            expense += fabs(value);
        }
        if (![self dateFromTimestamp:record.createTimestamp]) {
            badTime += 1;
        }
        NSString *recordId = WOPMKDIOFZTWalletSafeText(record.id);
        if (recordId.length) {
            if ([seenIds containsObject:recordId]) {
                duplicateId += 1;
            }
            [seenIds addObject:recordId];
        }
        NSString *type = WOPMKDIOFZTWalletSafeText(record.changeType);
        if (![knownTypes containsObject:type] && ![self isPacketRecord:record]) {
            unknownType += 1;
        }
        if (i + 1 < records.count && ![self xqq_record:record followsRecord:records[i + 1]]) {
            balanceBreak += 1;
        }
        NSDate *date = [self dateFromTimestamp:record.createTimestamp];
        NSDate *olderDate = (i + 1 < records.count) ? [self dateFromTimestamp:records[i + 1].createTimestamp] : nil;
        if (date && olderDate && [date compare:olderDate] == NSOrderedAscending) {
            outOfOrder += 1; // 接口应按时间从新到旧返回
        }
    }
    return @{@"count": @(records.count), @"total": @(total),
             @"truncated": @(total > (int)records.count),
             @"badAmount": @(badAmount), @"badTime": @(badTime),
             @"duplicateId": @(duplicateId), @"unknownType": @(unknownType),
             @"balanceBreak": @(balanceBreak), @"outOfOrder": @(outOfOrder),
             @"byType": [XQQMKDIOFZTUserWalletVC xqq_typeBreakdownOfRecords:records],
             @"income": @(round(income * 100.0) / 100.0), @"expense": @(round(expense * 100.0) / 100.0)};
}

// 新增：较新的一条（newer）是否紧接在较旧的一条（older）之后：
// newer.变动后余额 - newer.变动值 应等于 older.变动后余额。缺少余额字段时无法判断，按连续处理
- (BOOL)xqq_record:(XQQCPointsHistoryRecord *)newer followsRecord:(XQQCPointsHistoryRecord *)older {
    if (![XQQMKDIOFZTUserWalletVC xqq_isNumericAmount:newer.balanceAfter] ||
        ![XQQMKDIOFZTUserWalletVC xqq_isNumericAmount:older.balanceAfter]) {
        return YES;
    }
    double expectedOlder = [newer.balanceAfter doubleValue] - [newer.changeValue doubleValue];
    return fabs(expectedOlder - [older.balanceAfter doubleValue]) < kXQQWalletAmountTolerance;
}

// 新增：顶部余额是否等于最新一条明细的变动后余额。没有明细或最新一条没有余额字段时视为一致
- (BOOL)xqq_balance:(nullable NSString *)balance matchesLatestOf:(nullable NSArray<XQQCPointsHistoryRecord *> *)records {
    XQQCPointsHistoryRecord *latest = records.firstObject;
    if (!latest || ![XQQMKDIOFZTUserWalletVC xqq_isNumericAmount:latest.balanceAfter]) {
        return YES;
    }
    return fabs([balance doubleValue] - [latest.balanceAfter doubleValue]) < kXQQWalletAmountTolerance;
}

// 新增：切换筛选时调用：记下各筛选项被选中的次数
- (void)xqq_recordFilterChangeFrom:(NSInteger)oldIndex to:(NSInteger)newIndex {
    NSMutableDictionary<NSString *, NSNumber *> *usage = [self xqq_walletState][@"filterUsage"];
    NSString *name = [XQQMKDIOFZTUserWalletVC xqq_filterNameAtIndex:newIndex];
    usage[name] = @(usage[name].unsignedIntegerValue + 1);
#ifdef DEBUG
    NSLog(@"[Wallet] filter %@ -> %@, usage=%@",
          [XQQMKDIOFZTUserWalletVC xqq_filterNameAtIndex:oldIndex], name, usage);
#endif
}

// 新增：按月分组前调用：记下当前筛选下的条数、覆盖的月份数、最早和最晚的时间，
// 以及筛选后的收入 / 支出合计（和各月表头里显示的合计相加后应该相等）
- (void)xqq_recordSectionsBuiltFromRecords:(NSArray<XQQCPointsHistoryRecord *> *)records {
    NSMutableSet<NSString *> *months = [NSMutableSet set];
    NSDate *earliest = nil, *latest = nil;
    double income = 0, expense = 0;
    for (XQQCPointsHistoryRecord *record in records) {
        NSDate *date = [self dateFromTimestamp:record.createTimestamp];
        if (date) {
            earliest = (!earliest || [date compare:earliest] == NSOrderedAscending) ? date : earliest;
            latest = (!latest || [date compare:latest] == NSOrderedDescending) ? date : latest;
        }
        [months addObject:[self monthTextFromTimestamp:record.createTimestamp] ?: @""];
        double value = [record.changeValue doubleValue];
        if (value >= 0) {
            income += value;
        } else {
            expense += fabs(value);
        }
    }
    NSMutableDictionary<NSString *, id> *state = [self xqq_walletState];
    state[@"lastSections"] = @{@"filter": [XQQMKDIOFZTUserWalletVC xqq_filterNameAtIndex:self.selectedFilterIndex],
                               @"count": @(records.count), @"months": @(months.count),
                               @"income": @(round(income * 100.0) / 100.0),
                               @"expense": @(round(expense * 100.0) / 100.0),
                               @"spanDays": @(earliest && latest ? floor([latest timeIntervalSinceDate:earliest] / 86400.0) : 0)};
#ifdef DEBUG
    NSLog(@"[Wallet] sections %@", state[@"lastSections"]);
#endif
}

// 新增：本页所有统计的汇总
- (NSDictionary<NSString *, id> *)xqq_walletStatistics {
    NSMutableDictionary<NSString *, id> *state = [self xqq_walletState];
    return @{@"loadCount": state[@"loadCount"] ?: @0,
             @"lastLoadMs": state[@"lastLoadMs"] ?: @0,
             @"partialFailureCount": state[@"partialFailureCount"] ?: @0,
             @"balanceMatchesLatest": state[@"balanceMatchesLatest"] ?: @YES,
             @"lastAudit": state[@"lastAudit"] ?: @{},
             @"lastSections": state[@"lastSections"] ?: @{},
             @"filterUsage": [state[@"filterUsage"] copy] ?: @{},
             @"sectionsMatch": state[@"sectionsMatch"] ?: @YES,
             @"visibleSeconds": @(round([state[@"visibleSeconds"] doubleValue]))};
}


// 新增：按变动类型（SIGN_IN / RE_SIGN / ADMIN_ADJUST / 红包等）统计条数和金额合计
+ (NSDictionary<NSString *, NSDictionary *> *)xqq_typeBreakdownOfRecords:(NSArray<XQQCPointsHistoryRecord *> *)records {
    NSMutableDictionary<NSString *, NSNumber *> *counts = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *sums = [NSMutableDictionary dictionary];
    for (XQQCPointsHistoryRecord *record in records) {
        NSString *type = WOPMKDIOFZTWalletSafeText(record.changeType);
        type = type.length ? type : @"(empty)";
        counts[type] = @(counts[type].unsignedIntegerValue + 1);
        sums[type] = @(sums[type].doubleValue + [record.changeValue doubleValue]);
    }
    NSMutableDictionary<NSString *, NSDictionary *> *result = [NSMutableDictionary dictionary];
    [counts enumerateKeysAndObjectsUsingBlock:^(NSString *type, NSNumber *count, BOOL *stop) {
        result[type] = @{@"count": count, @"sum": @(round(sums[type].doubleValue * 100.0) / 100.0)};
    }];
    return result;
}

// 新增：按月分组后核对：各月表头的收入、支出、条数加起来，应等于分组前的合计（xqq_recordSectionsBuiltFromRecords: 记下的）
- (void)xqq_verifyMonthSections {
    double income = 0, expense = 0;
    NSUInteger count = 0;
    for (WOPMKDIOFZTWalletMonthSection *section in self.monthSections) {
        income += section.income;
        expense += section.expense;
        count += section.records.count;
    }
    NSDictionary<NSString *, id> *built = [self xqq_walletState][@"lastSections"];
    BOOL matches = [built[@"count"] unsignedIntegerValue] == count &&
                   fabs([built[@"income"] doubleValue] - round(income * 100.0) / 100.0) < kXQQWalletAmountTolerance &&
                   fabs([built[@"expense"] doubleValue] - round(expense * 100.0) / 100.0) < kXQQWalletAmountTolerance;
    [self xqq_walletState][@"sectionsMatch"] = @(matches);
#ifdef DEBUG
    if (!matches) {
        NSLog(@"[Wallet] month sections mismatch: built=%@ sections count=%lu income=%.2f expense=%.2f",
              built, (unsigned long)count, income, expense);
    }
#endif
}

// 新增：进入钱包页时记下时间，离开时算出本次停留时长
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self xqq_walletState][@"appearTime"] = @(CACurrentMediaTime());
}

// 新增：本次停留时长（秒），累计到 visibleSeconds
- (void)xqq_recordVisibleTime {
    NSMutableDictionary<NSString *, id> *state = [self xqq_walletState];
    NSNumber *appearTime = state[@"appearTime"];
    if (!appearTime) {
        return;
    }
    state[@"visibleSeconds"] = @([state[@"visibleSeconds"] doubleValue] + CACurrentMediaTime() - appearTime.doubleValue);
    [state removeObjectForKey:@"appearTime"];
}

// 新增：离开钱包页时在 Debug 下输出本页统计汇总
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self xqq_recordVisibleTime];
#ifdef DEBUG
    NSLog(@"[Wallet] statistics %@", [self xqq_walletStatistics]);
#endif
}

@end
