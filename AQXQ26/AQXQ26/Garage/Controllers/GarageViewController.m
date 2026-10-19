//
//  GarageViewController.m
//  WorkSpace
//

#import "GarageViewController.h"
#import "GarageScreens.h"
#import "GarageEditors.h"
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "GarageCharts.h"
#import "GarageUI.h"
#import "Vehicle.h"
#import "MaintenancePlan.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

@interface GarageViewController ()
@property (nonatomic, strong) GarageScrollStack *scroll;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@end

@implementation GarageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.scroll = [[GarageScrollStack alloc] initWithFrame:self.view.bounds];
    self.scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scroll];

    __weak typeof(self) weakSelf = self;
    self.emptyView = [WSEmptyStateView viewWithSymbol:@"car.fill" title:WSText(@"Your Garage Is Empty")
                                              message:WSText(@"Add your car to track maintenance, fuel economy and running costs. Or explore with a sample car first.")
                                          actionTitle:WSText(@"Add Vehicle") action:^{ [weakSelf addVehicle]; }];
    self.emptyView.frame = self.view.bounds;
    self.emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.emptyView];

    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [self reload];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];   // unit setting or current vehicle may have changed elsewhere
}

#pragma mark - Building

- (void)reload {
    if (!self.isViewLoaded) return;
    Vehicle *v = GarageManager.shared.currentVehicle;
    self.emptyView.hidden = v != nil;
    self.scroll.hidden = v == nil;
    [self configureNavigationFor:v];
    [self.scroll removeAllCards];
    if (!v) { [self addSampleButtonToEmptyState]; return; }

    UIStackView *s = self.scroll.stack;
    [s addArrangedSubview:[self heroCardFor:v]];
    [s addArrangedSubview:[self quickActionsFor:v]];
    UIView *renewals = [self renewalsCardFor:v];
    if (renewals) [s addArrangedSubview:renewals];
    [s addArrangedSubview:[self maintenanceCardFor:v]];
    [s addArrangedSubview:[self costCardFor:v]];
    [s addArrangedSubview:[self historyCardFor:v]];
    [s addArrangedSubview:[self knowledgeCard]];
}

- (void)configureNavigationFor:(Vehicle *)v {
    self.title = v ? v.name : WSText(@"Garage");
    if (!v) { self.navigationItem.rightBarButtonItem = nil; self.navigationItem.leftBarButtonItem = nil; return; }
    __weak typeof(self) weakSelf = self;
    NSArray *adds = @[
        [UIAction actionWithTitle:WSText(@"Service Record") image:[UIImage ws_symbol:@"wrench.and.screwdriver"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf addServiceWithItems:nil]; }],
        [UIAction actionWithTitle:WSText(@"Refuel") image:[UIImage ws_symbol:@"fuelpump"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf addFuel]; }],
        [UIAction actionWithTitle:WSText(@"Update Mileage") image:[UIImage ws_symbol:@"speedometer"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf updateMileage]; }],
    ];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"plus.circle.fill"] menu:[UIMenu menuWithChildren:adds]];
    add.accessibilityLabel = WSText(@"Add");
    self.navigationItem.rightBarButtonItem = add;

    NSMutableArray *switcher = NSMutableArray.new;
    for (Vehicle *other in GarageManager.shared.vehicles) {
        UIAction *pick = [UIAction actionWithTitle:other.name image:[UIImage ws_symbol:@"car"] identifier:nil handler:^(UIAction *a) {
            GarageManager.shared.currentVehicle = other;
            [weakSelf reload];
        }];
        if (other == v) pick.state = UIMenuElementStateOn;
        [switcher addObject:pick];
    }
    UIMenu *vehicles = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:switcher];
    UIMenu *manage = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
        [UIAction actionWithTitle:WSText(@"Add Vehicle") image:[UIImage ws_symbol:@"plus"] identifier:nil handler:^(UIAction *a) { [weakSelf addVehicle]; }],
        [UIAction actionWithTitle:WSText(@"Edit Vehicle") image:[UIImage ws_symbol:@"pencil"] identifier:nil handler:^(UIAction *a) { [weakSelf editVehicle:v]; }],
        [UIAction actionWithTitle:WSText(@"Garage Settings") image:[UIImage ws_symbol:@"gearshape"] identifier:nil handler:^(UIAction *a) {
            [weakSelf.navigationController pushViewController:GarageSettingsViewController.new animated:YES];
        }],
    ]];
    UIBarButtonItem *car = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"car.2.fill"] menu:[UIMenu menuWithChildren:@[vehicles, manage]]];
    car.accessibilityLabel = WSText(@"Vehicles");
    self.navigationItem.leftBarButtonItem = car;
}

