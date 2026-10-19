//
//  TripsViewController.m
//  WorkSpace
//

#import "TripsViewController.h"
#import "TripEditViewController.h"
#import "TripHeatmapView.h"
#import "TripManager.h"
#import "GarageManager.h"
#import "GarageCharts.h"
#import "GarageUI.h"
#import "Vehicle.h"
#import "DataManager.h"
#import "MainTabBarController.h"
#import "RootViewController.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

UIView *TripRowView(Trip *t) {
    AppThemeManager *th = AppThemeManager.shared;
    NSString *route = (t.fromPlace.length && t.toPlace.length) ? [NSString stringWithFormat:@"%@ → %@", t.fromPlace, t.toPlace]
                                                               : (t.toPlace ?: t.fromPlace ?: TripPurposeTitles()[MAX(0, MIN(4, t.purpose))]);
    NSMutableArray *sub = [NSMutableArray arrayWithObject:GarageShortDate(t.date)];
    [sub addObject:TripPurposeTitles()[MAX(0, MIN(4, t.purpose))]];
    if (t.expense > 0) [sub addObject:[GarageManager formatCost:t.expense]];
    return [GarageRow rowWithSymbol:TripPurposeSymbol(t.purpose) color:[th colorForIdentifier:TripPurposeColor(t.purpose)]
                              title:route subtitle:[sub componentsJoinedByString:@" · "]
                           trailing:[GarageManager formatDistance:t.distance]];
}

@interface TripsViewController ()
@property (nonatomic, strong) GarageScrollStack *scroll;
@property (nonatomic, strong) WSEmptyStateView *emptyView;
@end

@implementation TripsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.scroll = [[GarageScrollStack alloc] initWithFrame:self.view.bounds];
    self.scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scroll];
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reload) name:UIApplicationSignificantTimeChangeNotification object:nil];
    [self reload];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

#pragma mark - Building

/// No car → send to Garage; car but no trips → first trip / sample.
- (void)showEmptyStateHasCar:(BOOL)hasCar {
    [self.emptyView removeFromSuperview];
    __weak typeof(self) weakSelf = self;
    if (hasCar) {
        self.emptyView = [WSEmptyStateView viewWithSymbol:@"map" title:WSText(@"No Trips Yet")
                                                  message:WSText(@"Log trips to see where your mileage goes and export business trips for reimbursement.")
                                              actionTitle:WSText(@"New Trip") action:^{ [weakSelf newTripFrom:nil]; }];
    } else {
        self.emptyView = [WSEmptyStateView viewWithSymbol:@"car.fill" title:WSText(@"Add a Car First")
                                                  message:WSText(@"Trips belong to a vehicle. Add your car in Garage, or try the sample car.")
                                              actionTitle:WSText(@"Go to Garage") action:^{ [RootViewController.current.tabs selectTab:MainTabGarage]; }];
    }
    self.emptyView.frame = self.view.bounds;
    self.emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.emptyView];
}

- (void)reload {
    if (!self.isViewLoaded) return;
    BOOL hasCar = GarageManager.shared.vehicles.count > 0;
    NSArray<Trip *> *recent = [TripManager.shared tripsFrom:nil to:nil purpose:-1];
    BOOL empty = recent.count == 0;
    self.scroll.hidden = empty;
    [self.emptyView removeFromSuperview];
    if (empty) [self showEmptyStateHasCar:hasCar];
    [self configureNavigation:hasCar hasTrips:!empty];
    [self.scroll removeAllCards];
    if (empty) return;

    UIStackView *s = self.scroll.stack;
    [s addArrangedSubview:[self monthCard]];
    [s addArrangedSubview:[self quickActions:recent.firstObject]];
    [s addArrangedSubview:[self distanceCard]];
    [s addArrangedSubview:[self heatmapCard]];
    UIView *routes = [self routesCard];
    if (routes) [s addArrangedSubview:routes];
    [s addArrangedSubview:[self recentCard:recent]];
}

