//
//  TripManager.m
//  WorkSpace
//

#import "TripManager.h"
#import "GarageManager.h"
#import "Vehicle.h"
#import "DataManager.h"
#import "AppConstants.h"

static NSString * const kRateKey = @"trips.reimbursementRate";

NSArray<NSString *> *TripPurposeTitles(void) {
    return @[WSText(@"Commute"), WSText(@"Business"), WSText(@"Personal"), WSText(@"Travel"), WSText(@"Other")];
}

NSString *TripPurposeSymbol(TripPurpose purpose) {
    NSArray *s = @[@"building.2.fill", @"briefcase.fill", @"cart.fill", @"airplane", @"ellipsis.circle.fill"];
    return (purpose >= 0 && purpose < (NSInteger)s.count) ? s[purpose] : s.lastObject;
}

NSString *TripPurposeColor(TripPurpose purpose) {
    NSArray *c = @[@"sky", @"indigo", @"lime", @"amber", @"slate"];
    return (purpose >= 0 && purpose < (NSInteger)c.count) ? c[purpose] : @"slate";
}

@implementation TripDraft
+ (instancetype)draftFromTrip:(Trip *)t vehicle:(Vehicle *)vehicle {
    TripDraft *d = self.new;
    d.vehicle = t ? t.vehicle : vehicle;
    d.purpose = t ? t.purpose : TripPurposeCommute;
    d.title = t.title; d.fromPlace = t.fromPlace; d.toPlace = t.toPlace; d.notes = t.notes;
    d.date = t.date ?: NSDate.date;
    d.startOdometer = t ? t.startOdometer : d.vehicle.odometer;
    d.endOdometer = t.endOdometer;
    d.expense = t.expense;
    return d;
}
@end

@implementation TripStats
@end

@implementation TripManager

+ (instancetype)shared {
    static TripManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    return shared;
}

+ (double)reimbursementRate { return MAX(0, [NSUserDefaults.standardUserDefaults doubleForKey:kRateKey]); }
+ (void)setReimbursementRate:(double)rate {
    [NSUserDefaults.standardUserDefaults setDouble:(isfinite(rate) && rate > 0) ? rate : 0 forKey:kRateKey];
}

+ (NSDate *)startOfMonthOffset:(NSInteger)months {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *first = [cal dateFromComponents:[cal components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:NSDate.date]];
    return [cal dateByAddingUnit:NSCalendarUnitMonth value:months toDate:first options:0];
}

