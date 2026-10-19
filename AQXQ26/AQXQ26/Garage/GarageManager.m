//
//  GarageManager.m
//  WorkSpace
//

#import "GarageManager.h"
#import "GarageCatalog.h"
#import "Vehicle.h"
#import "ServiceRecord.h"
#import "FuelLog.h"
#import "MaintenancePlan.h"
#import "DataManager.h"
#import "TaskManager.h"
#import "Task.h"
#import "AppConstants.h"
#import "TripManager.h"

static NSString * const kCurrentVehicleKey = @"garage.currentVehicle";
static NSString * const kUsesMilesKey = @"garage.usesMiles";
static const double kKmPerMile = 1.609344;

#pragma mark - Value objects

@implementation PlanStatus
- (BOOL)isOverdue { return self.health <= 0; }
- (BOOL)isDueSoon { return self.health < 0.15; }
- (NSString *)remainingText {
    NSMutableArray *parts = NSMutableArray.new;
    if (!isnan(self.remainingKm)) {
        double km = self.remainingKm;
        NSString *d = [GarageManager formatDistance:fabs(km)];
        [parts addObject:km < 0 ? [NSString stringWithFormat:WSText(@"%@ over"), d] : [NSString stringWithFormat:WSText(@"%@ left"), d]];
    }
    if (self.remainingDays != NSIntegerMax) {
        NSInteger days = self.remainingDays;
        NSString *d = labs(days) >= 60 ? [NSString stringWithFormat:WSText(@"%ld mo"), (long)(labs(days) / 30)]
                                        : [NSString stringWithFormat:WSText(@"%ld d"), (long)labs(days)];
        [parts addObject:days < 0 ? [NSString stringWithFormat:WSText(@"%@ over"), d] : [NSString stringWithFormat:WSText(@"%@ left"), d]];
    }
    return parts.count ? [parts componentsJoinedByString:@" · "] : WSText(@"Not scheduled");
}
@end

@implementation GarageStats
@end

@implementation GarageTimelineEntry
@end

@implementation VehicleDraft
+ (instancetype)draftFromVehicle:(Vehicle *)v {
    VehicleDraft *d = self.new;
    d.name = v.name ?: @"";
    d.make = v.make; d.model = v.model; d.plate = v.plate; d.vin = v.vin; d.notes = v.notes;
    d.year = v ? v.year : (int16_t)[NSCalendar.currentCalendar component:NSCalendarUnitYear fromDate:NSDate.date];
    d.odometer = v.odometer;
    d.fuelType = v.fuelType;
    d.colorIdentifier = v.colorIdentifier ?: @"indigo";
    d.purchaseDate = v.purchaseDate; d.insuranceDue = v.insuranceDue; d.inspectionDue = v.inspectionDue;
    return d;
}
@end

@implementation ServiceDraft
+ (instancetype)draftFromRecord:(ServiceRecord *)r vehicle:(Vehicle *)vehicle {
    ServiceDraft *d = self.new;
    d.category = r ? r.category : ServiceCategoryMaintenance;
    d.title = r.title ?: @"";
    d.itemKeys = r.itemKeys.length ? [r.itemKeys componentsSeparatedByString:@","] : @[];
    d.date = r.date ?: NSDate.date;
    d.odometer = r ? r.odometer : vehicle.odometer;
    d.cost = r.cost;
    d.shop = r.shop; d.notes = r.notes;
    return d;
}
@end

@implementation FuelDraft
+ (instancetype)draftFromLog:(FuelLog *)l vehicle:(Vehicle *)vehicle {
    FuelDraft *d = self.new;
    d.date = l.date ?: NSDate.date;
    d.odometer = l ? l.odometer : vehicle.odometer;
    d.volume = l.volume; d.cost = l.cost;
    d.isFullTank = l ? l.isFullTank : YES;
    d.station = l.station;
    return d;
}
@end

@implementation GarageManager

+ (instancetype)shared {
    static GarageManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}

