//
//  XQQODJNMessageBurnTimePopView.h
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MessageBurnTimeBlock)(NSInteger row);

@interface XQQODJNMessageBurnTimePopView : UIView

- (void)showIndex:(NSInteger)index datas:(NSArray<NSString *> *)datas;

@property (nonatomic, copy) MessageBurnTimeBlock timeBlock;

@end

NS_ASSUME_NONNULL_END
