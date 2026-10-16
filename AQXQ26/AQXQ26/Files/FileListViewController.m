//
//  FileListViewController.m
//  WorkSpace
//

#import "FileListViewController.h"
#import "FileManagerService.h"
#import "FileImportManager.h"
#import "FileActions.h"
#import "FileCell.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "FileItem.h"

@interface FileListViewController () <UISearchResultsUpdating, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
@property (nonatomic, strong) WSChipBar *chipBar;
@property (nonatomic, strong) UILabel *storageLabel;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@property (nonatomic) FileCategory category;
@property (nonatomic) FileSort sort;
@property (nonatomic) BOOL favoritesOnly;
@property (nonatomic, copy, nullable) NSString *folder;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, copy) NSArray<FileItem *> *files;
@end

@implementation FileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.title = WSText(@"Files");
    self.view.backgroundColor = t.background;
    self.searchText = @"";

    // Storage summary
    self.storageLabel = UILabel.new;
    self.storageLabel.font = t.fontCaption;
    self.storageLabel.textColor = t.textSecondary;
    self.storageLabel.numberOfLines = 2;

    self.chipBar = WSChipBar.new;
    __weak typeof(self) weakSelf = self;
    self.chipBar.onSelect = ^(NSInteger index) {
        weakSelf.category = (FileCategory)index;
        [weakSelf reload];
    };
    [self.chipBar setTitles:@[FileCategoryTitle(FileCategoryAll), FileCategoryTitle(FileCategoryImages),
                              FileCategoryTitle(FileCategoryDocuments), FileCategoryTitle(FileCategoryOther)] selectedIndex:0];

    UIView *storageWrap = UIView.new;
    self.storageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [storageWrap addSubview:self.storageLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.storageLabel.leadingAnchor constraintEqualToAnchor:storageWrap.leadingAnchor constant:20],
        [self.storageLabel.trailingAnchor constraintEqualToAnchor:storageWrap.trailingAnchor constant:-20],
        [self.storageLabel.topAnchor constraintEqualToAnchor:storageWrap.topAnchor constant:2],
        [self.storageLabel.bottomAnchor constraintEqualToAnchor:storageWrap.bottomAnchor],
    ]];
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[storageWrap, self.chipBar]];
    header.axis = UILayoutConstraintAxisVertical;
    header.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:header];

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
        [header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [header.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [header.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:header.bottomAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UICollectionViewCellRegistration *reg = [UICollectionViewCellRegistration registrationWithCellClass:FileCell.class
                                                                                   configurationHandler:^(FileCell *cell, NSIndexPath *ip, NSManagedObjectID *oid) {
        FileItem *f = [weakSelf fileFor:oid];
        if (f) [cell configureWithFile:f];
    }];
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *ip, NSManagedObjectID *oid) {
        return [cv dequeueConfiguredReusableCellWithRegistration:reg forIndexPath:ip item:oid];
    }];
    self.emptyView = [WSEmptyStateView viewWithSymbol:@"doc" title:WSText(@"No Files")
                                              message:WSText(@"Import PDFs, documents, images and more. Files are stored on this iPhone.")
                                          actionTitle:WSText(@"Import File") action:^{ [weakSelf importTapped]; }];
    self.collectionView.backgroundView = self.emptyView;

    UISearchController *search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.searchResultsUpdater = self;
    search.obscuresBackgroundDuringPresentation = NO;
    search.searchBar.placeholder = WSText(@"Search files");
    self.navigationItem.searchController = search;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;
    [self refreshNavigation];

    [DataManager.shared observeChanges:self selector:@selector(dataChanged:)];
    [self reload];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)refreshNavigation {
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(importTapped)];
    add.accessibilityLabel = WSText(@"Import File");
    UIBarButtonItem *options = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"line.3.horizontal.decrease.circle"] menu:[self optionsMenu]];
    options.accessibilityLabel = WSText(@"Filter and Sort");
    self.navigationItem.rightBarButtonItems = @[add, options];
}

- (UIMenu *)optionsMenu {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *sorts = NSMutableArray.new;
    for (FileSort s = FileSortModified; s <= FileSortType; s++) {
        UIAction *a = [UIAction actionWithTitle:FileSortTitle(s) image:nil identifier:nil handler:^(UIAction *x) {
            weakSelf.sort = s;
            [weakSelf refreshNavigation];
            [weakSelf reload];
        }];
        a.state = self.sort == s ? UIMenuElementStateOn : UIMenuElementStateOff;
        [sorts addObject:a];
    }
    NSMutableArray *folders = NSMutableArray.new;
    UIAction *allFolders = [UIAction actionWithTitle:WSText(@"All Folders") image:nil identifier:nil handler:^(UIAction *x) {
        weakSelf.folder = nil;
        [weakSelf refreshNavigation];
        [weakSelf reload];
    }];
    allFolders.state = self.folder ? UIMenuElementStateOff : UIMenuElementStateOn;
    [folders addObject:allFolders];
    for (NSString *f in [FileManagerService.shared folders]) {
        UIAction *a = [UIAction actionWithTitle:f image:[UIImage ws_symbol:@"folder"] identifier:nil handler:^(UIAction *x) {
            weakSelf.folder = f;
            [weakSelf refreshNavigation];
            [weakSelf reload];
        }];
        a.state = [self.folder isEqualToString:f] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [folders addObject:a];
    }
    UIAction *fav = [UIAction actionWithTitle:WSText(@"Favorites Only") image:[UIImage ws_symbol:@"star"] identifier:nil handler:^(UIAction *x) {
        weakSelf.favoritesOnly = !weakSelf.favoritesOnly;
        [weakSelf refreshNavigation];
        [weakSelf reload];
    }];
    fav.state = self.favoritesOnly ? UIMenuElementStateOn : UIMenuElementStateOff;
    return [UIMenu menuWithChildren:@[
        [UIMenu menuWithTitle:WSText(@"Sort By") image:nil identifier:nil options:UIMenuOptionsDisplayInline children:sorts],
        [UIMenu menuWithTitle:WSText(@"Folder") image:[UIImage ws_symbol:@"folder"] identifier:nil options:0 children:folders],
        fav]];
}

