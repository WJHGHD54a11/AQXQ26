//
//  XQQMKDIOFZTAvatarVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 7/22/24.
//

#import "XQQMKDIOFZTAvatarVC.h"

#import "XQQMKDIOFZTAvatarRecordVC.h"
#import "XQQMKDIOFZTAvatarCVCell.h"

@interface XQQMKDIOFZTAvatarVC ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    BOOL _isChinese;
    BOOL _isCanUpdateAvatar; // 也就是waxiouvAvatarV 是否是下面列表的头像之一
    
    NSString *_waxiouvRemoteUrl; // 用于保存《自定义》下的头像更改url的值
}
@property (weak, nonatomic) IBOutlet UIImageView *waxiouvAvatarV;

@property (weak, nonatomic) IBOutlet UIView *waxiouvTypeV;
// (20, 5)
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *waxiouvLineLeft;

@property (nonatomic, assign) NSInteger waxiouvType;
@property (weak, nonatomic) IBOutlet UICollectionView *waxiouvCV;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *waxiouvLayout;
@property (nonatomic, strong) NSMutableArray<NSString *> *waxiouvAvatars; // 自定义的网络头像

@property (weak, nonatomic) IBOutlet UIButton *waxiouvCancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *waxiouvSaveBtn;

@property (nonatomic, strong) XQQCUserInfo *userInfo;

@end

@implementation XQQMKDIOFZTAvatarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self itemImage:@"waxiouvRecord" action:@selector(waxiouvRecord)]];
    
    _isChinese = [XQQCommonHelper.main isChinese];
    [_waxiouvCancelBtn setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
    if (_isChinese) {
        self.navigationItem.title = @"更换头像";
    }else {
        self.navigationItem.title = @"Change the avatar";
        [_waxiouvSaveBtn setTitle:LLLLLL(@"Save") forState:UIControlStateNormal];
        NSArray *waxiouvTypeTitles = @[@"Custom", @"Cartoon", @"Trend", @"3D"];
        for (UIView *waxiouvV in _waxiouvTypeV.subviews) {
            if (waxiouvV.tag >= 10) {
                continue;
            }
            UIButton *waxiouvBtn = (UIButton *)waxiouvV;
            [waxiouvBtn setTitle:waxiouvTypeTitles[waxiouvBtn.tag] forState:UIControlStateNormal];
        }
    }
    self.userInfo = [XQQMineProfile getMyInfo];
    [_waxiouvAvatarV sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"]];
    
    _isCanUpdateAvatar = NO;
    self.waxiouvType = 0;
    _waxiouvRemoteUrl = @"";
    _waxiouvAvatarV.layer.cornerRadius = 75.0;
    _waxiouvCancelBtn.layer.cornerRadius = 12.0;
    _waxiouvSaveBtn.layer.cornerRadius = 12.0;
    _waxiouvLineLeft.constant = (WIDTH - 30.0) / 8.0 * (2.0 * _waxiouvType + 1) - 10.0;
    
    [self requestCustomAvatar];
    _waxiouvLayout.sectionInset = UIEdgeInsetsMake(15.0, 25.0, 22.0, 25.0);
    _waxiouvLayout.itemSize = CGSizeMake(70.0, 70.0);
    _waxiouvLayout.minimumInteritemSpacing = 0.0;
    _waxiouvLayout.minimumLineSpacing = 22.0;
    _waxiouvCV.delegate = self;
    _waxiouvCV.dataSource = self;
    [_waxiouvCV registerNib:[UINib nibWithNibName:@"XQQMKDIOFZTAvatarCVCell" bundle:nil] forCellWithReuseIdentifier:@"XQQMKDIOFZTAvatarCVCell"];
}
- (void)requestCustomAvatar {
    [self.waxiouvAvatars removeAllObjects];
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Loading");
    [hud showAnimated:YES];
    
    WS(weakself) // type  0 自定义的头像  OR  1 更改头像的历史记录
    [XQQMineAPI requestUrl:@"/user/headers" params:@{@"type":@"0"} success:^(NSDictionary * _Nonnull dict) {
        [hud hideAnimated:YES];
        NSArray *results = dict[@"result"];
        if (results.count <= 0) {
            return;
        }
        for (NSDictionary *resultDic in results) {
            NSString *portrait = resultDic[@"portrait"];
            if (portrait.length <= 0) {
                continue;
            }
            [weakself.waxiouvAvatars addObject:portrait];
        }
        [weakself.waxiouvCV reloadData];
    } error:^(int errCode, NSString * _Nonnull message) {
        [hud hideAnimated:YES];
        [weakself.view makeToast:message duration:1.0 position:CSToastPositionCenter];
    }];
}

- (IBAction)waxiouvTypes:(UIButton *)sender {
    if (_waxiouvType == sender.tag) {
        return;
    }
    WS(weakself)
    _waxiouvLineLeft.constant = (WIDTH - 30.0) / 8.0 * (2.0 * sender.tag + 1) - 10.0;
    [UIView animateWithDuration:0.5 animations:^{
        [weakself.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        weakself.waxiouvType = sender.tag;
        for (UIView *waxiouvV in weakself.waxiouvTypeV.subviews) {
            if (waxiouvV.tag >= 10) {
                continue;
            }
            UIButton *waxiouvBtn = (UIButton *)waxiouvV;
            waxiouvBtn.selected = (waxiouvBtn.tag == sender.tag);
            [weakself.waxiouvCV reloadData];
        }
    }];
}
//- (void)setwaxiouvType:(NSInteger)waxiouvType {
//    _waxiouvType = waxiouvType;
//
//    [_waxiouvCV reloadData];
//}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_waxiouvType == 0) {
        return (1 + self.waxiouvAvatars.count);
    }
    return 10;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XQQMKDIOFZTAvatarCVCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XQQMKDIOFZTAvatarCVCell" forIndexPath:indexPath];
    if (_waxiouvType == 0) {
//        if (_waxiouvAvatars.count == 0) {
//            cell.waxiouvIconV.image = IMAGENAME(@"waxiouvAddAvatar");
//        }else {
//            if (_waxiouvAvatars.count > 0 && indexPath.row == 0) {
//                [cell.waxiouvIconV sd_setImageWithURL:URL((_waxiouvAvatars[indexPath.row]))];
//            }else {
//                cell.waxiouvIconV.image = IMAGENAME(@"waxiouvAddAvatar");
//            }
//        }
        
        
        if (_waxiouvAvatars.count > 0 && indexPath.row < _waxiouvAvatars.count) {
            [cell.waxiouvIconV sd_setImageWithURL:URL((_waxiouvAvatars[indexPath.row])) placeholderImage:nil options:SDWebImageScaleDownLargeImages
                                          context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        }else {
            cell.waxiouvIconV.image = IMAGENAME(@"waxiouvAddAvatar");
        }
    }else {
        cell.waxiouvIconV.image = IMAGENAME(([NSString stringWithFormat:@"waxiouvAvatar%ld_%ld",_waxiouvType, indexPath.row]));
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (_waxiouvType == 0) { // 自定义
        if (_waxiouvAvatars.count > 0 && indexPath.row < _waxiouvAvatars.count) {
            _isCanUpdateAvatar = YES;
            _waxiouvRemoteUrl = _waxiouvAvatars[indexPath.row];
            [_waxiouvAvatarV sd_setImageWithURL:URL(_waxiouvRemoteUrl) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                        context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}
];
        }else { // 上传头像按钮
            [self waxiouvAddAvatar];
        }
    }else {
        _isCanUpdateAvatar = YES;
        _waxiouvRemoteUrl = @"";
        _waxiouvAvatarV.image = IMAGENAME(([NSString stringWithFormat:@"waxiouvAvatar%ld_%ld",_waxiouvType, indexPath.row]));
    }
}

- (void)waxiouvAddAvatar {
    WS(weakself)
    [XQQCommonHelper.main showImagePikerWithimageBlock:^(UIImage * _Nonnull image) {
        [weakself uploadImage:image];
    }];
}

- (void)uploadImage:(UIImage *)targetImg {
    WS(weakself)
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"Uploading");
    [hud showAnimated:YES];
        
    [XQQMineProfile generateUploadFile:@"avatar.png"
                                              success:^(NSString * _Nonnull uploadUrl, NSString * _Nonnull requestUrl) {
        [XQQMineProfile uploadData:UIImageJPEGRepresentation(targetImg, 0.1)
                                              url:uploadUrl
                                        remoteUrl:requestUrl
                                          success:^(NSString * _Nonnull remoteUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];

                if (remoteUrl.length > 0) {
                    [weakself.waxiouvAvatars addObject:remoteUrl];
                    [weakself.waxiouvCV reloadData];
                }
            });
        } progress:^(long uploaded, long total) {
            
        } fail:^(int error_code) {
            
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          hud.mode = MBProgressHUDModeText;
          hud.label.text = LLLLLL(@"UploadFailure");
          hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
          [hud hideAnimated:YES afterDelay:1.f];
      });
    }];

    
    
