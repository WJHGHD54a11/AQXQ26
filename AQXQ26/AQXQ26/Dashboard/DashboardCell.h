//
//  DashboardCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Metric tile (number + caption + symbol) used by Task / Project summary.
@interface DashboardMetricCell : UICollectionViewCell
- (void)configureValue:(NSString *)value caption:(NSString *)caption symbol:(NSString *)symbol color:(UIColor *)color;
@end

/// Generic row inside a dashboard card (today item, recent item, activity).
@interface DashboardCell : UICollectionViewListCell
- (void)configureTitle:(NSString *)title subtitle:(nullable NSString *)subtitle symbol:(NSString *)symbol
                 color:(UIColor *)color accessory:(nullable NSString *)accessory;
@end

NS_ASSUME_NONNULL_END
