//
//  GarageScreens.m
//  WorkSpace
//
//  Shared helpers and the statistics screen. The list screens live in GarageListScreens.m.
//

#import "GarageScreens.h"
#import "GarageEditors.h"
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "GarageCharts.h"
#import "GarageUI.h"
#import "Vehicle.h"
#import "ServiceRecord.h"
#import "FuelLog.h"
#import "MaintenancePlan.h"
#import "Task.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

WSFormViewController *GarageEditorForEntry(id entry, Vehicle *vehicle) {
    if ([entry isKindOfClass:FuelLog.class]) return [[FuelEditViewController alloc] initWithVehicle:vehicle log:entry];
    return [[ServiceEditViewController alloc] initWithVehicle:vehicle record:entry itemKeys:nil];
}

void GarageShowPlanActions(UIViewController *from, PlanStatus *s) {
    MaintenancePlan *plan = s.plan;
    Vehicle *v = plan.vehicle;
    NSString *name = s.item.name ?: plan.itemKey;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:name message:s.remainingText
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    __weak UIViewController *weakFrom = from;
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Mark Done Today") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSError *error = nil;
        if ([GarageManager.shared markPlanDone:plan cost:0 error:&error]) [weakFrom ws_toast:WSText(@"Logged in history")];
        else [weakFrom ws_showError:error];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Log Service with Details…") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        ServiceEditViewController *editor = [[ServiceEditViewController alloc] initWithVehicle:v record:nil itemKeys:@[plan.itemKey]];
        [weakFrom presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Create Reminder Task") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSError *error = nil;
        Task *task = [GarageManager.shared reminderTaskForPlan:plan error:&error];
        if (!task) { [weakFrom ws_showError:error]; return; }
        if (weakFrom) [AppRouter.shared open:task from:weakFrom];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Adjust Interval") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakFrom presentViewController:[[PlanEditViewController alloc] initWithPlan:plan].embeddedInNavigation animated:YES completion:nil];
    }]];
    if (s.item) {
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"About This Item") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [weakFrom.navigationController pushViewController:[[GarageGuideViewController alloc] initWithSection:0] animated:YES];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = from.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(from.view.bounds), CGRectGetMidY(from.view.bounds), 1, 1);
    [from presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Statistics

@interface GarageStatsViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, strong) GarageScrollStack *scroll;
@property (nonatomic, strong) UISegmentedControl *range;
@end

@implementation GarageStatsViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _vehicle = vehicle;
        self.title = WSText(@"Statistics");
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.scroll = [[GarageScrollStack alloc] initWithFrame:self.view.bounds];
    self.scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scroll];
    self.range = [[UISegmentedControl alloc] initWithItems:@[WSText(@"3 Months"), WSText(@"12 Months"), WSText(@"All Time")]];
    self.range.selectedSegmentIndex = 1;
    __weak typeof(self) weakSelf = self;
    [self.range addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf reload]; }] forControlEvents:UIControlEventValueChanged];
    [DataManager.shared observeChanges:self selector:@selector(reload)];
    [self reload];
}

- (void)reload {
    if (self.vehicle.isDeleted || !self.vehicle.managedObjectContext) { [self.navigationController popViewControllerAnimated:YES]; return; }
    AppThemeManager *t = AppThemeManager.shared;
    static const NSInteger kRanges[] = {3, 12, 0};
    NSInteger months = kRanges[MAX(0, MIN(2, self.range.selectedSegmentIndex))];
    GarageStats *s = [GarageManager.shared statsFor:self.vehicle months:months];
    [self.scroll removeAllCards];
    UIStackView *stack = self.scroll.stack;
    [stack addArrangedSubview:self.range];

    // Summary tiles
    GarageCard *summary = [GarageCard cardWithTitle:WSText(@"Summary") action:nil handler:nil];
    double perUnit = GarageManager.usesMiles ? s.costPerKm * 1.609344 : s.costPerKm;
    NSString *consumption = s.averageConsumption > 0 ? [NSString stringWithFormat:@"%.1f L", s.averageConsumption] : @"—";
    NSArray *tiles = @[
        [GarageStatTile tileWithValue:[GarageManager formatCost:s.totalCost] caption:WSText(@"Total Spent") symbol:@"creditcard.fill" color:t.accent],
        [GarageStatTile tileWithValue:s.distance > 0 ? [GarageManager formatDistance:s.distance] : @"—" caption:WSText(@"Distance") symbol:@"map.fill" color:t.success],
        [GarageStatTile tileWithValue:perUnit > 0 ? [GarageManager formatCost:perUnit] : @"—"
                              caption:[NSString stringWithFormat:WSText(@"Per %@"), GarageManager.distanceUnit] symbol:@"gauge" color:t.warning],
        [GarageStatTile tileWithValue:consumption caption:WSText(@"Per 100 km") symbol:@"fuelpump.fill" color:[t colorForIdentifier:@"amber"]],
    ];
    UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[tiles[0], tiles[1]]];
    UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[tiles[2], tiles[3]]];
    for (UIStackView *r in @[row1, row2]) { r.distribution = UIStackViewDistributionFillEqually; r.spacing = 8; [summary.content addArrangedSubview:r]; }
    [stack addArrangedSubview:summary];

    // Monthly bars (always the last 12 months so the trend stays readable)
    GarageCard *monthly = [GarageCard cardWithTitle:WSText(@"Monthly Spending") action:nil handler:nil];
    NSMutableArray *stacks = NSMutableArray.new, *labels = NSMutableArray.new;
    NSDateFormatter *f = NSDateFormatter.new;
    [f setLocalizedDateFormatFromTemplate:@"MMM"];
    for (NSDictionary *m in s.monthly) {
        [stacks addObject:@[m[@"fuel"], m[@"service"]]];
        [labels addObject:[f stringFromDate:m[@"month"]]];
    }
    GarageBarChartView *bars = [[GarageBarChartView alloc] initWithFrame:CGRectZero];
    bars.valueFormatter = ^NSString *(double value) { return [GarageManager formatCost:value]; };
    UIColor *fuelColor = [t colorForIdentifier:ServiceCategoryColor(ServiceCategoryFuelChart)];
    [bars setStacks:stacks colors:@[fuelColor, t.accent] labels:labels];
    bars.accessibilityLabel = WSText(@"Monthly costs");
    [bars.heightAnchor constraintEqualToConstant:170].active = YES;
    [monthly.content addArrangedSubview:bars];
    [stack addArrangedSubview:monthly];

    [stack addArrangedSubview:[self categoryCard:s]];
    [stack addArrangedSubview:[self consumptionCard:s]];
}