- (void)addSampleButtonToEmptyState {
    if ([self.emptyView viewWithTag:77]) return;
    UIButton *sample = [UIButton buttonWithType:UIButtonTypeSystem];
    sample.tag = 77;
    [sample setTitle:WSText(@"Try a Sample Car") forState:UIControlStateNormal];
    sample.titleLabel.font = AppThemeManager.shared.fontCallout;
    sample.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    [sample addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf createSample]; }] forControlEvents:UIControlEventTouchUpInside];
    [self.emptyView addSubview:sample];
    [NSLayoutConstraint activateConstraints:@[
        [sample.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
        [sample.bottomAnchor constraintEqualToAnchor:self.emptyView.safeAreaLayoutGuide.bottomAnchor constant:-40],
    ]];
}

- (UIView *)heroCardFor:(Vehicle *)v {
    AppThemeManager *t = AppThemeManager.shared;
    UIColor *body = [t colorForIdentifier:v.colorIdentifier];
    GarageCard *card = [GarageCard cardWithTitle:nil action:nil handler:nil];

    // Tinted backdrop behind the car
    UIView *stage = UIView.new;
    stage.backgroundColor = [body colorWithAlphaComponent:0.12];
    stage.layer.cornerRadius = 12;
    stage.layer.cornerCurve = kCACornerCurveContinuous;
    GarageCarView *carView = [[GarageCarView alloc] initWithFrame:CGRectZero];
    carView.bodyColor = body;
    carView.translatesAutoresizingMaskIntoConstraints = NO;
    [stage addSubview:carView];
    UILabel *plate = GarageLabel(v.plate, [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightBold], t.textPrimary, 1);
    plate.textAlignment = NSTextAlignmentCenter;
    plate.backgroundColor = t.surface;
    plate.layer.cornerRadius = 5;
    plate.layer.borderWidth = 1.5;
    plate.layer.borderColor = t.textPrimary.CGColor;
    plate.clipsToBounds = YES;
    plate.hidden = v.plate.length == 0;
    plate.translatesAutoresizingMaskIntoConstraints = NO;
    [stage addSubview:plate];
    [NSLayoutConstraint activateConstraints:@[
        [stage.heightAnchor constraintEqualToConstant:132],
        [carView.leadingAnchor constraintEqualToAnchor:stage.leadingAnchor constant:12],
        [carView.trailingAnchor constraintEqualToAnchor:stage.trailingAnchor constant:-12],
        [carView.topAnchor constraintEqualToAnchor:stage.topAnchor constant:10],
        [carView.bottomAnchor constraintEqualToAnchor:stage.bottomAnchor constant:-6],
        [plate.topAnchor constraintEqualToAnchor:stage.topAnchor constant:10],
        [plate.trailingAnchor constraintEqualToAnchor:stage.trailingAnchor constant:-10],
        [plate.heightAnchor constraintEqualToConstant:22],
        [plate.widthAnchor constraintGreaterThanOrEqualToConstant:84],
    ]];
    [card.content addArrangedSubview:stage];

    // Name block + health gauge
    NSMutableArray *specs = NSMutableArray.new;
    NSString *makeModel = [[@[v.make ?: @"", v.model ?: @""] componentsJoinedByString:@" "]
                           stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (makeModel.length) [specs addObject:makeModel];
    if (v.year > 0) [specs addObject:[NSString stringWithFormat:@"%d", v.year]];
    [specs addObject:VehicleFuelTypeTitles()[MIN((NSUInteger)MAX(v.fuelType, 0), 2)]];
    UILabel *spec = GarageLabel([specs componentsJoinedByString:@" · "], t.fontCallout, t.textSecondary, 2);
    UILabel *odoCaption = GarageLabel(WSText(@"Odometer"), t.fontCaption, t.textTertiary, 1);
    UILabel *odo = GarageLabel([GarageManager formatDistance:v.odometer], [UIFont monospacedDigitSystemFontOfSize:26 weight:UIFontWeightBold], t.textPrimary, 1);
    odo.adjustsFontSizeToFitWidth = YES;
    odo.minimumScaleFactor = 0.6;
    UIButton *update = [UIButton buttonWithType:UIButtonTypeSystem];
    [update setTitle:WSText(@"Update Mileage") forState:UIControlStateNormal];
    update.titleLabel.font = t.fontCaption;
    update.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    __weak typeof(self) weakSelf = self;
    [update addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf updateMileage]; }] forControlEvents:UIControlEventTouchUpInside];
    UIStackView *left = [[UIStackView alloc] initWithArrangedSubviews:@[spec, GarageSpacer(4), odoCaption, odo, update]];
    left.axis = UILayoutConstraintAxisVertical;
    left.alignment = UIStackViewAlignmentLeading;
    left.spacing = 1;

    double health = [GarageManager.shared healthFor:v];
    GarageGaugeView *gauge = [[GarageGaugeView alloc] initWithFrame:CGRectZero];
    gauge.caption = WSText(@"Health");
    gauge.value = health;
    gauge.lineWidth = 11;
    [gauge.widthAnchor constraintEqualToConstant:120].active = YES;
    [gauge.heightAnchor constraintEqualToConstant:84].active = YES;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[left, gauge]];
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 8;
    [card.content addArrangedSubview:row];

    // Mini stats
    NSArray *statuses = [GarageManager.shared planStatusesFor:v];
    NSUInteger dueSoon = 0, overdue = 0;
    for (PlanStatus *st in statuses) { if (st.isOverdue) overdue++; else if (st.isDueSoon) dueSoon++; }
    GarageStats *year = [GarageManager.shared statsFor:v months:12];
    NSString *consumption = year.averageConsumption > 0 ? [NSString stringWithFormat:@"%.1f", year.averageConsumption] : @"—";
    UIStackView *tiles = [[UIStackView alloc] initWithArrangedSubviews:@[
        [GarageStatTile tileWithValue:[NSString stringWithFormat:@"%lu", (unsigned long)overdue] caption:WSText(@"Overdue")
                               symbol:@"exclamationmark.triangle.fill" color:overdue ? t.danger : t.textTertiary],
        [GarageStatTile tileWithValue:[NSString stringWithFormat:@"%lu", (unsigned long)dueSoon] caption:WSText(@"Due Soon")
                               symbol:@"clock.fill" color:dueSoon ? t.warning : t.textTertiary],
        [GarageStatTile tileWithValue:consumption caption:WSText(@"L/100km") symbol:@"fuelpump.fill" color:t.accent],
    ]];
    tiles.distribution = UIStackViewDistributionFillEqually;
    tiles.spacing = 8;
    [card.content addArrangedSubview:tiles];
    return card;
}

