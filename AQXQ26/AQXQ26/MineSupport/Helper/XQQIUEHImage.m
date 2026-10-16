//
//  XQQIUEHImage.m
//  WFChatUIKit
//
//  Created by Rain on 2022/7/16.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "XQQIUEHImage.h"

@implementation XQQIUEHImage
+ (nullable UIImage *)imageNamed:(NSString *)name {
    // UIKit 并入 App 后与 App 资源同名的图片，在 XQQChatUIKit.xcassets 中加了 wfcu_ 前缀
    static NSSet<NSString *> *renamed;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        renamed = [NSSet setWithArray:@[@"GroupChatRound", @"GroupNotiIcon", @"MessageSendError", @"PersonalChat",
                                        @"channel_default_portrait", @"conversation_message_sending", @"conversation_mute",
                                        @"groupIcon", @"nav_chat_group", @"nav_chat_single", @"organization_icon",
                                        @"pc_session", @"qrcode_Scan_weixin_Line", @"qrcode_scan_full_net",
                                        @"qrcode_scan_light_green", @"qrcode_scan_part_net", @"xaicosgoeSimpleArrow"]];
    });
    if (name && [renamed containsObject:name]) {
        name = [@"wfcu_" stringByAppendingString:name];
    }
    return [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}
@end