- (NSError *)errorWith:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (NSString *)trim:(NSString *)s {
    NSString *t = [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return t.length ? t : nil;
}

#pragma mark - Vehicles

- (NSArray<Vehicle *> *)vehicles {
    NSFetchRequest *r = [Vehicle fetchRequest];
    r.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:YES],
                          [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    return [DataManager.shared fetch:r];
}

- (Vehicle *)currentVehicle {
    NSString *uuid = [NSUserDefaults.standardUserDefaults stringForKey:kCurrentVehicleKey];
    NSArray *all = self.vehicles;
    for (Vehicle *v in all) if ([v.uuid isEqualToString:uuid]) return v;
    return all.firstObject;
}

- (void)setCurrentVehicle:(Vehicle *)vehicle {
    [NSUserDefaults.standardUserDefaults setObject:vehicle.uuid forKey:kCurrentVehicleKey];
}

- (BOOL)validateVehicle:(VehicleDraft *)d error:(NSError **)error {
    if (![self trim:d.name]) { if (error) *error = [self errorWith:WSText(@"Please enter a name for the vehicle.")]; return NO; }
    if (d.odometer < 0 || isnan(d.odometer)) { if (error) *error = [self errorWith:WSText(@"Mileage can't be negative.")]; return NO; }
    return YES;
}

- (void)apply:(VehicleDraft *)d to:(Vehicle *)v {
    v.name = [self trim:d.name];
    v.make = [self trim:d.make]; v.model = [self trim:d.model];
    v.plate = [[self trim:d.plate] uppercaseString]; v.vin = [[self trim:d.vin] uppercaseString];
    v.notes = [self trim:d.notes];
    v.year = d.year; v.odometer = d.odometer; v.fuelType = d.fuelType;
    v.colorIdentifier = d.colorIdentifier ?: @"indigo";
    v.purchaseDate = d.purchaseDate; v.insuranceDue = d.insuranceDue; v.inspectionDue = d.inspectionDue;
    v.updatedAt = NSDate.date;
}

- (Vehicle *)createVehicle:(VehicleDraft *)d error:(NSError **)error {
    if (![self validateVehicle:d error:error]) return nil;
    Vehicle *v = [DataManager.shared insertEntity:@"Vehicle"];
    [self apply:d to:v];
    v.sortIndex = self.vehicles.count;
    // Default plans start from the current odometer / today, so a new car isn't instantly "overdue".
    for (GarageItem *item in GarageCatalog.items) {
        if (!item.defaultPlan) continue;
        if (d.fuelType == VehicleFuelDiesel && [item.key isEqualToString:@"spark_plugs"]) continue;
        [self insertPlanFor:item vehicle:v];
    }
    if (![DataManager.shared save:error]) return nil;
    self.currentVehicle = v;
    return v;
}

- (BOOL)updateVehicle:(Vehicle *)v with:(VehicleDraft *)d error:(NSError **)error {
    if (![self validateVehicle:d error:error]) return NO;
    [self apply:d to:v];
    return [DataManager.shared save:error];
}

- (BOOL)deleteVehicle:(Vehicle *)v error:(NSError **)error {
    for (MaintenancePlan *p in v.plans) [self removeReminderTaskOf:p];
    [DataManager.shared deleteObject:v];
    return [DataManager.shared save:error];
}

- (BOOL)updateOdometer:(double)odometer forVehicle:(Vehicle *)v error:(NSError **)error {
    if (isnan(odometer) || odometer < 0) { if (error) *error = [self errorWith:WSText(@"Please enter a valid mileage.")]; return NO; }
    v.odometer = odometer;
    v.updatedAt = NSDate.date;
    return [DataManager.shared save:error];
}

/// The odometer only moves forward with new records; editing older entries never lowers it.
- (void)bumpOdometer:(double)odometer of:(Vehicle *)v {
    if (odometer > v.odometer) v.odometer = odometer;
}

#pragma mark - Records

- (NSArray<GarageTimelineEntry *> *)timelineFor:(Vehicle *)v limit:(NSUInteger)limit {
    NSMutableArray *entries = NSMutableArray.new;
    NSArray *titles = ServiceCategoryTitles();
    for (ServiceRecord *r in v.records) {
        GarageTimelineEntry *e = GarageTimelineEntry.new;
        e.object = r; e.date = r.date; e.odometer = r.odometer; e.cost = r.cost; e.category = r.category;
        e.title = r.title.length ? r.title : titles[MIN((NSUInteger)MAX(r.category, 0), titles.count - 1)];
        e.subtitle = r.shop;
        [entries addObject:e];
    }
    for (FuelLog *l in v.fuelLogs) {
        GarageTimelineEntry *e = GarageTimelineEntry.new;
        e.object = l; e.date = l.date; e.odometer = l.odometer; e.cost = l.cost; e.category = ServiceCategoryFuelChart;
        e.title = WSText(@"Refuel");
        e.subtitle = [NSString stringWithFormat:@"%@ L%@", [GarageManager formatNumber:l.volume digits:1],
                      l.station.length ? [@" · " stringByAppendingString:l.station] : @""];
        [entries addObject:e];
    }
    [entries sortUsingComparator:^NSComparisonResult(GarageTimelineEntry *a, GarageTimelineEntry *b) {
        NSComparisonResult r = [b.date compare:a.date];
        return r != NSOrderedSame ? r : (a.odometer < b.odometer ? NSOrderedDescending : NSOrderedAscending);
    }];
    if (limit && entries.count > limit) return [entries subarrayWithRange:NSMakeRange(0, limit)];
    return entries;
}

- (BOOL)validateAmounts:(double)odometer cost:(double)cost error:(NSError **)error {
    if (isnan(odometer) || odometer < 0) { if (error) *error = [self errorWith:WSText(@"Please enter a valid mileage.")]; return NO; }
    if (isnan(cost) || cost < 0) { if (error) *error = [self errorWith:WSText(@"Please enter a valid amount.")]; return NO; }
    return YES;
}

- (void)apply:(ServiceDraft *)d toRecord:(ServiceRecord *)r {
    r.category = d.category;
    r.title = [self trim:d.title] ?: @"";
    r.itemKeys = d.itemKeys.count ? [d.itemKeys componentsJoinedByString:@","] : nil;
    r.date = d.date ?: NSDate.date;
    r.odometer = d.odometer; r.cost = d.cost;
    r.shop = [self trim:d.shop]; r.notes = [self trim:d.notes];
    r.updatedAt = NSDate.date;
}

/// A service that covers catalog items resets those plans, if it is the newest one for the item.
- (void)resetPlansFrom:(ServiceRecord *)r vehicle:(Vehicle *)v {
    if (!r.itemKeys.length) return;
    NSSet *keys = [NSSet setWithArray:[r.itemKeys componentsSeparatedByString:@","]];
    for (MaintenancePlan *p in v.plans) {
        if (![keys containsObject:p.itemKey]) continue;
        if (p.lastDate && [p.lastDate compare:r.date] == NSOrderedDescending) continue;
        p.lastDate = r.date; p.lastOdometer = r.odometer; p.updatedAt = NSDate.date;
        [self completeReminderTaskOf:p];
    }
}

- (ServiceRecord *)addService:(ServiceDraft *)d to:(Vehicle *)v error:(NSError **)error {
    if (![self validateAmounts:d.odometer cost:d.cost error:error]) return nil;
    ServiceRecord *r = [DataManager.shared insertEntity:@"ServiceRecord"];
    r.vehicle = v;
    [self apply:d toRecord:r];
    [self bumpOdometer:r.odometer of:v];
    [self resetPlansFrom:r vehicle:v];
    return [DataManager.shared save:error] ? r : nil;
}

- (BOOL)updateService:(ServiceRecord *)r with:(ServiceDraft *)d error:(NSError **)error {
    if (![self validateAmounts:d.odometer cost:d.cost error:error]) return NO;
    [self apply:d toRecord:r];
    [self bumpOdometer:r.odometer of:r.vehicle];
    [self resetPlansFrom:r vehicle:r.vehicle];
    return [DataManager.shared save:error];
}

- (FuelLog *)addFuel:(FuelDraft *)d to:(Vehicle *)v error:(NSError **)error {
    if (![self validateFuel:d error:error]) return nil;
    FuelLog *l = [DataManager.shared insertEntity:@"FuelLog"];
    l.vehicle = v;
    [self apply:d toLog:l];
    [self bumpOdometer:l.odometer of:v];
    return [DataManager.shared save:error] ? l : nil;
}

- (BOOL)updateFuel:(FuelLog *)l with:(FuelDraft *)d error:(NSError **)error {
    if (![self validateFuel:d error:error]) return NO;
    [self apply:d toLog:l];
    [self bumpOdometer:l.odometer of:l.vehicle];
    return [DataManager.shared save:error];
}

- (BOOL)validateFuel:(FuelDraft *)d error:(NSError **)error {
    if (![self validateAmounts:d.odometer cost:d.cost error:error]) return NO;
    if (isnan(d.volume) || d.volume <= 0) { if (error) *error = [self errorWith:WSText(@"Please enter the fuel volume.")]; return NO; }
    return YES;
}

- (void)apply:(FuelDraft *)d toLog:(FuelLog *)l {
    l.date = d.date ?: NSDate.date;
    l.odometer = d.odometer; l.volume = d.volume; l.cost = d.cost; l.isFullTank = d.isFullTank;
    l.station = [self trim:d.station];
    l.updatedAt = NSDate.date;
}

- (BOOL)deleteEntry:(id)entry error:(NSError **)error {
    [DataManager.shared deleteObject:entry];
    return [DataManager.shared save:error];
}

#pragma mark - Plans

- (MaintenancePlan *)insertPlanFor:(GarageItem *)item vehicle:(Vehicle *)v {
    MaintenancePlan *p = [DataManager.shared insertEntity:@"MaintenancePlan"];
    p.itemKey = item.key;
    p.intervalKm = item.intervalKm;
    p.intervalMonths = (int16_t)item.intervalMonths;
    p.lastOdometer = v.odometer;
    p.lastDate = NSDate.date;
    p.enabled = YES;
    p.vehicle = v;
    return p;
}

- (NSArray<MaintenancePlan *> *)allPlansFor:(Vehicle *)v {
    NSArray *order = [GarageCatalog.items valueForKey:@"key"];
    return [v.plans.allObjects sortedArrayUsingComparator:^NSComparisonResult(MaintenancePlan *a, MaintenancePlan *b) {
        NSUInteger ia = [order indexOfObject:a.itemKey], ib = [order indexOfObject:b.itemKey];
        return ia < ib ? NSOrderedAscending : (ia > ib ? NSOrderedDescending : NSOrderedSame);
    }];
}

- (PlanStatus *)statusForPlan:(MaintenancePlan *)p {
    PlanStatus *s = PlanStatus.new;
    s.plan = p;
    s.item = [GarageCatalog itemForKey:p.itemKey];
    double health = 1;
    s.remainingKm = NAN;
    s.remainingDays = NSIntegerMax;
    if (p.intervalKm > 0) {
        s.dueOdometer = p.lastOdometer + p.intervalKm;
        s.remainingKm = s.dueOdometer - p.vehicle.odometer;
        health = MIN(health, s.remainingKm / p.intervalKm);
    }
    if (p.intervalMonths > 0) {
        NSDate *last = p.lastDate ?: p.createdAt ?: NSDate.date;
        NSCalendar *cal = NSCalendar.currentCalendar;
        s.dueDate = [cal dateByAddingUnit:NSCalendarUnitMonth value:p.intervalMonths toDate:last options:0];
        s.remainingDays = [cal components:NSCalendarUnitDay fromDate:[cal startOfDayForDate:NSDate.date]
                                   toDate:[cal startOfDayForDate:s.dueDate] options:0].day;
        double total = MAX(1.0, [s.dueDate timeIntervalSinceDate:last]);
        health = MIN(health, [s.dueDate timeIntervalSinceNow] / total);
    }
    s.health = MAX(0, MIN(1, health));
    return s;
}

- (NSArray<PlanStatus *> *)planStatusesFor:(Vehicle *)v {
    NSMutableArray *list = NSMutableArray.new;
    for (MaintenancePlan *p in v.plans) if (p.enabled) [list addObject:[self statusForPlan:p]];
    [list sortUsingComparator:^NSComparisonResult(PlanStatus *a, PlanStatus *b) {
        return a.health < b.health ? NSOrderedAscending : (a.health > b.health ? NSOrderedDescending : NSOrderedSame);
    }];
    return list;
}

- (double)healthFor:(Vehicle *)v {
    NSArray *statuses = [self planStatusesFor:v];
    if (!statuses.count) return 1;
    double sum = 0, weight = 0;
    for (PlanStatus *s in statuses) {
        double w = s.isOverdue ? 2 : 1;
        sum += s.health * w; weight += w;
    }
    return sum / weight;
}

- (MaintenancePlan *)addPlanForItem:(NSString *)key to:(Vehicle *)v error:(NSError **)error {
    GarageItem *item = [GarageCatalog itemForKey:key];
    if (!item) { if (error) *error = [self errorWith:WSText(@"Unknown maintenance item.")]; return nil; }
    for (MaintenancePlan *p in v.plans) {
        if ([p.itemKey isEqualToString:key]) {
            p.enabled = YES;
            return [DataManager.shared save:error] ? p : nil;
        }
    }
    MaintenancePlan *p = [self insertPlanFor:item vehicle:v];
    return [DataManager.shared save:error] ? p : nil;
}

- (BOOL)updatePlan:(MaintenancePlan *)p intervalKm:(double)km months:(NSInteger)months
      lastOdometer:(double)lastOdometer lastDate:(NSDate *)lastDate enabled:(BOOL)enabled error:(NSError **)error {
    if (isnan(km) || km < 0 || months < 0 || months > 240 || isnan(lastOdometer) || lastOdometer < 0) {
        if (error) *error = [self errorWith:WSText(@"Please enter valid intervals.")];
        return NO;
    }
    if (km == 0 && months == 0) {
        if (error) *error = [self errorWith:WSText(@"Set a mileage or time interval.")];
        return NO;
    }
    p.intervalKm = km; p.intervalMonths = (int16_t)months;
    p.lastOdometer = lastOdometer; p.lastDate = lastDate;
    p.enabled = enabled;
    p.updatedAt = NSDate.date;
    if (!enabled) [self removeReminderTaskOf:p];
    return [DataManager.shared save:error];
}

- (BOOL)deletePlan:(MaintenancePlan *)p error:(NSError **)error {
    [self removeReminderTaskOf:p];
    [DataManager.shared deleteObject:p];
    return [DataManager.shared save:error];
}

- (BOOL)markPlanDone:(MaintenancePlan *)p cost:(double)cost error:(NSError **)error {
    Vehicle *v = p.vehicle;
    GarageItem *item = [GarageCatalog itemForKey:p.itemKey];
    ServiceDraft *d = [ServiceDraft draftFromRecord:nil vehicle:v];
    d.title = item.name ?: @"";
    d.itemKeys = @[p.itemKey];
    d.cost = isnan(cost) ? 0 : cost;
    return [self addService:d to:v error:error] != nil;
}

#pragma mark - Tasks integration

- (Task *)openTaskWithId:(NSString *)uuid {
    if (!uuid) return nil;
    Task *t = [DataManager.shared objectOfKind:WSObjectKindTask uuid:uuid];
    return (t && t.status != TaskStatusCompleted && t.status != TaskStatusCancelled) ? t : nil;
}

- (Task *)reminderTaskForPlan:(MaintenancePlan *)p error:(NSError **)error {
    Task *existing = [self openTaskWithId:p.taskId];
    if (existing) return existing;
    PlanStatus *s = [self statusForPlan:p];
    TaskDraft *d = [TaskDraft draftFromTask:nil];
    d.title = [NSString stringWithFormat:@"%@ · %@", s.item.name ?: p.itemKey, p.vehicle.name];
    d.category = WSText(@"Car");
    d.priority = s.isOverdue ? TaskPriorityHigh : TaskPriorityMedium;
    NSDate *due = s.dueDate;
    if (!due || [due compare:NSDate.date] == NSOrderedAscending) {
        due = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:NSDate.date options:0];
    }
    d.dueDate = due;
    NSMutableArray *lines = NSMutableArray.new;
    if (s.dueOdometer > 0) [lines addObject:[NSString stringWithFormat:WSText(@"Due at %@"), [GarageManager formatDistance:s.dueOdometer]]];
    [lines addObject:s.remainingText];
    if (s.item.summary) [lines addObject:s.item.summary];
    d.detail = [lines componentsJoinedByString:@"\n"];
    d.checklistTitles = s.item.tips ?: @[];
    Task *task = [TaskManager.shared createTask:d error:error];
    if (!task) return nil;
    p.taskId = task.uuid;
    [DataManager.shared save:nil];
    return task;
}

