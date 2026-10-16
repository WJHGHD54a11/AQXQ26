//
//  XQQCSignTasks.m
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "XQQCSignTasks.h"

@implementation XQQCSignTaskSignRecord

@end


@implementation XQQCSignTaskRecent7DaySummary

@end


@implementation XQQCSignTask

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"signRecords" : [XQQCSignTaskSignRecord class]};
}

@end


@implementation XQQCSignTasks

+ (NSDictionary *)mj_objectClassInArray {
    return @{@"tasks" : [XQQCSignTask class]};
}

@end
