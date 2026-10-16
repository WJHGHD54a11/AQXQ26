//
//  XQQMKDIOFZTFeedbackVC.m
//  WUHOIBDK
//
//  Created by Ruby on 11/15/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTFeedbackVC.h"

@interface XQQMKDIOFZTFeedbackVC ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>
{
    UIImage *_uploadImg;
    
    BOOL _isChinese;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIButton *typeAButton;
@property (weak, nonatomic) IBOutlet UIButton *typeBButton;
@property (weak, nonatomic) IBOutlet UIButton *typeCButton;

@property (weak, nonatomic) IBOutlet UIView *contentBgView;
@property (weak, nonatomic) IBOutlet UITextView *contentTV;

@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@property (weak, nonatomic) IBOutlet UIButton *okButton;

@property (nonatomic, assign) NSInteger selectType;

@property (strong, nonatomic) UIImagePickerController *pickerController;

@property (nonatomic, weak) UILabel *placeHolderLabel;

@property (weak, nonatomic) IBOutlet UILabel *feedbackTypeL;
@property (weak, nonatomic) IBOutlet UIButton *proposalBtn;
@property (weak, nonatomic) IBOutlet UIButton *errorBtn;
@property (weak, nonatomic) IBOutlet UIButton *otherBtn;
@property (weak, nonatomic) IBOutlet UILabel *feedbackContentL;
@property (weak, nonatomic) IBOutlet UILabel *relatedScreenshotsL;
@property (weak, nonatomic) IBOutlet UILabel *uploadLogsL;
@property (weak, nonatomic) IBOutlet UIButton *commitBtn;

@end

@implementation XQQMKDIOFZTFeedbackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _typeAButton.layer.cornerRadius = 20.0;
    _typeBButton.layer.cornerRadius = 20.0;
    _typeCButton.layer.cornerRadius = 20.0;
    _contentBgView.layer.cornerRadius = 10.0;
    _imgView.layer.cornerRadius = 10.0;
    _okButton.layer.cornerRadius = 15.0;
    
    _uploadImg = nil;
    
    _contentTV.backgroundColor = UIColor.clearColor;
    UILabel *placeHolderLabel = [[UILabel alloc] init];
    placeHolderLabel.text = @"";
    placeHolderLabel.numberOfLines = 0;
    placeHolderLabel.textColor = UIColor.lightGrayColor;
    [placeHolderLabel sizeToFit];
    placeHolderLabel.font = PINGFANG_R(14.0);
    [_contentTV addSubview:placeHolderLabel];
    [_contentTV setValue:placeHolderLabel forKey:@"_placeholderLabel"];
    _placeHolderLabel = placeHolderLabel;
    
    _scrollView.delegate = self;
    [_scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)]];
    
    _isChinese = [XQQCommonHelper.main isChinese];
    [self updateADFLanguage];
}
- (void)updateADFLanguage {
    self.navigationItem.title = LLLLLL(@"Feedback");
    if (_isChinese) {
        _placeHolderLabel.text = @"请尽量详细描述您要反馈的问题，以便我们尽快为您解决(500字内)";
        
        
    }else {
        _placeHolderLabel.text = @"Please provide a detailed description of the issue you want to provide feedback on so that we can resolve it for you as soon as possible (within 500 words)";
        
        _feedbackTypeL.text = @"Feedback type";
        [_proposalBtn setTitle:@"Proposal" forState:UIControlStateNormal];
        [_errorBtn setTitle:@"Error" forState:UIControlStateNormal];
        [_otherBtn setTitle:@"Other" forState:UIControlStateNormal];
        _feedbackContentL.text = @"Feedback content";
        _relatedScreenshotsL.text = @"Related screenshots";
        _uploadLogsL.text = @"Upload system logs to help improve products and services";
        [_commitBtn setTitle:@"Submit" forState:UIControlStateNormal];
    }
}

