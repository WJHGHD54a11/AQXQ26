//
//  XQQMKDIOFZTAvatarCVCell.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "XQQMKDIOFZTAvatarCVCell.h"

@interface XQQMKDIOFZTAvatarCVCell ()


@end

@implementation XQQMKDIOFZTAvatarCVCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _waxiouvIconV.layer.cornerRadius = 35.0;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.waxiouvIconV sd_cancelCurrentImageLoad];
    self.waxiouvIconV.image = nil;
}
@end
