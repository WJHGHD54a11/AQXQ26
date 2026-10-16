//
//  ProjectEditViewController.h
//  WorkSpace
//

#import "WSFormViewController.h"

@class Project;

NS_ASSUME_NONNULL_BEGIN

@interface ProjectEditViewController : WSFormViewController
- (instancetype)initWithProject:(nullable Project *)project;
@property (nonatomic, strong, readonly, nullable) Project *savedProject;
@end

NS_ASSUME_NONNULL_END