#pragma mark - Data

- (FileItem *)fileFor:(NSManagedObjectID *)oid {
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:oid error:nil];
    return [o isKindOfClass:FileItem.class] && !o.isDeleted ? (FileItem *)o : nil;
}

- (void)dataChanged:(NSNotification *)note {
    NSSet *kinds = note.userInfo[WSChangedKindsKey];
    if (kinds && ![kinds containsObject:@(WSObjectKindFile)]) return;
    [self refreshNavigation];
    [self reload];
}

- (void)reload {
    self.files = [FileManagerService.shared filesIn:self.category folder:self.folder text:self.searchText sort:self.sort favoritesOnly:self.favoritesOnly];
    NSDiffableDataSourceSnapshot *snap = [[NSDiffableDataSourceSnapshot alloc] init];
    [snap appendSectionsWithIdentifiers:@[@"files"]];
    NSArray *ids = [self.files valueForKey:@"objectID"];
    [snap appendItemsWithIdentifiers:ids];
    [snap reloadItemsWithIdentifiers:ids];
    [self.dataSource applySnapshot:snap animatingDifferences:self.view.window != nil];

    FileStorageStats *s = [FileManagerService.shared storageStats];
    self.storageLabel.text = [NSString stringWithFormat:WSText(@"%lu files · %@  —  Images %lu · Documents %lu · Other %lu"),
                              (unsigned long)s.totalFiles, [FileManagerService sizeText:s.totalBytes],
                              (unsigned long)s.imageCount, (unsigned long)s.documentCount, (unsigned long)s.otherCount];

    BOOL filtering = self.searchText.length || self.category != FileCategoryAll || self.folder || self.favoritesOnly;
    self.emptyView.hidden = self.files.count > 0;
    self.emptyView.title = filtering ? WSText(@"No Matching Files") : WSText(@"No Files");
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    if ([text isEqualToString:self.searchText]) return;
    self.searchText = text;
    [self reload];
}

#pragma mark - Actions

- (void)importTapped {
    __weak typeof(self) weakSelf = self;
    [FileImportManager.shared presentPickerFrom:self project:nil task:nil folder:self.folder completion:^(FileImportResult *result) {
        if (result.failedNames.count) {
            [weakSelf ws_showMessage:[NSString stringWithFormat:WSText(@"Imported %lu. Could not import: %@"), (unsigned long)result.imported.count,
                                      [result.failedNames componentsJoinedByString:@", "]] title:WSText(@"Import")];
        } else if (result.imported.count) {
            [weakSelf ws_toast:[NSString stringWithFormat:WSText(@"%lu file(s) imported"), (unsigned long)result.imported.count]];
        }
    }];
}

- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)ip {
    [cv deselectItemAtIndexPath:ip animated:YES];
    [AppRouter.shared open:[self fileFor:[self.dataSource itemIdentifierForIndexPath:ip]] from:self];
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)cv contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)ip point:(CGPoint)point {
    FileItem *file = [self fileFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!file) return nil;
    NSArray *all = self.files;
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu *(NSArray *s) {
        return [FileActions menuFor:file among:all from:self];
    }];
}

- (UISwipeActionsConfiguration *)leadingActionsAt:(NSIndexPath *)ip {
    FileItem *file = [self fileFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!file) return nil;
    UIContextualAction *fav = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                      title:file.isFavorite ? WSText(@"Unfavorite") : WSText(@"Favorite")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [FileActions toggleFavorite:file from:self];
        done(YES);
    }];
    fav.backgroundColor = AppThemeManager.shared.warning;
    fav.image = [UIImage ws_symbol:file.isFavorite ? @"star.slash" : @"star"];
    UIContextualAction *share = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Share")
                                                                      handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [FileActions share:file from:self source:v];
        done(YES);
    }];
    share.backgroundColor = AppThemeManager.shared.accent;
    share.image = [UIImage ws_symbol:@"square.and.arrow.up"];
    return [UISwipeActionsConfiguration configurationWithActions:@[fav, share]];
}

- (UISwipeActionsConfiguration *)trailingActionsAt:(NSIndexPath *)ip {
    FileItem *file = [self fileFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!file) return nil;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [FileActions confirmDelete:file from:self completion:nil];
        done(NO);
    }];
    del.image = [UIImage ws_symbol:@"trash"];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

@end