- (UIView *)quickActionsFor:(Vehicle *)v {
    AppThemeManager *t = AppThemeManager.shared;
    __weak typeof(self) weakSelf = self;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[
        [GarageQuickButton buttonWithSymbol:@"wrench.and.screwdriver.fill" title:WSText(@"Service") color:t.accent handler:^{ [weakSelf addServiceWithItems:nil]; }],
        [GarageQuickButton buttonWithSymbol:@"fuelpump.fill" title:WSText(@"Refuel") color:[t colorForIdentifier:@"amber"] handler:^{ [weakSelf addFuel]; }],
        [GarageQuickButton buttonWithSymbol:@"chart.pie.fill" title:WSText(@"Costs") color:[t colorForIdentifier:@"teal"] handler:^{ [weakSelf openStats]; }],
        [GarageQuickButton buttonWithSymbol:@"book.fill" title:WSText(@"Guide") color:[t colorForIdentifier:@"violet"] handler:^{ [weakSelf openGuide]; }],
    ]];
    row.distribution = UIStackViewDistributionFillEqually;
    return row;
}

/// Insurance / inspection renewals within 60 days.
- (UIView *)renewalsCardFor:(Vehicle *)v {
    AppThemeManager *t = AppThemeManager.shared;
    NSMutableArray *rows = NSMutableArray.new;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *today = [cal startOfDayForDate:NSDate.date];
    NSArray *pairs = @[@[WSText(@"Insurance Renewal"), @"shield.lefthalf.filled", v.insuranceDue ?: NSNull.null],
                       @[WSText(@"Annual Inspection"), @"checkmark.seal.fill", v.inspectionDue ?: NSNull.null]];
    for (NSArray *p in pairs) {
        if (p[2] == NSNull.null) continue;
        NSInteger days = [cal components:NSCalendarUnitDay fromDate:today toDate:[cal startOfDayForDate:p[2]] options:0].day;
        if (days > 60) continue;
        UIColor *color = days < 0 ? t.danger : (days <= 14 ? t.warning : t.accent);
        NSString *when = days < 0 ? [NSString stringWithFormat:WSText(@"%ld days overdue"), (long)-days]
                       : (days == 0 ? WSText(@"Today") : [NSString stringWithFormat:WSText(@"In %ld days"), (long)days]);
        GarageRow *row = [GarageRow rowWithSymbol:p[1] color:color title:p[0] subtitle:GarageShortDate(p[2]) trailing:when];
        row.trailingLabel.textColor = color;
        __weak typeof(self) weakSelf = self;
        row.onTap = ^{ [weakSelf editVehicle:v]; };
        [rows addObject:row];
    }
    if (!rows.count) return nil;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Renewals") action:nil handler:nil];
    for (UIView *r in rows) [card.content addArrangedSubview:r];
    return card;
}

