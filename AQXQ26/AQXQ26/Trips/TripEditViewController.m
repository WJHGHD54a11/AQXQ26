//
//  TripEditViewController.m
//  WorkSpace
//

#import "TripEditViewController.h"
#import "TripManager.h"
#import "GarageManager.h"
#import "Vehicle.h"
#import "WSUIKit.h"

@interface TripEditViewController ()
@property (nonatomic, strong, nullable) Trip *trip;
@property (nonatomic, strong) TripDraft *draft;
@property (nonatomic, copy) NSArray<Vehicle *> *vehicles;
@end

@implementation TripEditViewController

- (instancetype)initWithTrip:(Trip *)trip vehicle:(Vehicle *)vehicle template:(Trip *)templateTrip {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _trip = trip;
        _vehicles = GarageManager.shared.vehicles;
        _draft = [TripDraft draftFromTrip:trip vehicle:vehicle ?: templateTrip.vehicle ?: GarageManager.shared.currentVehicle];
        if (!trip && templateTrip) {
            _draft.purpose = templateTrip.purpose;
            _draft.fromPlace = templateTrip.fromPlace;
            _draft.toPlace = templateTrip.toPlace;
            _draft.endOdometer = _draft.startOdometer + templateTrip.distance;
        }
        self.title = trip ? WSText(@"Edit Trip") : WSText(@"New Trip");
    }
    return self;
}

- (void)prefillFrom:(NSString *)from to:(NSString *)to purpose:(NSInteger)purpose distance:(double)km {
    if (self.trip) return;
    self.draft.fromPlace = from;
    self.draft.toPlace = to;
    if (purpose >= 0 && purpose < TripPurposeCount) self.draft.purpose = (TripPurpose)purpose;
    self.draft.endOdometer = km > 0 ? self.draft.startOdometer + km : 0;
    if (self.isViewLoaded) [self reloadForm];
}

static NSString *TENumber(double v) {
    if (v <= 0) return nil;
    NSString *s = [NSString stringWithFormat:@"%.1f", v];
    return [s hasSuffix:@".0"] ? [s substringToIndex:s.length - 2] : s;
}