- (void)completeReminderTaskOf:(MaintenancePlan *)p {
    Task *t = [self openTaskWithId:p.taskId];
    if (t) [TaskManager.shared setStatus:TaskStatusCompleted forTask:t error:nil];
    p.taskId = nil;
}

/// Plans that go away take their unfinished reminder with them.
- (void)removeReminderTaskOf:(MaintenancePlan *)p {
    Task *t = [self openTaskWithId:p.taskId];
    if (t) [TaskManager.shared deleteTask:t error:nil];
    p.taskId = nil;
}

- (Task *)taskFromChecklistAt:(NSUInteger)index vehicle:(Vehicle *)v error:(NSError **)error {
    NSArray *lists = GarageCatalog.checklists;
    if (index >= lists.count) return nil;
    GarageChecklist *c = lists[index];
    TaskDraft *d = [TaskDraft draftFromTask:nil];
    d.title = v ? [NSString stringWithFormat:@"%@ · %@", c.name, v.name] : c.name;
    d.detail = c.summary;
    d.category = WSText(@"Car");
    d.checklistTitles = c.items;
    return [TaskManager.shared createTask:d error:error];
}

#pragma mark - Stats

- (GarageStats *)statsFor:(Vehicle *)v months:(NSInteger)months {
    GarageStats *s = GarageStats.new;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *now = NSDate.date;
    NSDate *thisMonth = [cal dateFromComponents:[cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:now]];
    NSDate *from = months > 0 ? [cal dateByAddingUnit:NSCalendarUnitMonth value:-(months - 1) toDate:thisMonth options:0] : nil;
    NSDate *chartFrom = [cal dateByAddingUnit:NSCalendarUnitMonth value:-11 toDate:thisMonth options:0];

    double serviceBuf[12] = {0}, fuelBuf[12] = {0};
    double *service = serviceBuf, *fuel = fuelBuf;   // blocks can't capture C arrays, pointers are fine
    NSMutableDictionary<NSNumber *, NSNumber *> *byCategory = NSMutableDictionary.new;
    double minOdo = DBL_MAX, maxOdo = 0;
    void (^track)(NSDate *, double, double, NSInteger, BOOL) = ^(NSDate *date, double odometer, double cost, NSInteger category, BOOL isFuel) {
        if ([date compare:chartFrom] != NSOrderedAscending) {
            NSInteger idx = [cal components:NSCalendarUnitMonth fromDate:chartFrom toDate:date options:0].month;
            if (idx >= 0 && idx < 12) { if (isFuel) fuel[idx] += cost; else service[idx] += cost; }
        }
    };
    for (ServiceRecord *r in v.records) {
        track(r.date, r.odometer, r.cost, r.category, NO);
        if (from && [r.date compare:from] == NSOrderedAscending) continue;
        s.serviceCost += r.cost;
        byCategory[@(r.category)] = @(byCategory[@(r.category)].doubleValue + r.cost);
    }
    NSArray *logs = [v.fuelLogs.allObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"odometer" ascending:YES]]];
    for (FuelLog *l in logs) {
        track(l.date, l.odometer, l.cost, ServiceCategoryFuelChart, YES);
        if (from && [l.date compare:from] == NSOrderedAscending) continue;
        s.fuelCost += l.cost;
        minOdo = MIN(minOdo, l.odometer); maxOdo = MAX(maxOdo, l.odometer);
    }
    if (s.fuelCost > 0) byCategory[@(ServiceCategoryFuelChart)] = @(s.fuelCost);
    s.totalCost = s.serviceCost + s.fuelCost;

    NSMutableArray *monthly = NSMutableArray.new;
    for (NSInteger i = 0; i < 12; i++) {
        [monthly addObject:@{@"month": [cal dateByAddingUnit:NSCalendarUnitMonth value:i toDate:chartFrom options:0],
                             @"service": @(service[i]), @"fuel": @(fuel[i])}];
    }
    s.monthly = monthly;

    NSMutableArray *cats = NSMutableArray.new;
    [byCategory enumerateKeysAndObjectsUsingBlock:^(NSNumber *k, NSNumber *amount, BOOL *stop) {
        if (amount.doubleValue > 0) [cats addObject:@{@"category": k, @"amount": amount}];
    }];
    [cats sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"amount" ascending:NO]]];
    s.byCategory = cats;

    // Full-tank method: fuel added since the previous full tank / distance since it.
    NSMutableArray *consumption = NSMutableArray.new;
    FuelLog *lastFull = nil;
    double pending = 0, litres = 0, distance = 0;
    for (FuelLog *l in logs) {
        if (!lastFull) { if (l.isFullTank) lastFull = l; continue; }
        pending += l.volume;
        if (!l.isFullTank) continue;
        double km = l.odometer - lastFull.odometer;
        if (km > 0) {
            double value = pending / km * 100;
            if (value > 1 && value < 40) {   // ignore typos (e.g. a missed refuel)
                [consumption addObject:@{@"date": l.date, @"value": @(value)}];
                if (!from || [l.date compare:from] != NSOrderedAscending) { litres += pending; distance += km; }
            }
        }
        pending = 0; lastFull = l;
    }
    s.consumption = consumption;
    s.averageConsumption = distance > 0 ? litres / distance * 100 : 0;
    s.distance = maxOdo > minOdo && minOdo != DBL_MAX ? maxOdo - minOdo : 0;
    s.costPerKm = s.distance > 0 ? s.totalCost / s.distance : 0;
    return s;
}

