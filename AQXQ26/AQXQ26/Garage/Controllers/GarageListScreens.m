//
//  GarageListScreens.m
//  WorkSpace
//
//  Table-based Garage screens: timeline, maintenance items, guide, vehicle info, settings.
//

#import "GarageScreens.h"
#import "GarageEditors.h"
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "GarageCharts.h"
#import "GarageUI.h"
#import "Vehicle.h"
#import "MaintenancePlan.h"
#import "Task.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

/// Common table setup for Garage list screens.
static void GLStyleTable(UITableViewController *vc) {
    vc.tableView.backgroundColor = AppThemeManager.shared.background;
    vc.tableView.rowHeight = UITableViewAutomaticDimension;
    vc.tableView.estimatedRowHeight = 56;
    vc.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    vc.hidesBottomBarWhenPushed = YES;
}

/// A table cell hosting a GarageRow (keeps list rows identical to the cards).
static UITableViewCell *GLCellWithRow(UITableView *table, GarageRow *row) {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"row"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"row"];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.backgroundColor = AppThemeManager.shared.surface;
    row.userInteractionEnabled = NO;   // the table handles selection
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:row];
    UILayoutGuide *m = cell.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:m.topAnchor],
        [row.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
        [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
    ]];
    cell.isAccessibilityElement = YES;
    cell.accessibilityLabel = row.accessibilityLabel;
    cell.accessibilityTraits = UIAccessibilityTraitButton;
    return cell;
}

#pragma mark - Timeline

@interface GarageTimelineViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, copy) NSArray<NSString *> *monthTitles;
@property (nonatomic, copy) NSArray<NSArray<GarageTimelineEntry *> *> *groups;
@property (nonatomic, strong) UISegmentedControl *filter;
@end

@implementation GarageTimelineViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle;
        self.title = WSText(@"History");
        GLStyleTable(self);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.filter = [[UISegmentedControl alloc] initWithItems:@[WSText(@"All"), WSText(@"Service"), WSText(@"Fuel")]];
    self.filter.selectedSegmentIndex = 0;
    __weak typeof(self) weakSelf = self;
    [self.filter addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf reload]; }] forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.filter;
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [self reload];
}

- (void)reload {
    if (self.vehicle.isDeleted || !self.vehicle.managedObjectContext) { [self.navigationController popViewControllerAnimated:YES]; return; }
    NSInteger mode = self.filter.selectedSegmentIndex;
    NSDateFormatter *f = NSDateFormatter.new;
    [f setLocalizedDateFormatFromTemplate:@"yyyyMMMM"];
    NSMutableArray *titles = NSMutableArray.new, *groups = NSMutableArray.new;
    for (GarageTimelineEntry *e in [GarageManager.shared timelineFor:self.vehicle limit:0]) {
        BOOL fuel = e.category == ServiceCategoryFuelChart;
        if ((mode == 1 && fuel) || (mode == 2 && !fuel)) continue;
        NSString *month = [f stringFromDate:e.date];
        if (![titles.lastObject isEqualToString:month]) { [titles addObject:month]; [groups addObject:NSMutableArray.new]; }
        [groups.lastObject addObject:e];
    }
    self.monthTitles = titles; self.groups = groups;
    self.tableView.backgroundView = groups.count ? nil
        : [WSEmptyStateView viewWithSymbol:@"clock.arrow.circlepath" title:WSText(@"No Records")
                                   message:WSText(@"Service records and refuels will appear here.") actionTitle:nil action:nil];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.groups.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.groups[section].count; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    double total = 0;
    for (GarageTimelineEntry *e in self.groups[section]) total += e.cost;
    return [NSString stringWithFormat:@"%@ · %@", self.monthTitles[section], [GarageManager formatCost:total]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return GLCellWithRow(tableView, GarageRowForEntry(self.groups[indexPath.section][indexPath.row]));
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GarageTimelineEntry *e = self.groups[indexPath.section][indexPath.row];
    [self presentViewController:GarageEditorForEntry(e.object, self.vehicle).embeddedInNavigation animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    GarageTimelineEntry *e = self.groups[indexPath.section][indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [weakSelf ws_confirm:WSText(@"Delete this record?") message:nil destructive:WSText(@"Delete") handler:^{
            NSError *error = nil;
            if (![GarageManager.shared deleteEntry:e.object error:&error]) [weakSelf ws_showError:error];
        }];
        done(YES);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[del]];
}

@end

#pragma mark - Maintenance items

@interface GaragePlansViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, copy) NSArray<PlanStatus *> *tracked;
@property (nonatomic, copy) NSArray<MaintenancePlan *> *paused;
@property (nonatomic, copy) NSArray<GarageItem *> *available;
@end

@implementation GaragePlansViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle;
        self.title = WSText(@"Maintenance Items");
        GLStyleTable(self);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [self reload];
}

