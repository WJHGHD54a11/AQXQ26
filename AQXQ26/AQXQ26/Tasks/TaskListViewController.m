//
//  TaskListViewController.m
//  WorkSpace
//

#import "TaskListViewController.h"
#import "TaskFilterViewController.h"
#import "TaskCell.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Project.h"
#import "Tag.h"

@interface TaskListViewController () <UISearchResultsUpdating, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
@property (nonatomic, strong) WSChipBar *chipBar;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@property (nonatomic) TaskFilter filter;
@property (nonatomic) TaskSort sort;
@property (nonatomic, strong, nullable) Project *project;
@property (nonatomic, strong, nullable) Tag *tag;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, copy) NSArray<Task *> *tasks;
@end

/// Quick chips cover the common filters; By Project / By Tag live in the filter sheet.
static NSArray<NSNumber *> *WSChipFilters(void) {
    return @[@(TaskFilterAll), @(TaskFilterToday), @(TaskFilterUpcoming), @(TaskFilterOverdue), @(TaskFilterHighPriority), @(TaskFilterCompleted)];
}

@implementation TaskListViewController

- (instancetype)init {
    return [self initWithFilter:TaskFilterAll];
}

- (instancetype)initWithFilter:(TaskFilter)filter {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _filter = filter;
        _sort = TaskSortDueDate;
        _searchText = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    if (!self.title) self.title = WSText(@"Tasks");
    self.view.backgroundColor = t.background;

    self.chipBar = WSChipBar.new;
    self.chipBar.accessoryTitle = WSText(@"More");
    self.chipBar.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    self.chipBar.onSelect = ^(NSInteger index) {
        weakSelf.project = nil;
        weakSelf.tag = nil;
        weakSelf.filter = (TaskFilter)WSChipFilters()[index].integerValue;
        [weakSelf reload];
    };
    self.chipBar.onAccessory = ^{ [weakSelf showFilterSheet]; };
    [self.view addSubview:self.chipBar];

    UICollectionViewCompositionalLayout *layout = WSListLayout(^UISwipeActionsConfiguration *(NSIndexPath *ip) {
        return [weakSelf trailingActionsAt:ip];
    }, ^UISwipeActionsConfiguration *(NSIndexPath *ip) {
        return [weakSelf leadingActionsAt:ip];
    }, NO);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = t.background;
    self.collectionView.delegate = self;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.chipBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.chipBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chipBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.chipBar.bottomAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UICollectionViewCellRegistration *reg = [UICollectionViewCellRegistration registrationWithCellClass:TaskCell.class
                                                                                   configurationHandler:^(TaskCell *cell, NSIndexPath *ip, NSManagedObjectID *oid) {
        Task *task = [weakSelf taskFor:oid];
        if (!task) return;
        [cell configureWithTask:task showProject:weakSelf.project == nil];
        __weak Task *weakTask = task;
        cell.onToggleComplete = ^{ [weakSelf toggle:weakTask]; };
        // Manual order: drag handle reorders.
        cell.accessories = weakSelf.sort == TaskSortManual && weakSelf.searchText.length == 0 ? @[[[UICellAccessoryReorder alloc] init]] : @[];
    }];
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *ip, NSManagedObjectID *oid) {
        return [cv dequeueConfiguredReusableCellWithRegistration:reg forIndexPath:ip item:oid];
    }];
    self.dataSource.reorderingHandlers.canReorderItemHandler = ^BOOL(id item) {
        return weakSelf.sort == TaskSortManual && weakSelf.searchText.length == 0;
    };
    self.dataSource.reorderingHandlers.didReorderHandler = ^(NSDiffableDataSourceTransaction *transaction) {
        [weakSelf persistOrder:transaction.finalSnapshot.itemIdentifiers];
    };

    self.emptyView = [WSEmptyStateView viewWithSymbol:@"checkmark.circle" title:WSText(@"No Tasks")
                                              message:WSText(@"Plan your work with due dates, priorities and checklists.")
                                          actionTitle:WSText(@"New Task") action:^{ [weakSelf addTask]; }];
    self.collectionView.backgroundView = self.emptyView;

    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.searchResultsUpdater = self;
    search.obscuresBackgroundDuringPresentation = NO;
    search.searchBar.placeholder = WSText(@"Search tasks");
    self.navigationItem.searchController = search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
    [self refreshNavigation];

    [DataManager.shared observeChanges:self selector:@selector(dataChanged:)];
    [self syncChips];
    [self reload];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)applyFilter:(TaskFilter)filter {
    self.filter = filter;
    self.project = nil;
    self.tag = nil;
    if (self.isViewLoaded) { [self syncChips]; [self reload]; }
}

