//
//  XQQCSignHistory.h
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQCSignHistoryRecord : NSObject
@property(nonatomic, strong)NSString *dateTimestamp;
@property(nonatomic, strong)NSString *signType;
@property(nonatomic, strong)NSString *taskId;
@property(nonatomic, strong)NSString *taskCode;
@property(nonatomic, strong)NSString *rewardPoints;
@property(nonatomic, strong)NSString *status;

@end


@interface XQQCSignHistory : NSObject
@property(nonatomic, strong)NSArray<XQQCSignHistoryRecord *> *records;
@property(nonatomic)int total;

@end

NS_ASSUME_NONNULL_END
