//
//  DashboardViewController.m
//  WorkSpace
//
//  Sections are rebuilt from one DashboardSnapshot whenever data changes.
//

#import "DashboardViewController.h"
#import "DashboardManager.h"
#import "DashboardCell.h"
#import "QuickActionCell.h"
#import "TaskListViewController.h"
#import "ProjectListViewController.h"
#import "ScheduleListViewController.h"
#import "BackupManager.h"
#import "ImportManager.h"
#import "ReminderManager.h"
#import "TaskManager.h"
#import "ProjectManager.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Project.h"
#import "Schedule.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "GarageCharts.h"
#import "Vehicle.h"
#import "MaintenancePlan.h"
#import "MainTabBarController.h"
#import "RootViewController.h"

typedef NS_ENUM(NSInteger, DashSection) {
    DashSectionGarage = 0,
    DashSectionToday,
    DashSectionTaskSummary,
    DashSectionProjects,
    DashSectionQuick,
    DashSectionShortcuts,
};

/// Diffable item. `kind` decides the cell; `ref` is an object ID, metric key or action index.
@interface DashItem : NSObject <NSCopying>
@property (nonatomic, copy) NSString *kind;   // task, schedule, todayInfo, metric, project, progress, quick, link
@property (nonatomic, strong) id ref;
@property (nonatomic, copy) NSString *version; // forces reload when content changes
+ (instancetype)kind:(NSString *)kind ref:(id)ref version:(NSString *)version;
@end

@implementation DashItem
+ (instancetype)kind:(NSString *)kind ref:(id)ref version:(NSString *)version {
    DashItem *i = [[self alloc] init];
    i.kind = kind; i.ref = ref; i.version = version ?: @"";
    return i;
}
- (id)copyWithZone:(NSZone *)zone { return self; }
- (BOOL)isEqual:(DashItem *)o {
    return [o isKindOfClass:DashItem.class] && [o.kind isEqualToString:self.kind] && [o.ref isEqual:self.ref] && [o.version isEqualToString:self.version];
}
- (NSUInteger)hash { return self.kind.hash ^ [self.ref hash] ^ self.version.hash; }
@end

@interface DashboardViewController () <UICollectionViewDelegate, UIDocumentPickerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewDiffableDataSource<NSNumber *, DashItem *> *dataSource;
@property (nonatomic, strong) DashboardSnapshot *snapshot;
@end

@implementation DashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.title = WSText(@"Home");
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:[self makeLayout]];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.backgroundColor = AppThemeManager.shared.background;
    self.collectionView.delegate = self;
    [self.view addSubview:self.collectionView];
    [self configureDataSource];

    UIBarButtonItem *data = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"externaldrive"] menu:[self dataMenu]];
    data.accessibilityLabel = WSText(@"Backup");
    self.navigationItem.rightBarButtonItem = data;

    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.prompt = nil;
    self.title = [self greeting];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (NSString *)greeting {
    NSInteger hour = [NSCalendar.currentCalendar component:NSCalendarUnitHour fromDate:NSDate.date];
    if (hour < 5 || hour >= 22) return WSText(@"Good Night");
    if (hour < 12) return WSText(@"Good Morning");
    if (hour < 18) return WSText(@"Good Afternoon");
    return WSText(@"Good Evening");
}

#pragma mark - Layout