- (NSError *)errorWith:(NSString *)message {
    return [NSError errorWithDomain:@"WorkSpace" code:1 userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (NSString *)trim:(NSString *)s {
    NSString *t = [s stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return t.length ? t : nil;
}

#pragma mark - CRUD

- (NSArray<Trip *> *)tripsFrom:(NSDate *)from to:(NSDate *)to purpose:(NSInteger)purpose {
    NSFetchRequest *r = [Trip fetchRequest];
    NSMutableArray *preds = NSMutableArray.new;
    if (from) [preds addObject:[NSPredicate predicateWithFormat:@"date >= %@", from]];
    if (to) [preds addObject:[NSPredicate predicateWithFormat:@"date < %@", to]];
    if (purpose >= 0) [preds addObject:[NSPredicate predicateWithFormat:@"purpose == %d", (int)purpose]];
    if (preds.count) r.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:preds];
    r.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                          [NSSortDescriptor sortDescriptorWithKey:@"startOdometer" ascending:NO]];
    return [DataManager.shared fetch:r];
}

- (BOOL)validate:(TripDraft *)d error:(NSError **)error {
    if (!d.vehicle) { if (error) *error = [self errorWith:WSText(@"Add a vehicle in Garage first.")]; return NO; }
    if (isnan(d.startOdometer) || isnan(d.endOdometer) || d.startOdometer < 0) {
        if (error) *error = [self errorWith:WSText(@"Please enter a valid mileage.")];
        return NO;
    }
    if (d.endOdometer <= d.startOdometer) {
        if (error) *error = [self errorWith:WSText(@"The end mileage must be greater than the start mileage.")];
        return NO;
    }
    if (d.endOdometer - d.startOdometer > 5000) {
        if (error) *error = [self errorWith:WSText(@"A single trip can't be longer than 5,000 km. Please check the mileage.")];
        return NO;
    }
    if (isnan(d.expense) || d.expense < 0) { if (error) *error = [self errorWith:WSText(@"Please enter a valid amount.")]; return NO; }
    return YES;
}

- (void)apply:(TripDraft *)d to:(Trip *)t {
    t.vehicle = d.vehicle;
    t.purpose = d.purpose;
    t.title = [self trim:d.title];
    t.fromPlace = [self trim:d.fromPlace]; t.toPlace = [self trim:d.toPlace];
    t.notes = [self trim:d.notes];
    t.date = d.date ?: NSDate.date;
    t.startOdometer = d.startOdometer; t.endOdometer = d.endOdometer;
    t.expense = d.expense;
    t.updatedAt = NSDate.date;
    // Trips only move the odometer forward.
    if (t.vehicle && t.endOdometer > t.vehicle.odometer) {
        t.vehicle.odometer = t.endOdometer;
        t.vehicle.updatedAt = NSDate.date;
    }
}

- (Trip *)createTrip:(TripDraft *)d error:(NSError **)error {
    if (![self validate:d error:error]) return nil;
    Trip *t = [DataManager.shared insertEntity:@"Trip"];
    [self apply:d to:t];
    return [DataManager.shared save:error] ? t : nil;
}

- (BOOL)updateTrip:(Trip *)t with:(TripDraft *)d error:(NSError **)error {
    if (![self validate:d error:error]) return NO;
    [self apply:d to:t];
    return [DataManager.shared save:error];
}

- (BOOL)deleteTrip:(Trip *)t error:(NSError **)error {
    [DataManager.shared deleteObject:t];
    return [DataManager.shared save:error];
}

#pragma mark - Stats

- (TripStats *)statsFrom:(NSDate *)from to:(NSDate *)to {
    TripStats *s = TripStats.new;
    double byPurpose[TripPurposeCount] = {0};
    double rate = TripManager.reimbursementRate;
    for (Trip *t in [self tripsFrom:from to:to purpose:-1]) {
        double km = t.distance;
        s.distance += km;
        s.count += 1;
        s.expense += t.expense;
        NSInteger p = MAX(0, MIN(TripPurposeCount - 1, t.purpose));
        byPurpose[p] += km;
        if (t.purpose == TripPurposeBusiness) { s.businessDistance += km; s.businessExpense += t.expense; }
        if (!s.longest || km > s.longest.distance) s.longest = t;
    }
    NSMutableArray *list = NSMutableArray.new;
    for (NSInteger i = 0; i < TripPurposeCount; i++) [list addObject:@(byPurpose[i])];
    s.byPurpose = list;
    s.reimbursement = s.businessDistance * rate + s.businessExpense;
    return s;
}

- (NSArray<NSDictionary *> *)monthlyDistance {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *start = [TripManager startOfMonthOffset:-11];
    NSMutableArray<NSMutableArray *> *values = NSMutableArray.new;
    for (NSInteger i = 0; i < 12; i++) {
        NSMutableArray *row = NSMutableArray.new;
        for (NSInteger p = 0; p < TripPurposeCount; p++) [row addObject:@0];
        [values addObject:row];
    }
    for (Trip *t in [self tripsFrom:start to:nil purpose:-1]) {
        NSInteger m = [cal components:NSCalendarUnitMonth fromDate:start toDate:t.date options:0].month;
        if (m < 0 || m >= 12) continue;
        NSInteger p = MAX(0, MIN(TripPurposeCount - 1, t.purpose));
        values[m][p] = @([values[m][p] doubleValue] + t.distance);
    }
    NSMutableArray *out = NSMutableArray.new;
    for (NSInteger i = 0; i < 12; i++) {
        [out addObject:@{@"month": [cal dateByAddingUnit:NSCalendarUnitMonth value:i toDate:start options:0], @"values": values[i]}];
    }
    return out;
}

- (NSDictionary<NSDate *, NSNumber *> *)dailyDistanceForLast:(NSInteger)days {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *from = [cal dateByAddingUnit:NSCalendarUnitDay value:-(days - 1) toDate:[cal startOfDayForDate:NSDate.date] options:0];
    NSMutableDictionary *map = NSMutableDictionary.new;
    for (Trip *t in [self tripsFrom:from to:nil purpose:-1]) {
        NSDate *day = [cal startOfDayForDate:t.date];
        map[day] = @([map[day] doubleValue] + t.distance);
    }
    return map;
}

- (NSArray<NSDictionary *> *)topRoutes:(NSUInteger)limit {
    NSMutableDictionary<NSString *, NSMutableDictionary *> *routes = NSMutableDictionary.new;
    for (Trip *t in [self tripsFrom:[TripManager startOfMonthOffset:-11] to:nil purpose:-1]) {
        if (!t.fromPlace.length || !t.toPlace.length) continue;
        // A → B and B → A are the same route.
        NSArray *pair = [@[t.fromPlace, t.toPlace] sortedArrayUsingSelector:@selector(localizedCompare:)];
        NSString *key = [pair componentsJoinedByString:@"↔"];
        NSMutableDictionary *r = routes[key];
        if (!r) routes[key] = r = [@{@"from": pair[0], @"to": pair[1], @"count": @0, @"distance": @0} mutableCopy];
        r[@"count"] = @([r[@"count"] integerValue] + 1);
        r[@"distance"] = @([r[@"distance"] doubleValue] + t.distance);
    }
    NSArray *sorted = [routes.allValues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"count" ascending:NO],
                                                                       [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:NO]]];
    return sorted.count > limit ? [sorted subarrayWithRange:NSMakeRange(0, limit)] : sorted;
}

