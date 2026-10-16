//
//  XQQMKDIOFZTAppearanceVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 8/15/24.
//

#import "XQQMKDIOFZTAppearanceVC.h"
#import "XQQMKDIOFZTChatBackgroundSetVC.h"
#import "XQQMKDIOFZTBubbleColorCVCell.h"

@interface XQQMKDIOFZTAppearanceVC ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    float _waxiouvAlpha;
    NSInteger _waxiouvBgColorIndex;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UISwitch *waxiouvStatusSw;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvStatusL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvStatusDescL;

@property (weak, nonatomic) IBOutlet UIView *waxiouvBgV;

@property (weak, nonatomic) IBOutlet UIView *waxiouvChatBgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBgImgV;
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvBubbleColorImgV;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextAL;
@property (weak, nonatomic) IBOutlet UILabel *waxiouvTextBL;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvBubbleColorFL;

@property (nonatomic, assign) NSInteger waxiouvBubbleColorIndex; // kAppearanceBubbleColor 气泡颜色的索引
@property (weak, nonatomic) IBOutlet UICollectionView *waxiouvCV;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *waxiouvLayout;

@property (weak, nonatomic) IBOutlet UILabel *waxiouvChatBgFL;
@property (nonatomic, assign) NSInteger waxiouvChatBgImgIndex; // kAppearanceChatBackgroundImg 聊天背景图片索引
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBg0Btn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgABtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgBBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgCBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvChatBgDBtn;

@end

// 新增：外观设置的修改记录与预览检查，只读取状态、不修改界面和保存的值，实现在文件尾部
@interface XQQMKDIOFZTAppearanceVC (XQQSettingCheck)
- (void)xqq_recordChange:(NSString *)field;  // 新增
- (void)xqq_logPendingChangesWithAction:(NSString *)action; // 新增
@end

@implementation XQQMKDIOFZTAppearanceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = LLLLLL(@"Appearance");
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"waxiouvBack" action:@selector(waxiouvBack)]];
    _isChinese = [XQQCommonHelper.main isChinese];
    
    _waxiouvBgColorIndex = -1;
    
    _waxiouvChatBgV.layer.cornerRadius = 15.0;
    _waxiouvChatBgV.layer.borderWidth = 0.67;
    _waxiouvChatBgV.layer.borderColor = RGBA(0xF6F6F6).CGColor;
    
    _waxiouvStatusSw.on = ![NSUserDefaults.standardUserDefaults boolForKey:kAppearanceStatus];
    _waxiouvBgV.hidden = _waxiouvStatusSw.on;
    if (!_waxiouvStatusSw.on) {
        [self waxiouvSaveItem];
    }
    
    self.waxiouvChatBgImgIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundImg];
    
    self.waxiouvBubbleColorIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceBubbleColor];
    _waxiouvLayout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
    _waxiouvLayout.itemSize = CGSizeMake(40.0, 40.0);
    _waxiouvLayout.minimumInteritemSpacing = ( WIDTH-40.0-40*7.0-0.1)/6.0;
    _waxiouvLayout.minimumLineSpacing = 0.0;
    _waxiouvCV.delegate = self;
    _waxiouvCV.dataSource = self;
    [_waxiouvCV registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTBubbleColorCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQMKDIOFZTBubbleColorCVCell"];
    
    _waxiouvAlpha = [NSUserDefaults.standardUserDefaults floatForKey:kAppearanceChatBackgroundImgAlpha];
    _waxiouvBgColorIndex = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundColor];
    _waxiouvBgImgV.backgroundColor = [ChatBgImgColors[_waxiouvBgColorIndex] alpha:_waxiouvAlpha];
    
    if (_isChinese) {
    }else {
        _waxiouvStatusL.text = @"Pure mode";
        _waxiouvStatusDescL.text = @"No appearance is displayed after opening";
        _waxiouvTextAL.text = @"Chat style";
        _waxiouvTextBL.text = @"Chat bubble style";
        _waxiouvBubbleColorFL.text = @"Dialog bubble color";
        _waxiouvChatBgFL.text = @"Chat background";
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self waxiouvBack];
}