- (NSArray<PlanStatus *> *)upcomingAcrossVehicles:(NSUInteger)limit {
    NSMutableArray *all = NSMutableArray.new;
    for (Vehicle *v in self.vehicles) [all addObjectsFromArray:[self planStatusesFor:v]];
    [all sortUsingComparator:^NSComparisonResult(PlanStatus *a, PlanStatus *b) {
        return a.health < b.health ? NSOrderedAscending : (a.health > b.health ? NSOrderedDescending : NSOrderedSame);
    }];
    return all.count > limit ? [all subarrayWithRange:NSMakeRange(0, limit)] : all;
}

#pragma mark - Sample data

/// A realistic year of ownership: monthly refuels, periodic services and a few one-off costs.
/// Everything is ordinary editable data; deleting the vehicle removes it.
- (BOOL)createSampleGarage:(NSError **)error {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *today = [cal startOfDayForDate:NSDate.date];
    NSDate *(^ago)(NSInteger) = ^NSDate *(NSInteger days) {
        return [cal dateByAddingUnit:NSCalendarUnitDay value:-days toDate:today options:0];
    };
    const NSInteger spanDays = 420;
    const double startOdo = 38200, kmPerDay = 36.5;
    double (^odoAt)(NSInteger) = ^double(NSInteger days) { return round(startOdo + (spanDays - days) * kmPerDay); };

    VehicleDraft *d = [VehicleDraft draftFromVehicle:nil];
    d.name = WSText(@"My Sedan");
    d.make = @"Toyota"; d.model = @"Corolla"; d.year = 2021;
    d.plate = WSText(@"SAMPLE-01");
    d.fuelType = VehicleFuelGasoline;
    d.colorIdentifier = @"sky";
    d.odometer = odoAt(0);
    d.purchaseDate = ago(spanDays + 400);
    d.insuranceDue = [cal dateByAddingUnit:NSCalendarUnitDay value:24 toDate:today options:0];
    d.inspectionDue = [cal dateByAddingUnit:NSCalendarUnitMonth value:5 toDate:today options:0];
    d.notes = WSText(@"Sample vehicle. Edit or delete it any time.");
    Vehicle *v = [DataManager.shared insertEntity:@"Vehicle"];
    [self apply:d to:v];
    v.sortIndex = self.vehicles.count;

    // Refuel roughly every 14 days; every 5th is a partial top-up.
    double price = 7.6;
    for (NSInteger day = spanDays, n = 0; day >= 3; day -= 13 + (n % 3), n++) {
        FuelLog *l = [DataManager.shared insertEntity:@"FuelLog"];
        l.vehicle = v;
        l.date = [ago(day) dateByAddingTimeInterval:8 * 3600 + (n % 5) * 1800];
        l.odometer = odoAt(day);
        l.isFullTank = n % 5 != 4;
        double consumption = 6.4 + 0.6 * sin(n * 0.7) + (n % 4 == 0 ? 0.5 : 0);  // L/100km, seasonal wobble
        l.volume = round((l.isFullTank ? 470 : 230) * consumption / 100 * 10) / 10;
        price = 7.3 + 0.5 * sin(n * 0.35);
        l.cost = round(l.volume * price * 100) / 100;
        l.station = @[WSText(@"Sinopec"), WSText(@"PetroChina"), WSText(@"Shell")][n % 3];
    }

    NSArray *services = @[
        @[@400, @(ServiceCategoryMaintenance), @"Oil Service", @"oil,oil_filter", @420, @"AutoCare Center"],
        @[@330, @(ServiceCategoryWash), @"Detail Wash", @"", @80, @"Sparkle Car Wash"],
        @[@300, @(ServiceCategoryInsurance), @"Annual Insurance", @"", @4200, @""],
        @[@250, @(ServiceCategoryMaintenance), @"Oil Service", @"oil,oil_filter,cabin_filter", @560, @"AutoCare Center"],
        @[@210, @(ServiceCategoryTires), @"Tire Rotation", @"tire_rotation", @120, @"Tire Pro"],
        @[@170, @(ServiceCategoryParking), @"Parking & Tolls", @"", @260, @""],
        @[@140, @(ServiceCategoryRepair), @"Replace Wiper Blades", @"wipers", @150, @"AutoCare Center"],
        @[@120, @(ServiceCategoryMaintenance), @"Major Service", @"oil,oil_filter,air_filter,battery", @980, @"AutoCare Center"],
        @[@60,  @(ServiceCategoryWash), @"Car Wash", @"", @45, @"Sparkle Car Wash"],
        @[@35,  @(ServiceCategoryRepair), @"Front Brake Pads", @"brake_pads", @680, @"Brake & More"],
        @[@12,  @(ServiceCategoryParking), @"Parking & Tolls", @"", @95, @""],
    ];

    // Default plans, starting at purchase so the sample shows a realistic mix of states.
    for (GarageItem *item in GarageCatalog.items) {
        if (!item.defaultPlan) continue;
        MaintenancePlan *p = [self insertPlanFor:item vehicle:v];
        p.lastDate = ago(spanDays);
        p.lastOdometer = startOdo;
    }
    for (NSArray *row in services) {
        NSInteger day = [row[0] integerValue];
        ServiceDraft *sd = [ServiceDraft draftFromRecord:nil vehicle:v];
        sd.date = [ago(day) dateByAddingTimeInterval:10 * 3600];
        sd.category = [row[1] integerValue];
        sd.title = WSText(row[2]);
        sd.itemKeys = [row[3] length] ? [row[3] componentsSeparatedByString:@","] : @[];
        sd.odometer = odoAt(day);
        sd.cost = [row[4] doubleValue];
        sd.shop = [row[5] length] ? WSText(row[5]) : nil;
        ServiceRecord *r = [DataManager.shared insertEntity:@"ServiceRecord"];
        r.vehicle = v;
        [self apply:sd toRecord:r];
        [self resetPlansFrom:r vehicle:v];
    }
    // Half a year of trips along the same odometer timeline; a sample rate so reimbursement shows up.
    [TripManager.shared insertSampleTripsFor:v days:180 odometerAt:odoAt];
    if (TripManager.reimbursementRate <= 0) TripManager.reimbursementRate = 0.8;
    v.odometer = odoAt(0);
    if (![DataManager.shared save:error]) return NO;
    self.currentVehicle = v;
    return YES;
}