- (UICollectionViewCompositionalLayout *)makeLayout {
    __weak typeof(self) weakSelf = self;
    return [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection *(NSInteger index, id<NSCollectionLayoutEnvironment> env) {
        NSNumber *sectionId = [weakSelf.dataSource sectionIdentifierForIndex:index];
        DashSection section = sectionId ? (DashSection)sectionId.integerValue : DashSectionToday;
        NSCollectionLayoutSection *layout;
        if (section == DashSectionTaskSummary) {
            // 3 + 2 tiles; fractional width keeps them even on every iPhone.
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:
                [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0 / 3]
                                               heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1]]];
            item.contentInsets = NSDirectionalEdgeInsetsMake(4, 4, 4, 4);
            NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:
                [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                               heightDimension:[NSCollectionLayoutDimension estimatedDimension:104]] subitems:@[item]];
            layout = [NSCollectionLayoutSection sectionWithGroup:group];
            layout.contentInsets = NSDirectionalEdgeInsetsMake(0, 12, 8, 12);
        } else if (section == DashSectionQuick) {
            NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:
                [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.2]
                                               heightDimension:[NSCollectionLayoutDimension estimatedDimension:88]]];
            NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:
                [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                               heightDimension:[NSCollectionLayoutDimension estimatedDimension:88]] subitems:@[item]];
            layout = [NSCollectionLayoutSection sectionWithGroup:group];
            layout.contentInsets = NSDirectionalEdgeInsetsMake(4, 16, 12, 16);
        } else {
            UICollectionLayoutListConfiguration *list = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
            list.backgroundColor = UIColor.clearColor;
            list.headerMode = UICollectionLayoutListHeaderModeNone;
            if (section == DashSectionToday) {
                list.leadingSwipeActionsConfigurationProvider = ^UISwipeActionsConfiguration *(NSIndexPath *ip) { return [weakSelf leadingActionsAt:ip]; };
            }
            layout = [NSCollectionLayoutSection sectionWithListConfiguration:list layoutEnvironment:env];
        }
        // Section title header
        NSCollectionLayoutBoundarySupplementaryItem *header = [NSCollectionLayoutBoundarySupplementaryItem boundarySupplementaryItemWithLayoutSize:
            [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1]
                                           heightDimension:[NSCollectionLayoutDimension estimatedDimension:36]]
                                                                                                                 elementKind:UICollectionElementKindSectionHeader
                                                                                                                   alignment:NSRectAlignmentTop];
        layout.boundarySupplementaryItems = @[header];
        return layout;
    }];
}

#pragma mark - Data source

- (NSString *)titleForSection:(DashSection)section {
    switch (section) {
        case DashSectionGarage:      return WSText(@"My Car");
        case DashSectionToday:       return WSText(@"Today");
        case DashSectionTaskSummary: return WSText(@"Task Summary");
        case DashSectionProjects:    return WSText(@"Projects");
        case DashSectionQuick:       return WSText(@"Quick Actions");
        case DashSectionShortcuts:   return WSText(@"Browse");
    }
    return @"";
}

- (NSManagedObject *)objectFor:(DashItem *)item {
    if (![item.ref isKindOfClass:NSManagedObjectID.class]) return nil;
    NSManagedObject *o = [DataManager.shared.context existingObjectWithID:item.ref error:nil];
    return o.isDeleted ? nil : o;
}

