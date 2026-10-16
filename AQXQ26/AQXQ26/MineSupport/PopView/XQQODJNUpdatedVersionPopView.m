//
//  XQQODJNUpdatedVersionPopView.m
//  WUHOIBDK
//
//  Created by Ruby on 1/5/24.
//

#import "XQQODJNUpdatedVersionPopView.h"


@interface XQQODJNUpdatedVersionPopView ()
{
    NSString *_downloadUrl;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *bgAView;

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *updateContentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@property (weak, nonatomic) IBOutlet UIButton *aButton;

@property (weak, nonatomic) IBOutlet UIView *btnBgView;
@property (weak, nonatomic) IBOutlet UIButton *bButton;
@property (weak, nonatomic) IBOutlet UIButton *cButton;

@property (weak, nonatomic) IBOutlet UILabel *newsVersionL;

@end


@implementation XQQODJNUpdatedVersionPopView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [NSBundle.mainBundle loadNibNamed:@"XQQODJNUpdatedVersionPopView" owner:self options:nil].lastObject;
        self.frame = ShareAppDelegate.window.frame;
        
        _downloadUrl = @"";
        _bgAView.layer.cornerRadius = 18.0;
        _bgAView.layer.masksToBounds = YES;

        _logoImageView.contentMode = UIViewContentModeScaleAspectFit;
        _logoImageView.image = [UIImage imageNamed:@"upgrade_logo"];

        _versionLabel.layer.cornerRadius = 11.0;
        _versionLabel.layer.masksToBounds = YES;
        _versionLabel.backgroundColor = RGBCOLOR(82, 224, 92);
        _versionLabel.textColor = UIColor.whiteColor;
        
        _aButton.layer.cornerRadius = 8.0;
        _cButton.layer.cornerRadius = 8.0;
        _aButton.backgroundColor = RGBCOLOR(82, 224, 92);
        _cButton.backgroundColor = RGBCOLOR(82, 224, 92);
        [_aButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_cButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        
        _bButton.layer.borderWidth = 1.0;
        _bButton.layer.borderColor = RGBCOLOR(82, 224, 92).CGColor;
        _bButton.layer.cornerRadius = 8.0;
        [_bButton setTitleColor:RGBCOLOR(82, 224, 92) forState:UIControlStateNormal];
        
        if ([XQQCommonHelper.main isChinese]) {
            
        }else {
            _newsVersionL.text = @"New Versions";
        }
        [_aButton setTitle:LLLLLL(@"UpdateNow") forState:UIControlStateNormal];
        [_bButton setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
        [_cButton setTitle:LLLLLL(@"UpdateNow") forState:UIControlStateNormal];
    }
    return self;
}
- (void)setIsForce:(BOOL)isForce {
    _isForce = isForce;
    if (_isForce) {
        _btnBgView.hidden = YES;
        _aButton.hidden = NO;
    }else {
        _btnBgView.hidden = NO;
        _aButton.hidden = YES;
    }
}
- (void)showVersion:(NSString *)version info:(NSString *)info download:(NSString *)download {
    [_bgView exChangeOutDur];
    [ShareAppDelegate.window addSubview:self];
    
    _versionLabel.text = UNString(@"V%@", version);
    _updateContentLabel.text = info;
    _downloadUrl = download;
}

- (IBAction)action:(UIButton *)sender {
    if (sender.tag == 0) {
        [self removeFromSuperview];
        return;
    }
    if (_downloadUrl != nil && _downloadUrl.length > 0) {
        WS(weakself)
        [[UIApplication sharedApplication] openURL:URL(_downloadUrl) options:@{} completionHandler:^(BOOL success) {
            [weakself exit];
            [weakself removeFromSuperview];
        }];
    }else {
        [self removeFromSuperview];
    }
}

- (void)exit {
    UIWindow *window = ShareAppDelegate.window;
    [UIView animateWithDuration:0.35 animations:^{
        window.alpha = 0.0;
        window.frame = CGRectMake(CGRectGetWidth(window.frame)/2, CGRectGetHeight(window.frame)/2,1,1);
    } completion:^(BOOL finished) {
        exit(0);
    }];
}

@end
