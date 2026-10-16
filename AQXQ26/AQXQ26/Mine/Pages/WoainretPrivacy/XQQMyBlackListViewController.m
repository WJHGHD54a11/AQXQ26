//
//  WildFireChat
//
//  Created by wtb on 2025/8/20.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQMyBlackListViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface XQQMyBlackListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)  UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation XQQMyBlackListViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 用 App 内语言设置（LLLLLL），与隐私页入口的"黑名单"文字保持一致
    self.title = LLLLLL(@"Blacklist");
    self.view.backgroundColor = UIColor.whiteColor;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView registerClass:MyBlackListCell.class forCellReuseIdentifier:@"MyBlackListCell"];

    [self getData];
}

- (void)getData {
    __weak typeof(self) ws = self;
    [XQQMineRelation friendBlackList:^(NSArray<XQQCUserInfo *> * _Nonnull friends) {
        ws.dataArr = [NSMutableArray arrayWithArray:friends ?: @[]];
        [ws.tableView reloadData];
        [ws updateEmptyView];
    } error:^(int errCode, NSString * _Nonnull message) {
        [ws updateEmptyView];
    }];
}

/// 黑名单为空（或加载失败）时显示提示，避免整页空白看起来像没加载出来
- (void)updateEmptyView {
    if (self.dataArr.count > 0) {
        self.tableView.backgroundView = nil;
        return;
    }
    UILabel *label = [[UILabel alloc] init];
    label.text = LLLLLL(@"BlacklistEmpty");
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
    label.textColor = RGBCOLOR(176, 176, 176);
    self.tableView.backgroundView = label;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete || indexPath.row >= self.dataArr.count) {
        return;
    }
    XQQCUserInfo *userInfo = self.dataArr[indexPath.row];
    __weak typeof(self) ws = self;

    [SVProgressHUD show];
    [XQQMineRelation friendBlackCancel:userInfo.userId
                                             success:^{
        [SVProgressHUD dismiss];
        // 按对象删除而不是按行号：请求期间列表可能已刷新，行号不一定还对应这个人
        NSUInteger row = [ws.dataArr indexOfObjectIdenticalTo:userInfo];
        if (row != NSNotFound) {
            [ws.dataArr removeObjectAtIndex:row];
            [ws.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]]
                                withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [ws updateEmptyView];
        // 移出黑名单后通讯录里会重新出现这个人
        [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
    } error:^(int errCode, NSString * _Nonnull message) {
        [SVProgressHUD dismiss];
        [ws.tableView setEditing:NO animated:YES];
        [ws.view makeToast:(message.length ? message : LLLLLL(@"LoadFailure")) duration:1.5 position:CSToastPositionCenter];
    }];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return LLLLLL(@"RemoveFromBlacklist");
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MyBlackListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyBlackListCell" forIndexPath:indexPath];
    XQQCUserInfo *userInfo = self.dataArr[indexPath.row];

//    XQQCUserInfo *userInfo = [XQQMineProfile getUserInfo:[self.dataArr objectAtIndex:indexPath.row] refresh:NO];
    
    [cell.iconView sd_setImageWithURL:URL(userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                              context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    cell.tzboeuNameLabel.text = (userInfo.alias.length > 0 ? userInfo.alias : userInfo.displayName);
    if (userInfo.finalName.length > 0) {
        cell.tzboeuNameLabel.text = userInfo.finalName;
    }
    return cell;
}

@end


@implementation MyBlackListCell

- (void)awakeFromNib {
    [super awakeFromNib];

}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.iconView];
        [self.contentView addSubview:self.tzboeuNameLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(70.0, 59.5, UIScreen.mainScreen.bounds.size.width-70.0, 0.5)];
        lineView.backgroundColor = RGBCOLOR(224, 224, 224);
        [self.contentView addSubview:lineView];
    }
    return self;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0,10.0, 40.0, 40.0)];
        _iconView.contentMode = UIViewContentModeScaleAspectFill;
        _iconView.layer.cornerRadius = 20.0;
        _iconView.layer.masksToBounds = YES;
    }return _iconView;
}

- (UILabel *)tzboeuNameLabel {
    if (!_tzboeuNameLabel) {
        _tzboeuNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(70.0, 15.0, UIScreen.mainScreen.bounds.size.width - 80.0, 30.0)];
        _tzboeuNameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:15.0];
        _tzboeuNameLabel.textAlignment = NSTextAlignmentLeft;
        _tzboeuNameLabel.textColor = UIColor.blackColor;
    }return _tzboeuNameLabel;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.iconView sd_cancelCurrentImageLoad];
    self.iconView.image = nil;
}

@end