//    [XQQMineAPI uploadFile:@"/media/upload/avatar" images:@[targetImg] progress:^(int sentcount, int total) {
//    } success:^(NSString * _Nonnull url) {
//        [hud hideAnimated:YES];
//        if (url.length > 0) {
//            [weakself.waxiouvAvatars addObject:url];
//            [weakself.waxiouvCV reloadData];
//        }
//    } error:^(NSString * _Nonnull errorMsg) {
//        [hud hideAnimated:YES];
//        [weakself.view makeToast:errorMsg duration:1.0 position:CSToastPositionCenter];
//    }];
}



#pragma mark - 头像更改的历史列表

- (void)waxiouvRecord {
    XQQMKDIOFZTAvatarRecordVC *vc = XQQMKDIOFZTAvatarRecordVC.new;
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - 更改头像 至 IM服务器

- (IBAction)waxiouvCancel:(UIButton *)sender {
    if (_isCanUpdateAvatar) {
        [_waxiouvAvatarV sd_setImageWithURL:URL(_userInfo.portrait) placeholderImage:[XQQIUEHImage imageNamed:@"PersonalChat"] options:SDWebImageScaleDownLargeImages
                                    context:@{SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever), SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}];
        _isCanUpdateAvatar = NO;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)waxiouvSave:(UIButton *)sender {
    if (!_isCanUpdateAvatar) {
        [self.view makeToast:(_isChinese ? @"请选择头像..." : @"Please select an avatar...") duration:1.0 position:CSToastPositionCenter];
        return;
    }
    if (_waxiouvType == 0) { // 自定义的头像，本地保存的本身就是url格式，更改时就不用上传至服务器，直接通过IM进行更改头像
        [self modityAvatarWithIM:_waxiouvRemoteUrl];
    }else {
        [self uploadServiceImg:UIImageJPEGRepresentation(_waxiouvAvatarV.image, 0.1)];
    }
}

- (void)uploadServiceImg:(NSData *)imgData { // 这一步是更改本地的头像  必须上传至服务器，再通过IM进行更改
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LLLLLL(@"OperationInProgress");
    [hud showAnimated:YES];
    WS(weakself)
    [XQQMineProfile generateUploadFile:@"avatar.png"
                                              success:^(NSString * _Nonnull uploadUrl, NSString * _Nonnull requestUrl) {
        [XQQMineProfile uploadData:imgData
                                              url:uploadUrl
                                        remoteUrl:requestUrl
                                          success:^(NSString * _Nonnull remoteUrl) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
                [weakself modityAvatarWithIM:remoteUrl];
            });
        } progress:^(long uploaded, long total) {
            
        } fail:^(int error_code) {
            
        }];
    } error:^(int errCode, NSString * _Nonnull message) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
          MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
          hud.mode = MBProgressHUDModeText;
          hud.label.text = LLLLLL(@"UploadFailure");
          hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
          [hud hideAnimated:YES afterDelay:1.f];
      });
    }];
    
