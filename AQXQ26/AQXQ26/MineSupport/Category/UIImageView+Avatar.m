#import "UIImageView+Avatar.h"
#import <SDWebImage/SDWebImage.h>
#import <objc/runtime.h>

@implementation UIImageView (Avatar)

static const void *kAvatarIdentifierKey = &kAvatarIdentifierKey;
static const void *kAvatarURLKey = &kAvatarURLKey;

- (void)setAvatarIdentifier:(NSString *)identifier {
    objc_setAssociatedObject(self, kAvatarIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)avatarIdentifier {
    return objc_getAssociatedObject(self, kAvatarIdentifierKey);
}

- (void)sd_setAvatarWithURLString:(nullable NSString *)urlString
                      placeholder:(nullable UIImage *)placeholder
                           userId:(nullable NSString *)userId
                     cornerRadius:(CGFloat)cornerRadius {
    
    // 优化：先检查是否需要加载
    // 强化复用检查
    NSString *currentUserId = [self avatarIdentifier];
    NSString *normalizedUserId = userId ?: @"";
    NSString *normalizedURLString = urlString ?: @"";
    NSString *lastURLString = objc_getAssociatedObject(self, kAvatarURLKey);

    // 同一用户、同一URL且已有图片时，直接复用当前显示，避免重复设置造成闪烁
    if (currentUserId.length > 0 &&
        [currentUserId isEqualToString:normalizedUserId] &&
        ((lastURLString == nil && normalizedURLString.length == 0) || [lastURLString isEqualToString:normalizedURLString]) &&
        self.image != nil) {
        // 如果当前是占位图，仍需继续加载真实头像
        if (placeholder && [self.image isEqual:placeholder]) {
            // fallthrough
        } else {
            return;
        }
    }

    BOOL userChanged = (currentUserId.length > 0 && normalizedUserId.length > 0 && ![currentUserId isEqualToString:normalizedUserId]);

    [self setAvatarIdentifier:normalizedUserId];
    objc_setAssociatedObject(self, kAvatarURLKey, normalizedURLString, OBJC_ASSOCIATION_COPY_NONATOMIC);

    // URL 编码
    NSString *encodedURLString =
        [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:encodedURLString];
    
    if (!url) {
        self.image = placeholder;
        return;
    }
    
    // 优先同步命中缓存，页面切换时可直接显示，避免先占位再回调导致闪烁
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromCacheForKey:cacheKey];
    if (cachedImage) {
        self.image = cachedImage;
        return;
    }

    // 缓存未命中时，确保有占位图，避免空白
    if (!self.image && placeholder) {
        self.image = placeholder;
    }

    // 换用户且缓存未命中时，先显示占位图，避免错误旧头像短暂可见
    if (userChanged && placeholder) {
        self.image = placeholder;
    }
    
    // ✅ 使用 SDWebImage 内部缓存机制（无 queryImageForKey）
    id transformer = nil;
    if (cornerRadius > 0) {
        transformer = [SDImageRoundCornerTransformer transformerWithRadius:cornerRadius
                                                                   corners:UIRectCornerAllCorners
                                                               borderWidth:0
                                                               borderColor:nil];
    }

    // 避免闪烁：placeholder 仅在真正下载时显示
    [self sd_setImageWithURL:url
             placeholderImage:nil
                      options:SDWebImageRetryFailed | SDWebImageScaleDownLargeImages | SDWebImageLowPriority | SDWebImageAvoidAutoSetImage
                      context:@{
                          SDWebImageContextImageForceDecodePolicy : @(SDImageForceDecodePolicyNever),
                          SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk),
                          SDWebImageContextImageTransformer : transformer ?: [NSNull null]
                      }
                    progress:nil
                   completed:^(UIImage * _Nullable image,
                               NSError * _Nullable error,
                               SDImageCacheType cacheType,
                               NSURL * _Nullable imageURL) {
        (void)cacheType;
        (void)error;
        (void)imageURL;
        
        // 强化复用检查：不仅要检查userId，还要检查当前是否有图片
        NSString *currentIdentifier = [self avatarIdentifier];
        if (![currentIdentifier isEqualToString:(userId ?: @"")]) {
            return; // cell已被复用
        }
        
        // 额外检查：如果已经有图片显示，且新图片为空，则不替换
        if (!image && self.image != nil) {
            return;
        }
        
        if (image) {
            // 直接设置，避免 reload 期间多次淡入导致的头像闪烁
            self.image = image;
        } else {
            // 加载失败时使用占位图（仅在当前没有图片时）
            if (self.image == nil) {
                self.image = placeholder;
            }
        }

        
//        // 防止 cell 重用错图
//        if (![[self avatarIdentifier] isEqualToString:(userId ?: @"")]) return;
//        
//        if (image) {
//            // 仅网络下载图片时添加淡入动画
//            if (cacheType == SDImageCacheTypeNone) {
//                self.alpha = 0.0;
//                self.image = image;
//                [UIView animateWithDuration:0.15 animations:^{
//                    self.alpha = 1.0;
//                }];
//            } else {
//                self.image = image;
//            }
//        } else {
//            // 加载失败时使用占位图
//            self.image = placeholder;
//        }
    }];
}

- (BOOL)shouldLoadAvatarWithURLString:(NSString *)urlString userId:(NSString *)userId {
    NSString *currentIdentifier = [self avatarIdentifier];
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:urlString]];
    
    // 如果userId相同且图片已在缓存中，不需要重新加载
    if ([currentIdentifier isEqualToString:userId] &&
        [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:cacheKey]) {
        return NO;
    }
    return YES;
}

@end
