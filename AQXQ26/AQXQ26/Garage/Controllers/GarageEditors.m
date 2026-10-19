//
//  GarageEditors.m
//  WorkSpace
//

#import "GarageEditors.h"
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "Vehicle.h"
#import "ServiceRecord.h"
#import "FuelLog.h"
#import "MaintenancePlan.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

/// Numbers in forms are shown without grouping so they parse back cleanly.
static NSString *GENumberText(double v, NSInteger digits) {
    if (v == 0) return nil;
    NSString *s = [NSString stringWithFormat:@"%.*f", (int)digits, v];
    if ([s containsString:@"."]) {
        while ([s hasSuffix:@"0"]) s = [s substringToIndex:s.length - 1];
        if ([s hasSuffix:@"."]) s = [s substringToIndex:s.length - 1];
    }
    return s;
}

static WSFormRow *GENumberRow(NSString *key, NSString *title, double value, NSInteger digits, NSString *placeholder) {
    WSFormRow *row = [WSFormRow type:WSFormRowText key:key title:title value:GENumberText(value, digits)];
    row.keyboardType = digits ? UIKeyboardTypeDecimalPad : UIKeyboardTypeNumberPad;
    row.placeholder = placeholder;
    return row;
}

static NSString *GEOdometerTitle(void) {
    return [NSString stringWithFormat:@"%@ (%@)", WSText(@"Odometer"), GarageManager.distanceUnit];
}

#pragma mark - Vehicle

@interface VehicleEditViewController ()
@property (nonatomic, strong, nullable) Vehicle *vehicle;
@property (nonatomic, strong, readwrite, nullable) Vehicle *savedVehicle;
@end

@implementation VehicleEditViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle;
        self.title = vehicle ? WSText(@"Edit Vehicle") : WSText(@"Add Vehicle");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    VehicleDraft *d = [VehicleDraft draftFromVehicle:self.vehicle];
    WSFormRow *name = [WSFormRow type:WSFormRowText key:@"name" title:WSText(@"Name") value:d.name];
    name.placeholder = WSText(@"e.g. Family car");
    WSFormRow *make = [WSFormRow type:WSFormRowText key:@"make" title:WSText(@"Make") value:d.make];
    make.placeholder = WSText(@"e.g. Toyota");
    WSFormRow *model = [WSFormRow type:WSFormRowText key:@"model" title:WSText(@"Model") value:d.model];
    model.placeholder = WSText(@"e.g. Corolla");
    WSFormRow *year = GENumberRow(@"year", WSText(@"Year"), d.year, 0, WSText(@"Year"));
    WSFormRow *fuel = [WSFormRow type:WSFormRowChoice key:@"fuel" title:WSText(@"Fuel") value:@(d.fuelType)];
    fuel.options = VehicleFuelTypeTitles();
    WSFormRow *color = [WSFormRow type:WSFormRowColor key:@"color" title:WSText(@"Color") value:d.colorIdentifier];
    WSFormRow *odo = GENumberRow(@"odometer", GEOdometerTitle(), [GarageManager displayFromKm:d.odometer], 0, WSText(@"Current mileage"));
    WSFormRow *plate = [WSFormRow type:WSFormRowText key:@"plate" title:WSText(@"License Plate") value:d.plate];
    WSFormRow *vin = [WSFormRow type:WSFormRowText key:@"vin" title:WSText(@"VIN") value:d.vin];
    WSFormRow *purchase = [WSFormRow type:WSFormRowDate key:@"purchase" title:WSText(@"Purchase Date") value:d.purchaseDate];
    purchase.dateMode = UIDatePickerModeDate;
    WSFormRow *insurance = [WSFormRow type:WSFormRowDate key:@"insurance" title:WSText(@"Insurance Renewal") value:d.insuranceDue];
    insurance.dateMode = UIDatePickerModeDate;
    WSFormRow *inspection = [WSFormRow type:WSFormRowDate key:@"inspection" title:WSText(@"Annual Inspection") value:d.inspectionDue];
    inspection.dateMode = UIDatePickerModeDate;
    WSFormRow *notes = [WSFormRow type:WSFormRowTextArea key:@"notes" title:WSText(@"Remarks") value:d.notes];
    WSFormSection *dates = [WSFormSection title:WSText(@"Dates") rows:@[purchase, insurance, inspection]];
    dates.footer = WSText(@"Renewal dates appear on Home when they get close.");
    WSFormSection *basic = [WSFormSection title:nil rows:@[name, make, model, year, fuel, color]];
    WSFormSection *mileage = [WSFormSection title:WSText(@"Mileage") rows:@[odo]];
    if (!self.vehicle) mileage.footer = WSText(@"Common maintenance plans are added automatically and start from this mileage.");
    return @[basic, mileage, [WSFormSection title:WSText(@"Registration") rows:@[plate, vin]], dates,
             [WSFormSection title:nil rows:@[notes]]];
}