//      [XQQMineProfile uploadMedia:nil mediaData:imgData mediaType:Media_Type_PORTRAIT success:^(NSString *remoteUrl) {
//          dispatch_async(dispatch_get_main_queue(), ^{
//              [hud hideAnimated:YES];
//              [weakself modityAvatarWithIM:remoteUrl];
//          });
//      } progress:^(long uploaded, long total) {
//      } error:^(int error_code) {
//          dispatch_async(dispatch_get_main_queue(), ^{
//            [hud hideAnimated:YES];
//            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//            hud.mode = MBProgressHUDModeText;
//            hud.label.text = LLLLLL(@"UploadFailure");
//            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
//            [hud hideAnimated:YES afterDelay:1.f];
//        });
//    }];
}

- (void)modityAvatarWithIM:(NSString *)remoteUrl {
//    [XQQMineProfile modifyMyInfo:@{@(Modify_Portrait):remoteUrl} success:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self->_isCanUpdateAvatar = NO;
//
//            [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//      });
//    } error:^(int error_code) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:1.0 position:CSToastPositionCenter];
//        });
//    }];
    WS(weakself)
    [XQQMineProfile userUpdate:@{@"portrait":remoteUrl}
                                      success:^{
        self->_isCanUpdateAvatar = NO;

        [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];

        if (weakself.isRegister) {
            if (self.setBlock) {
                self.setBlock(remoteUrl);
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.navigationController popViewControllerAnimated:YES];
            });
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //            [weakself.navigationController popViewControllerAnimated:YES];
                [weakself.navigationController popToRootViewControllerAnimated:YES];
            });
        }

    } error:^(int errCode, NSString * _Nonnull message) {
        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:1.0 position:CSToastPositionCenter];

    }];
//    [XQQMineAPI requestUrl:@"/update/avatar" params:@{@"portrait":remoteUrl} success:^(NSDictionary * _Nonnull dict) {
//        self->_isCanUpdateAvatar = NO;
//
//        [weakself.view makeToast:LLLLLL(@"SuccessfulOperation") duration:1.0 position:CSToastPositionCenter];
//
//        if (weakself.isRegister) {
//            if (self.setBlock) {
//                self.setBlock(remoteUrl);
//            }
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [weakself.navigationController popViewControllerAnimated:YES];
//            });
//        } else {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"kUserDataUpdated" object:nil];
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//    //            [weakself.navigationController popViewControllerAnimated:YES];
//                [weakself.navigationController popToRootViewControllerAnimated:YES];
//            });
//        }
//    } error:^(int errCode, NSString * _Nonnull message) {
//        [weakself.view makeToast:LLLLLL(@"OperationFailure") duration:1.0 position:CSToastPositionCenter];
//    }];
}

- (NSMutableArray *)waxiouvAvatars {
    if (!_waxiouvAvatars) {
        _waxiouvAvatars = NSMutableArray.new;
    }return _waxiouvAvatars;
}

@end
/**
 获取用户历史头像  自定义的头像0 and 更改头像的历史记录
 http://ec2-54-254-43-61.ap-southeast-1.compute.amazonaws.com:8888/swagger-ui/index.html#/app-controller/headers

 删除历史头像
 http://ec2-54-254-43-61.ap-southeast-1.compute.amazonaws.com:8888/swagger-ui/index.html#/app-controller/deleteAvatar
 上传头像(上传后会返回访问URL)
 http://ec2-54-254-43-61.ap-southeast-1.compute.amazonaws.com:8888/swagger-ui/index.html#/app-controller/uploadAvatar
 */


