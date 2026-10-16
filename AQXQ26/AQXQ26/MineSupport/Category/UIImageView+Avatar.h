#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (Avatar)

- (void)setAvatarIdentifier:(NSString *)identifier;
- (NSString *)avatarIdentifier;

/**
 加载头像图片（无闪烁、低内存、安全复用）

 @param urlString 图片 URL 字符串
 @param placeholder 占位图（本地小图）
 @param userId 用户唯一标识（字符串）
 @param cornerRadius 圆角半径（0 表示不圆角）
 */
- (void)sd_setAvatarWithURLString:(nullable NSString *)urlString
                      placeholder:(nullable UIImage *)placeholder
                           userId:(nullable NSString *)userId
                     cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