- (void)configureDataSource {
    __weak typeof(self) weakSelf = self;
    AppThemeManager *t = AppThemeManager.shared;

    UICollectionViewCellRegistration *rowReg = [UICollectionViewCellRegistration registrationWithCellClass:DashboardCell.class
                                                                                      configurationHandler:^(DashboardCell *cell, NSIndexPath *ip, DashItem *item) {
        [weakSelf configureRow:cell item:item];
    }];
    UICollectionViewCellRegistration *metricReg = [UICollectionViewCellRegistration registrationWithCellClass:DashboardMetricCell.class
                                                                                         configurationHandler:^(DashboardMetricCell *cell, NSIndexPath *ip, DashItem *item) {
        DashboardSnapshot *s = weakSelf.snapshot;
        NSDictionary *metrics = @{
            @"total":    @[@(s.totalTasks), WSText(@"Total Tasks"), @"tray.full", t.accent],
            @"todo":     @[@(s.todoTasks), WSText(@"To Do"), @"circle", t.textSecondary],
            @"progress": @[@(s.inProgressTasks), WSText(@"In Progress"), @"circle.lefthalf.filled", [t colorForIdentifier:@"sky"]],
            @"done":     @[@(s.completedTasks), WSText(@"Completed"), @"checkmark.circle", t.success],
            @"overdue":  @[@(s.overdueTasks), WSText(@"Overdue"), @"exclamationmark.circle", t.danger],
        };
        NSArray *m = metrics[item.ref];
        [cell configureValue:[m[0] stringValue] caption:m[1] symbol:m[2] color:m[3]];
    }];
    UICollectionViewCellRegistration *quickReg = [UICollectionViewCellRegistration registrationWithCellClass:QuickActionCell.class
                                                                                        configurationHandler:^(QuickActionCell *cell, NSIndexPath *ip, DashItem *item) {
        NSArray *titles = @[WSText(@"New Task"), WSText(@"New Note"), WSText(@"New Project"), WSText(@"New Schedule"), WSText(@"Import File")];
        NSArray *symbols = @[@"checkmark.circle", @"square.and.pencil", @"folder.badge.plus", @"calendar.badge.plus", @"square.and.arrow.down"];
        NSArray *colors = @[@"indigo", @"amber", @"teal", @"rose", @"sky"];
        NSInteger i = [item.ref integerValue];
        [cell configureTitle:titles[i] symbol:symbols[i] color:[t colorForIdentifier:colors[i]]];
    }];

    self.dataSource = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView
                                                                            cellProvider:^UICollectionViewCell *(UICollectionView *cv, NSIndexPath *ip, DashItem *item) {
        if ([item.kind isEqualToString:@"metric"]) return [cv dequeueConfiguredReusableCellWithRegistration:metricReg forIndexPath:ip item:item];
        if ([item.kind isEqualToString:@"quick"])  return [cv dequeueConfiguredReusableCellWithRegistration:quickReg forIndexPath:ip item:item];
        return [cv dequeueConfiguredReusableCellWithRegistration:rowReg forIndexPath:ip item:item];
    }];

    UICollectionViewSupplementaryRegistration *headerReg = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:UICollectionViewListCell.class
                                                                                                                             elementKind:UICollectionElementKindSectionHeader
                                                                                                                    configurationHandler:^(UICollectionViewListCell *header, NSString *kind, NSIndexPath *ip) {
        NSNumber *section = [weakSelf.dataSource sectionIdentifierForIndex:ip.section];
        UIListContentConfiguration *c = [UIListContentConfiguration groupedHeaderConfiguration];
        c.text = [weakSelf titleForSection:(DashSection)section.integerValue];
        c.textProperties.font = AppThemeManager.shared.fontHeadline;
        c.textProperties.color = AppThemeManager.shared.textPrimary;
        c.textProperties.transform = UIListContentTextTransformNone;
        header.contentConfiguration = c;
    }];
    self.dataSource.supplementaryViewProvider = ^UICollectionReusableView *(UICollectionView *cv, NSString *kind, NSIndexPath *ip) {
        return [cv dequeueConfiguredReusableSupplementaryViewWithRegistration:headerReg forIndexPath:ip];
    };
}