- (void)syncChips {
    NSMutableArray *titles = NSMutableArray.new;
    for (NSNumber *f in WSChipFilters()) [titles addObject:TaskFilterTitle(f.integerValue)];
    NSUInteger idx = [WSChipFilters() indexOfObject:@(self.filter)];
    [self.chipBar setTitles:titles selectedIndex:idx == NSNotFound ? -1 : (NSInteger)idx];
}

- (void)refreshNavigation {
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTask)];
    NSMutableArray *sorts = NSMutableArray.new;
    for (TaskSort s = TaskSortDueDate; s <= TaskSortManual; s++) {
        UIAction *a = [UIAction actionWithTitle:TaskSortTitle(s) image:nil identifier:nil handler:^(UIAction *x) {
            self.sort = s;
            [self refreshNavigation];
            [self reload];
        }];
        a.state = s == self.sort ? UIMenuElementStateOn : UIMenuElementStateOff;
        [sorts addObject:a];
    }
    UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"arrow.up.arrow.down"] menu:[UIMenu menuWithTitle:WSText(@"Sort By") children:sorts]];
    sort.accessibilityLabel = WSText(@"Sort");
    self.navigationItem.rightBarButtonItems = @[add, sort];
}

#pragma mark - Data

- (Task *)taskFor:(NSManagedObjectID *)oid {
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:oid error:nil];
    return [o isKindOfClass:Task.class] && !o.isDeleted ? (Task *)o : nil;
}

- (void)dataChanged:(NSNotification *)note {
    NSSet *kinds = note.userInfo[WSChangedKindsKey];
    if (kinds && ![kinds containsObject:@(WSObjectKindTask)] && ![kinds containsObject:@(WSObjectKindProject)] && ![kinds containsObject:@(WSObjectKindTag)]) return;
    [self reload];
}

