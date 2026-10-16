//
//  ScheduleListViewController.m
//  WorkSpace
//
//  Today / Upcoming / Past. Upcoming and Past are grouped by day.
//

#import "ScheduleListViewController.h"
#import "ScheduleEditViewController.h"
#import "ScheduleManager.h"
#import "ScheduleCell.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Schedule.h"

@interface ScheduleListViewController () <UICollectionViewDelegate>
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSDate *, NSManagedObjectID *> *dataSource;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@property (nonatomic, strong, nullable) NSNumber *kind;
@end

@implementation ScheduleListViewController

- (ScheduleScope)scope {
    switch (self.segment.selectedSegmentIndex) {
        case 1:  return ScheduleScopeUpcoming;
        case 2:  return ScheduleScopePast;
        default: return ScheduleScopeToday;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.title = WSText(@"Schedule");
    self.view.backgroundColor = t.background;

    self.segment = [[UISegmentedControl alloc] initWithItems:@[WSText(@"Today"), WSText(@"Upcoming"), WSText(@"Past")]];
    self.segment.selectedSegmentIndex = 0;
    [self.segment addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    self.segment.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.segment];

    __weak typeof(self) weakSelf = self;
    UICollectionViewCompositionalLayout *layout = WSListLayout(^UISwipeActionsConfiguration *(NSIndexPath *ip) {
        return [weakSelf trailingActionsAt:ip];
    }, ^UISwipeActionsConfiguration *(NSIndexPath *ip) {
        return [weakSelf leadingActionsAt:ip];
    }, YES);
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

    UICollectionViewCellRegistration *reg = [UICollectionViewCellRegistration registrationWithCellClass:ScheduleCell.class
                                                                                   configurationHandler:^(ScheduleCell *cell, NSIndexPath *ip, NSManagedObjectID *oid) {
        Schedule *s = [weakSelf scheduleFor:oid];
        if (s) [cell configureWithSchedule:s showDate:NO];
    }];
    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *ip, NSManagedObjectID *oid) {
        return [cv dequeueConfiguredReusableCellWithRegistration:reg forIndexPath:ip item:oid];
    }];
    UICollectionViewSupplementaryRegistration *headerReg = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:UICollectionViewListCell.class
                                                                                                                             elementKind:UICollectionElementKindSectionHeader
                                                                                                                    configurationHandler:^(UICollectionViewListCell *header, NSString *kind, NSIndexPath *ip) {
        NSDate *day = [weakSelf.dataSource sectionIdentifierForIndex:ip.section];
        UIListContentConfiguration *c = [UIListContentConfiguration groupedHeaderConfiguration];
        c.text = day ? [Task relativeDayText:day includeTime:NO] : @"";
        header.contentConfiguration = c;
    }];
    self.dataSource.supplementaryViewProvider = ^UICollectionReusableView *(UICollectionView *cv, NSString *kind, NSIndexPath *ip) {
        return [cv dequeueConfiguredReusableSupplementaryViewWithRegistration:headerReg forIndexPath:ip];
    };

    self.emptyView = [WSEmptyStateView viewWithSymbol:@"calendar" title:WSText(@"No Schedule")
                                              message:WSText(@"Add appointments, meetings and events with reminders.")
                                          actionTitle:WSText(@"New Schedule") action:^{ [weakSelf addSchedule]; }];
    self.collectionView.backgroundView = self.emptyView;
    [self refreshNavigation];

    [DataManager.shared observeChanges:self selector:@selector(dataChanged:)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [self reload];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)refreshNavigation {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *kinds = NSMutableArray.new;
    UIAction *all = [UIAction actionWithTitle:WSText(@"All Types") image:nil identifier:nil handler:^(UIAction *a) {
        weakSelf.kind = nil; [weakSelf refreshNavigation]; [weakSelf reload];
    }];
    all.state = self.kind ? UIMenuElementStateOff : UIMenuElementStateOn;
    [kinds addObject:all];
    for (ScheduleKind k = ScheduleKindAppointment; k <= ScheduleKindReminder; k++) {
        UIAction *a = [UIAction actionWithTitle:ScheduleKindTitle(k) image:[UIImage ws_symbol:ScheduleKindSymbol(k)] identifier:nil handler:^(UIAction *x) {
            weakSelf.kind = @(k); [weakSelf refreshNavigation]; [weakSelf reload];
        }];
        a.state = self.kind.integerValue == k && self.kind ? UIMenuElementStateOn : UIMenuElementStateOff;
        [kinds addObject:a];
    }
    UIBarButtonItem *filter = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:self.kind ? @"line.3.horizontal.decrease.circle.fill" : @"line.3.horizontal.decrease.circle"]
                                                                menu:[UIMenu menuWithTitle:WSText(@"Type") children:kinds]];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSchedule)];
    add.accessibilityLabel = WSText(@"New Schedule");
    self.navigationItem.rightBarButtonItems = @[add, filter];
}

