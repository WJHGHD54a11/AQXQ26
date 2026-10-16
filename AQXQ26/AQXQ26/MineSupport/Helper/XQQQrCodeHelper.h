//
//  XQQQrCodeHelper.h
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 heavyrain lee. All rights reserved.
//


#ifndef XQQQrCodeHelper_h
#define XQQQrCodeHelper_h
#import <UIKit/UIKit.h>

#define QRType_User  0
#define QRType_Group 1
#define QRType_Channel 2
#define QRType_Chatroom 3
#define QRType_PC_Session 4
#define QRType_Conference 5

@protocol XQQQrCodeDelegate <NSObject>
- (void)showQrCodeViewController:(UINavigationController *)navigator type:(int)type target:(NSString *)target;
- (void)scanQrCode:(UINavigationController *)navigator;
- (BOOL)handleUrl:(NSString *)str withNav:(UINavigationController *)navigator;
- (void)enterLogin;
@end

extern id<XQQQrCodeDelegate> gXQQQrCodeDelegate;

extern void setXQQQrCodeDelegate(id<XQQQrCodeDelegate> delegate);
#endif /* XQQQrCodeHelper_h */