- (void)reload {
    if (self.vehicle.isDeleted || !self.vehicle.managedObjectContext) { [self.navigationController popViewControllerAnimated:YES]; return; }
    self.tracked = [GarageManager.shared planStatusesFor:self.vehicle];
    NSMutableArray *paused = NSMutableArray.new;
    NSMutableSet *used = NSMutableSet.new;
    for (MaintenancePlan *p in [GarageManager.shared allPlansFor:self.vehicle]) {
        [used addObject:p.itemKey];
        if (!p.enabled) [paused addObject:p];
    }
    self.paused = paused;
    NSMutableArray *available = NSMutableArray.new;
    for (GarageItem *i in GarageCatalog.items) if (![used containsObject:i.key]) [available addObject:i];
    self.available = available;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 3; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.tracked.count : (section == 1 ? self.paused.count : self.available.count);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return self.tracked.count ? WSText(@"Tracked") : nil;
    if (section == 1) return self.paused.count ? WSText(@"Paused") : nil;
    return self.available.count ? WSText(@"Add an Item") : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0 && self.tracked.count ? WSText(@"Tap an item to mark it done, log a service or create a reminder task.") : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    if (indexPath.section == 0) return GLCellWithRow(tableView, GarageRowForPlan(self.tracked[indexPath.row]));
    if (indexPath.section == 1) {
        GarageItem *item = [GarageCatalog itemForKey:self.paused[indexPath.row].itemKey];
        return GLCellWithRow(tableView, [GarageRow rowWithSymbol:item.symbol ?: @"wrench.fill" color:t.textTertiary
                                                           title:item.name ?: self.paused[indexPath.row].itemKey
                                                        subtitle:WSText(@"Not tracked") trailing:nil]);
    }
    GarageItem *item = self.available[indexPath.row];
    GarageRow *row = [GarageRow rowWithSymbol:item.symbol color:t.accent title:item.name subtitle:item.summary trailing:nil];
    UITableViewCell *cell = GLCellWithRow(tableView, row);
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"plus.circle.fill"]];
    cell.accessoryView.tintColor = t.accent;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSError *error = nil;
    if (indexPath.section == 0) {
        GarageShowPlanActions(self, self.tracked[indexPath.row]);
    } else if (indexPath.section == 1) {
        [self presentViewController:[[PlanEditViewController alloc] initWithPlan:self.paused[indexPath.row]].embeddedInNavigation animated:YES completion:nil];
    } else if (![GarageManager.shared addPlanForItem:self.available[indexPath.row].key to:self.vehicle error:&error]) {
        [self ws_showError:error];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) return nil;
    MaintenancePlan *plan = indexPath.section == 0 ? self.tracked[indexPath.row].plan : self.paused[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Remove")
                                                                       handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        if (![GarageManager.shared deletePlan:plan error:&error]) [weakSelf ws_showError:error];
        done(YES);
    }];
    UIContextualAction *edit = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Edit")
                                                                     handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [weakSelf presentViewController:[[PlanEditViewController alloc] initWithPlan:plan].embeddedInNavigation animated:YES completion:nil];
        done(YES);
    }];
    edit.backgroundColor = AppThemeManager.shared.accent;
    return [UISwipeActionsConfiguration configurationWithActions:@[remove, edit]];
}

@end

#pragma mark - Guide

@interface GarageGuideViewController ()
@property (nonatomic) NSInteger section;
@property (nonatomic, strong) UISegmentedControl *picker;
@end

@implementation GarageGuideViewController