#pragma mark - Export

static NSString *TMCSVField(NSString *value) {
    NSString *v = value ?: @"";
    if ([v rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@",\"\n\r"]].location == NSNotFound) return v;
    return [NSString stringWithFormat:@"\"%@\"", [v stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
}

- (NSURL *)exportCSVFrom:(NSDate *)from to:(NSDate *)to error:(NSError **)error {
    NSArray<Trip *> *trips = [[self tripsFrom:from to:to purpose:-1] reverseObjectEnumerator].allObjects;   // oldest first
    if (!trips.count) { if (error) *error = [self errorWith:WSText(@"There are no trips in this period.")]; return nil; }
    NSString *unit = GarageManager.distanceUnit;
    NSDateFormatter *df = NSDateFormatter.new;
    df.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    df.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *(^num)(double) = ^NSString *(double v) { return [NSString stringWithFormat:@"%.1f", v]; };
    NSArray *titles = TripPurposeTitles();

    NSMutableArray<NSString *> *lines = NSMutableArray.new;
    NSArray *header = @[WSText(@"Date"), WSText(@"Vehicle"), WSText(@"Purpose"), WSText(@"From"), WSText(@"To"),
                        [NSString stringWithFormat:@"%@ (%@)", WSText(@"Start"), unit], [NSString stringWithFormat:@"%@ (%@)", WSText(@"End"), unit],
                        [NSString stringWithFormat:@"%@ (%@)", WSText(@"Distance"), unit], WSText(@"Expense"), WSText(@"Remarks")];
    [lines addObject:[header componentsJoinedByString:@","]];
    for (Trip *t in trips) {
        NSArray *row = @[[df stringFromDate:t.date], TMCSVField(t.vehicle.name), TMCSVField(titles[MAX(0, MIN(TripPurposeCount - 1, t.purpose))]),
                         TMCSVField(t.fromPlace), TMCSVField(t.toPlace),
                         num([GarageManager displayFromKm:t.startOdometer]), num([GarageManager displayFromKm:t.endOdometer]),
                         num([GarageManager displayFromKm:t.distance]), [NSString stringWithFormat:@"%.2f", t.expense], TMCSVField(t.title.length ? t.title : t.notes)];
        [lines addObject:[row componentsJoinedByString:@","]];
    }
    TripStats *s = [self statsFrom:from to:to];
    [lines addObject:@""];
    [lines addObject:[NSString stringWithFormat:@"%@,%@", TMCSVField(WSText(@"Business distance")), num([GarageManager displayFromKm:s.businessDistance])]];
    [lines addObject:[NSString stringWithFormat:@"%@,%.2f", TMCSVField(WSText(@"Business expenses")), s.businessExpense]];
    if (TripManager.reimbursementRate > 0) {
        [lines addObject:[NSString stringWithFormat:@"%@,%.2f", TMCSVField(WSText(@"Reimbursement")), s.reimbursement]];
    }

    // BOM so spreadsheet apps detect UTF-8 (Chinese text).
    NSString *csv = [@"﻿" stringByAppendingString:[lines componentsJoinedByString:@"\r\n"]];
    NSDateFormatter *nameFormatter = NSDateFormatter.new;
    nameFormatter.dateFormat = @"yyyy-MM-dd";
    NSString *name = [NSString stringWithFormat:@"%@ %@.csv", WSText(@"Trip Log"), [nameFormatter stringFromDate:NSDate.date]];
    NSURL *url = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:name];
    NSError *writeError = nil;
    if (![csv writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&writeError]) {
        if (error) *error = writeError ?: [self errorWith:WSText(@"Export failed.")];
        return nil;
    }
    return url;
}

