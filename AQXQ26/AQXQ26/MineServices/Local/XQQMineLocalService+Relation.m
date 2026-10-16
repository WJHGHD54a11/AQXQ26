//
//  XQQMineLocalService+Relation.m
//  AQXQ26
//
//  好友关系 / 群资料 / 会话 + 签到积分的本地实现
//

#import "XQQMineLocalService+Private.h"
#import "XQQCUserInfo.h"
#import "XQQCGroupInfo.h"
#import "XQQCSignTasks.h"
#import "XQQCSign.h"
#import "XQQCPointsHistory.h"
#import "MJExtension.h"

@implementation XQQMineLocalService (Relation)

- (NSString *)xqq_blackKey {
    return [@"black." stringByAppendingString:self.currentUserId];
}

- (void)friendBlackList:(void (^)(NSArray<XQQCUserInfo *> *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSArray *ids = [self objectForKey:self.xqq_blackKey] ?: @[];
    NSMutableArray *users = NSMutableArray.new;
    for (NSString *uid in ids) {
        XQQCUserInfo *user = [self getUserInfo:uid];
        if (user) [users addObject:user];
    }
    [self after:^{ if (successBlock) successBlock(users); }];
}

- (void)friendBlackCancel:(NSString *)userId success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSMutableArray *ids = [[self objectForKey:self.xqq_blackKey] mutableCopy] ?: NSMutableArray.new;
    [ids removeObject:userId ?: @""];
    [self setObject:ids forKey:self.xqq_blackKey];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)friendAliasUpdate:(NSString *)userId alias:(NSString *)alias success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    XQQCUserInfo *user = [self getUserInfo:userId];
    if (user) {
        user.alias = alias;
        [self insertOrUpdateUserInfo:user];
        [NSNotificationCenter.defaultCenter postNotificationName:kUserInfoUpdated object:nil userInfo:@{@"userInfoList": @[user]}];
    }
    [self after:^{ if (successBlock) successBlock(); }];
}

#pragma mark - 群（群模块未迁移，仅保存本地副本，供 TextModifyVC 被群页面复用时使用）

- (NSString *)xqq_groupKey:(NSString *)groupId {
    return [@"group." stringByAppendingString:groupId ?: @""];
}

- (XQQCGroupInfo *)getGroupInfoFromDB:(NSString *)groupId {
    NSDictionary *dict = [self objectForKey:[self xqq_groupKey:groupId]];
    return dict ? [XQQCGroupInfo mj_objectWithKeyValues:dict] : nil;
}

- (void)insertOrUpdateGroupInfo:(XQQCGroupInfo *)groupInfo {
    if (groupInfo.target.length == 0) return;
    [self setObject:[groupInfo mj_keyValues] forKey:[self xqq_groupKey:groupInfo.target]];
}

- (void)groupUpdate:(NSDictionary *)params success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSString *gid = params[@"gid"];
    XQQCGroupInfo *group = [self getGroupInfoFromDB:gid] ?: XQQCGroupInfo.new;
    group.target = gid;
    if (params[@"name"]) group.name = params[@"name"];
    [self insertOrUpdateGroupInfo:group];
    [NSNotificationCenter.defaultCenter postNotificationName:kGroupInfoUpdated object:nil userInfo:@{@"groupInfoList": @[group]}];
    [self after:^{ if (successBlock) successBlock(); }];
}

- (void)groupMemberAlias:(NSDictionary *)params success:(void (^)(void))successBlock error:(void (^)(int, NSString *))errorBlock {
    [self setObject:params[@"alias"] forKey:[NSString stringWithFormat:@"groupAlias.%@.%@", params[@"gid"], params[@"uid"]]];
    [self after:^{ if (successBlock) successBlock(); }];
}

#pragma mark - 会话（聊天模块未迁移，本地无会话数据）

- (void)clearAllConversations {
    [NSNotificationCenter.defaultCenter postNotificationName:XQQMineDidClearMessagesNotification object:nil];
}

- (void)clearAllMessages:(BOOL)removeConversation {
    [self clearAllConversations];
}

@end

@implementation XQQMineLocalService (Extra)

- (NSString *)xqq_signKey { return [@"sign." stringByAppendingString:self.currentUserId]; }
- (NSString *)xqq_todayString {
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.dateFormat = @"yyyy-MM-dd";
    return [fmt stringFromDate:NSDate.date];
}

