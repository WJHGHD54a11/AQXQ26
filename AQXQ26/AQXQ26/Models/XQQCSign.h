//
//  XQQCSign.h
//  WFChatClient
//
//  Created by wtb on 2026/5/8.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQQCSignAward : NSObject
@property(nonatomic, strong)NSString *taskId;
@property(nonatomic, strong)NSString *taskName;
@property(nonatomic, strong)NSString *awardType;
@property(nonatomic, strong)NSString *awardValue;

@end


@interface XQQCSign : NSObject
@property(nonatomic, strong)NSString *taskId;
@property(nonatomic, strong)NSString *earnedPoints;
@property(nonatomic, strong)NSString *continuousDays;
@property(nonatomic, strong)NSArray<XQQCSignAward *> *awards;
@end

NS_ASSUME_NONNULL_END