- (void)configureRow:(DashboardCell *)cell item:(DashItem *)item {
    AppThemeManager *t = AppThemeManager.shared;
    DashboardSnapshot *s = self.snapshot;
    if ([item.kind isEqualToString:@"todayInfo"]) {
        NSString *sub = [NSString stringWithFormat:WSText(@"%lu due today · %lu completed today"),
                         (unsigned long)s.dueTodayCount, (unsigned long)s.completedTodayCount];
        BOOL empty = s.todayTasks.count == 0 && s.todaySchedules.count == 0;
        [cell configureTitle:empty ? WSText(@"Nothing planned for today") : WSText(@"Today's Plan") subtitle:sub
                      symbol:@"sun.max" color:t.warning accessory:nil];
        return;
    }
    if ([item.kind isEqualToString:@"garageInfo"]) {
        Vehicle *v = GarageManager.shared.currentVehicle;
        if (!v) {
            [cell configureTitle:WSText(@"Add your car") subtitle:WSText(@"Track maintenance, fuel economy and running costs")
                          symbol:@"car.fill" color:t.accent accessory:nil];
            return;
        }
        double health = [GarageManager.shared healthFor:v];
        NSString *sub = [NSString stringWithFormat:@"%@ · %@ %.0f%%", [GarageManager formatDistance:v.odometer], WSText(@"Health"), health * 100];
        [cell configureTitle:v.name subtitle:sub symbol:@"car.fill" color:[GarageGaugeView colorForHealth:health] accessory:nil];
        return;
    }
    if ([item.kind isEqualToString:@"garagePlan"]) {
        for (PlanStatus *st in [GarageManager.shared upcomingAcrossVehicles:3]) {
            if (![st.plan.objectID isEqual:item.ref]) continue;
            NSString *title = [NSString stringWithFormat:@"%@ · %@", st.item.name ?: st.plan.itemKey, st.plan.vehicle.name];
            [cell configureTitle:title subtitle:st.remainingText symbol:st.item.symbol ?: @"wrench.fill"
                           color:[GarageGaugeView colorForHealth:st.health] accessory:[NSString stringWithFormat:@"%.0f%%", st.health * 100]];
            return;
        }
        [cell configureTitle:@"" subtitle:nil symbol:@"wrench.fill" color:t.textTertiary accessory:nil];
        return;
    }
    if ([item.kind isEqualToString:@"progress"]) {
        [cell configureTitle:WSText(@"Overall Progress")
                    subtitle:[NSString stringWithFormat:WSText(@"%lu active · %lu completed projects"), (unsigned long)s.activeProjects, (unsigned long)s.completedProjects]
                      symbol:@"chart.pie" color:t.accent accessory:[NSString stringWithFormat:@"%.0f%%", s.overallProgress * 100]];
        return;
    }
    if ([item.kind isEqualToString:@"link"]) {
        NSArray *titles = @[WSText(@"All Projects"), WSText(@"Schedule")];
        NSArray *symbols = @[@"folder", @"calendar"];
        NSInteger i = [item.ref integerValue];
        [cell configureTitle:titles[i] subtitle:nil symbol:symbols[i] color:t.accent accessory:nil];
        cell.accessories = @[[[UICellAccessoryDisclosureIndicator alloc] init]];
        return;
    }
    NSManagedObject *o = [self objectFor:item];
    if ([o isKindOfClass:Task.class]) {
        Task *task = (Task *)o;
        [cell configureTitle:task.title subtitle:task.dueText ?: TaskPriorityTitle(task.priority)
                      symbol:task.status == TaskStatusInProgress ? @"circle.lefthalf.filled" : @"circle"
                       color:task.isOverdue ? t.danger : [t colorForPriority:task.priority] accessory:nil];
    } else if ([o isKindOfClass:Schedule.class]) {
        Schedule *sc = (Schedule *)o;
        NSString *time = sc.allDay ? WSText(@"All day") : [NSDateFormatter localizedStringFromDate:sc.startTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
        [cell configureTitle:sc.title subtitle:sc.location.length ? [NSString stringWithFormat:@"%@ · %@", time, sc.location] : time
                      symbol:ScheduleKindSymbol(sc.kind) color:[t colorForScheduleKind:sc.kind] accessory:nil];
    } else if ([o isKindOfClass:Project.class]) {
        Project *p = (Project *)o;
        ProjectProgress pr = [ProjectManager.shared progressFor:p];
        [cell configureTitle:p.name subtitle:[NSString stringWithFormat:WSText(@"%lu of %lu tasks"), (unsigned long)pr.completed, (unsigned long)pr.total]
                      symbol:@"folder.fill" color:[t colorForIdentifier:p.colorIdentifier] accessory:[NSString stringWithFormat:@"%.0f%%", pr.fraction * 100]];
    }
}

- (void)reload {
    DashboardSnapshot *s = [DashboardManager.shared snapshot];
    self.snapshot = s;
    NSDiffableDataSourceSnapshot<NSNumber *, DashItem *> *snap = [[NSDiffableDataSourceSnapshot alloc] init];
    // Version strings make diffable reload rows whose content changed.
    NSString *(^ver)(NSManagedObject *) = ^NSString *(NSManagedObject *o) {
        NSDate *d = [o.entity.attributesByName objectForKey:@"updatedAt"] ? [o valueForKey:@"updatedAt"] : nil;
        return [NSString stringWithFormat:@"%f", d.timeIntervalSince1970];
    };

    // My Car: current vehicle + the most urgent maintenance across vehicles
    Vehicle *car = GarageManager.shared.currentVehicle;
    NSString *carVersion = car ? [NSString stringWithFormat:@"%@-%f-%f-%d", ver(car), car.odometer, [GarageManager.shared healthFor:car], GarageManager.usesMiles] : @"none";
    NSMutableArray *garage = [NSMutableArray arrayWithObject:[DashItem kind:@"garageInfo" ref:@0 version:carVersion]];
    for (PlanStatus *st in [GarageManager.shared upcomingAcrossVehicles:3]) {
        if (!st.isDueSoon) continue;
        [garage addObject:[DashItem kind:@"garagePlan" ref:st.plan.objectID
                                 version:[NSString stringWithFormat:@"%@-%.4f-%d", ver(st.plan), st.health, GarageManager.usesMiles]]];
    }
    [snap appendSectionsWithIdentifiers:@[@(DashSectionGarage)]];
    [snap appendItemsWithIdentifiers:garage intoSectionWithIdentifier:@(DashSectionGarage)];

    NSMutableArray *today = [NSMutableArray arrayWithObject:[DashItem kind:@"todayInfo" ref:@0
        version:[NSString stringWithFormat:@"%lu-%lu-%lu-%lu", (unsigned long)s.dueTodayCount, (unsigned long)s.completedTodayCount, (unsigned long)s.todayTasks.count, (unsigned long)s.todaySchedules.count]]];
    for (Schedule *sc in s.todaySchedules) [today addObject:[DashItem kind:@"schedule" ref:sc.objectID version:ver(sc)]];
    for (Task *task in s.todayTasks) [today addObject:[DashItem kind:@"task" ref:task.objectID version:ver(task)]];
    [snap appendSectionsWithIdentifiers:@[@(DashSectionToday)]];
    [snap appendItemsWithIdentifiers:today intoSectionWithIdentifier:@(DashSectionToday)];

    NSString *counts = [NSString stringWithFormat:@"%lu-%lu-%lu-%lu-%lu", (unsigned long)s.totalTasks, (unsigned long)s.todoTasks,
                        (unsigned long)s.inProgressTasks, (unsigned long)s.completedTasks, (unsigned long)s.overdueTasks];
    [snap appendSectionsWithIdentifiers:@[@(DashSectionTaskSummary)]];
    NSMutableArray *metrics = NSMutableArray.new;
    for (NSString *key in @[@"total", @"todo", @"progress", @"done", @"overdue"]) [metrics addObject:[DashItem kind:@"metric" ref:key version:counts]];
    [snap appendItemsWithIdentifiers:metrics intoSectionWithIdentifier:@(DashSectionTaskSummary)];

    NSMutableArray *projects = [NSMutableArray arrayWithObject:[DashItem kind:@"progress" ref:@0
        version:[NSString stringWithFormat:@"%lu-%lu-%.3f", (unsigned long)s.activeProjects, (unsigned long)s.completedProjects, s.overallProgress]]];
    for (Project *p in s.topProjects) {
        ProjectProgress pr = [ProjectManager.shared progressFor:p];
        [projects addObject:[DashItem kind:@"project" ref:p.objectID version:[NSString stringWithFormat:@"%@-%lu-%lu", ver(p), (unsigned long)pr.completed, (unsigned long)pr.total]]];
    }
    [snap appendSectionsWithIdentifiers:@[@(DashSectionProjects)]];
    [snap appendItemsWithIdentifiers:projects intoSectionWithIdentifier:@(DashSectionProjects)];

    [snap appendSectionsWithIdentifiers:@[@(DashSectionQuick)]];
    NSMutableArray *quick = NSMutableArray.new;
    for (NSInteger i = WSQuickActionNewTask; i <= WSQuickActionImportFile; i++) [quick addObject:[DashItem kind:@"quick" ref:@(i) version:@""]];
    [snap appendItemsWithIdentifiers:quick intoSectionWithIdentifier:@(DashSectionQuick)];

    [snap appendSectionsWithIdentifiers:@[@(DashSectionShortcuts)]];
    [snap appendItemsWithIdentifiers:@[[DashItem kind:@"link" ref:@0 version:@""], [DashItem kind:@"link" ref:@1 version:@""]]
           intoSectionWithIdentifier:@(DashSectionShortcuts)];
    [self.dataSource applySnapshot:snap animatingDifferences:self.view.window != nil];
}

#pragma mark - Selection

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    DashItem *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if ([item.kind isEqualToString:@"metric"]) {
        NSDictionary *filters = @{@"total": @(TaskFilterAll), @"todo": @(TaskFilterAll), @"progress": @(TaskFilterAll),
                                  @"done": @(TaskFilterCompleted), @"overdue": @(TaskFilterOverdue)};
        TaskListViewController *list = [[TaskListViewController alloc] initWithFilter:(TaskFilter)[filters[item.ref] integerValue]];
        [self.navigationController pushViewController:list animated:YES];
    } else if ([item.kind isEqualToString:@"quick"]) {
        [AppRouter.shared perform:(WSQuickAction)[item.ref integerValue] from:self];
    } else if ([item.kind isEqualToString:@"link"]) {
        UIViewController *vc = [item.ref integerValue] == 0 ? [[ProjectListViewController alloc] initWithScope:ProjectListScopeCurrent]
                                                            : ScheduleListViewController.new;
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([item.kind isEqualToString:@"progress"]) {
        [self.navigationController pushViewController:[[ProjectListViewController alloc] initWithScope:ProjectListScopeCurrent] animated:YES];
    } else if ([item.kind isEqualToString:@"garageInfo"] || [item.kind isEqualToString:@"garagePlan"]) {
        [RootViewController.current.tabs selectTab:MainTabGarage];
    } else if ([item.kind isEqualToString:@"todayInfo"]) {
        [self.navigationController pushViewController:[[TaskListViewController alloc] initWithFilter:TaskFilterToday] animated:YES];
    } else {
        [AppRouter.shared open:[self objectFor:item] from:self];
    }
}

/// Swipe right on a today task to complete it.
- (UISwipeActionsConfiguration *)leadingActionsAt:(NSIndexPath *)indexPath {
    DashItem *item = [self.dataSource itemIdentifierForIndexPath:indexPath];
    if (![item.kind isEqualToString:@"task"]) return nil;
    Task *task = (Task *)[self objectFor:item];
    if (!task) return nil;
    UIContextualAction *done = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Complete")
                                                                     handler:^(UIContextualAction *a, UIView *v, void (^finish)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [TaskManager.shared toggleCompleted:task error:&error];
        if (!ok) [self ws_showError:error];
        finish(ok);
    }];
    done.backgroundColor = AppThemeManager.shared.success;
    done.image = [UIImage ws_symbol:@"checkmark"];
    return [UISwipeActionsConfiguration configurationWithActions:@[done]];
}

