//
//  XQQMKDIOFZTDeviceVC.m
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import "XQQMKDIOFZTDeviceVC.h"

#import "XQQMKDIOFZTDeviceDetailsVC.h"
#import "XQQMKDIOFZTDeviceTVCell.h"

@interface XQQMKDIOFZTDeviceVC ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *descL;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<DeviceHistory *>    *dataList;

@end

@implementation XQQMKDIOFZTDeviceVC


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"Equipment");
    if ([XQQCommonHelper.main isChinese]) {
    }else {
        _descL.text = @"This page shows all the devices you have logged in, please pay attention to whether your account has logged in on strange devices, beware of theft!";
    }
    [self requestData];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 130.0;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTDeviceTVCell" bundle:NSBundle.mainBundle] forCellReuseIdentifier:@"XQQMKDIOFZTDeviceTVCell"];
}

- (void)requestData {
    [self.dataList removeAllObjects];
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    WS(weakself)
    [XQQMineAPI requestUrl:@"/device_history" params:@{} success:^(NSDictionary * _Nonnull dict) {
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
    return _dataList.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTDeviceTVCell *cell = [tableView dequeueReusableCellWithIdentifier:@"XQQMKDIOFZTDeviceTVCell" forIndexPath:indexPath];
    cell.model = _dataList[indexPath.section];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTDeviceDetailsVC *vc = XQQMKDIOFZTDeviceDetailsVC.new;
    vc.model = _dataList[indexPath.section];
    [self.navigationController pushViewController:vc animated:YES];
}




- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WS(weakself)
        // XQQIUEHConfigManager.globalManager.appServiceProvider
        [XQQMineAPI requestUrl:@"/delete_device_history" params:@{@"deviceId":_dataList[indexPath.section].id} success:^(NSDictionary * _Nonnull dict) {
        } error:^(int errCode, NSString * _Nonnull message) {
        }];
        [weakself.dataList removeObjectAtIndex:indexPath.section];
        [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10.0;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, 10.0)];
    view.backgroundColor = UIColor.groupTableViewBackgroundColor;
    return view;
}


- (NSMutableArray<DeviceHistory *> *)dataList {
    if (!_dataList) {
        _dataList = NSMutableArray.new;
    }return _dataList;
}

@end
