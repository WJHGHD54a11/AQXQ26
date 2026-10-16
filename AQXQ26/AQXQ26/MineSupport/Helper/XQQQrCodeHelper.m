//
//  XQQQrCodeHelper.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/3/3.
//  Copyright © 2019 heavyrain lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQQQrCodeHelper.h"

id<XQQQrCodeDelegate> gXQQQrCodeDelegate = nil;

void setXQQQrCodeDelegate(id<XQQQrCodeDelegate> delegate) {
    gXQQQrCodeDelegate = delegate;
}
