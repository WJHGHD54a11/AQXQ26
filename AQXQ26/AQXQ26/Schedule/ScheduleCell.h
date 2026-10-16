//
//  ScheduleCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Schedule;

NS_ASSUME_NONNULL_BEGIN

/// Time column + colored kind bar + title / location / reminder.
@interface ScheduleCell : UICollectionViewListCell
- (void)configureWithSchedule:(Schedule *)schedule showDate:(BOOL)showDate;
@end

NS_ASSUME_NONNULL_END
