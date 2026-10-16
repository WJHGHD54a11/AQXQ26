//
//  XQQCPointsHistory.h
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQCPointsHistoryRecord : NSObject
@property(nonatomic, strong)NSString *balanceAfter;
@property(nonatomic, strong)NSString *changeType;
@property(nonatomic, strong)NSString *changeValue;
@property(nonatomic, strong)NSString *createTimestamp;
@property(nonatomic, strong)NSString *taskId;
@property(nonatomic, strong)NSString *id;

@end


@interface XQQCPointsHistory : NSObject
@property(nonatomic, strong)NSArray<XQQCPointsHistoryRecord *> *records;
@property(nonatomic)int total;
@end

NS_ASSUME_NONNULL_END