- (IBAction)ok:(UIButton *)sender {
    [self.view endEditing:YES];
    if (_contentTV.text.length <= 0) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@%@",LLLLLL(@"PleaseEnter"), LLLLLL(@"Feedback")]];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }
    /**
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"上传中...";
    [hud showAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"反馈成功！";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
     */
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (_uploadImg == nil) {
        hud.label.text = LLLLLL(@"Loading");
        
        [self feedbackHud:hud images:@[]];
    }else {
        hud.label.text = LLLLLL(@"Uploading");
        WS(weakself)
        
        NSData *portraitData = UIImageJPEGRepresentation(_uploadImg, 0.7);
        [XQQMineProfile uploadFile:@"jubao.png"
                                               data:portraitData
                                           mimeType:@"image/png"
                                            success:^(NSString * _Nonnull remoteUrl) {
            [weakself feedbackHud:hud images:@[remoteUrl]];
        } progress:^(long uploaded, long total) {

        } fail:^(int error_code, NSString * _Nonnull message) {
            
        }];

        
//        [XQQMineAPI uploadFile:@"/media/upload/file" images:@[_uploadImg] progress:^(int sentcount, int total) {
//        } success:^(NSString * _Nonnull url) {
//            [weakself feedbackHud:hud images:@[url]];
//        } error:^(NSString * _Nonnull errorMsg) {
//            [hud hideAnimated:YES];
//            [weakself.view makeToast:errorMsg duration:1.0 position:CSToastPositionCenter];
//        }];
    }
    [hud showAnimated:YES];
}
- (void)feedbackHud:(MBProgressHUD *)hud images:(NSArray<NSString *> *)images {
    NSMutableDictionary *params = NSMutableDictionary.new;
    params[@"type"] = @"1"; // 0 投诉  1 意见反馈
    if (_isChinese) {
        params[@"reason"] = @[@"建议", @"错误", @"其他", @""][self.selectType];
    }else {
        params[@"reason"] = @[@"Proposal", @"Error", @"Other", @""][self.selectType];
    }
    params[@"info"] = _contentTV.text;
    if (images.count) {
        params[@"images"] = images;
    }
    WS(weakself)
    [XQQMineAPI requestUrl:@"/complaint" params:params success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakself.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        NSString *text = @"";
        if (self->_isChinese) {
            text = message;
        }else {
            if ([message containsString:@"失败"]) {
                text = @"Failure...";
            }else if ([message containsString:@"错误"]) {
                text = @"Error...";
            }else {
                text = @"Error...";
            }
        }
        [self.view makeToast:text duration:1.0 position:CSToastPositionCenter];
    }];
}



- (IBAction)type:(UIButton *)sender {
    [self.view endEditing:YES];
    if (self.selectType == sender.tag) {
        return;
    }
    self.selectType = sender.tag;
}


- (void)setSelectType:(NSInteger)selectType {
    _selectType = selectType;
    
    _typeAButton.selected = (_selectType == 0);
    _typeBButton.selected = (_selectType == 1);
    _typeCButton.selected = (_selectType == 2);
    _typeAButton.backgroundColor = (_selectType == 0) ? MAINCOLOR : RGBA(0xEDEEF1);
    _typeBButton.backgroundColor = (_selectType == 1)  ? MAINCOLOR : RGBA(0xEDEEF1);
    _typeCButton.backgroundColor = (_selectType == 2)  ? MAINCOLOR : RGBA(0xEDEEF1);
}

- (IBAction)img:(UIButton *)sender {
    [self.view endEditing:YES];
//    [self presentViewController:self.pickerController animated:YES completion:nil];
    WS(weakself)
    [XQQCommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        self->_uploadImg = image;
        weakself.imgView.image = image;
    }];
}



- (UIImagePickerController *)pickerController {
    if (!_pickerController) {
        _pickerController = [[UIImagePickerController alloc] init];
        _pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _pickerController.delegate = self;
    }return _pickerController;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    WS(weakself)
    dispatch_async(dispatch_get_main_queue(), ^{
        weakself.imgView.image = img;
    });
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

- (void)close {
    [self.view endEditing:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