/// Donut + legend rows with share of total.
- (UIView *)categoryCard:(GarageStats *)s {
    AppThemeManager *t = AppThemeManager.shared;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"By Category") action:nil handler:nil];
    if (!s.byCategory.count) {
        [card.content addArrangedSubview:GarageLabel(WSText(@"No costs in this period."), t.fontCallout, t.textSecondary, 0)];
        return card;
    }
    NSArray *titles = ServiceCategoryTitles();
    NSMutableArray *values = NSMutableArray.new, *colors = NSMutableArray.new;
    for (NSDictionary *c in s.byCategory) {
        [values addObject:c[@"amount"]];
        [colors addObject:[t colorForIdentifier:ServiceCategoryColor([c[@"category"] integerValue])]];
    }
    GarageDonutView *donut = [[GarageDonutView alloc] initWithFrame:CGRectZero];
    [donut setValues:values colors:colors title:[GarageManager formatCost:s.totalCost] subtitle:WSText(@"Total")];
    donut.isAccessibilityElement = YES;
    donut.accessibilityLabel = WSText(@"By Category");
    [donut.heightAnchor constraintEqualToConstant:180].active = YES;
    [card.content addArrangedSubview:donut];

    for (NSDictionary *c in s.byCategory) {
        NSInteger cat = [c[@"category"] integerValue];
        double amount = [c[@"amount"] doubleValue];
        NSString *name = cat == ServiceCategoryFuelChart ? WSText(@"Fuel") : titles[MIN((NSUInteger)MAX(cat, 0), titles.count - 1)];
        NSString *share = s.totalCost > 0 ? [NSString stringWithFormat:@"%.0f%%", amount / s.totalCost * 100] : nil;
        [card.content addArrangedSubview:[GarageRow rowWithSymbol:ServiceCategorySymbol(cat)
                                                            color:[t colorForIdentifier:ServiceCategoryColor(cat)]
                                                            title:name subtitle:share trailing:[GarageManager formatCost:amount]]];
    }
    return card;
}

- (UIView *)consumptionCard:(GarageStats *)s {
    AppThemeManager *t = AppThemeManager.shared;
    GarageCard *card = [GarageCard cardWithTitle:WSText(@"Fuel Economy") action:nil handler:nil];
    NSArray *points = s.consumption.count > 16 ? [s.consumption subarrayWithRange:NSMakeRange(s.consumption.count - 16, 16)] : s.consumption;
    if (points.count < 2) {
        [card.content addArrangedSubview:GarageLabel(WSText(@"Log at least two full-tank refuels to see your fuel economy."),
                                                     t.fontCallout, t.textSecondary, 0)];
        return card;
    }
    NSMutableArray *values = NSMutableArray.new, *labels = NSMutableArray.new;
    for (NSDictionary *p in points) {
        [values addObject:p[@"value"]];
        [labels addObject:GarageShortDate(p[@"date"])];
    }
    GarageLineChartView *line = [[GarageLineChartView alloc] initWithFrame:CGRectZero];
    [line setValues:values labels:labels unit:@"L/100km"];
    line.isAccessibilityElement = YES;
    line.accessibilityLabel = WSText(@"Fuel Economy");
    line.accessibilityValue = s.averageConsumption > 0 ? [NSString stringWithFormat:@"%.1f L/100km", s.averageConsumption] : nil;
    [line.heightAnchor constraintEqualToConstant:170].active = YES;
    [card.content addArrangedSubview:line];
    [card.content addArrangedSubview:GarageLabel(WSText(@"Calculated between full tanks. Green marks your best, amber your highest."),
                                                 t.fontCaption, t.textTertiary, 0)];
    return card;
}

@end