- (BOOL)save {
    VehicleDraft *d = [VehicleDraft draftFromVehicle:self.vehicle];
    d.name = [self stringForKey:@"name"];
    d.make = [self stringForKey:@"make"]; d.model = [self stringForKey:@"model"];
    d.plate = [self stringForKey:@"plate"]; d.vin = [self stringForKey:@"vin"];
    d.notes = [self stringForKey:@"notes"];
    double year = [GarageManager parseNumber:[self stringForKey:@"year"]];
    NSInteger thisYear = [NSCalendar.currentCalendar component:NSCalendarUnitYear fromDate:NSDate.date];
    if (isnan(year) || (year != 0 && (year < 1900 || year > thisYear + 1))) {
        [self ws_showMessage:WSText(@"Please enter a valid year.") title:nil];
        return NO;
    }
    d.year = (int16_t)year;
    double odo = [GarageManager parseNumber:[self stringForKey:@"odometer"]];
    d.odometer = isnan(odo) ? NAN : [GarageManager kmFromDisplay:odo];
    d.fuelType = (VehicleFuelType)[[self formValueForKey:@"fuel"] integerValue];
    d.colorIdentifier = [self formValueForKey:@"color"] ?: @"indigo";
    d.purchaseDate = [self formValueForKey:@"purchase"];
    d.insuranceDue = [self formValueForKey:@"insurance"];
    d.inspectionDue = [self formValueForKey:@"inspection"];
    NSError *error = nil;
    BOOL ok;
    if (self.vehicle) {
        ok = [GarageManager.shared updateVehicle:self.vehicle with:d error:&error];
        self.savedVehicle = self.vehicle;
    } else {
        self.savedVehicle = [GarageManager.shared createVehicle:d error:&error];
        ok = self.savedVehicle != nil;
    }
    if (!ok) [self ws_showError:error];
    return ok;
}

@end

#pragma mark - Service

@interface ServiceEditViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, strong, nullable) ServiceRecord *record;
@property (nonatomic, copy) NSArray<NSString *> *itemKeys;
@end

@implementation ServiceEditViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle record:(ServiceRecord *)record itemKeys:(NSArray<NSString *> *)itemKeys {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle;
        _record = record;
        ServiceDraft *d = [ServiceDraft draftFromRecord:record vehicle:vehicle];
        _itemKeys = record ? d.itemKeys : (itemKeys ?: @[]);
        self.title = record ? WSText(@"Edit Record") : WSText(@"Add Record");
    }
    return self;
}

- (NSString *)itemsSummary {
    NSMutableArray *names = NSMutableArray.new;
    for (NSString *k in self.itemKeys) { GarageItem *i = [GarageCatalog itemForKey:k]; if (i) [names addObject:i.name]; }
    return names.count ? [names componentsJoinedByString:@", "] : WSText(@"None");
}

- (NSArray<WSFormSection *> *)buildSections {
    ServiceDraft *d = [ServiceDraft draftFromRecord:self.record vehicle:self.vehicle];
    BOOL fromPlan = !self.record && self.itemKeys.count;
    WSFormRow *category = [WSFormRow type:WSFormRowChoice key:@"category" title:WSText(@"Type") value:@(d.category)];
    category.options = ServiceCategoryTitles();
    NSString *title = d.title;
    if (fromPlan && !title.length) title = [GarageCatalog itemForKey:self.itemKeys.firstObject].name;
    WSFormRow *name = [WSFormRow type:WSFormRowText key:@"title" title:WSText(@"Title") value:title];
    name.placeholder = WSText(@"e.g. Oil change");
    __weak typeof(self) weakSelf = self;
    WSFormRow *items = [WSFormRow type:WSFormRowButton key:@"items" title:WSText(@"Items Serviced") value:self.itemsSummary];
    items.symbol = @"checklist";
    items.onTap = ^(WSFormRow *row) {
        GarageItemPickerViewController *picker = [[GarageItemPickerViewController alloc] initWithSelected:weakSelf.itemKeys completion:^(NSArray *keys) {
            weakSelf.itemKeys = keys;
            [weakSelf setFormValue:weakSelf.itemsSummary forKey:@"items"];
        }];
        [weakSelf.navigationController pushViewController:picker animated:YES];
    };
    WSFormRow *date = [WSFormRow type:WSFormRowDate key:@"date" title:WSText(@"Date") value:d.date];
    date.dateMode = UIDatePickerModeDate;
    date.dateRequired = YES;
    WSFormRow *odo = GENumberRow(@"odometer", GEOdometerTitle(), [GarageManager displayFromKm:d.odometer], 0, WSText(@"Mileage at service"));
    WSFormRow *cost = GENumberRow(@"cost", WSText(@"Cost"), d.cost, 2, @"0");
    WSFormRow *shop = [WSFormRow type:WSFormRowText key:@"shop" title:WSText(@"Shop") value:d.shop];
    shop.placeholder = WSText(@"Workshop or dealer");
    WSFormRow *notes = [WSFormRow type:WSFormRowTextArea key:@"notes" title:WSText(@"Remarks") value:d.notes];
    notes.placeholder = WSText(@"Parts, part numbers, warranty…");
    WSFormSection *what = [WSFormSection title:nil rows:@[category, name, items]];
    what.footer = WSText(@"Selecting items resets their maintenance plan from this service.");
    return @[what, [WSFormSection title:WSText(@"Details") rows:@[date, odo, cost, shop]], [WSFormSection title:nil rows:@[notes]]];
}

