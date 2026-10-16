//
//  XQQCUserInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "XQQCUserInfo.h"

@implementation XQQCUserInfo
- (void)cloneFrom:(XQQCUserInfo *)other {
    self.userId = other.userId;
    self.name = other.name;
    self.displayName = other.displayName;
    self.groupAlias = other.groupAlias;
    self.alias = other.alias;
    self.portrait = other.portrait;
    self.gender = other.gender;
    self.mobile = other.mobile;
    self.email = other.email;
    self.address = other.address;
    self.company = other.company;
    self.social = other.social;
    self.extra = other.extra;
    self.updateDt = other.updateDt;
    self.type = other.type;
    self.deleted = other.deleted;
    self.birthday = other.birthday;
    self.finalName = other.finalName;
}

- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"uid"] = self.userId;
    dict[@"name"] = self.name;
    dict[@"displayName"] = self.displayName;
    dict[@"groupAlias"] = self.groupAlias;
    dict[@"alias"] = self.alias;
    dict[@"portrait"] = self.portrait;
    dict[@"gender"] = @(self.gender);
    dict[@"type"] = @(self.type);
    dict[@"mobile"] = self.mobile;
    dict[@"email"] = self.email;
    dict[@"address"] = self.address;
    dict[@"company"] = self.company;
    dict[@"social"] = self.social;
    dict[@"extra"] = self.extra;
    dict[@"updateDt"] = @(self.updateDt);
    dict[@"deleted"] = @(self.deleted);
    dict[@"birthday"] = self.birthday;
    dict[@"finalName"] = self.finalName;
    return dict;
}

//+ (NSDictionary *)mj_replacedKeyFromPropertyName {
//    return @{
//        @"friendAlias" : @"alias"
//    };
//}

@end