- (void)configureNavigation:(BOOL)hasCar hasTrips:(BOOL)hasTrips {
    self.title = WSText(@"Trips");
    __weak typeof(self) weakSelf = self;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithPrimaryAction:
        [UIAction actionWithTitle:@"" image:[UIImage ws_symbol:@"plus.circle.fill"] identifier:nil handler:^(UIAction *a) { [weakSelf newTripFrom:nil]; }]];
    add.accessibilityLabel = WSText(@"New Trip");
    add.enabled = hasCar;
    NSArray *menu = @[
        [UIAction actionWithTitle:WSText(@"Export This Month") image:[UIImage ws_symbol:@"square.and.arrow.up"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf exportFrom:[TripManager startOfMonthOffset:0] to:nil]; }],
        [UIAction actionWithTitle:WSText(@"Export Last Month") image:[UIImage ws_symbol:@"square.and.arrow.up"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf exportFrom:[TripManager startOfMonthOffset:-1] to:[TripManager startOfMonthOffset:0]]; }],
        [UIAction actionWithTitle:WSText(@"Export All Trips") image:[UIImage ws_symbol:@"square.and.arrow.up.on.square"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf exportFrom:nil to:nil]; }],
        [UIAction actionWithTitle:WSText(@"Reimbursement Rate") image:[UIImage ws_symbol:@"creditcard"] identifier:nil
                          handler:^(UIAction *a) { [weakSelf editRate]; }],
    ];
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:[UIMenu menuWithChildren:menu]];
    more.accessibilityLabel = WSText(@"More");
    more.enabled = hasTrips;
    self.navigationItem.rightBarButtonItems = @[add, more];
}

#pragma mark - Cards

