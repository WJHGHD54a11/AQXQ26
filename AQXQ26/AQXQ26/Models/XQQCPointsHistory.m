//
//  XQQCPointsHistory.m
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQCPointsHistory.h"

@implementation XQQCPointsHistoryRecord

@end

@implementation XQQCPointsHistory

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"records" : [XQQCPointsHistoryRecord class]};
}

@end
