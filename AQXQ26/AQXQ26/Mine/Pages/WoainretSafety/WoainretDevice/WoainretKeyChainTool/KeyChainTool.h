//
//  KeyChainTool.h
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define     kUUIDStringValue     @"UUIDStringValue" // 存设备的唯一ID

@interface KeyChainTool : NSObject

/*!
 保存数据
 @data  要存储的数据
 @identifier 存储数据的标示
 */
+ (BOOL)saveData:(id)data withIdentifier:(NSString*)identifier;

/*!
 读取数据
  */
+ (id)readData:(NSString*)identifier;

/*!
 更新数据
 @data  要更新的数据
 */
+ (BOOL)updata:(id)data withIdentifier:(NSString*)identifier;

/*!
 删除数据
 */
+ (void)Delete:(NSString*)identifier;


@end

NS_ASSUME_NONNULL_END
