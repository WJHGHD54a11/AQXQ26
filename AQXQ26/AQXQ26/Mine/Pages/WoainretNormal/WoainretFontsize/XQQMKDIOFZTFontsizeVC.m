//
//  XQQMKDIOFZTFontsizeVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 4/24/24.
//

#import "XQQMKDIOFZTFontsizeVC.h"

@interface XQQMKDIOFZTFontsizeVC ()
{
    NSInteger _fontSize;
}
@property (weak, nonatomic) IBOutlet UIView *haecgAView;
@property (weak, nonatomic) IBOutlet UIView *haecgBView;
@property (weak, nonatomic) IBOutlet UIView *haecgCView;
@property (weak, nonatomic) IBOutlet UILabel *haecgTitleALabel;
@property (weak, nonatomic) IBOutlet UILabel *haecgTitleBLabel;
@property (weak, nonatomic) IBOutlet UILabel *haecgTitleCLabel;


@property (weak, nonatomic) IBOutlet UILabel *haecgSmallLabel;
@property (weak, nonatomic) IBOutlet UILabel *haecgStandardLabel;
@property (weak, nonatomic) IBOutlet UILabel *haecgBigLabel;

@property (weak, nonatomic) IBOutlet UISlider *haecgSlider;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *haecgBottom;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvYulanL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvQJZTDXL;

@end

@implementation XQQMKDIOFZTFontsizeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"FontSize");
    UIButton *rightItem = [self itemTitle:LLLLLL(@"OK") action:@selector(haecgDone)];
    [rightItem setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
    
    _haecgAView.layer.cornerRadius = 8.0;
    _haecgBView.layer.cornerRadius = 8.0;
    _haecgCView.layer.cornerRadius = 8.0;
    
    _haecgBottom.constant = 100.0 + TabBarHeight;
    if ([XQQCommonHelper.main isChinese]) {
    }else {
        _haecgTitleALabel.text = @"Drag the slider below to set the font size of the chat screen.";
        _haecgTitleBLabel.text = @"Preview the font size.";
        _haecgTitleCLabel.text = @"This only changes the text font size in the chat interface.";
        
        _haecgSmallLabel.text = @"Small";
        _haecgStandardLabel.text = @"Standard";
        _haecgBigLabel.text = @"Big";
        
        _waxiouvYulanL.text = @"Preview effect";
        _waxiouvQJZTDXL.text = @"Global font size";
    }
    _fontSize = [NSUserDefaults.standardUserDefaults integerForKey:@"kFontSize"];
    _haecgSlider.value = _fontSize;
    [self haecoFontSize];
}

- (void)haecgDone {
    [NSUserDefaults.standardUserDefaults setInteger:_fontSize forKey:@"kFontSize"];
    [NSUserDefaults.standardUserDefaults synchronize];
    WS(weakself)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakself.navigationController popToRootViewControllerAnimated:YES];
    });
}

- (IBAction)haecoSlider:(UISlider *)sender {
    // 取整数值
    _fontSize = roundf(sender.value);
    sender.value = _fontSize;
    [self haecoFontSize];
}

- (void)haecoFontSize {
    _haecgTitleALabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:_fontSize];
    _haecgTitleBLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:_fontSize];
    _haecgTitleCLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:_fontSize];
}


//override func viewDidLoad() {
//    super.viewDidLoad()
//
//    // 设置slider的属性
//    slider.minimumValue = 1
//    slider.maximumValue = 5
////        slider.
//    slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
//
//    slider.translatesAutoresizingMaskIntoConstraints = false
//    NSLayoutConstraint.activate([
//        slider.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
//        slider.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
//    ])
//}
//
//@objc func sliderValueChanged(_ sender: UISlider) {
//    // 取整数值
//    let currentValue = Int(sender.value.rounded())
//    sender.value = Float(currentValue)
//    print("Slider value: \(currentValue)")
//}

@end