- (BOOL)save {
    ServiceDraft *d = [ServiceDraft draftFromRecord:self.record vehicle:self.vehicle];
    d.category = (ServiceCategory)[[self formValueForKey:@"category"] integerValue];
    d.title = [self stringForKey:@"title"];
    d.itemKeys = self.itemKeys;
    d.date = [self formValueForKey:@"date"] ?: NSDate.date;
    double odo = [GarageManager parseNumber:[self stringForKey:@"odometer"]];
    d.odometer = isnan(odo) ? NAN : [GarageManager kmFromDisplay:odo];
    d.cost = [GarageManager parseNumber:[self stringForKey:@"cost"]];
    d.shop = [self stringForKey:@"shop"]; d.notes = [self stringForKey:@"notes"];
    if (!d.title.length && !d.itemKeys.count) d.title = ServiceCategoryTitles()[d.category];
    NSError *error = nil;
    BOOL ok = self.record ? [GarageManager.shared updateService:self.record with:d error:&error]
                          : [GarageManager.shared addService:d to:self.vehicle error:&error] != nil;
    if (!ok) [self ws_showError:error];
    return ok;
}

@end

#pragma mark - Fuel

@interface FuelEditViewController ()
@property (nonatomic, strong) Vehicle *vehicle;
@property (nonatomic, strong, nullable) FuelLog *log;
@end

@implementation FuelEditViewController

- (instancetype)initWithVehicle:(Vehicle *)vehicle log:(FuelLog *)log {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _vehicle = vehicle; _log = log;
        self.title = log ? WSText(@"Edit Refuel") : WSText(@"Add Refuel");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    FuelDraft *d = [FuelDraft draftFromLog:self.log vehicle:self.vehicle];
    WSFormRow *date = [WSFormRow type:WSFormRowDate key:@"date" title:WSText(@"Date") value:d.date];
    date.dateMode = UIDatePickerModeDateAndTime;
    date.dateRequired = YES;
    WSFormRow *odo = GENumberRow(@"odometer", GEOdometerTitle(), [GarageManager displayFromKm:d.odometer], 0, WSText(@"Mileage at the pump"));
    WSFormRow *volume = GENumberRow(@"volume", WSText(@"Volume (L)"), d.volume, 2, @"0");
    WSFormRow *cost = GENumberRow(@"cost", WSText(@"Total Cost"), d.cost, 2, @"0");
    WSFormRow *full = [WSFormRow type:WSFormRowToggle key:@"full" title:WSText(@"Filled the Tank") value:@(d.isFullTank)];
    WSFormRow *station = [WSFormRow type:WSFormRowText key:@"station" title:WSText(@"Station") value:d.station];
    WSFormSection *main = [WSFormSection title:nil rows:@[date, odo, volume, cost, full]];
    main.footer = WSText(@"Fuel economy is calculated between two full tanks.");
    return @[main, [WSFormSection title:nil rows:@[station]]];
}

- (BOOL)save {
    FuelDraft *d = [FuelDraft draftFromLog:self.log vehicle:self.vehicle];
    d.date = [self formValueForKey:@"date"] ?: NSDate.date;
    double odo = [GarageManager parseNumber:[self stringForKey:@"odometer"]];
    d.odometer = isnan(odo) ? NAN : [GarageManager kmFromDisplay:odo];
    d.volume = [GarageManager parseNumber:[self stringForKey:@"volume"]];
    d.cost = [GarageManager parseNumber:[self stringForKey:@"cost"]];
    d.isFullTank = [[self formValueForKey:@"full"] boolValue];
    d.station = [self stringForKey:@"station"];
    NSError *error = nil;
    BOOL ok = self.log ? [GarageManager.shared updateFuel:self.log with:d error:&error]
                       : [GarageManager.shared addFuel:d to:self.vehicle error:&error] != nil;
    if (!ok) [self ws_showError:error];
    return ok;
}

@end

#pragma mark - Plan

