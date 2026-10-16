//
//  XQQMKDIOFZTUserQrcodeVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "XQQMKDIOFZTUserQrcodeVC.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface XQQMKDIOFZTUserQrcodeVC ()
{
    NSString *_qrStr;
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIView *waxiouvBgV;

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvIconV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvNameL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvIdL;

@property (weak, nonatomic) IBOutlet UIImageView *waxiouvQrImgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvQrIconV;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAddFirendL;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvLogoV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvExpirationL;

@property (weak, nonatomic) IBOutlet UIButton *waxiouvRefreshBtn;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvSkanL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvShareL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvDownloadL;

@property (nonatomic, strong) XQQCUserInfo *userInfo;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

// 新增：二维码生成与操作的检查记录，只读取状态、不修改界面，实现在文件尾部
@interface XQQMKDIOFZTUserQrcodeVC (XQQQrcodeCheck)
- (void)xqq_verifyQrImage:(nullable UIImage *)image content:(NSString *)content; // 新增
- (void)xqq_recordAction:(NSInteger)tag;                                        // 新增
@end

@implementation XQQMKDIOFZTUserQrcodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    self.navigationItem.title = _isChinese ? @"二维码" : @"QR code";
 
    _waxiouvIconV.layer.cornerRadius = 30.0;
    _waxiouvQrIconV.hidden = YES;
    _waxiouvQrIconV.layer.cornerRadius = 26.0;
    _waxiouvLogoV.layer.cornerRadius = 10.0;
    if (_isChinese) {
    }else {
        _waxiouvAddFirendL.text = @"Sweep\nAdd me as a friend";
        [_waxiouvRefreshBtn setTitle:@"Click to refresh" forState:UIControlStateNormal];
        
        _waxiouvSkanL.text = @"Sweep";
        _waxiouvShareL.text = @"Share it";
        _waxiouvDownloadL.text = @"Save picture";
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    self.userInfo = [XQQMineProfile getMyInfo];
    [self waxiouvRefreshTime];
}

- (void)waxiouvRefreshTime {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSDateFormatter *waxiouvFormatter = NSDateFormatter.new;
    waxiouvFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    
    NSString *waxiouvExpiration = @"";
    NSDate *waxiouvDate = [NSDate.date dateByAddingTimeInterval:60*60];
    if (_isChinese) {
        waxiouvExpiration = UNString(@"有效期至%@", [waxiouvFormatter stringFromDate:waxiouvDate]);
    }else {
        waxiouvExpiration = UNString(@"Valid until %@", [waxiouvFormatter stringFromDate:waxiouvDate]);
    }
    if ([waxiouvExpiration isEqualToString:_waxiouvExpirationL.text]) {
        return;
    }
    _waxiouvExpirationL.text = waxiouvExpiration;
    
    NSInteger waxiouvTimeInterval = (NSInteger)[waxiouvDate timeIntervalSince1970];
    
    _qrStr = [NSString stringWithFormat:@"wildfirechat://user/%@####%ld", userId, waxiouvTimeInterval];
    WS(weakself)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImage *waxiouvQrImg = [LBXScanNative logolOrQRImage:self->_qrStr logolImage:weakself.waxiouvIconV.image];
            weakself.waxiouvQrIconV.hidden = NO;
            UIImage *waxiouvQrImg = [LBXScanNative logolOrQRImage:self->_qrStr logolImage:nil];
            weakself.waxiouvQrImgV.image = waxiouvQrImg;
            [weakself xqq_verifyQrImage:waxiouvQrImg content:self->_qrStr]; // 新增
        });
    });
}

- (void)setUserInfo:(XQQCUserInfo *)userInfo {
    _userInfo = userInfo;
    UIImage *placeholder = [UIImage imageNamed:@"PersonalChat"];
    __weak typeof(self) weakSelf = self;
    [_waxiouvIconV sd_setImageWithURL:URL(_userInfo.portrait)
                     placeholderImage:placeholder
                              options:SDWebImageScaleDownLargeImages
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        (void)error;
        (void)cacheType;
        (void)imageURL;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.waxiouvQrIconV.image = image ?: placeholder;
    }];

    _waxiouvNameL.text = _userInfo.displayName;
    _waxiouvIdL.text = _userInfo.name;
}