- (UIView *)maintenanceCardFor:(Vehicle *)v {
    __weak typeof(self) weakSelf = self;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Maintenance") action:WSText(@"All Items") handler:^{
        [weakSelf.navigationController pushViewController:[[GaragePlansViewController alloc] initWithVehicle:v] animated:YES];
    }];
    NSArray<PlanStatus *> *statuses = [GarageManager.shared planStatusesFor:v];
    if (!statuses.count) {
        [card.content addArrangedSubview:GarageLabel(WSText(@"No items tracked. Add items from All Items."), AppThemeManager.shared.fontCallout,
                                                     AppThemeManager.shared.textSecondary, 0)];
        return card;
    }
    for (PlanStatus *s in [statuses subarrayWithRange:NSMakeRange(0, MIN(4, statuses.count))]) {
        GarageRow *row = GarageRowForPlan(s);
        row.onTap = ^{ [weakSelf showActionsForPlan:s]; };
        [card.content addArrangedSubview:row];
    }
    return card;
}

- (UIView *)costCardFor:(Vehicle *)v {
    AppThemeManager *t = AppThemeManager.shared;
    __weak typeof(self) weakSelf = self;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Running Costs") action:WSText(@"Statistics") handler:^{
        [weakSelf.navigationController pushViewController:[[GarageStatsViewController alloc] initWithVehicle:v] animated:YES];
    }];
    GarageStats *stats = [GarageManager.shared statsFor:v months:12];
    UILabel *total = GarageLabel([GarageManager formatCost:stats.totalCost], [UIFont monospacedDigitSystemFontOfSize:24 weight:UIFontWeightBold], t.textPrimary, 1);
    NSString *perKm = stats.costPerKm > 0 ? [NSString stringWithFormat:WSText(@"%@ per %@"),
                                             [GarageManager formatCost:[GarageManager usesMiles] ? stats.costPerKm * 1.609344 : stats.costPerKm],
                                             GarageManager.distanceUnit] : nil;
    UILabel *caption = GarageLabel(perKm ? [NSString stringWithFormat:@"%@ · %@", WSText(@"Last 12 months"), perKm] : WSText(@"Last 12 months"),
                                   t.fontCaption, t.textSecondary, 1);
    [card.content addArrangedSubview:total];
    [card.content addArrangedSubview:caption];

    // Last 6 months, service + fuel stacked
    NSArray *monthly = [stats.monthly subarrayWithRange:NSMakeRange(6, 6)];
    NSMutableArray *stacks = NSMutableArray.new, *labels = NSMutableArray.new;
    NSDateFormatter *f = NSDateFormatter.new;
    [f setLocalizedDateFormatFromTemplate:@"MMM"];
    for (NSDictionary *m in monthly) {
        [stacks addObject:@[m[@"fuel"], m[@"service"]]];
        [labels addObject:[f stringFromDate:m[@"month"]]];
    }
    GarageBarChartView *bars = [[GarageBarChartView alloc] initWithFrame:CGRectZero];
    bars.valueFormatter = ^NSString *(double value) { return [GarageManager formatCost:value]; };
    UIColor *fuelColor = [t colorForIdentifier:ServiceCategoryColor(ServiceCategoryFuelChart)];
    [bars setStacks:stacks colors:@[fuelColor, t.accent] labels:labels];
    bars.accessibilityLabel = WSText(@"Monthly costs");
    [bars.heightAnchor constraintEqualToConstant:130].active = YES;
    [card.content addArrangedSubview:bars];

    UIStackView *legend = [[UIStackView alloc] initWithArrangedSubviews:@[[self legendDot:fuelColor text:WSText(@"Fuel")],
                                                                          [self legendDot:t.accent text:WSText(@"Service & Other")], UIView.new]];
    legend.spacing = 16;
    [card.content addArrangedSubview:legend];
    return card;
}