- (void)reload {
    NSArray<Task *> *tasks = [TaskManager.shared tasksWithFilter:self.filter sort:self.sort project:self.project tag:self.tag includeSubtasks:NO];
    NSString *q = [self.searchText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (q.length) {
        tasks = [tasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@ OR detail CONTAINS[cd] %@ OR notes CONTAINS[cd] %@ OR ANY tags.name CONTAINS[cd] %@", q, q, q, q]];
    }
    self.tasks = tasks;
    NSDiffableDataSourceSnapshot *snap = [[NSDiffableDataSourceSnapshot alloc] init];
    [snap appendSectionsWithIdentifiers:@[@"tasks"]];
    NSArray *ids = [tasks valueForKey:@"objectID"];
    [snap appendItemsWithIdentifiers:ids];
    [snap reconfigureItemsWithIdentifiers:ids];
    [self.dataSource applySnapshot:snap animatingDifferences:self.view.window != nil];

    BOOL filtered = q.length || self.filter != TaskFilterAll;
    self.emptyView.hidden = tasks.count > 0;
    self.emptyView.title = filtered ? WSText(@"No Matching Tasks") : WSText(@"No Tasks");
    self.emptyView.message = filtered ? WSText(@"Nothing matches this filter.") : WSText(@"Plan your work with due dates, priorities and checklists.");
    NSString *suffix = self.project ? self.project.name : (self.tag ? [@"#" stringByAppendingString:self.tag.name] : nil);
    self.navigationItem.prompt = nil;
    self.title = suffix ? [NSString stringWithFormat:@"%@ · %@", WSText(@"Tasks"), suffix] : WSText(@"Tasks");
}

- (void)updateSearchResultsForSearchController:(UISearchController *)sc {
    NSString *text = sc.searchBar.text ?: @"";
    if ([text isEqualToString:self.searchText]) return;
    self.searchText = text;
    [self reload];
}

- (void)persistOrder:(NSArray<NSManagedObjectID *> *)ids {
    NSMutableArray *ordered = NSMutableArray.new;
    for (NSManagedObjectID *oid in ids) { Task *t = [self taskFor:oid]; if (t) [ordered addObject:t]; }
    [ordered enumerateObjectsUsingBlock:^(Task *t, NSUInteger idx, BOOL *stop) { t.sortIndex = idx; }];
    NSError *error = nil;
    if (![DataManager.shared save:&error]) [self ws_showError:error];
}

#pragma mark - Actions

- (void)addTask {
    [AppRouter.shared presentNewTaskFrom:self project:self.project parent:nil];
}

- (void)showFilterSheet {
    TaskFilterViewController *vc = [[TaskFilterViewController alloc] initWithFilter:self.filter sort:self.sort project:self.project tag:self.tag];
    __weak typeof(self) weakSelf = self;
    vc.onApply = ^(TaskFilter filter, TaskSort sort, Project *project, Tag *tag) {
        weakSelf.filter = filter;
        weakSelf.sort = sort;
        weakSelf.project = project;
        weakSelf.tag = tag;
        [weakSelf syncChips];
        [weakSelf refreshNavigation];
        [weakSelf reload];
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.sheetPresentationController.detents = @[UISheetPresentationControllerDetent.mediumDetent, UISheetPresentationControllerDetent.largeDetent];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)toggle:(Task *)task {
    if (!task) return;
    NSError *error = nil;
    if (![TaskManager.shared toggleCompleted:task error:&error]) [self ws_showError:error];
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    [cv deselectItemAtIndexPath:ip animated:YES];
    [AppRouter.shared open:[self taskFor:[self.dataSource itemIdentifierForIndexPath:ip]] from:self];
}

- (UISwipeActionsConfiguration *)leadingActionsAt:(NSIndexPath *)ip {
    Task *task = [self taskFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!task) return nil;
    BOOL done = task.status == TaskStatusCompleted;
    UIContextualAction *complete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                           title:done ? WSText(@"Reopen") : WSText(@"Complete")
                                                                         handler:^(UIContextualAction *a, UIView *v, void (^finish)(BOOL)) {
        [self toggle:task];
        finish(YES);
    }];
    complete.image = [UIImage ws_symbol:done ? @"arrow.uturn.backward" : @"checkmark"];
    complete.backgroundColor = AppThemeManager.shared.success;
    return [UISwipeActionsConfiguration configurationWithActions:@[complete]];
}

- (UISwipeActionsConfiguration *)trailingActionsAt:(NSIndexPath *)ip {
    Task *task = [self taskFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!task) return nil;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^finish)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [TaskManager.shared deleteTask:task error:&error];
        if (!ok) [self ws_showError:error];
        finish(ok);
    }];
    del.image = [UIImage ws_symbol:@"trash"];
    UIContextualAction *fav = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                      title:task.isFavorite ? WSText(@"Unfavorite") : WSText(@"Favorite")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^finish)(BOOL)) {
        task.isFavorite = !task.isFavorite;
        NSError *error = nil;
        BOOL ok = [DataManager.shared save:&error];
        if (!ok) [self ws_showError:error];
        finish(ok);
    }];
    fav.image = [UIImage ws_symbol:@"star"];
    fav.backgroundColor = AppThemeManager.shared.warning;
    return [UISwipeActionsConfiguration configurationWithActions:@[del, fav]];
}

@end
