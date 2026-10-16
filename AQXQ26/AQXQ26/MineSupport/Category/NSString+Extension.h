//
//  NSString+Extension.h
//  UNI Z META
//
//  Created by Loooooo on 8/31/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Extension)

- (NSString *)md5;



- (BOOL)checkPhoneNum;
- (BOOL)checkPassword;

/**
 *  身份证号全校验
 */
//- (BOOL)verifyIDCardNumber;

/**
 *  时间戳转对应的时间字符串
 */
- (NSString *)timeIntervalDateFormat:(NSString *)format;

/**
 *  yyyy-MM-dd HH:mm:ss 格式的时间转换成需要的格式
 */
- (NSString *)dateConvertFormat:(NSString *)format;


/**
 *  时间小于1个小时  显示 20分钟前在线
 *  时间小于24小时  显示 5个小时前在线
 *  时间大于24小时  显示 2023-10-18 在线
 */
- (NSString *)timeFromNow:(NSInteger)timestamp;

@end

NS_ASSUME_NONNULL_END
