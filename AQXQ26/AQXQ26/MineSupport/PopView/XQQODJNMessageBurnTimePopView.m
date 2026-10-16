//
//  XQQODJNMessageBurnTimePopView.m
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQODJNMessageBurnTimePopView.h"


@interface XQQODJNMessageBurnTimePopView ()<UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSInteger _selectIndex;
}
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgViewButton;

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) NSArray<NSString *> *dataSource;

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *okBtn;

@end

@implementation XQQODJNMessageBurnTimePopView

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"XQQODJNMessageBurnTimePopView" owner:self options:nil] lastObject];
        self.frame = ShareAppDelegate.window.frame;
        
        self.bgViewButton.constant = -320.0/375.0*WIDTH;
        [self layoutIfNeeded];
        
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
        
        [_cancelBtn setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
        [_okBtn setTitle:LLLLLL(@"Confirm") forState:UIControlStateNormal];
    }
    return self;
}

- (void)showIndex:(NSInteger)index datas:(NSArray<NSString *> *)datas {
    [ShareAppDelegate.window addSubview:self];
    
    _selectIndex = index;
    _dataSource = datas;
    [self.pickerView reloadComponent:0];
    [self.pickerView selectRow:_selectIndex inComponent:0 animated:YES];
    
    _bgViewButton.constant = 0.0;
    [UIView animateWithDuration:0.6 animations:^{
        [self layoutIfNeeded];
    }];
}


- (IBAction)ok:(UIButton *)sender {
    if (self.timeBlock) {
        self.timeBlock(_selectIndex);
    }
    [self close];
}


- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _dataSource.count;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _dataSource[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectIndex = row;
}



- (IBAction)closeView:(UIButton *)sender {
    [self close];
}

- (void)close {
    _bgViewButton.constant = -320.0/375.0*WIDTH;
    [UIView animateWithDuration:0.6 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