- (UIView *)monthCard {
    AppThemeManager *t = AppThemeManager.shared;
    TripStats *now = [TripManager.shared statsFrom:[TripManager startOfMonthOffset:0] to:nil];
    TripStats *last = [TripManager.shared statsFrom:[TripManager startOfMonthOffset:-1] to:[TripManager startOfMonthOffset:0]];
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"This Month") action:nil handler:nil];

    UILabel *distance = GarageLabel([GarageManager formatDistance:now.distance], [UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightBold], t.textPrimary, 1);
    distance.adjustsFontSizeToFitWidth = YES;
    distance.minimumScaleFactor = 0.6;
    NSString *trend = WSText(@"No trips last month");
    UIColor *trendColor = t.textSecondary;
    if (last.distance > 0) {
        double change = (now.distance - last.distance) / last.distance * 100;
        trend = [NSString stringWithFormat:WSText(@"%@%.0f%% vs last month"), change >= 0 ? @"+" : @"", change];
        trendColor = change >= 0 ? t.accent : t.success;
    }
    UILabel *trendLabel = GarageLabel(trend, t.fontCaption, trendColor, 1);
    UIStackView *head = [[UIStackView alloc] initWithArrangedSubviews:@[distance, trendLabel]];
    head.axis = UILayoutConstraintAxisVertical;
    head.spacing = 2;

    // Purpose donut next to the number
    NSMutableArray *values = NSMutableArray.new, *colors = NSMutableArray.new;
    for (NSInteger p = 0; p < TripPurposeCount; p++) {
        [values addObject:now.byPurpose[p]];
        [colors addObject:[t colorForIdentifier:TripPurposeColor(p)]];
    }
    GarageDonutView *donut = [[GarageDonutView alloc] initWithFrame:CGRectZero];
    [donut setValues:values colors:colors title:[NSString stringWithFormat:@"%lu", (unsigned long)now.count] subtitle:WSText(@"trips")];
    [donut.widthAnchor constraintEqualToConstant:92].active = YES;
    [donut.heightAnchor constraintEqualToConstant:92].active = YES;
    donut.isAccessibilityElement = YES;
    donut.accessibilityLabel = [NSString stringWithFormat:WSText(@"%lu trips"), (unsigned long)now.count];
    UIStackView *top = [[UIStackView alloc] initWithArrangedSubviews:@[head, donut]];
    top.alignment = UIStackViewAlignmentCenter;
    [card.content addArrangedSubview:top];

    // Legend: only purposes used this month
    UIStackView *legend = [[UIStackView alloc] init];
    legend.spacing = 12;
    for (NSInteger p = 0; p < TripPurposeCount; p++) {
        if ([now.byPurpose[p] doubleValue] <= 0) continue;
        UIView *dot = UIView.new;
        dot.backgroundColor = colors[p];
        dot.layer.cornerRadius = 4;
        [dot.widthAnchor constraintEqualToConstant:8].active = YES;
        [dot.heightAnchor constraintEqualToConstant:8].active = YES;
        UIStackView *item = [[UIStackView alloc] initWithArrangedSubviews:@[dot, GarageLabel(TripPurposeTitles()[p], t.fontCaption, t.textSecondary, 1)]];
        item.alignment = UIStackViewAlignmentCenter;
        item.spacing = 5;
        [legend addArrangedSubview:item];
    }
    [legend addArrangedSubview:UIView.new];
    [card.content addArrangedSubview:legend];

    double rate = TripManager.reimbursementRate;
    NSString *reimb = rate > 0 ? [GarageManager formatCost:now.reimbursement] : WSText(@"Set rate");
    UIStackView *tiles = [[UIStackView alloc] initWithArrangedSubviews:@[
        [GarageStatTile tileWithValue:[GarageManager formatDistance:now.businessDistance] caption:WSText(@"Business") symbol:@"briefcase.fill"
                                color:[t colorForIdentifier:TripPurposeColor(TripPurposeBusiness)]],
        [GarageStatTile tileWithValue:[GarageManager formatCost:now.expense] caption:WSText(@"Tolls & Parking") symbol:@"parkingsign.circle.fill"
                                color:[t colorForIdentifier:@"amber"]],
        [GarageStatTile tileWithValue:reimb caption:WSText(@"Reimbursable") symbol:@"banknote.fill" color:t.success],
    ]];
    tiles.distribution = UIStackViewDistributionFillEqually;
    tiles.spacing = 8;
    [card.content addArrangedSubview:tiles];
    return card;
}

- (UIView *)quickActions:(Trip *)lastTrip {
    AppThemeManager *t = AppThemeManager.shared;
    __weak typeof(self) weakSelf = self;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[
        [GarageQuickButton buttonWithSymbol:@"plus" title:WSText(@"New Trip") color:t.accent handler:^{ [weakSelf newTripFrom:nil]; }],
        [GarageQuickButton buttonWithSymbol:@"arrow.uturn.backward" title:WSText(@"Return Trip") color:[t colorForIdentifier:@"teal"] handler:^{ [weakSelf returnTrip:lastTrip]; }],
        [GarageQuickButton buttonWithSymbol:@"square.and.arrow.up" title:WSText(@"Export") color:[t colorForIdentifier:@"amber"] handler:^{
            [weakSelf exportFrom:[TripManager startOfMonthOffset:0] to:nil];
        }],
        [GarageQuickButton buttonWithSymbol:@"list.bullet" title:WSText(@"All Trips") color:[t colorForIdentifier:@"violet"] handler:^{
            [weakSelf.navigationController pushViewController:TripListViewController.new animated:YES];
        }],
    ]];
    row.distribution = UIStackViewDistributionFillEqually;
    return row;
}