- (NSArray<WSFormSection *> *)buildSections {
    TripDraft *d = self.draft;
    NSString *unit = GarageManager.distanceUnit;
    NSMutableArray *names = NSMutableArray.new;
    for (Vehicle *v in self.vehicles) [names addObject:v.name];
    NSUInteger vi = d.vehicle ? [self.vehicles indexOfObject:d.vehicle] : 0;
    WSFormRow *vehicle = [WSFormRow type:WSFormRowChoice key:@"vehicle" title:WSText(@"Vehicle") value:@(vi == NSNotFound ? 0 : vi)];
    vehicle.options = names;
    __weak typeof(self) weakSelf = self;
    vehicle.onChange = ^(WSFormRow *row) {
        // A different car has a different odometer: restart from its reading.
        NSUInteger i = [row.value unsignedIntegerValue];
        if (weakSelf.trip || i >= weakSelf.vehicles.count) return;
        double km = [weakSelf distanceKm];
        Vehicle *v = weakSelf.vehicles[i];
        [weakSelf setFormValue:TENumber([GarageManager displayFromKm:v.odometer]) forKey:@"start"];
        [weakSelf setFormValue:km > 0 ? TENumber([GarageManager displayFromKm:v.odometer + km]) : nil forKey:@"end"];
    };
    WSFormRow *purpose = [WSFormRow type:WSFormRowChoice key:@"purpose" title:WSText(@"Purpose") value:@(d.purpose)];
    purpose.options = TripPurposeTitles();
    WSFormRow *date = [WSFormRow type:WSFormRowDate key:@"date" title:WSText(@"Departure") value:d.date];
    date.dateMode = UIDatePickerModeDateAndTime;
    date.dateRequired = YES;
    WSFormRow *from = [WSFormRow type:WSFormRowText key:@"from" title:WSText(@"From") value:d.fromPlace];
    from.placeholder = WSText(@"e.g. Home");
    WSFormRow *to = [WSFormRow type:WSFormRowText key:@"to" title:WSText(@"To") value:d.toPlace];
    to.placeholder = WSText(@"e.g. Office");
    WSFormRow *start = [WSFormRow type:WSFormRowText key:@"start" title:[NSString stringWithFormat:@"%@ (%@)", WSText(@"Start Mileage"), unit]
                                 value:TENumber([GarageManager displayFromKm:d.startOdometer])];
    start.keyboardType = UIKeyboardTypeDecimalPad;
    WSFormRow *end = [WSFormRow type:WSFormRowText key:@"end" title:[NSString stringWithFormat:@"%@ (%@)", WSText(@"End Mileage"), unit]
                               value:TENumber([GarageManager displayFromKm:d.endOdometer])];
    end.keyboardType = UIKeyboardTypeDecimalPad;
    end.placeholder = WSText(@"Odometer at arrival");
    WSFormRow *expense = [WSFormRow type:WSFormRowText key:@"expense" title:WSText(@"Tolls & Parking") value:d.expense > 0 ? [NSString stringWithFormat:@"%.2f", d.expense] : nil];
    expense.keyboardType = UIKeyboardTypeDecimalPad;
    expense.placeholder = @"0";
    WSFormRow *title = [WSFormRow type:WSFormRowText key:@"title" title:WSText(@"Reason") value:d.title];
    title.placeholder = WSText(@"e.g. Client visit");
    WSFormRow *notes = [WSFormRow type:WSFormRowTextArea key:@"notes" title:WSText(@"Remarks") value:d.notes];

    WSFormSection *mileage = [WSFormSection title:WSText(@"Mileage") rows:@[start, end, expense]];
    mileage.footer = WSText(@"Saving updates the vehicle odometer, which keeps maintenance reminders accurate.");
    return @[[WSFormSection title:nil rows:@[vehicle, purpose, date]],
             [WSFormSection title:WSText(@"Route") rows:@[from, to]],
             mileage,
             [WSFormSection title:WSText(@"Details") rows:@[title, notes]]];
}

/// Current end − start in km (0 when either is missing).
- (double)distanceKm {
    double s = [GarageManager parseNumber:[self stringForKey:@"start"]];
    double e = [GarageManager parseNumber:[self stringForKey:@"end"]];
    return (isnan(s) || isnan(e) || e <= s) ? 0 : [GarageManager kmFromDisplay:e - s];
}

- (BOOL)save {
    TripDraft *d = self.draft;
    NSUInteger vi = [[self formValueForKey:@"vehicle"] unsignedIntegerValue];
    d.vehicle = vi < self.vehicles.count ? self.vehicles[vi] : nil;
    d.purpose = (TripPurpose)[[self formValueForKey:@"purpose"] integerValue];
    d.date = [self formValueForKey:@"date"] ?: NSDate.date;
    d.fromPlace = [self stringForKey:@"from"];
    d.toPlace = [self stringForKey:@"to"];
    double s = [GarageManager parseNumber:[self stringForKey:@"start"]];
    double e = [GarageManager parseNumber:[self stringForKey:@"end"]];
    d.startOdometer = isnan(s) ? NAN : [GarageManager kmFromDisplay:s];
    d.endOdometer = isnan(e) ? NAN : [GarageManager kmFromDisplay:e];
    d.expense = [GarageManager parseNumber:[self stringForKey:@"expense"]];
    d.title = [self stringForKey:@"title"];
    d.notes = [self stringForKey:@"notes"];
    NSError *error = nil;
    BOOL ok = self.trip ? [TripManager.shared updateTrip:self.trip with:d error:&error]
                        : [TripManager.shared createTrip:d error:&error] != nil;
    if (!ok) [self ws_showError:error];
    return ok;
}

@end
