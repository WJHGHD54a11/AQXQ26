//
//  ProjectListViewController.m
//  WorkSpace
//

#import "ProjectListViewController.h"
#import "ProjectEditViewController.h"
#import "ProjectCell.h"
#import "FavoriteManager.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Project.h"

@interface ProjectListViewController () <UICollectionViewDelegate>
@property (nonatomic) ProjectListScope scope;
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@end

@implementation ProjectListViewController

- (instancetype)initWithScope:(ProjectListScope)scope {
    if ((self = [super initWithNibName:nil bundle:nil])) _scope = scope;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.title = WSText(@"Projects");
    self.view.backgroundColor = t.background;

    self.segment = [[UISegmentedControl alloc] initWithItems:@[WSText(@"Current"), WSText(@"Completed"), WSText(@"Archived")]];
    self.segment.selectedSegmentIndex = MIN(self.scope, 2);
    [self.segment addTarget:self action:@selector(scopeChanged) forControlEvents:UIControlEventValueChanged];
    self.segment.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.segment];

    __weak typeof(self) weakSelf = self;
    UICollectionViewCompositionalLayout *layout = WSListLayout(^UISwipeActionsConfiguration *(NSIndexPath *ip) {
        return [weakSelf trailingActionsAt:ip];
    }, nil, NO);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = t.background;
    self.collectionView.delegate = self;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.segment.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.segment.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [self.segment.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.segment.bottomAnchor constant:4],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UICollectionViewCellRegistration *reg = [UICollectionViewCellRegistration registrationWithCellClass:ProjectCell.class
                                                                                   configurationHandler:^(ProjectCell *cell, NSIndexPath *ip, NSManagedObjectID *oid) {
        Project *p = [weakSelf projectFor:oid];
        if (p) [cell configureWithProject:p];
    }];
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *ip, NSManagedObjectID *oid) {
        return [cv dequeueConfiguredReusableCellWithRegistration:reg forIndexPath:ip item:oid];
    }];
    self.emptyView = [WSEmptyStateView viewWithSymbol:@"folder" title:WSText(@"No Projects")
                                              message:WSText(@"Group related tasks, notes and files. Progress updates as tasks are completed.")
                                          actionTitle:WSText(@"New Project") action:^{ [weakSelf addProject]; }];
    self.collectionView.backgroundView = self.emptyView;

    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addProject)];
    add.accessibilityLabel = WSText(@"New Project");
    self.navigationItem.rightBarButtonItem = add;

    [DataManager.shared observeChanges:self selector:@selector(dataChanged:)];
    [self reload];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (Project *)projectFor:(NSManagedObjectID *)oid {
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:oid error:nil];
    return [o isKindOfClass:Project.class] && !o.isDeleted ? (Project *)o : nil;
}

- (void)scopeChanged {
    self.scope = (ProjectListScope)self.segment.selectedSegmentIndex;
    [self reload];
}

- (void)dataChanged:(NSNotification *)note {
    NSSet *kinds = note.userInfo[WSChangedKindsKey];
    if (kinds && ![kinds containsObject:@(WSObjectKindProject)] && ![kinds containsObject:@(WSObjectKindTask)]) return;
    [self reload];
}

- (void)reload {
    NSArray<Project *> *projects = [ProjectManager.shared projectsInScope:self.scope];
    NSDiffableDataSourceSnapshot *snap = [[NSDiffableDataSourceSnapshot alloc] init];
    [snap appendSectionsWithIdentifiers:@[@"projects"]];
    NSArray *ids = [projects valueForKey:@"objectID"];
    [snap appendItemsWithIdentifiers:ids];
    [snap reloadItemsWithIdentifiers:ids];   // progress depends on tasks, not on the project row
    [self.dataSource applySnapshot:snap animatingDifferences:self.view.window != nil];

    self.emptyView.hidden = projects.count > 0;
    NSArray *titles = @[WSText(@"No Projects"), WSText(@"No Completed Projects"), WSText(@"No Archived Projects")];
    self.emptyView.title = titles[MIN(self.scope, 2)];
}

- (void)addProject {
    ProjectEditViewController *editor = [[ProjectEditViewController alloc] initWithProject:nil];
    __weak typeof(self) weakSelf = self;
    __weak ProjectEditViewController *weakEditor = editor;
    editor.onSaved = ^{
        if (weakEditor.savedProject) [AppRouter.shared open:weakEditor.savedProject from:weakSelf];
    };
    [self presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    [cv deselectItemAtIndexPath:ip animated:YES];
    [AppRouter.shared open:[self projectFor:[self.dataSource itemIdentifierForIndexPath:ip]] from:self];
}

- (UISwipeActionsConfiguration *)trailingActionsAt:(NSIndexPath *)ip {
    Project *p = [self projectFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!p) return nil;
    AppThemeManager *t = AppThemeManager.shared;
    __weak typeof(self) weakSelf = self;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [weakSelf confirmDelete:p];
        done(YES);
    }];
    del.image = [UIImage ws_symbol:@"trash"];
    BOOL archived = p.status == ProjectStatusArchived;
    UIContextualAction *arch = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                       title:archived ? WSText(@"Restore") : WSText(@"Archive")
                                                                     handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        BOOL ok = archived ? [ProjectManager.shared restore:p error:&error] : [ProjectManager.shared archive:p error:&error];
        if (!ok) [weakSelf ws_showError:error];
        done(ok);
    }];
    arch.image = [UIImage ws_symbol:archived ? @"tray.and.arrow.up" : @"archivebox"];
    arch.backgroundColor = [t colorForIdentifier:@"slate"];
    return [UISwipeActionsConfiguration configurationWithActions:@[del, arch]];
}

/// Tasks are moved to "No Project" unless the user also wants them gone.
- (void)confirmDelete:(Project *)p {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:WSText(@"Delete “%@”?"), p.name]
                                                                   message:p.tasks.count ? WSText(@"Choose what happens to its tasks.") : nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    void (^run)(BOOL) = ^(BOOL withTasks) {
        NSError *error = nil;
        if (![ProjectManager.shared deleteProject:p deleteTasks:withTasks error:&error]) [self ws_showError:error];
    };
    [sheet addAction:[UIAlertAction actionWithTitle:p.tasks.count ? WSText(@"Delete Project, Keep Tasks") : WSText(@"Delete Project")
                                              style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { run(NO); }]];
    if (p.tasks.count) {
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Delete Project and Tasks") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { run(YES); }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
