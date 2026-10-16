//
//  KeyChainTool.m
//  WUHOIBDK
//
//  Created by Ruby on 2/1/24.
//

#import "KeyChainTool.h"
#import <Security/Security.h>

@implementation KeyChainTool

/*!
 //kSecClass 密钥类型键
 1.kSecClassGenericPassword 普通的密码类型
 2.kSecClassInternetPassword 互联网密码类型
 3.kSecClassCertificate 证书类型
 4.kSecClassKey 加密的键类型
 5.kSecClassIdentity 身份类型
 
 
 //kSecAttrAccessible 可访问性类型
 1.kSecAttrAccessibleWhenUnlocked //keychain项受到保护，只有在设备未被锁定时才可以访问 ，备份
 2.kSecAttrAccessibleAfterFirstUnlock //keychain项受到保护，直到设备启动并且用户第一次输入密码，备份
 3.kSecAttrAccessibleAlways //keychain未受保护，任何时候都可以访问 （Default)，备份
 4.kSecAttrAccessibleWhenUnlockedThisDeviceOnly //keychain项受到保护，只有在设备未被锁定时才可以访问，而且不可以转移到其他设备，不备份
 5.kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly //keychain项受到保护，直到设备启动并且用户第一次输入密码，而且不可以转移到其他设备，不备份
 6.kSecAttrAccessibleAlwaysThisDeviceOnly //keychain未受保护，任何时候都可以访问，但是不能转移到其他设备，不备份
 */
+ (NSMutableDictionary *)keyChainIdentifier:(NSString*)identifier {
    return [@{(__bridge id)kSecClass            : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService      : identifier,//[NSBundle mainBundle].bundleIdentifier,//服务
              (__bridge id)kSecAttrAccount      : identifier,//账户名
              (__bridge id)kSecAttrAccessible   : (__bridge id)kSecAttrAccessibleAfterFirstUnlock
              } mutableCopy];
}

/*!
 保存数据
 */
+ (BOOL)saveData:(id)data withIdentifier:(NSString*)identifier {
    // 获取存储的数据的条件
    NSMutableDictionary * saveQueryMutableDictionary = [self keyChainIdentifier:identifier];
    // 删除旧的数据
    SecItemDelete((CFDictionaryRef)saveQueryMutableDictionary);
    // 设置新的数据
    [saveQueryMutableDictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(id)kSecValueData];
    // 添加数据
    OSStatus saveState = SecItemAdd((CFDictionaryRef)saveQueryMutableDictionary, nil);
    // 释放对象
    saveQueryMutableDictionary = nil ;
    // 判断是否存储成功
    if (saveState == errSecSuccess) {
        return YES;
    }
    return NO;
}


/*!
 读取数据
 */
+ (id)readData:(NSString *)identifier {
    id idObject = nil ;
    // 通过标记获取数据查询条件
    NSMutableDictionary * keyChainReadQueryMutableDictionary = [self keyChainIdentifier:identifier];
    // 这是获取数据的时，必须提供的两个属性
    // TODO: 查询结果返回到 kSecValueData
    [keyChainReadQueryMutableDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    // TODO: 只返回搜索到的第一条数据
    [keyChainReadQueryMutableDictionary setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    // 创建一个数据对象
    CFDataRef keyChainData = nil ;
    // 通过条件查询数据
    if (SecItemCopyMatching((CFDictionaryRef)keyChainReadQueryMutableDictionary , (CFTypeRef *)&keyChainData) == noErr){
        @try {
            idObject = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)(keyChainData)];
        } @catch (NSException * exception){
            NSLog(@"Unarchive of search data where %@ failed of %@ ",identifier,exception);
        }
    }
    if (keyChainData) {
        CFRelease(keyChainData);
    }
    // 释放对象
    keyChainReadQueryMutableDictionary = nil;
    // 返回数据
    return idObject ;
}


/*!
 更新数据
 
 @data  要更新的数据
 @identifier 数据存储时的标示
 */
+ (BOOL)updata:(id)data withIdentifier:(NSString *)identifier {
    // 通过标记获取数据更新的条件
    NSMutableDictionary * keyChainUpdataQueryMutableDictionary = [self keyChainIdentifier:identifier];
    // 创建更新数据字典
    NSMutableDictionary * updataMutableDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    // 存储数据
    [updataMutableDictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(id)kSecValueData];
    // 获取存储的状态
    OSStatus  updataStatus = SecItemUpdate((CFDictionaryRef)keyChainUpdataQueryMutableDictionary, (CFDictionaryRef)updataMutableDictionary);
    // 释放对象
    keyChainUpdataQueryMutableDictionary = nil;
    updataMutableDictionary = nil;
    // 判断是否更新成功
    if (updataStatus == errSecSuccess) {
        return  YES ;
    }
    return NO;
}


/*!
 删除数据
 */
+ (void)Delete:(NSString *)identifier {
    // 获取删除数据的查询条件
    NSMutableDictionary * keyChainDeleteQueryMutableDictionary = [self keyChainIdentifier:identifier];
    // 删除指定条件的数据
    SecItemDelete((CFDictionaryRef)keyChainDeleteQueryMutableDictionary);
    // 释放内存
    keyChainDeleteQueryMutableDictionary = nil ;
}



@end
