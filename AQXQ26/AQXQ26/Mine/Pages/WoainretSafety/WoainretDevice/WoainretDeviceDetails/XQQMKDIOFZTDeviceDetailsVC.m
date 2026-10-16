//
//  XQQMKDIOFZTDeviceDetailsVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import "XQQMKDIOFZTDeviceDetailsVC.h"
#import "XQQMKDIOFZTDeviceDetailsTVCell.h"

@interface XQQMKDIOFZTDeviceDetailsVC ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *deviceImgView;
@property (weak, nonatomic) IBOutlet UILabel *devicetzboeuNameLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<DeviceHistory *>    *dataList;

@end

@implementation XQQMKDIOFZTDeviceDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"Details");
    
    _devicetzboeuNameLabel.text = _model.type;
    if ([_model.type.lowercaseString containsString:@"Mac".lowercaseString]) {
        _deviceImgView.image = IMAGENAME(@"device1");
    }else if ([_model.type.lowercaseString containsString:@"iPad".lowercaseString]) {
        _deviceImgView.image = IMAGENAME(@"device2");
    }else {
        _deviceImgView.image = IMAGENAME(@"device0");
    }
    
    [self requestData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 80.0;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTDeviceDetailsTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQMKDIOFZTDeviceDetailsTVCell"];
}

- (void)requestData {
    [self.dataList removeAllObjects];
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    WS(weakself)
    [XQQMineAPI requestUrl:@"/device_history_list" params:@{@"deviceId":_model.id} success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSArray *datas = dict[@"result"];
        
        weakself.dataList = [[DeviceHistory mj_objectArrayWithKeyValuesArray:datas] sortedArrayUsingComparator:^NSComparisonResult(DeviceHistory  * obj1, DeviceHistory  * obj2) {
            return obj1.lastLogin <= obj2.lastLogin;
        }].mutableCopy;
        [weakself.tableView reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if ([XQQCommonHelper.main isChinese]) {
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
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataList.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTDeviceDetailsTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQMKDIOFZTDeviceDetailsTVCell" forIndexPath:indexPath];
//    cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
    cell.model = _dataList[indexPath.row];
    return cell;
}


- (NSMutableArray<DeviceHistory *> *)dataList {
    if (!_dataList) {
        _dataList = NSMutableArray.new;
    }return _dataList;
}

@end
