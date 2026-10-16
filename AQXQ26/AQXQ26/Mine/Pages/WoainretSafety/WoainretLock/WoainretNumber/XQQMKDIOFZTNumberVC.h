//
//  WUHOIBDK
//
//  Created by Ruby on 12/5/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQWJEFDOCYMainVC.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^NumericCodeBlock)(NSString *psw);

@interface XQQMKDIOFZTNumberVC : XQQWJEFDOCYMainVC


/**
 * type=0 设置数字密码  输入2次
 * type=1 验证数字密码。输入1次 跟服务器的值进行对比
 * type=2 修改数字密码。首先先验证数字密码，再实现2次设置
 * type=3 忘记数字密码，设置数字密码，输入2次
 * type=4 window启动时判断是否开启了安全锁，如果开启了(需要验证数字密码方可进入)
 * type=5   登录界面 判断是否设置了安全锁、  跟 4一样的。只是有一点区别(切换账号实现方式不同)
 * type=6   进入后台时间大于设置的时间，弹出安全锁进行验证。。跟4 和 5一样，些许不同
 *
 */
@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NumericCodeBlock pswBlock;

// type=3 时该字段有值
@property (nonatomic, copy) NSString *code;

@end

NS_ASSUME_NONNULL_END