#pragma mark - Sample data

/// Weekday commutes, fortnightly client visits, weekend errands and a trip away every few months.
/// Each day's trips fit inside that day's odometer window, so they agree with refuels and services.
- (void)insertSampleTripsFor:(Vehicle *)v days:(NSInteger)days odometerAt:(double (^)(NSInteger))odoAt {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *today = [cal startOfDayForDate:NSDate.date];
    __block uint32_t seed = 20261019;
    double (^rnd)(void) = ^double { seed = seed * 1664525u + 1013904223u; return (seed >> 8) / 16777216.0; };
    NSString *home = WSText(@"My Home"), *office = WSText(@"Office");
    NSArray *errands = @[WSText(@"Supermarket"), WSText(@"Gym"), WSText(@"Parents' Home"), WSText(@"Shopping Mall")];
    NSArray *clients = @[WSText(@"Client Site"), WSText(@"Branch Office"), WSText(@"Supplier")];
    double cursor = odoAt(days + 1);

    for (NSInteger d = days; d >= 1; d--) {
        NSDate *day = [cal dateByAddingUnit:NSCalendarUnitDay value:-d toDate:today options:0];
        NSInteger weekday = [cal component:NSCalendarUnitWeekday fromDate:day];   // 1 = Sunday
        BOOL weekend = weekday == 1 || weekday == 7;
        // [purpose, from, to, km, hour, expense]
        NSMutableArray<NSArray *> *plan = NSMutableArray.new;
        if (!weekend && rnd() > 0.12) {
            double km = 13.5 + rnd() * 2;
            BOOL visit = (weekday == 3 || weekday == 5) && rnd() > 0.55;
            if (visit) {
                NSString *client = clients[(NSUInteger)(rnd() * clients.count) % clients.count];
                double out = 28 + rnd() * 40;
                [plan addObject:@[@(TripPurposeCommute), home, office, @(km), @8.3, @0]];
                [plan addObject:@[@(TripPurposeBusiness), office, client, @(out), @10.0, @(round(rnd() * 3) * 10)]];
                [plan addObject:@[@(TripPurposeBusiness), client, office, @(out * (0.95 + rnd() * 0.1)), @15.5, @(10 + round(rnd() * 2) * 5)]];
            } else {
                [plan addObject:@[@(TripPurposeCommute), home, office, @(km), @8.3, @0]];
            }
            [plan addObject:@[@(TripPurposeCommute), office, home, @(km * (0.97 + rnd() * 0.06)), @18.2, @0]];
        } else if (weekend && rnd() > 0.35) {
            NSString *place = errands[(NSUInteger)(rnd() * errands.count) % errands.count];
            double km = 5 + rnd() * 18;
            [plan addObject:@[@(TripPurposePersonal), home, place, @(km), @(10 + rnd() * 5), @(rnd() > 0.7 ? 10 : 0)]];
            [plan addObject:@[@(TripPurposePersonal), place, home, @(km), @(16 + rnd() * 3), @0]];
        }
        if (weekday == 7 && (d / 7) % 9 == 4) {   // a weekend away roughly every 9 weeks
            [plan addObject:@[@(TripPurposeTravel), home, WSText(@"Hangzhou"), @(178 + rnd() * 10), @9.0, @(85)]];
        }

        double total = 0;
        for (NSArray *p in plan) total += [p[3] doubleValue];
        double end = odoAt(d);
        if (!plan.count || total > end - cursor) continue;   // not enough mileage that day: skip
        double pos = end - total - MIN(4.0, (end - cursor - total) * rnd());
        for (NSArray *p in plan) {
            Trip *t = [DataManager.shared insertEntity:@"Trip"];
            t.vehicle = v;
            t.purpose = (TripPurpose)[p[0] integerValue];
            t.fromPlace = p[1]; t.toPlace = p[2];
            t.date = [day dateByAddingTimeInterval:[p[4] doubleValue] * 3600];
            t.startOdometer = round(pos * 10) / 10;
            pos += [p[3] doubleValue];
            t.endOdometer = round(pos * 10) / 10;
            t.expense = [p[5] doubleValue];
            if (t.purpose == TripPurposeBusiness) t.title = WSText(@"Client visit");
        }
        cursor = pos;
    }
}

@end
