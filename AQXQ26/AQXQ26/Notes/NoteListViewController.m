//
//  NoteListViewController.m
//  WorkSpace
//

#import "NoteListViewController.h"
#import "NoteManager.h"
#import "DataManager.h"
#import "NoteCategoryManager.h"
#import "NoteEditViewController.h"
#import "NoteCell.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Note.h"
#import "NoteCategory.h"

typedef NS_ENUM(NSInteger, NoteScope) {
    NoteScopeAll = 0,
    NoteScopeFavorites,
    NoteScopeCategory,
    NoteScopeUncategorized,
};

@interface NoteListViewController () <UISearchResultsUpdating, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSString *, NSManagedObjectID *> *dataSource;
@property (nonatomic, strong) WSChipBar *chipBar;
@property (nonatomic, copy) NSArray<NoteCategory *> *categories;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) NoteScope scope;
@property (nonatomic, strong, nullable) NSManagedObjectID *categoryID;
@property (nonatomic) NoteSort sort;
@property (nonatomic, copy) NSString *searchText;
@end

@implementation NoteListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.title = WSText(@"Notes");
    self.view.backgroundColor = t.background;
    self.searchText = @"";

    [self buildChipBar];
    [self buildCollection];
    [self buildNavigation];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(dataChanged:) name:WSDataDidChangeNotification object:nil];
    [self rebuildChips];
    [self reload];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Layout

- (void)buildChipBar {
    self.chipBar = WSChipBar.new;
    self.chipBar.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    self.chipBar.onSelect = ^(NSInteger index) { [weakSelf selectChip:index]; };
    [self.view addSubview:self.chipBar];
    [NSLayoutConstraint activateConstraints:@[
        [self.chipBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.chipBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.chipBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
}

- (void)buildCollection {
    __weak typeof(self) weakSelf = self;
    UICollectionViewCompositionalLayout *layout = WSListLayout(^UISwipeActionsConfiguration *(NSIndexPath *indexPath) {
        return [weakSelf trailingActionsAt:indexPath];
    }, ^UISwipeActionsConfiguration *(NSIndexPath *indexPath) {
        return [weakSelf leadingActionsAt:indexPath];
    }, NO);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.backgroundColor = AppThemeManager.shared.background;
    self.collectionView.delegate = self;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.chipBar.bottomAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UICollectionViewCellRegistration *reg = [UICollectionViewCellRegistration registrationWithCellClass:NoteCell.class
                                                                                   configurationHandler:^(NoteCell *cell, NSIndexPath *indexPath, NSManagedObjectID *objectID) {
        Note *note = [weakSelf noteFor:objectID];
        if (note) [cell configureWithNote:note];
    }];
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *indexPath, NSManagedObjectID *objectID) {
        return [cv dequeueConfiguredReusableCellWithRegistration:reg forIndexPath:indexPath item:objectID];
    }];

    self.emptyView = [WSEmptyStateView viewWithSymbol:@"note.text" title:WSText(@"No Notes")
                                              message:WSText(@"Capture ideas, meeting notes and references. They stay on this iPhone.")
                                          actionTitle:WSText(@"New Note") action:^{ [weakSelf newNote]; }];
    self.collectionView.backgroundView = self.emptyView;
}

- (void)buildNavigation {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.obscuresBackgroundDuringPresentation = NO;
    self.searchController.searchBar.placeholder = WSText(@"Search notes and tags");
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.definesPresentationContext = YES;

    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"square.and.pencil"] style:UIBarButtonItemStylePlain
                                                           target:self action:@selector(newNote)];
    add.accessibilityLabel = WSText(@"New Note");
    UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"arrow.up.arrow.down"] menu:[self sortMenu]];
    sort.accessibilityLabel = WSText(@"Sort");
    self.navigationItem.rightBarButtonItems = @[add, sort];
}

- (UIMenu *)sortMenu {
    NSMutableArray *actions = NSMutableArray.new;
    for (NoteSort s = NoteSortUpdated; s <= NoteSortAlphabetical; s++) {
        UIAction *a = [UIAction actionWithTitle:NoteSortTitle(s) image:nil identifier:nil handler:^(UIAction *action) {
            self.sort = s;
            self.navigationItem.rightBarButtonItems.lastObject.menu = [self sortMenu];
            [self reload];
        }];
        a.state = self.sort == s ? UIMenuElementStateOn : UIMenuElementStateOff;
        [actions addObject:a];
    }
    return [UIMenu menuWithTitle:WSText(@"Sort By") children:actions];
}


#pragma mark - Chips

/// Chips: All · Favorites · <categories> · Uncategorized
- (void)rebuildChips {
    self.categories = [NoteCategoryManager.shared allCategories];
    NSMutableArray *titles = [NSMutableArray arrayWithObjects:WSText(@"All"), WSText(@"Favorites"), nil];
    for (NoteCategory *c in self.categories) [titles addObject:c.name ?: @""];
    [titles addObject:WSText(@"Uncategorized")];

    // Keep the selected category if it still exists.
    NSInteger selected = 0;
    if (self.scope == NoteScopeFavorites) selected = 1;
    else if (self.scope == NoteScopeUncategorized) selected = (NSInteger)titles.count - 1;
    else if (self.scope == NoteScopeCategory) {
        NSUInteger idx = [[self.categories valueForKey:@"objectID"] indexOfObject:self.categoryID];
        if (idx == NSNotFound) { self.scope = NoteScopeAll; self.categoryID = nil; }
        else selected = 2 + (NSInteger)idx;
    }
    [self.chipBar setTitles:titles selectedIndex:selected];
}