- (instancetype)initWithSection:(NSInteger)section {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _section = MAX(0, MIN(2, section));
        self.title = WSText(@"Car Care Guide");
        GLStyleTable(self);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.picker = [[UISegmentedControl alloc] initWithItems:@[WSText(@"Items"), WSText(@"Warning Lights"), WSText(@"Checklists")]];
    self.picker.selectedSegmentIndex = self.section;
    __weak typeof(self) weakSelf = self;
    [self.picker addAction:[UIAction actionWithHandler:^(UIAction *a) {
        weakSelf.section = weakSelf.picker.selectedSegmentIndex;
        [weakSelf.tableView reloadData];
    }] forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.picker;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)s {
    return self.section == 0 ? GarageCatalog.items.count : (self.section == 1 ? GarageCatalog.warningLights.count : GarageCatalog.checklists.count);
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)s {
    if (self.section == 0) return WSText(@"Intervals are general guidance for passenger cars. Your owner's manual is the final reference.");
    if (self.section == 1) return WSText(@"Red: stop safely. Amber: check soon. Green / blue: information.");
    return WSText(@"Tap a checklist to add it to Tasks.");
}

/// Icon + title + body lines, all plain labels so Dynamic Type works.
- (UITableViewCell *)guideCellSymbol:(NSString *)symbol color:(UIColor *)color title:(NSString *)title
                                badge:(NSString *)badge lines:(NSArray<NSString *> *)lines {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    GarageRow *head = [GarageRow rowWithSymbol:symbol color:color title:title subtitle:badge trailing:nil];
    head.userInteractionEnabled = NO;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[head]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 6;
    for (NSString *line in lines) [stack addArrangedSubview:GarageLabel(line, t.fontCallout, t.textSecondary, 0)];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:stack];
    UILayoutGuide *m = cell.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:m.topAnchor constant:4],
        [stack.bottomAnchor constraintEqualToAnchor:m.bottomAnchor constant:-4],
        [stack.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
    ]];
    cell.selectionStyle = self.section == 2 ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    if (self.section == 0) {
        GarageItem *i = GarageCatalog.items[indexPath.row];
        NSMutableArray *every = NSMutableArray.new;
        if (i.intervalKm > 0) [every addObject:[GarageManager formatDistance:i.intervalKm]];
        if (i.intervalMonths > 0) [every addObject:[NSString stringWithFormat:WSText(@"%ld months"), (long)i.intervalMonths]];
        NSString *badge = [NSString stringWithFormat:WSText(@"Every %@"), [every componentsJoinedByString:@" / "]];
        NSMutableArray *lines = [NSMutableArray arrayWithObject:i.summary];
        for (NSString *tip in i.tips) [lines addObject:[@"• " stringByAppendingString:tip]];
        return [self guideCellSymbol:i.symbol color:t.accent title:i.name badge:badge lines:lines];
    }
    if (self.section == 1) {
        GarageWarningLight *l = GarageCatalog.warningLights[indexPath.row];
        NSArray *levels = @[WSText(@"Information"), WSText(@"Check Soon"), WSText(@"Stop Safely")];
        return [self guideCellSymbol:l.symbol color:[GarageCatalog colorForWarningLevel:l.level] title:l.name
                               badge:levels[l.level] lines:@[l.meaning, [NSString stringWithFormat:@"→ %@", l.action]]];
    }
    GarageChecklist *c = GarageCatalog.checklists[indexPath.row];
    NSMutableArray *lines = [NSMutableArray arrayWithObject:c.summary];
    for (NSString *item in c.items) [lines addObject:[@"☐ " stringByAppendingString:item]];
    UITableViewCell *cell = [self guideCellSymbol:c.symbol color:[t colorForIdentifier:@"teal"] title:c.name
                                            badge:[NSString stringWithFormat:WSText(@"%lu items"), (unsigned long)c.items.count] lines:lines];
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"plus.circle.fill"]];
    cell.accessoryView.tintColor = t.accent;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.section != 2) return;
    GarageChecklist *c = GarageCatalog.checklists[indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:WSText(@"Add “%@” to Tasks?"), c.name]
                                                                   message:WSText(@"Each item becomes a checklist step.")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *add = [UIAlertAction actionWithTitle:WSText(@"Add") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSError *error = nil;
        Task *task = [GarageManager.shared taskFromChecklistAt:indexPath.row vehicle:GarageManager.shared.currentVehicle error:&error];
        if (!task) { [weakSelf ws_showError:error]; return; }
        [AppRouter.shared open:task from:weakSelf];
    }];
    [alert addAction:add];
    alert.preferredAction = add;
    [self presentViewController:alert animated:YES completion:nil];
}

@end

#pragma mark - Vehicle info

@interface GarageVehicleViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *rows;   // [title, value]
@end

@implementation GarageVehicleViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle;
        GLStyleTable(self);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                           target:self action:@selector(edit)];
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [self reload];
}