/// 本地签到记录：{ days: [yyyy-MM-dd...], points: N, history: [record...] }
- (NSMutableDictionary *)xqq_signState {
    NSMutableDictionary *state = [[self objectForKey:self.xqq_signKey] mutableCopy] ?: NSMutableDictionary.new;
    if (!state[@"days"]) state[@"days"] = @[];
    if (!state[@"points"]) state[@"points"] = @0;
    if (!state[@"history"]) state[@"history"] = @[];
    return state;
}

- (void)signTasks:(void (^)(XQQCSignTasks *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSDictionary *state = self.xqq_signState;
    NSArray<NSString *> *days = state[@"days"];
    BOOL signedToday = [days containsObject:self.xqq_todayString];

    NSMutableArray *records = NSMutableArray.new;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDateFormatter *fmt = NSDateFormatter.new;
    fmt.dateFormat = @"yyyy-MM-dd";
    for (NSInteger i = 6; i >= 0; i--) {
        NSDate *date = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:NSDate.date options:0];
        NSDate *start = [cal startOfDayForDate:date];
        BOOL done = [days containsObject:[fmt stringFromDate:date]];
        [records addObject:@{@"dateTimestamp": [NSString stringWithFormat:@"%lld", (long long)(start.timeIntervalSince1970 * 1000)],
                             @"status": done ? @"1" : @"0",
                             @"points": done ? @"10" : @"0"}];
    }
    NSDictionary *dict = @{@"totalPoints": [state[@"points"] stringValue],
                           @"tasks": @[@{@"taskId": @"daily_sign", @"taskCode": @"DAILY_SIGN", @"taskName": @"每日签到",
                                         @"taskType": @"1", @"lifecycleType": @"1", @"cycleDays": @"7",
                                         @"progress": [NSString stringWithFormat:@"%lu", (unsigned long)MIN(days.count, 7)], @"target": @"7",
                                         @"status": signedToday ? @"1" : @"0", @"rewardDesc": @"每日 +10 积分",
                                         @"todayPoints": signedToday ? @"10" : @"0", @"allowReSign": @NO,
                                         @"signRecords": records}]};
    XQQCSignTasks *tasks = [XQQCSignTasks mj_objectWithKeyValues:dict];
    [self after:^{ if (successBlock) successBlock(tasks); }];
}

- (void)signSubmit:(NSDictionary *)param success:(void (^)(XQQCSign *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSMutableDictionary *state = self.xqq_signState;
    NSMutableArray *days = [state[@"days"] mutableCopy];
    NSString *today = self.xqq_todayString;
    if ([days containsObject:today]) {
        [self after:^{ if (errorBlock) errorBlock(-1, @"今日已签到"); }];
        return;
    }
    [days addObject:today];
    NSInteger points = [state[@"points"] integerValue] + 10;
    NSMutableArray *history = [state[@"history"] mutableCopy];
    [history insertObject:@{@"id": NSUUID.UUID.UUIDString, @"taskId": param[@"taskId"] ?: @"daily_sign",
                            @"changeType": @"1", @"changeValue": @"10",
                            @"balanceAfter": [NSString stringWithFormat:@"%ld", (long)points],
                            @"createTimestamp": [NSString stringWithFormat:@"%lld", (long long)(NSDate.date.timeIntervalSince1970 * 1000)]} atIndex:0];
    state[@"days"] = days;
    state[@"points"] = @(points);
    state[@"history"] = history;
    [self setObject:state forKey:self.xqq_signKey];

    XQQCSign *sign = [XQQCSign mj_objectWithKeyValues:@{@"taskId": param[@"taskId"] ?: @"daily_sign", @"earnedPoints": @"10",
                                                       @"continuousDays": [NSString stringWithFormat:@"%lu", (unsigned long)days.count]}];
    [self after:^{ if (successBlock) successBlock(sign); }];
}

- (void)pointsHistory:(NSDictionary *)param success:(void (^)(XQQCPointsHistory *))successBlock error:(void (^)(int, NSString *))errorBlock {
    NSArray *history = self.xqq_signState[@"history"];
    XQQCPointsHistory *result = [XQQCPointsHistory mj_objectWithKeyValues:@{@"records": history, @"total": @(history.count)}];
    [self after:^{ if (successBlock) successBlock(result); }];
}

@end
