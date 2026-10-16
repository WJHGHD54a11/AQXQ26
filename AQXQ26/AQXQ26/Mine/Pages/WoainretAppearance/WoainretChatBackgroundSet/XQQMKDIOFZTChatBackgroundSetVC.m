//
//  XQQMKDIOFZTChatBackgroundSetVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 8/12/24.
//

#import "XQQMKDIOFZTChatBackgroundSetVC.h"

@interface XQQMKDIOFZTChatBackgroundSetVC ()
{
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UILabel *waxiouvPreviewFL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvChatBgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBgImgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBubbleColorImgV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextAL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextBL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvAlphaFL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvMinFL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvMaxFL;
@property (weak, nonatomic) IBOutlet UISlider *waxiouvAlphaSlider;

@property (nonatomic, assign) NSInteger waxiouvChatBgColorIndex;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvBgColorFL;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvColorABtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvColorBBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvColorCBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvColorDBtn;

@end

@implementation XQQMKDIOFZTChatBackgroundSetVC

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_chatBackgroundSet) {
        _chatBackgroundSet(_waxiouvAlphaSlider.value, _waxiouvChatBgColorIndex);
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _isChinese = [XQQCommonHelper.main isChinese];
    self.navigationItem.title = (_isChinese?@"聊天背景":@"Chat background");
    
    _waxiouvChatBgV.layer.cornerRadius = 15.0;
    _waxiouvChatBgV.layer.borderWidth = 0.67;
    _waxiouvChatBgV.layer.borderColor = RGBA(0xF6F6F6).CGColor;
    
    _waxiouvBgImgV.image = IMAGENAME((UNString(@"erovaeChatBgImg%ld", _waxiouvChatBgImgIndex)));
    _waxiouvBubbleColorImgV.image = IMAGENAME((UNString(@"sent_msg_background%ld", _waxiouvBubbleColorIndex)));
    
    _waxiouvAlphaSlider.value = _waxiouvAlpha;
    self.waxiouvChatBgColorIndex = _waxiouvBgColorIndex;
    
    if (_isChinese) {
    }else {
        _waxiouvPreviewFL.text = @"Preview effect";
        _waxiouvTextAL.text = @"Chat style";
        _waxiouvTextBL.text = @"Chat bubble style";
        _waxiouvAlphaFL.text = @"Pattern transparency";
        _waxiouvMinFL.text = @"Min";
        _waxiouvMaxFL.text = @"Max";
        _waxiouvBgColorFL.text = @"Background color";
    }
}


// 图案透明度
- (IBAction)waxiouvAlphaSet:(UISlider *)sender {
    _waxiouvBgImgV.backgroundColor = [ChatBgImgColors[_waxiouvChatBgColorIndex] alpha:_waxiouvAlphaSlider.value];
}

// 背景颜色
- (IBAction)waxiouvColors:(UIButton *)sender {
    if (sender.tag == _waxiouvChatBgColorIndex) {
        return;
    }
    self.waxiouvChatBgColorIndex = sender.tag;
}

- (void)setwaxiouvChatBgColorIndex:(NSInteger)waxiouvChatBgColorIndex {
    _waxiouvChatBgColorIndex = waxiouvChatBgColorIndex;
    
    for (UIButton *waxiouvColorBtn in @[_waxiouvColorABtn, _waxiouvColorBBtn, _waxiouvColorCBtn, _waxiouvColorDBtn]) {
        if (waxiouvColorBtn.tag == _waxiouvChatBgColorIndex) {
            ViewBorderRadius(waxiouvColorBtn, 15.0, 2.0, MAINCOLOR);
        }else {
            ViewBorderRadius(waxiouvColorBtn, 15.0, 0.0, UIColor.clearColor);
        }
    }
    _waxiouvBgImgV.backgroundColor = [ChatBgImgColors[_waxiouvChatBgColorIndex] alpha:_waxiouvAlphaSlider.value];
}



@end