#pragma mark - Backup

- (UIMenu *)dataMenu {
    __weak typeof(self) weakSelf = self;
    return [UIMenu menuWithTitle:WSText(@"Data & Backup") children:@[
        [UIAction actionWithTitle:WSText(@"Export Backup") image:[UIImage ws_symbol:@"square.and.arrow.up"] identifier:nil handler:^(UIAction *a) { [weakSelf exportBackup]; }],
        [UIAction actionWithTitle:WSText(@"Import Backup") image:[UIImage ws_symbol:@"square.and.arrow.down"] identifier:nil handler:^(UIAction *a) { [weakSelf importBackup]; }],
        [UIAction actionWithTitle:WSText(@"Notification Settings") image:[UIImage ws_symbol:@"bell"] identifier:nil handler:^(UIAction *a) { [weakSelf notificationStatus]; }],
    ]];
}

- (void)exportBackup {
    __weak typeof(self) weakSelf = self;
    [BackupManager.shared exportWithCompletion:^(NSURL *url, NSError *error) {
        if (!url) { [weakSelf ws_showError:error]; return; }
        [weakSelf ws_share:@[url] from:weakSelf.navigationItem.rightBarButtonItem];
    }];
}

- (void)importBackup {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeJSON] asCopy:YES];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    __weak typeof(self) weakSelf = self;
    [ImportManager.shared importBackupAt:url completion:^(ImportReport *report, NSError *error) {
        if (!report) { [weakSelf ws_showError:error]; return; }
        [weakSelf ws_showMessage:report.summary title:WSText(@"Backup Imported")];
    }];
}

- (void)notificationStatus {
    __weak typeof(self) weakSelf = self;
    [ReminderManager.shared refreshAuthorizationStatus:^(UNAuthorizationStatus status) {
        if (status == UNAuthorizationStatusNotDetermined) {
            [ReminderManager.shared ensureAuthorization:^(BOOL granted) {
                [weakSelf ws_toast:granted ? WSText(@"Notifications allowed") : WSText(@"Notifications are off")];
            }];
            return;
        }
        BOOL on = status == UNAuthorizationStatusAuthorized || status == UNAuthorizationStatusProvisional;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WSText(@"Notifications")
                                                                       message:on ? WSText(@"Reminders for tasks and schedule are on.")
                                                                                  : WSText(@"Notifications are turned off for this app. Turn them on in Settings to get reminders.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:WSText(@"Open Settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WSText(@"OK") style:UIAlertActionStyleCancel handler:nil]];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

@end