- (Schedule *)scheduleFor:(NSManagedObjectID *)oid {
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:oid error:nil];
    return [o isKindOfClass:Schedule.class] && !o.isDeleted ? (Schedule *)o : nil;
}

- (void)dataChanged:(NSNotification *)note {
    NSSet *kinds = note.userInfo[WSChangedKindsKey];
    if (kinds && ![kinds containsObject:@(WSObjectKindSchedule)]) return;
    [self reload];
}

- (void)reload {
    NSArray<Schedule *> *items = [ScheduleManager.shared schedulesIn:self.scope day:nil kind:self.kind];
    NSDiffableDataSourceSnapshot *snap = [[NSDiffableDataSourceSnapshot alloc] init];
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *currentDay = nil;
    for (Schedule *s in items) {
        NSDate *day = [cal startOfDayForDate:s.startTime ?: s.date];
        if (![day isEqualToDate:currentDay]) {
            currentDay = day;
            [snap appendSectionsWithIdentifiers:@[day]];
        }
        [snap appendItemsWithIdentifiers:@[s.objectID] intoSectionWithIdentifier:day];
    }
    [snap reloadItemsWithIdentifiers:snap.itemIdentifiers];
    [self.dataSource applySnapshot:snap animatingDifferences:self.view.window != nil];
    self.emptyView.hidden = items.count > 0;
    NSArray *titles = @[WSText(@"Nothing Scheduled Today"), WSText(@"Nothing Upcoming"), WSText(@"No Past Items")];
    self.emptyView.title = self.kind ? WSText(@"No Schedule") : titles[self.segment.selectedSegmentIndex];
}

- (void)addSchedule {
    ScheduleEditViewController *editor = [[ScheduleEditViewController alloc] initWithSchedule:nil day:nil];
    [self presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    [AppRouter.shared open:[self scheduleFor:[self.dataSource itemIdentifierForIndexPath:indexPath]] from:self];
}

- (UISwipeActionsConfiguration *)leadingActionsAt:(NSIndexPath *)ip {
    Schedule *s = [self scheduleFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!s) return nil;
    BOOL planned = s.status == ScheduleStatusPlanned;
    UIContextualAction *a = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                    title:planned ? WSText(@"Complete") : WSText(@"Reopen")
                                                                  handler:^(UIContextualAction *x, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        BOOL ok = planned ? [ScheduleManager.shared complete:s error:&error] : [ScheduleManager.shared reopen:s error:&error];
        if (!ok) [self ws_showError:error];
        done(ok);
    }];
    a.image = [UIImage ws_symbol:planned ? @"checkmark" : @"arrow.uturn.backward"];
    a.backgroundColor = planned ? AppThemeManager.shared.success : AppThemeManager.shared.accent;
    return [UISwipeActionsConfiguration configurationWithActions:@[a]];
}

- (UISwipeActionsConfiguration *)trailingActionsAt:(NSIndexPath *)ip {
    Schedule *s = [self scheduleFor:[self.dataSource itemIdentifierForIndexPath:ip]];
    if (!s) return nil;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *x, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [ScheduleManager.shared deleteSchedule:s error:&error];
        if (!ok) [self ws_showError:error];
        done(ok);
    }];
    del.image = [UIImage ws_symbol:@"trash"];
    NSMutableArray *actions = [NSMutableArray arrayWithObject:del];
    if (s.status == ScheduleStatusPlanned) {
        UIContextualAction *cancel = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Cancel Event")
                                                                           handler:^(UIContextualAction *x, UIView *v, void (^done)(BOOL)) {
            NSError *error = nil;
            BOOL ok = [ScheduleManager.shared cancel:s error:&error];
            if (!ok) [self ws_showError:error];
            done(ok);
        }];
        cancel.backgroundColor = AppThemeManager.shared.warning;
        [actions addObject:cancel];
    }
    return [UISwipeActionsConfiguration configurationWithActions:actions];
}

@end
