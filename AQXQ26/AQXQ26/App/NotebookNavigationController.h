//
//  NotebookNavigationController.h
//  WorkSpace
//
//  记事 tab: Tasks, Notes and Files share one tab. A segmented control in the
//  title bar swaps the root page; each page keeps its own state while hidden.
//

#import "NavigationController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NotebookSection) {
    NotebookSectionTasks = 0,
    NotebookSectionNotes,
    NotebookSectionFiles,
};

@interface NotebookNavigationController : NavigationController
- (instancetype)init;
@property (nonatomic, readonly) NotebookSection section;
/// Pops to the section's root page and shows it.
- (void)showSection:(NotebookSection)section;
@property (nonatomic, readonly) UIViewController *tasksPage;
@end

NS_ASSUME_NONNULL_END
