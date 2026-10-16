//
//  XQQMKDIOFZTAvatarRecordVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/29/24.
//

#import "XQQMKDIOFZTAvatarRecordVC.h"
#import "XQQMKDIOFZTAvatarVC.h"
#import "XQQMKDIOFZTAvatarCVCell.h"
#import "XQQMKDIOFZTAvatarRecordCRView.h"

@interface XQQMKDIOFZTAvatarRecordVC ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UICollectionView *waxiouvCV;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *waxiouvLayout;
@property (nonatomic, strong) NSMutableArray<NSArray<AvatarHistoryList *> *> *waxiouvAvatars;
@property (nonatomic, strong) NSMutableArray<NSString *> *waxiouvHeads;

@end

@implementation XQQMKDIOFZTAvatarRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    if (_isChinese) {
        self.navigationItem.title = @"头像更改历史";
    }else {
        self.navigationItem.title = @"Avatar change history";
    }
    UIButton *waxiouvClearBtn = [self itemTitle:(_isChinese?@"清除":@"Clear") action:@selector(waxiouvClearAvatarRecord)];
    [waxiouvClearBtn setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:waxiouvClearBtn];
    
    [self requestAvatarHistroy];
    _waxiouvLayout.sectionInset = UIEdgeInsetsMake(15.0, 25.0, 15.0, 25.0);
    _waxiouvLayout.itemSize = CGSizeMake(70.0, 70.0);
    _waxiouvLayout.minimumInteritemSpacing = 0.0;
    _waxiouvLayout.minimumLineSpacing = 22.0;
    _waxiouvCV.delegate = self;
    _waxiouvCV.dataSource = self;
    [_waxiouvCV registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTAvatarCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQMKDIOFZTAvatarCVCell"];
    [_waxiouvCV registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTAvatarRecordCRView" bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"XQQMKDIOFZTAvatarRecordCRView"];
}


- (void)requestAvatarHistroy {
    [self.waxiouvAvatars removeAllObjects];
    [self.waxiouvHeads removeAllObjects];
    WS(weakself)
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    [XQQMineAPI requestUrl:@"/user/headers" params:@{@"type":@"1"} success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSArray *results = dict[@"result"];
        if (results.count <= 0) {
            return;
        }
        NSArray *waxiouvDatas = [[AvatarHistoryList mj_objectArrayWithKeyValuesArray:results] sortedArrayUsingComparator:^NSComparisonResult(AvatarHistoryList  * obj1, AvatarHistoryList  * obj2) {
//            return [obj1.createTime compare:obj2.createTime] == NSOrderedAscending;
            return obj1.id <= obj2.id;
        }];
        for (AvatarHistoryList *avatarHistory in waxiouvDatas) {
            NSString *waxiouvTimesStr = [weakself.waxiouvHeads componentsJoinedByString:@""];
            if ([waxiouvTimesStr containsString:avatarHistory.createTime]) {
                continue;
            }
            [weakself.waxiouvHeads addObject:avatarHistory.createTime];
        }
        for (NSString *waxiouvTime in weakself.waxiouvHeads) {
            NSMutableArray<AvatarHistoryList *> *waxiouvResults = NSMutableArray.new;
            for (AvatarHistoryList *avatarHistory in waxiouvDatas) {
                if ([avatarHistory.createTime isEqualToString:waxiouvTime]) {
                    [waxiouvResults addObject:avatarHistory];
                }
            }
            [weakself.waxiouvAvatars addObject:waxiouvResults];
        }
        [weakself.waxiouvCV reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
    }];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.waxiouvAvatars.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.waxiouvAvatars.count == 0) {
        return 0;
    }
    return self.waxiouvAvatars[section].count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTAvatarCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQMKDIOFZTAvatarCVCell" forIndexPath:indexPath];
    AvatarHistoryList *avatarHistory = _waxiouvAvatars[indexPath.section][indexPath.row];
    [cell.waxiouvIconV sd_setImageWithURL:URL(avatarHistory.portrait) placeholderImage:nil options:SDWebImageScaleDownLargeImages
                                  context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (self.waxiouvAvatars.count == 0) {
        return CGSizeZero;
    }
    return CGSizeMake(WIDTH, 44.0);
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTAvatarRecordCRView *waxiouvHeadView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"XQQMKDIOFZTAvatarRecordCRView" forIndexPath:indexPath];
    waxiouvHeadView.waxiouvDateL.text = _waxiouvHeads[indexPath.section];
    return waxiouvHeadView;
}



- (void)waxiouvClearAvatarRecord {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese ? @"您确定要清空吗？" : @"Are you sure you want to empty it?") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"ConfirmDelete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [XQQMineAPI requestUrl:@"/user/delete/avatars" params:@[] success:^(NSDictionary * _Nonnull dict) {
            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        } error:^(int errCode, NSString * _Nonnull message) {
            [weakself.view makeToast:message duration:1.0 position:CSToastPositionCenter];
        }];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (NSMutableArray<NSArray<AvatarHistoryList *> *> *)waxiouvAvatars {
    if (!_waxiouvAvatars) {
        _waxiouvAvatars = NSMutableArray.new;
    }return _waxiouvAvatars;
}

- (NSMutableArray<NSString *> *)waxiouvHeads {
    if (!_waxiouvHeads) {
        _waxiouvHeads = NSMutableArray.new;
    }return _waxiouvHeads;
}

@end