- (void)waxiouvBack {
    if ([self waxiouvDataIsUpdate] == NO) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"温馨提示":@"Warm Tips") message:(_isChinese?@"您已修改设置，是否保存后返回？":@"You have modified the Settings, whether to save and return?") preferredStyle:UIAlertControllerStyleAlert];
    WS(weakself)
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:(_isChinese?@"暂不":@"Not yet") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakself.navigationController popViewControllerAnimated:YES];
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:(_isChinese?@"保存并返回":@"Save and return") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself waxiouvSaved];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)waxiouvDataIsUpdate {
    NSInteger waxiouvBubbleColor = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceBubbleColor];
    NSInteger waxiouvChatBgImg = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundImg];
    float waxiouvAlpha = [NSUserDefaults.standardUserDefaults floatForKey:kAppearanceChatBackgroundImgAlpha];
    NSInteger waxiouvBgColor = [NSUserDefaults.standardUserDefaults integerForKey:kAppearanceChatBackgroundColor];
    if (waxiouvBubbleColor == self.waxiouvBubbleColorIndex && waxiouvChatBgImg == self.waxiouvChatBgImgIndex && waxiouvAlpha == _waxiouvAlpha && waxiouvBgColor == _waxiouvBgColorIndex) {
        return NO;
    }
    return YES;
}

- (void)waxiouvSave {
    if ([self waxiouvDataIsUpdate] == NO) {
        [self.view makeToast:(_isChinese?@"您没有修改设置，不需要保存...":@"You have not modified the Settings, do not need to save...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if (_waxiouvBgColorIndex == -1) {
        [self.view makeToast:(_isChinese?@"请设置聊天背景参数":@"Please set the chat background parameters") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:(_isChinese?@"您确定要保存吗？":@"Are you sure you want to save it?") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    WS(weakself)
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself waxiouvSaved];
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)waxiouvSaved {
    [self xqq_logPendingChangesWithAction:@"save"]; // 新增
    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvBubbleColorIndex forKey:kAppearanceBubbleColor];
    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvChatBgImgIndex forKey:kAppearanceChatBackgroundImg];
    [NSUserDefaults.standardUserDefaults setFloat:_waxiouvAlpha forKey:kAppearanceChatBackgroundImgAlpha];
    [NSUserDefaults.standardUserDefaults setInteger:_waxiouvBgColorIndex forKey:kAppearanceChatBackgroundColor];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    [self.view makeToast:LLLLLL(@"SaveSuccessfully") duration:1.0 position:CSToastPositionCenter];
    WS(weakself)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakself.navigationController popViewControllerAnimated:YES];
    });
}



- (IBAction)waxiouvStatus:(UISwitch *)sender { // 纯净模式开关
    _waxiouvBgV.hidden = sender.on;
    if (!sender.on) {
        [self waxiouvSaveItem];
    }else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    [NSUserDefaults.standardUserDefaults setBool:!sender.on forKey:kAppearanceStatus];
    [NSUserDefaults.standardUserDefaults synchronize];
}
- (void)waxiouvSaveItem {
    UIButton *waxiouvSaveBtn = [self itemTitle:LLLLLL(@"Save") action:@selector(waxiouvSave)];
    [waxiouvSaveBtn setTitleColor:MAINCOLOR forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:waxiouvSaveBtn];
}

- (IBAction)waxiouvChatBgMore:(UIButton *)sender { // 设置聊天背景
//    if (_waxiouvChatBgImgIndex <= 0) {
//        [self.view makeToast:(_isChinese?@"请先选择背景图片":@"Please select the background image first") duration:1.0 position:CSToastPositionCenter];
//        return;
//    }
    XQQMKDIOFZTChatBackgroundSetVC *vc = XQQMKDIOFZTChatBackgroundSetVC.new;
    vc.waxiouvBubbleColorIndex = _waxiouvBubbleColorIndex;
    vc.waxiouvChatBgImgIndex = _waxiouvChatBgImgIndex;
    vc.waxiouvAlpha = _waxiouvAlpha;
    vc.waxiouvBgColorIndex = _waxiouvBgColorIndex;
    WS(weakself)
    [vc setChatBackgroundSet:^(float waxiouvAlpha, NSInteger waxiouvBgColorIndex) {
        self->_waxiouvAlpha = waxiouvAlpha;
        self->_waxiouvBgColorIndex = waxiouvBgColorIndex;
        weakself.waxiouvBgImgV.backgroundColor = [ChatBgImgColors[waxiouvBgColorIndex] alpha:waxiouvAlpha];
        [weakself xqq_recordChange:@"chatBgColor"]; // 新增
    }];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - 聊天背景图片

- (void)setwaxiouvChatBgImgIndex:(NSInteger)waxiouvChatBgImgIndex {
    _waxiouvChatBgImgIndex = waxiouvChatBgImgIndex;
    for (UIButton *waxiouvChatBgBtn in @[_waxiouvChatBg0Btn, _waxiouvChatBgABtn, _waxiouvChatBgBBtn, _waxiouvChatBgCBtn, _waxiouvChatBgDBtn]) {
        waxiouvChatBgBtn.selected = (_waxiouvChatBgImgIndex == waxiouvChatBgBtn.tag);
    }
    if (_waxiouvChatBgImgIndex <= 0) {
        _waxiouvBgImgV.image = UIImage.new;
        return;
    }
    _waxiouvBgImgV.image = IMAGENAME((UNString(@"erovaeChatBgImg%ld", _waxiouvChatBgImgIndex)));
}

- (IBAction)waxiouvChatBg:(UIButton *)sender { // 聊天背景图片->切换
    if (_waxiouvChatBgImgIndex == sender.tag) {
        return;
    }
    self.waxiouvChatBgImgIndex = sender.tag;
    [self xqq_recordChange:@"chatBgImage"]; // 新增
//    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvChatBgImgIndex forKey:kAppearanceChatBackgroundImg];
//    [NSUserDefaults.standardUserDefaults synchronize];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (void)setwaxiouvBubbleColorIndex:(NSInteger)waxiouvBubbleColorIndex {
    _waxiouvBubbleColorIndex = waxiouvBubbleColorIndex;
    [_waxiouvCV reloadData];
    if (_waxiouvBubbleColorIndex < 0) {
        return;
    }
    _waxiouvBubbleColorImgV.image = IMAGENAME((UNString(@"sent_msg_background%ld", _waxiouvBubbleColorIndex)));
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return BubbleColors.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTBubbleColorCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQMKDIOFZTBubbleColorCVCell" forIndexPath:indexPath];
    cell.erovaeBgV.backgroundColor = BubbleColors[indexPath.row];
    cell.erovaeSelectV.hidden = (indexPath.row != (_waxiouvBubbleColorIndex - 1));
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_waxiouvBubbleColorIndex == indexPath.row + 1) {
        return;
    }
    self.waxiouvBubbleColorIndex = indexPath.row + 1;
    [self xqq_recordChange:@"bubbleColor"]; // 新增
//    [NSUserDefaults.standardUserDefaults setInteger:self.waxiouvBubbleColorIndex forKey:kAppearanceBubbleColor];
//    [NSUserDefaults.standardUserDefaults synchronize];
}