- (void)reload {
    Vehicle *v = self.vehicle;
    if (v.isDeleted || !v.managedObjectContext) { [self.navigationController popToRootViewControllerAnimated:YES]; return; }
    self.title = v.name;
    NSMutableArray *rows = NSMutableArray.new;
    void (^add)(NSString *, NSString *) = ^(NSString *title, NSString *value) { if (value.length) [rows addObject:@[title, value]]; };
    add(WSText(@"Make"), v.make);
    add(WSText(@"Model"), v.model);
    add(WSText(@"Year"), v.year > 0 ? [NSString stringWithFormat:@"%d", v.year] : nil);
    add(WSText(@"Fuel"), VehicleFuelTypeTitles()[MIN((NSUInteger)MAX(v.fuelType, 0), 2)]);
    add(WSText(@"Odometer"), [GarageManager formatDistance:v.odometer]);
    add(WSText(@"License Plate"), v.plate);
    add(WSText(@"VIN"), v.vin);
    add(WSText(@"Purchase Date"), GarageShortDate(v.purchaseDate));
    add(WSText(@"Insurance Renewal"), GarageShortDate(v.insuranceDue));
    add(WSText(@"Annual Inspection"), GarageShortDate(v.inspectionDue));
    add(WSText(@"Service Records"), [NSString stringWithFormat:@"%lu", (unsigned long)v.records.count]);
    add(WSText(@"Refuels"), [NSString stringWithFormat:@"%lu", (unsigned long)v.fuelLogs.count]);
    self.rows = rows;
    [self.tableView reloadData];
}

- (void)edit {
    [self presentViewController:[[VehicleEditViewController alloc] initWithVehicle:self.vehicle].embeddedInNavigation animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.vehicle.notes.length ? 3 : 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return self.rows.count;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 1 && self.vehicle.notes.length ? WSText(@"Remarks") : nil;
}

- (BOOL)isDeleteSection:(NSInteger)section { return section == [self numberOfSectionsInTableView:self.tableView] - 1; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    UIListContentConfiguration *c;
    if ([self isDeleteSection:indexPath.section]) {
        c = UIListContentConfiguration.cellConfiguration;
        c.text = WSText(@"Delete Vehicle");
        c.textProperties.color = t.danger;
        c.textProperties.alignment = UIListContentTextAlignmentCenter;
    } else if (indexPath.section == 1) {
        c = UIListContentConfiguration.cellConfiguration;
        c.text = self.vehicle.notes;
        c.textProperties.color = t.textSecondary;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        c = UIListContentConfiguration.valueCellConfiguration;
        c.text = self.rows[indexPath.row][0];
        c.secondaryText = self.rows[indexPath.row][1];
        c.secondaryTextProperties.color = t.textSecondary;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.contentConfiguration = c;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (![self isDeleteSection:indexPath.section]) return;
    __weak typeof(self) weakSelf = self;
    [self ws_confirm:[NSString stringWithFormat:WSText(@"Delete “%@”?"), self.vehicle.name]
             message:WSText(@"All service records, refuels and maintenance plans of this vehicle will be deleted.")
         destructive:WSText(@"Delete") handler:^{
        NSError *error = nil;
        if (![GarageManager.shared deleteVehicle:weakSelf.vehicle error:&error]) [weakSelf ws_showError:error];
    }];
}

@end

#pragma mark - Settings

@implementation GarageSettingsViewController

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        self.title = WSText(@"Garage Settings");
        GLStyleTable(self);
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) return WSText(@"Mileage is stored in kilometers and converted for display. Currency follows your region settings.");
    return WSText(@"Adds a sample car with a year of history. It is ordinary data you can edit or delete.");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    UIListContentConfiguration *c = UIListContentConfiguration.cellConfiguration;
    if (indexPath.section == 0) {
        c.text = WSText(@"Show Distances in Miles");
        c.image = [UIImage ws_symbol:@"ruler"];
        UISwitch *toggle = UISwitch.new;
        toggle.on = GarageManager.usesMiles;
        toggle.onTintColor = t.accent;
        [toggle addAction:[UIAction actionWithHandler:^(UIAction *a) {
            GarageManager.usesMiles = toggle.on;
            [NSNotificationCenter.defaultCenter postNotificationName:WSDataDidChangeNotification object:nil];
        }] forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        c.text = WSText(@"Add Sample Car");
        c.image = [UIImage ws_symbol:@"car.fill"];
        c.textProperties.color = t.accent;
    }
    c.imageProperties.tintColor = t.accent;
    cell.contentConfiguration = c;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 1) return;
    NSError *error = nil;
    if ([GarageManager.shared createSampleGarage:&error]) {
        [self ws_toast:WSText(@"Sample car added")];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self ws_showError:error];
    }
}

@end