#pragma mark - Units & formatting

+ (BOOL)usesMiles { return [NSUserDefaults.standardUserDefaults boolForKey:kUsesMilesKey]; }
+ (void)setUsesMiles:(BOOL)usesMiles { [NSUserDefaults.standardUserDefaults setBool:usesMiles forKey:kUsesMilesKey]; }
+ (NSString *)distanceUnit { return self.usesMiles ? @"mi" : @"km"; }
+ (double)displayFromKm:(double)km { return self.usesMiles ? km / kKmPerMile : km; }
+ (double)kmFromDisplay:(double)value { return self.usesMiles ? value * kKmPerMile : value; }

+ (NSString *)formatNumber:(double)value digits:(NSInteger)digits {
    static NSNumberFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ f = NSNumberFormatter.new; f.numberStyle = NSNumberFormatterDecimalStyle; });
    @synchronized (f) {
        f.minimumFractionDigits = 0;
        f.maximumFractionDigits = digits;
        return [f stringFromNumber:@(value)] ?: @"0";
    }
}

+ (NSString *)formatCost:(double)amount {
    static NSNumberFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        f = NSNumberFormatter.new;
        f.numberStyle = NSNumberFormatterCurrencyStyle;
        f.locale = NSLocale.currentLocale;
    });
    @synchronized (f) {
        f.maximumFractionDigits = fabs(amount) >= 1000 ? 0 : 2;
        return [f stringFromNumber:@(amount)] ?: @"0";
    }
}

+ (NSString *)formatDistance:(double)km {
    return [NSString stringWithFormat:@"%@ %@", [self formatNumber:round([self displayFromKm:km]) digits:0], self.distanceUnit];
}

+ (double)parseNumber:(NSString *)text {
    NSString *t = [[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]
                   stringByReplacingOccurrencesOfString:@"," withString:@"."];
    t = [t stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (!t.length) return 0;
    NSScanner *scanner = [NSScanner scannerWithString:t];
    scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    double value = 0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd || !isfinite(value)) return NAN;
    return value;
}

@end
