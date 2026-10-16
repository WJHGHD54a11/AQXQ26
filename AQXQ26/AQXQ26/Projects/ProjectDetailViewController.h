//
//  ProjectDetailViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Project;

NS_ASSUME_NONNULL_BEGIN

/// Overview + live progress, task / note / file sections, recent activity, status menu.
@interface ProjectDetailViewController : UIViewController
- (instancetype)initWithProject:(Project *)project;
@property (nonatomic, strong, readonly) Project *project;
@end

NS_ASSUME_NONNULL_END