@interface PlanEditViewController ()
@property (nonatomic, strong) MaintenancePlan *plan;
@end

@implementation PlanEditViewController

- (instancetype)initWithPlan:(MaintenancePlan *)plan {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _plan = plan;
        self.title = [GarageCatalog itemForKey:plan.itemKey].name ?: WSText(@"Maintenance Plan");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    MaintenancePlan *p = self.plan;
    GarageItem *item = [GarageCatalog itemForKey:p.itemKey];
    WSFormRow *enabled = [WSFormRow type:WSFormRowToggle key:@"enabled" title:WSText(@"Track This Item") value:@(p.enabled)];
    NSString *km = [NSString stringWithFormat:@"%@ (%@)", WSText(@"Every"), GarageManager.distanceUnit];
    WSFormRow *intervalKm = GENumberRow(@"km", km, round([GarageManager displayFromKm:p.intervalKm]), 0, WSText(@"No mileage interval"));
    WSFormRow *months = GENumberRow(@"months", WSText(@"Every (months)"), p.intervalMonths, 0, WSText(@"No time interval"));
    WSFormRow *lastOdo = GENumberRow(@"lastOdo", [NSString stringWithFormat:@"%@ (%@)", WSText(@"Last Done At"), GarageManager.distanceUnit],
                                     [GarageManager displayFromKm:p.lastOdometer], 0, @"0");
    WSFormRow *lastDate = [WSFormRow type:WSFormRowDate key:@"lastDate" title:WSText(@"Last Done On") value:p.lastDate];
    lastDate.dateMode = UIDatePickerModeDate;
    WSFormSection *interval = [WSFormSection title:WSText(@"Interval") rows:@[intervalKm, months]];
    if (item) {
        NSMutableArray *rec = NSMutableArray.new;
        if (item.intervalKm > 0) [rec addObject:[GarageManager formatDistance:item.intervalKm]];
        if (item.intervalMonths > 0) [rec addObject:[NSString stringWithFormat:WSText(@"%ld months"), (long)item.intervalMonths]];
        interval.footer = [NSString stringWithFormat:WSText(@"Recommended: %@. Whichever comes first. Always check your owner's manual."),
                           [rec componentsJoinedByString:@" / "]];
    }
    return @[[WSFormSection title:nil rows:@[enabled]], interval,
             [WSFormSection title:WSText(@"Last Service") rows:@[lastOdo, lastDate]]];
}

- (BOOL)save {
    double km = [GarageManager parseNumber:[self stringForKey:@"km"]];
    double months = [GarageManager parseNumber:[self stringForKey:@"months"]];
    double lastOdo = [GarageManager parseNumber:[self stringForKey:@"lastOdo"]];
    if (isnan(months) || months != floor(months)) months = -1;
    NSError *error = nil;
    BOOL ok = [GarageManager.shared updatePlan:self.plan
                                    intervalKm:isnan(km) ? NAN : [GarageManager kmFromDisplay:km]
                                        months:(NSInteger)months
                                  lastOdometer:isnan(lastOdo) ? NAN : [GarageManager kmFromDisplay:lastOdo]
                                      lastDate:[self formValueForKey:@"lastDate"]
                                       enabled:[[self formValueForKey:@"enabled"] boolValue]
                                         error:&error];
    if (!ok) [self ws_showError:error];
    return ok;
}

@end

#pragma mark - Item picker

@interface GarageItemPickerViewController ()
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *selected;
@property (nonatomic, copy) void (^completion)(NSArray<NSString *> *);
@end

@implementation GarageItemPickerViewController

- (instancetype)initWithSelected:(NSArray<NSString *> *)keys completion:(void (^)(NSArray<NSString *> *))completion {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _selected = [NSMutableOrderedSet orderedSetWithArray:keys];
        _completion = [completion copy];
        self.title = WSText(@"Items Serviced");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"item"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Keep catalog order regardless of tap order.
    NSArray *order = [GarageCatalog.items valueForKey:@"key"];
    NSArray *keys = [self.selected.array sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return [@([order indexOfObject:a]) compare:@([order indexOfObject:b])];
    }];
    if (self.completion) self.completion(keys);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return GarageCatalog.items.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    GarageItem *item = GarageCatalog.items[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"item" forIndexPath:indexPath];
    UIListContentConfiguration *c = UIListContentConfiguration.cellConfiguration;
    c.text = item.name;
    c.textProperties.font = t.fontBody;
    c.image = [UIImage ws_symbol:item.symbol];
    c.imageProperties.tintColor = t.accent;
    cell.contentConfiguration = c;
    cell.backgroundColor = t.surface;
    cell.accessoryType = [self.selected containsObject:item.key] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *key = GarageCatalog.items[indexPath.row].key;
    if ([self.selected containsObject:key]) [self.selected removeObject:key]; else [self.selected addObject:key];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
