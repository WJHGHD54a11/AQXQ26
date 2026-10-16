//
//  XQQWJEFDOCYMainVC.m
//  QXQ
//
//  Created by Loooooo on 9/28/23.
//

#import "XQQWJEFDOCYMainVC.h"
#import "XQQGNRJYDIOZLoginVC.h"


@interface XQQWJEFDOCYMainVC ()

@end

@implementation XQQWJEFDOCYMainVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.topItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.shadowImage = UIImage.new;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
//    self.navigationController.navigationBar.subviews.firstObject.subviews.firstObject.hidden = YES;
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    
//    Other Linker Flag -> -ld_classic 0220删掉了
}

- (void)loginVC {
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:XQQGNRJYDIOZLoginVC.new];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navi animated:YES completion:nil];
}

- (void)setStatusBarColorType:(StatusBarColor)colorType {
    if (colorType == StatusBarColorWhite) { // 白色
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }else if (colorType == StatusBarColorBlock) {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    }
}

- (UIImageView *)leftImg:(NSString *)img {
    UIImageView *imgView = UIImageView.new;
    imgView.frame = CGRectMake(0.0, 0.0, 63.0, 20.0);
    imgView.image = IMAGENAME(img);
    return imgView;
}


- (UIButton *)itemImage:(NSString *)img action:(SEL)action {
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 32.0, 32.0);
    rightButton.backgroundColor = UIColor.clearColor;
    [rightButton setImage:IMAGENAME(img) forState:UIControlStateNormal];
    [rightButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    rightButton.adjustsImageWhenHighlighted = NO;
    return rightButton;
}

- (UIButton *)itemTitle:(NSString *)title action:(SEL)action {
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 40.0, 30.0);
    rightButton.backgroundColor = UIColor.clearColor;
    [rightButton setTitle:title forState:UIControlStateNormal];
    [rightButton setTitleColor:RGBA(0x222222) forState:UIControlStateNormal];
    rightButton.titleLabel.font = [UIFont fontWithName:@"PingFang-SC-Medium" size:15.0];
    [rightButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    rightButton.adjustsImageWhenHighlighted = NO;
    return rightButton;
}

- (UILabel *)leftTitle:(NSString *)title len:(NSInteger)len {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 32.0)];
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:22.0];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.textColor = UIColor.blackColor;
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:title];
    [attr addAttribute:NSForegroundColorAttributeName value:MAINCOLOR range:NSMakeRange(0, len)];
    [attr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Medium" size:24.0] range:NSMakeRange(0, len)];
    titleLabel.attributedText = attr;
    return titleLabel;
}

- (UILabel *)centerTitle:(NSString *)title {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 32.0)];
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18.0];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.text = title;
    return titleLabel;
}



- (UIViewController *)getCurrentVC {
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
    if (!window) {
        return nil;
    }
    UIView *tempView;
    for (UIView *subview in window.subviews) {
        if ([[subview.classForCoder description] isEqualToString:@"UILayoutContainerView"]) {
            tempView = subview;
            break;
        }
    }
    if (!tempView) {
        tempView = [window.subviews lastObject];
    }
    id nextResponder = [tempView nextResponder];
    while (![nextResponder isKindOfClass:[UIViewController class]] || [nextResponder isKindOfClass:[UINavigationController class]] || [nextResponder isKindOfClass:[UITabBarController class]]) {
        tempView =  [tempView.subviews firstObject];
        
        if (!tempView) {
            return nil;
        }
        nextResponder = [tempView nextResponder];
    }
    return  (UIViewController *)nextResponder;
}




- (void)cornerView:(UIView *)view round:(CGFloat)round rectCorners:(UIRectCorner)rectCorners {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:rectCorners cornerRadii:CGSizeMake(round, round)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = view.bounds;
    maskLayer.path = [maskPath CGPath];
    view.layer.mask = maskLayer;
}


@end