- (IBAction)waxiouvScanShareDownloads:(UIButton *)sender {
    [self xqq_recordAction:sender.tag]; // 新增
    if (sender.tag == 0) {
        if (gXQQQrCodeDelegate) { // 走的delegate方法
            [gXQQQrCodeDelegate scanQrCode:self.navigationController];
        }
    }else {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] init];
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        indicator.center = self.view.center;
        _indicatorView = indicator;
        [[UIApplication sharedApplication].keyWindow addSubview:indicator];
        [indicator startAnimating];
        
        UIImage *image = [self shotShareImageFromView:self.waxiouvBgV];
        if (sender.tag == 1) {
            [_indicatorView removeFromSuperview];
            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
            [self presentViewController:avc animated:YES completion:nil];
        }else {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }
    }
}



- (IBAction)waxiouvCopy:(UIButton *)sender {
    if (_waxiouvIdL.text.length <= 0) {
        return;
    }
    UIPasteboard *pasteboard = UIPasteboard.generalPasteboard;
    pasteboard.string = _waxiouvIdL.text;
    [SVProgressHUD showSuccessWithStatus:LLLLLL(@"CopySuccessfully")];
    [SVProgressHUD dismissWithDelay:1.0];
}

- (IBAction)waxiouvRefresh:(UIButton *)sender {
    [self waxiouvRefreshTime];
}





- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedUserId"];
    NSArray<XQQCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (XQQCUserInfo *userInfo in userInfoList) {
        if ([userId isEqualToString:userInfo.userId]) {
            self.userInfo = userInfo;
            break;
        }
    }
}

/** 1、截取屏幕上指定view的内容 */
- (UIImage *)shotShareImageFromView:(UIView *)view {
    //高清方法
    //第一个参数表示区域大小 第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    CGSize size = CGSizeMake(view.layer.bounds.size.width, view.layer.bounds.size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, ([UIScreen mainScreen].scale));
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [_indicatorView removeFromSuperview];

    if (error) {
        [SVProgressHUD showErrorWithStatus:LLLLLL(@"SaveFailure")];
        [SVProgressHUD dismissWithDelay:1.0];
    } else {
        [SVProgressHUD showSuccessWithStatus:LLLLLL(@"SaveSuccessfully")];
        [SVProgressHUD dismissWithDelay:1.0];
    }
}


@end

#pragma mark - 新增：二维码检查

// 新增：以下检查只在 Debug 下执行和输出日志，不修改界面、二维码内容和保存 / 分享结果
@implementation XQQMKDIOFZTUserQrcodeVC (XQQQrcodeCheck)

// 新增：二维码生成后检查：图片是否生成、尺寸，以及用系统识别器读回来的内容是否等于要编码的内容。
// 识别在后台队列做，不阻塞界面；二维码内容里有 userId 和过期时间，日志只打长度和是否一致
- (void)xqq_verifyQrImage:(nullable UIImage *)image content:(NSString *)content {
#ifdef DEBUG
    if (!image.CGImage) {
        NSLog(@"[UserQrcode] qr image missing, content length=%lu", (unsigned long)content.length);
        return;
    }
    NSString *expected = [content copy];
    CGImageRef cgImage = CGImageRetain(image.CGImage);
    CGSize size = image.size;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil
                                                  options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray<CIFeature *> *features = [detector featuresInImage:[CIImage imageWithCGImage:cgImage]];
        CGImageRelease(cgImage);
        NSString *decoded = [(CIQRCodeFeature *)features.firstObject messageString];
        NSLog(@"[UserQrcode] qr %.0fx%.0f decoded=%d matches=%d length=%lu",
              size.width, size.height, decoded != nil, [decoded isEqualToString:expected], (unsigned long)expected.length);
    });
#endif
}

// 新增：点"扫一扫 / 分享 / 保存图片"时调用：记下点了哪个，以及此时二维码离过期还有多久。
// 过期时间只在进入页面或点"刷新"时更新，停留超过 1 小时后分享出去的二维码已经过期
- (void)xqq_recordAction:(NSInteger)tag {
#ifdef DEBUG
    NSString *name = tag == 0 ? @"scan" : (tag == 1 ? @"share" : @"save");
    NSString *expiry = [[_qrStr componentsSeparatedByString:@"####"] lastObject];
    NSTimeInterval remaining = expiry.doubleValue - NSDate.date.timeIntervalSince1970;
    NSLog(@"[UserQrcode] action %@ qrRemaining=%.0fs expired=%d", name, remaining, remaining <= 0);
#endif
}

@end