- (UIView *)legendDot:(UIColor *)color text:(NSString *)text {
    UIView *dot = UIView.new;
    dot.backgroundColor = color;
    dot.layer.cornerRadius = 4;
    [dot.widthAnchor constraintEqualToConstant:8].active = YES;
    [dot.heightAnchor constraintEqualToConstant:8].active = YES;
    UIStackView *s = [[UIStackView alloc] initWithArrangedSubviews:@[dot, GarageLabel(text, AppThemeManager.shared.fontCaption, AppThemeManager.shared.textSecondary, 1)]];
    s.alignment = UIStackViewAlignmentCenter;
    s.spacing = 6;
    return s;
}

- (UIView *)historyCardFor:(Vehicle *)v {
    __weak typeof(self) weakSelf = self;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Recent History") action:WSText(@"See All") handler:^{
        [weakSelf.navigationController pushViewController:[[GarageTimelineViewController alloc] initWithVehicle:v] animated:YES];
    }];
    NSArray *entries = [GarageManager.shared timelineFor:v limit:5];
    if (!entries.count) {
        [card.content addArrangedSubview:GarageLabel(WSText(@"No records yet. Log a service or refuel to start the history."),
                                                     AppThemeManager.shared.fontCallout, AppThemeManager.shared.textSecondary, 0)];
    }
    for (GarageTimelineEntry *e in entries) {
        GarageRow *row = GarageRowForEntry(e);
        row.onTap = ^{ [weakSelf editEntry:e.object vehicle:v]; };
        [card.content addArrangedSubview:row];
    }
    return card;
}