/// Last 12 months, stacked by purpose.
- (UIView *)distanceCard {
    AppThemeManager *t = AppThemeManager.shared;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Monthly Mileage") action:nil handler:nil];
    NSMutableArray *stacks = NSMutableArray.new, *labels = NSMutableArray.new, *colors = NSMutableArray.new;
    NSDateFormatter *f = NSDateFormatter.new;
    [f setLocalizedDateFormatFromTemplate:@"MMM"];
    double total = 0;
    for (NSDictionary *m in TripManager.shared.monthlyDistance) {
        NSMutableArray *display = NSMutableArray.new;
        for (NSNumber *km in m[@"values"]) { [display addObject:@([GarageManager displayFromKm:km.doubleValue])]; total += km.doubleValue; }
        [stacks addObject:display];
        [labels addObject:[f stringFromDate:m[@"month"]]];
    }
    for (NSInteger p = 0; p < TripPurposeCount; p++) [colors addObject:[t colorForIdentifier:TripPurposeColor(p)]];
    GarageBarChartView *bars = [[GarageBarChartView alloc] initWithFrame:CGRectZero];
    NSString *unit = GarageManager.distanceUnit;
    bars.valueFormatter = ^NSString *(double v) { return [NSString stringWithFormat:@"%@ %@", [GarageManager formatNumber:round(v) digits:0], unit]; };
    [bars setStacks:stacks colors:colors labels:labels];
    bars.accessibilityLabel = WSText(@"Monthly Mileage");
    [bars.heightAnchor constraintEqualToConstant:150].active = YES;
    [card.content addArrangedSubview:bars];
    [card.content addArrangedSubview:GarageLabel([NSString stringWithFormat:WSText(@"%@ logged in the last 12 months"), [GarageManager formatDistance:total]],
                                                 t.fontCaption, t.textSecondary, 1)];
    return card;
}

- (UIView *)heatmapCard {
    AppThemeManager *t = AppThemeManager.shared;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Driving Activity") action:nil handler:nil];
    NSDictionary *daily = [TripManager.shared dailyDistanceForLast:26 * 7];
    TripHeatmapView *map = [[TripHeatmapView alloc] initWithFrame:CGRectZero];
    map.tint = t.accent;
    [map setDailyValues:daily weeks:26];
    map.accessibilityLabel = WSText(@"Driving Activity");
    [map.heightAnchor constraintEqualToConstant:110].active = YES;
    [card.content addArrangedSubview:map];

    // Streak = consecutive days with trips ending today or yesterday.
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *day = [cal startOfDayForDate:NSDate.date];
    if ([daily[day] doubleValue] <= 0) day = [cal dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:day options:0];
    NSInteger streak = 0;
    while ([daily[day] doubleValue] > 0) { streak++; day = [cal dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:day options:0]; }
    NSUInteger active = 0;
    for (NSNumber *v in daily.allValues) if (v.doubleValue > 0) active++;
    NSString *text = [NSString stringWithFormat:WSText(@"%lu driving days in 26 weeks · current streak %ld days"), (unsigned long)active, (long)streak];
    [card.content addArrangedSubview:GarageLabel(text, t.fontCaption, t.textSecondary, 0)];
    return card;
}

/// Frequent routes with a relative bar; tapping one starts a new trip on that route.
- (UIView *)routesCard {
    AppThemeManager *t = AppThemeManager.shared;
    NSArray *routes = [TripManager.shared topRoutes:4];
    if (!routes.count) return nil;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Frequent Routes") action:nil handler:nil];
    NSInteger maxCount = [routes.firstObject[@"count"] integerValue];
    __weak typeof(self) weakSelf = self;
    for (NSDictionary *r in routes) {
        NSInteger count = [r[@"count"] integerValue];
        double avg = count ? [r[@"distance"] doubleValue] / count : 0;
        GarageRow *row = [GarageRow rowWithSymbol:@"arrow.left.arrow.right" color:t.accent
                                            title:[NSString stringWithFormat:@"%@ ↔ %@", r[@"from"], r[@"to"]]
                                         subtitle:[NSString stringWithFormat:WSText(@"%ld trips · avg %@"), (long)count, [GarageManager formatDistance:avg]]
                                         trailing:nil];
        NSString *from = r[@"from"], *to = r[@"to"];
        row.onTap = ^{ [weakSelf newTripRouteFrom:from to:to]; };
        UIProgressView *bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        bar.progress = maxCount ? (float)count / maxCount : 0;
        bar.progressTintColor = [t.accent colorWithAlphaComponent:0.7];
        bar.trackTintColor = t.surfaceRaised;
        bar.layer.cornerRadius = 2;
        bar.clipsToBounds = YES;
        bar.isAccessibilityElement = NO;
        UIStackView *v = [[UIStackView alloc] initWithArrangedSubviews:@[row, bar]];
        v.axis = UILayoutConstraintAxisVertical;
        v.spacing = 6;
        [card.content addArrangedSubview:v];
    }
    return card;
}

