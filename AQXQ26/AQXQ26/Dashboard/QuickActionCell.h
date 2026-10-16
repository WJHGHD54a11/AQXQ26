//
//  QuickActionCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QuickActionCell : UICollectionViewCell
- (void)configureTitle:(NSString *)title symbol:(NSString *)symbol color:(UIColor *)color;
@end

NS_ASSUME_NONNULL_END
