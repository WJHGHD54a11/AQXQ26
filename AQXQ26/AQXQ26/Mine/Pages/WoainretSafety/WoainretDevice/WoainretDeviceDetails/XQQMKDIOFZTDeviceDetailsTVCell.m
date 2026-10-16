//
//  XQQMKDIOFZTDeviceDetailsTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import "XQQMKDIOFZTDeviceDetailsTVCell.h"

@interface XQQMKDIOFZTDeviceDetailsTVCell ()

@property (weak, nonatomic) IBOutlet UILabel *lastLoginTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;

@property (weak, nonatomic) IBOutlet UILabel *lastLoginTimeL;
@property (weak, nonatomic) IBOutlet UILabel *ipL;
@end

@implementation XQQMKDIOFZTDeviceDetailsTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    _lastLoginTimeL.text = LLLLLL(@"LastOnlineTime");
    _ipL.text = LLLLLL(@"IPAddress");
}

- (void)setModel:(DeviceHistory *)model {
    _model = model;
    
    _ipLabel.text = _model.ip;
    _lastLoginTimeLabel.text = [UNString(@"%lld", _model.lastLogin) timeIntervalDateFormat:@"yyyy-MM-dd HH:mm:ss"];
}

@end