- (UIView *)recentCard:(NSArray<Trip *> *)trips {
    __weak typeof(self) weakSelf = self;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Recent Trips") action:WSText(@"See All") handler:^{
        [weakSelf.navigationController pushViewController:TripListViewController.new animated:YES];
    }];
    for (Trip *trip in [trips subarrayWithRange:NSMakeRange(0, MIN(5, trips.count))]) {
        GarageRow *row = (GarageRow *)TripRowView(trip);
        row.onTap = ^{ [weakSelf editTrip:trip]; };
        [card.content addArrangedSubview:row];
    }
    return card;
}

#pragma mark - Actions

- (void)present:(TripEditViewController *)editor {
    if (!GarageManager.shared.vehicles.count) {
        [self ws_showMessage:WSText(@"Trips belong to a vehicle. Add your car in Garage, or try the sample car.") title:WSText(@"Add a Car First")];
        return;
    }
    [self presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
}

- (void)newTripFrom:(Trip *)templateTrip {
    [self present:[[TripEditViewController alloc] initWithTrip:nil vehicle:nil template:templateTrip]];
}

/// Same route back: places swapped, same purpose and distance.
- (void)returnTrip:(Trip *)last {
    TripEditViewController *editor = [[TripEditViewController alloc] initWithTrip:nil vehicle:last.vehicle template:nil];
    if (last) [editor prefillFrom:last.toPlace to:last.fromPlace purpose:last.purpose distance:last.distance];
    [self present:editor];
}

- (void)newTripRouteFrom:(NSString *)from to:(NSString *)to {
    Trip *match = nil;
    for (Trip *trip in [TripManager.shared tripsFrom:nil to:nil purpose:-1]) {
        if ([trip.fromPlace isEqualToString:from] && [trip.toPlace isEqualToString:to]) { match = trip; break; }
    }
    TripEditViewController *editor = [[TripEditViewController alloc] initWithTrip:nil vehicle:match.vehicle template:nil];
    [editor prefillFrom:from to:to purpose:match ? match.purpose : -1 distance:match.distance];
    [self present:editor];
}

- (void)editTrip:(Trip *)trip {
    [self present:[[TripEditViewController alloc] initWithTrip:trip vehicle:nil template:nil]];
}

- (void)exportFrom:(NSDate *)from to:(NSDate *)to {
    NSError *error = nil;
    NSURL *url = [TripManager.shared exportCSVFrom:from to:to error:&error];
    if (!url) { [self ws_showError:error]; return; }
    [self ws_share:@[url] from:self.navigationItem.rightBarButtonItems.lastObject];
}

- (void)editRate {
    double rate = TripManager.reimbursementRate;
    NSString *current = rate > 0 ? [NSString stringWithFormat:@"%.2f", GarageManager.usesMiles ? rate * 1.609344 : rate] : @"";
    NSString *message = [NSString stringWithFormat:WSText(@"Amount reimbursed per %@ for business trips. Tolls and parking on business trips are added."),
                         GarageManager.distanceUnit];
    __weak typeof(self) weakSelf = self;
    [self ws_promptTitle:WSText(@"Reimbursement Rate") message:message placeholder:@"0.80" text:current action:WSText(@"Save")
                 handler:^(NSString *text) {
        double value = [GarageManager parseNumber:text];
        if (isnan(value) || value < 0) {
            [weakSelf ws_showMessage:WSText(@"Please enter a valid amount.") title:nil];
            return;
        }
        TripManager.reimbursementRate = GarageManager.usesMiles ? value / 1.609344 : value;
        [weakSelf reload];
    }];
}

@end

#pragma mark - All trips

@interface TripListViewController ()
@property (nonatomic, strong) UISegmentedControl *filter;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, copy) NSArray<NSArray<Trip *> *> *groups;
@end

