//
//  XQQCResign.h
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQCResign : NSObject
@property(nonatomic, strong)NSArray *affectedTaskIds;
@property(nonatomic, strong)NSArray *ignoredTaskIds;
@property(nonatomic, strong)NSArray *affectedTaskCodes;
@property(nonatomic, strong)NSArray *ignoredTaskCodes;
@property(nonatomic, strong)NSString *compensationStatus;

@end

NS_ASSUME_NONNULL_END