- (UIView *)knowledgeCard {
    AppThemeManager *t = AppThemeManager.shared;
    __weak typeof(self) weakSelf = self;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Car Care Guide") action:nil handler:nil];
    NSArray *rows = @[
        @[@"book.fill", @"indigo", WSText(@"Maintenance Guide"), [NSString stringWithFormat:WSText(@"%lu items with recommended intervals"), (unsigned long)GarageCatalog.items.count], @0],
        @[@"exclamationmark.triangle.fill", @"amber", WSText(@"Warning Lights"), WSText(@"What each dashboard light means"), @1],
        @[@"checklist", @"teal", WSText(@"Checklists"), WSText(@"Road trip, winter, used car and more"), @2],
    ];
    for (NSArray *r in rows) {
        GarageRow *row = [GarageRow rowWithSymbol:r[0] color:[t colorForIdentifier:r[1]] title:r[2] subtitle:r[3] trailing:nil];
        NSInteger section = [r[4] integerValue];
        row.onTap = ^{ [weakSelf.navigationController pushViewController:[[GarageGuideViewController alloc] initWithSection:section] animated:YES]; };
        [card.content addArrangedSubview:row];
    }
    return card;
}

#pragma mark - Actions

- (void)present:(WSFormViewController *)form {
    [self presentViewController:form.embeddedInNavigation animated:YES completion:nil];
}

- (void)addVehicle {
    VehicleEditViewController *editor = [[VehicleEditViewController alloc] initWithVehicle:nil];
    __weak typeof(self) weakSelf = self;
    editor.onSaved = ^{ [weakSelf reload]; };
    [self present:editor];
}

- (void)editVehicle:(Vehicle *)v {
    [self.navigationController pushViewController:[[GarageVehicleViewController alloc] initWithVehicle:v] animated:YES];
}

- (void)createSample {
    NSError *error = nil;
    if (![GarageManager.shared createSampleGarage:&error]) [self ws_showError:error];
    else [self ws_toast:WSText(@"Sample car added")];
    [self reload];
}

- (void)addServiceWithItems:(NSArray *)keys {
    Vehicle *v = GarageManager.shared.currentVehicle;
    if (v) [self present:[[ServiceEditViewController alloc] initWithVehicle:v record:nil itemKeys:keys]];
}

- (void)addFuel {
    Vehicle *v = GarageManager.shared.currentVehicle;
    if (v) [self present:[[FuelEditViewController alloc] initWithVehicle:v log:nil]];
}

- (void)updateMileage {
    Vehicle *v = GarageManager.shared.currentVehicle;
    if (!v) return;
    NSString *current = [NSString stringWithFormat:@"%.0f", [GarageManager displayFromKm:v.odometer]];
    NSString *title = [NSString stringWithFormat:@"%@ (%@)", WSText(@"Update Mileage"), GarageManager.distanceUnit];
    __weak typeof(self) weakSelf = self;
    [self ws_promptTitle:title message:WSText(@"Enter the reading on your odometer.") placeholder:current text:current action:WSText(@"Save")
                 handler:^(NSString *text) {
        double value = [GarageManager parseNumber:text];
        NSError *error = nil;
        if (isnan(value) || ![GarageManager.shared updateOdometer:[GarageManager kmFromDisplay:value] forVehicle:v error:&error]) {
            [weakSelf ws_showError:error ?: [NSError errorWithDomain:@"WorkSpace" code:1 userInfo:@{NSLocalizedDescriptionKey: WSText(@"Please enter a valid mileage.")}]];
        }
    }];
}

- (void)editEntry:(id)entry vehicle:(Vehicle *)v {
    [self present:GarageEditorForEntry(entry, v)];
}

- (void)showActionsForPlan:(PlanStatus *)s {
    GarageShowPlanActions(self, s);
}

- (void)openStats {
    Vehicle *v = GarageManager.shared.currentVehicle;
    if (v) [self.navigationController pushViewController:[[GarageStatsViewController alloc] initWithVehicle:v] animated:YES];
}

- (void)openGuide {
    [self.navigationController pushViewController:[[GarageGuideViewController alloc] initWithSection:0] animated:YES];
}

@end
