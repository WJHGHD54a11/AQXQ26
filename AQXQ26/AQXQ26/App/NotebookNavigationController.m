//
//  NotebookNavigationController.m
//  WorkSpace
//

#import "NotebookNavigationController.h"
#import "TaskListViewController.h"
#import "NoteListViewController.h"
#import "FileListViewController.h"
#import "AppConstants.h"

static NSString * const kSectionKey = @"notebook.section";

@interface NotebookNavigationController ()
@property (nonatomic, strong) NSArray<UIViewController *> *pages;
@property (nonatomic, strong) UISegmentedControl *picker;
@property (nonatomic, readwrite) NotebookSection section;
@end

@implementation NotebookNavigationController

- (instancetype)init {
    NSArray *pages = @[TaskListViewController.new, NoteListViewController.new, FileListViewController.new];
    NSInteger saved = [NSUserDefaults.standardUserDefaults integerForKey:kSectionKey];
    NotebookSection section = (saved >= 0 && saved < 3) ? saved : NotebookSectionTasks;
    if ((self = [super initWithRootViewController:pages[section]])) {
        _pages = pages;
        _section = section;
        _picker = [[UISegmentedControl alloc] initWithItems:@[WSText(@"Tasks"), WSText(@"Notes"), WSText(@"Files")]];
        _picker.selectedSegmentIndex = section;
        _picker.accessibilityLabel = WSText(@"Notebook");
        __weak typeof(self) weakSelf = self;
        [_picker addAction:[UIAction actionWithHandler:^(UIAction *a) {
            [weakSelf showSection:weakSelf.picker.selectedSegmentIndex];
        }] forControlEvents:UIControlEventValueChanged];
        for (UIViewController *page in pages) {
            // Compact bar: the picker takes the title's place.
            page.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
            page.navigationItem.titleView = _picker;
        }
    }
    return self;
}

- (UIViewController *)tasksPage { return self.pages[NotebookSectionTasks]; }

- (void)showSection:(NotebookSection)section {
    if (section < 0 || section >= (NSInteger)self.pages.count) return;
    self.section = section;
    self.picker.selectedSegmentIndex = section;
    [NSUserDefaults.standardUserDefaults setInteger:section forKey:kSectionKey];
    UIViewController *page = self.pages[section];
    page.navigationItem.titleView = self.picker;   // a view can only live in one bar at a time
    if (self.viewControllers.firstObject != page || self.viewControllers.count > 1) {
        [self setViewControllers:@[page] animated:NO];
    }
}

@end
