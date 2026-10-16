//
//  XQQMKDIOFZTDeviceTVCell.m
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import "XQQMKDIOFZTDeviceTVCell.h"

@interface XQQMKDIOFZTDeviceTVCell ()

@property (weak, nonatomic) IBOutlet UIImageView *deviceImgView;
@property (weak, nonatomic) IBOutlet UILabel *devicetzboeuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *isCurrentDeviceLabel;

@property (weak, nonatomic) IBOutlet UILabel *lastLoginTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipLabel;

@property (weak, nonatomic) IBOutlet UILabel *lastLoginTimeL;
@property (weak, nonatomic) IBOutlet UILabel *ipL;
@end

@implementation XQQMKDIOFZTDeviceTVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _isCurrentDeviceLabel.text = LLLLLL(@"CurrentDevice");
    _lastLoginTimeL.text = LLLLLL(@"LastOnlineTime");
    _ipL.text = LLLLLL(@"IPAddress");
}

- (void)setModel:(DeviceHistory *)model {
    _model = model;
    
    _devicetzboeuNameLabel.text = _model.type;
    _isCurrentDeviceLabel.hidden = ![_model.type isEqualToString:UIDevice.currentDevice.name];
 
    _lastLoginTimeLabel.text = [UNString(@"%lld", _model.lastLogin) timeIntervalDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    _ipLabel.text = _model.ip;
    
    if ([_model.type.lowercaseString containsString:@"Mac".lowercaseString]) {
        _deviceImgView.image = IMAGENAME(@"device1");
    }else if ([_model.type.lowercaseString containsString:@"iPad".lowercaseString]) {
        _deviceImgView.image = IMAGENAME(@"device2");
    }else {
        _deviceImgView.image = IMAGENAME(@"device0");
    }
}


@end