- (void)selectChip:(NSInteger)index {
    NSInteger lastIndex = 2 + (NSInteger)self.categories.count;
    self.categoryID = nil;
    if (index == 0) self.scope = NoteScopeAll;
    else if (index == 1) self.scope = NoteScopeFavorites;
    else if (index == lastIndex) self.scope = NoteScopeUncategorized;
    else {
        self.scope = NoteScopeCategory;
        self.categoryID = self.categories[index - 2].objectID;
    }
    [self reload];
}

- (NoteCategory *)selectedCategory {
    if (self.scope != NoteScopeCategory || !self.categoryID) return nil;
    return (NoteCategory *)[DataManager.shared.context existingObjectWithID:self.categoryID error:nil];
}

#pragma mark - Data

- (Note *)noteFor:(NSManagedObjectID *)objectID {
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:objectID error:nil];
    return [o isKindOfClass:Note.class] && !o.isDeleted ? (Note *)o : nil;
}

- (void)dataChanged:(NSNotification *)note {
    NSSet *kinds = note.userInfo[WSChangedKindsKey];
    if (kinds && ![kinds containsObject:@(WSObjectKindNote)] && ![kinds containsObject:@(WSObjectKindNoteCategory)] && ![kinds containsObject:@(WSObjectKindTag)]) return;
    [self rebuildChips];
    [self reload];
}

- (void)reload {
    NoteQuery *query = NoteQuery.new;
    query.text = self.searchText;
    query.sort = self.sort;
    query.favoritesOnly = self.scope == NoteScopeFavorites;
    query.uncategorizedOnly = self.scope == NoteScopeUncategorized;
    query.category = [self selectedCategory];
    NSArray<Note *> *notes = [NoteManager.shared notesMatching:query];

    NSDiffableDataSourceSnapshot *snapshot = [[NSDiffableDataSourceSnapshot alloc] init];
    [snapshot appendSectionsWithIdentifiers:@[@"notes"]];
    [snapshot appendItemsWithIdentifiers:[notes valueForKey:@"objectID"]];
    [snapshot reloadItemsWithIdentifiers:[notes valueForKey:@"objectID"]];
    [self.dataSource applySnapshot:snapshot animatingDifferences:self.view.window != nil];

    BOOL filtering = self.searchText.length || self.scope != NoteScopeAll;
    self.emptyView.hidden = notes.count > 0;
    self.emptyView.title = filtering ? WSText(@"No Matching Notes") : WSText(@"No Notes");
    self.emptyView.message = filtering ? WSText(@"Try another search or category.")
                                       : WSText(@"Capture ideas, meeting notes and references. They stay on this iPhone.");
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *text = searchController.searchBar.text ?: @"";
    if ([text isEqualToString:self.searchText]) return;
    self.searchText = text;
    [self reload];
}

#pragma mark - Actions

- (void)newNote {
    NoteEditViewController *editor = [[NoteEditViewController alloc] initWithNote:nil category:[self selectedCategory] project:nil];
    [self.navigationController pushViewController:editor animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    NSManagedObjectID *objectID = [self.dataSource itemIdentifierForIndexPath:indexPath];
    [AppRouter.shared open:[self noteFor:objectID] from:self];
}

- (UISwipeActionsConfiguration *)leadingActionsAt:(NSIndexPath *)indexPath {
    Note *note = [self noteFor:[self.dataSource itemIdentifierForIndexPath:indexPath]];
    if (!note) return nil;
    AppThemeManager *t = AppThemeManager.shared;
    UIContextualAction *pin = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                      title:note.isPinned ? WSText(@"Unpin") : WSText(@"Pin")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [NoteManager.shared togglePinned:note error:&error];
        if (!ok) [self ws_showError:error];
        done(ok);
    }];
    pin.image = [UIImage ws_symbol:note.isPinned ? @"pin.slash" : @"pin"];
    pin.backgroundColor = t.accent;
    UIContextualAction *fav = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                      title:note.isFavorite ? WSText(@"Unfavorite") : WSText(@"Favorite")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [NoteManager.shared toggleFavorite:note error:&error];
        if (!ok) [self ws_showError:error];
        done(ok);
    }];
    fav.image = [UIImage ws_symbol:note.isFavorite ? @"star.slash" : @"star"];
    fav.backgroundColor = t.warning;
    return [UISwipeActionsConfiguration configurationWithActions:@[pin, fav]];
}

- (UISwipeActionsConfiguration *)trailingActionsAt:(NSIndexPath *)indexPath {
    Note *note = [self noteFor:[self.dataSource itemIdentifierForIndexPath:indexPath]];
    if (!note) return nil;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [self ws_confirm:WSText(@"Delete Note?") message:note.title destructive:WSText(@"Delete") handler:^{
            NSError *error = nil;
            if (![NoteManager.shared deleteNote:note error:&error]) [self ws_showError:error];
        }];
        done(YES);
    }];
    del.image = [UIImage ws_symbol:@"trash"];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

@end
