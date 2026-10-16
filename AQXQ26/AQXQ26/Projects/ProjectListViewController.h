//
//  ProjectListViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>
#import "ProjectManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Projects tab: scope segments (Current / Completed / Archived), progress cards, archive / restore / delete.
@interface ProjectListViewController : UIViewController
- (instancetype)initWithScope:(ProjectListScope)scope;
@end

NS_ASSUME_NONNULL_END
