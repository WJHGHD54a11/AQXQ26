//
//  TripHeatmapView.h
//  WorkSpace
//
//  Calendar heatmap: one square per day, columns are weeks, darker = more distance.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TripHeatmapView : UIView
/// startOfDay → km. `weeks` columns ending with the current week.
- (void)setDailyValues:(NSDictionary<NSDate *, NSNumber *> *)values weeks:(NSInteger)weeks;
@property (nonatomic, strong) UIColor *tint;
@end

NS_ASSUME_NONNULL_END
