//
//  TripsViewController.h
//  WorkSpace
//
//  行程 tab: this month's mileage, purpose split, activity heatmap, frequent routes and recent trips.
//

#import <UIKit/UIKit.h>

@class Trip;

NS_ASSUME_NONNULL_BEGIN

@interface TripsViewController : UIViewController
@end

/// Every trip grouped by month, filterable by purpose.
@interface TripListViewController : UITableViewController
@end

/// Row used by both lists.
FOUNDATION_EXPORT UIView *TripRowView(Trip *trip);

NS_ASSUME_NONNULL_END