@end

#pragma mark - 新增：设置修改记录与预览检查

// 新增：本页的修改次数只存在这个字典里，日志只在 Debug 下输出
static NSMutableDictionary<NSString *, NSNumber *> *XQQAppearanceChangeCounts(void) {
    static NSMutableDictionary<NSString *, NSNumber *> *counts;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ counts = [NSMutableDictionary dictionary]; });
    return counts;
}

@implementation XQQMKDIOFZTAppearanceVC (XQQSettingCheck)

// 新增：每次改动气泡颜色 / 背景图 / 背景色后调用：计数，并检查预览区是否跟着变了
- (void)xqq_recordChange:(NSString *)field {
    NSMutableDictionary<NSString *, NSNumber *> *counts = XQQAppearanceChangeCounts();
    counts[field] = @(counts[field].unsignedIntegerValue + 1);
#ifdef DEBUG
    NSLog(@"[Appearance] change %@ counts=%@ previewInSync=%d", field, counts, [self xqq_isPreviewInSync]);
#endif
}

// 新增：预览区是否与当前选择一致：背景图按钮的选中状态、预览背景图、预览气泡图。
// 这两个自定义 setter 写成了 setwaxiouv...（w 小写），属性赋值调用的是系统生成的
// setWaxiouv...，所以它们从不执行，预览区不会跟着选择变化。这里只检测、不修正
- (BOOL)xqq_isPreviewInSync {
    for (UIButton *button in @[self.waxiouvChatBg0Btn, self.waxiouvChatBgABtn, self.waxiouvChatBgBBtn,
                               self.waxiouvChatBgCBtn, self.waxiouvChatBgDBtn]) {
        if (button.selected != (button.tag == self.waxiouvChatBgImgIndex)) {
            return NO;
        }
    }
    UIImage *bubble = self.waxiouvBubbleColorIndex > 0 ? IMAGENAME((UNString(@"sent_msg_background%ld", self.waxiouvBubbleColorIndex))) : nil;
    return bubble == nil || [self.waxiouvBubbleColorImgV.image isEqual:bubble];
}

// 新增：保存前列出和已保存值不同的项
- (void)xqq_logPendingChangesWithAction:(NSString *)action {
#ifdef DEBUG
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableArray<NSString *> *changed = [NSMutableArray array];
    if ([defaults integerForKey:kAppearanceBubbleColor] != self.waxiouvBubbleColorIndex) { [changed addObject:@"bubbleColor"]; }
    if ([defaults integerForKey:kAppearanceChatBackgroundImg] != self.waxiouvChatBgImgIndex) { [changed addObject:@"chatBgImage"]; }
    NSLog(@"[Appearance] %@ changed=%@ counts=%@", action, changed, XQQAppearanceChangeCounts());
#endif
}

@end