@implementation TripListViewController

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        self.title = WSText(@"All Trips");
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    NSMutableArray *items = [NSMutableArray arrayWithObject:WSText(@"All")];
    [items addObjectsFromArray:@[WSText(@"Commute"), WSText(@"Business"), WSText(@"Personal")]];
    self.filter = [[UISegmentedControl alloc] initWithItems:items];
    self.filter.selectedSegmentIndex = 0;
    __weak typeof(self) weakSelf = self;
    [self.filter addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf reload]; }] forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.filter;
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [self reload];
}

- (void)reload {
    NSInteger purpose = self.filter.selectedSegmentIndex - 1;   // -1 all, 0 commute, 1 business, 2 personal
    NSDateFormatter *f = NSDateFormatter.new;
    [f setLocalizedDateFormatFromTemplate:@"yyyyMMMM"];
    NSMutableArray *titles = NSMutableArray.new, *groups = NSMutableArray.new;
    for (Trip *trip in [TripManager.shared tripsFrom:nil to:nil purpose:purpose]) {
        NSString *month = [f stringFromDate:trip.date];
        if (![titles.lastObject isEqualToString:month]) { [titles addObject:month]; [groups addObject:NSMutableArray.new]; }
        [groups.lastObject addObject:trip];
    }
    self.titles = titles; self.groups = groups;
    self.tableView.backgroundView = groups.count ? nil
        : [WSEmptyStateView viewWithSymbol:@"map" title:WSText(@"No Trips") message:nil actionTitle:nil action:nil];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.groups.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.groups[section].count; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    double km = 0;
    for (Trip *t in self.groups[section]) km += t.distance;
    return [NSString stringWithFormat:@"%@ · %@", self.titles[section], [GarageManager formatDistance:km]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"trip"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"trip"];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.backgroundColor = AppThemeManager.shared.surface;
    UIView *row = TripRowView(self.groups[indexPath.section][indexPath.row]);
    row.userInteractionEnabled = NO;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:row];
    UILayoutGuide *m = cell.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:m.topAnchor], [row.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
        [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor], [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
    ]];
    cell.isAccessibilityElement = YES;
    cell.accessibilityLabel = row.accessibilityLabel;
    cell.accessibilityTraits = UIAccessibilityTraitButton;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Trip *trip = self.groups[indexPath.section][indexPath.row];
    [self presentViewController:[[TripEditViewController alloc] initWithTrip:trip vehicle:nil template:nil].embeddedInNavigation animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    Trip *trip = self.groups[indexPath.section][indexPath.row];
    __weak typeof(self) weakSelf = self;
    UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                    handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        NSError *error = nil;
        if (![TripManager.shared deleteTrip:trip error:&error]) [weakSelf ws_showError:error];
        done(YES);
    }];
    UIContextualAction *again = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Repeat")
                                                                      handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
        [weakSelf presentViewController:[[TripEditViewController alloc] initWithTrip:nil vehicle:nil template:trip].embeddedInNavigation animated:YES completion:nil];
        done(YES);
    }];
    again.backgroundColor = AppThemeManager.shared.accent;
    return [UISwipeActionsConfiguration configurationWithActions:@[del, again]];
}

@end
