//
//  GarageCatalog.m
//  WorkSpace
//

#import "GarageCatalog.h"
#import "GarageTypes.h"
#import "AppThemeManager.h"

@interface GarageItem ()
@property (nonatomic, copy, readwrite) NSString *key, *name, *symbol, *summary;
@property (nonatomic, readwrite) double intervalKm;
@property (nonatomic, readwrite) NSInteger intervalMonths;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *tips;
@property (nonatomic, readwrite) BOOL defaultPlan;
@end
@implementation GarageItem
@end

@interface GarageWarningLight ()
@property (nonatomic, copy, readwrite) NSString *name, *symbol, *meaning, *action;
@property (nonatomic, readwrite) WarningLevel level;
@end
@implementation GarageWarningLight
@end

@interface GarageChecklist ()
@property (nonatomic, copy, readwrite) NSString *name, *symbol, *summary;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *items;
@end
@implementation GarageChecklist
@end

@implementation GarageCatalog

static NSArray<NSString *> *GTArray(NSArray<NSString *> *keys) {
    NSMutableArray *out = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString *k in keys) [out addObject:GarageText(k)];
    return out;
}

/// Intervals are common conservative values for passenger cars; the owner's manual always wins,
/// and every plan can be adjusted per vehicle.
+ (NSArray<GarageItem *> *)items {
    static NSArray *items;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *rows = @[
            @[@"oil", @"Engine Oil", @"drop.fill", @5000, @6, @YES, @"Lubricates and cools the engine. Old oil thickens and wears parts faster.",
              @[@"Synthetic oil often allows 7,500–10,000 km; follow the manual.", @"Check the dipstick monthly with the engine cold.", @"Short trips and city traffic count as severe use."]],
            @[@"oil_filter", @"Oil Filter", @"aqi.medium", @5000, @6, @YES, @"Traps metal particles and sludge. Replace it with every oil change.",
              @[@"Use a filter that matches the engine specification.", @"Lightly oil the new gasket before fitting."]],
            @[@"air_filter", @"Engine Air Filter", @"wind", @20000, @12, @YES, @"Keeps dust out of the engine. A clogged filter costs power and fuel.",
              @[@"Replace sooner in dusty or sandy areas.", @"Hold it up to light: if you can't see through it, replace it."]],
            @[@"cabin_filter", @"Cabin Air Filter", @"aqi.low", @15000, @12, @YES, @"Filters the air you breathe inside the car and keeps the A/C efficient.",
              @[@"A musty smell from the vents is a sign it's due.", @"Activated-carbon filters also reduce odors."]],
            @[@"tire_rotation", @"Tire Rotation", @"arrow.triangle.2.circlepath", @10000, @0, @YES, @"Moves tires between positions so they wear evenly and last longer.",
              @[@"Check tread depth: replace below 1.6 mm, ideally at 3 mm.", @"Good time to check for nails and sidewall cracks."]],
            @[@"tire_pressure", @"Tire Pressure", @"speedometer", @0, @1, @NO, @"Correct pressure improves grip, braking and fuel economy.",
              @[@"Use the pressure on the door-frame sticker, not the tire wall.", @"Check cold, before driving.", @"Don't forget the spare."]],
            @[@"brake_pads", @"Brake Pads", @"exclamationmark.octagon.fill", @30000, @0, @YES, @"Pads wear with every stop. Worn pads damage discs and lengthen braking distance.",
              @[@"Squealing or grinding means inspect now.", @"Front pads usually wear twice as fast as rear."]],
            @[@"brake_fluid", @"Brake Fluid", @"drop.triangle.fill", @40000, @24, @YES, @"Brake fluid absorbs water over time, which lowers its boiling point.",
              @[@"Replace every 2 years regardless of mileage.", @"A soft pedal needs immediate attention."]],
            @[@"coolant", @"Coolant", @"thermometer.snowflake", @60000, @36, @YES, @"Prevents overheating in summer and freezing in winter.",
              @[@"Never open the radiator cap when the engine is hot.", @"Don't mix coolant types or colors."]],
            @[@"spark_plugs", @"Spark Plugs", @"bolt.fill", @40000, @0, @YES, @"Ignite the fuel. Worn plugs cause rough idle, misfires and higher consumption.",
              @[@"Iridium plugs can last 80,000–100,000 km.", @"Replace as a full set."]],
            @[@"transmission_fluid", @"Transmission Fluid", @"gearshape.2.fill", @60000, @48, @YES, @"Keeps gear changes smooth and protects the gearbox.",
              @[@"CVT and dual-clutch boxes have their own fluid type.", @"Delayed or harsh shifts are a warning sign."]],
            @[@"battery", @"Battery Check", @"battery.100", @0, @12, @YES, @"Most batteries last 3–5 years. Cold weather exposes weak ones.",
              @[@"Slow cranking is the first symptom.", @"Clean white or green corrosion from the terminals."]],
            @[@"wipers", @"Wiper Blades", @"cloud.rain.fill", @0, @12, @YES, @"Rubber hardens in sun and cold, leaving streaks and reducing visibility.",
              @[@"Replace when they streak, chatter or skip.", @"Top up washer fluid at the same time."]],
            @[@"alignment", @"Wheel Alignment", @"steeringwheel", @20000, @0, @NO, @"Keeps the car tracking straight and prevents uneven tire wear.",
              @[@"Check after hitting a big pothole or curb.", @"A pulling car or off-center steering wheel means check now."]],
            @[@"timing_belt", @"Timing Belt", @"link", @100000, @72, @NO, @"Synchronizes the engine. A broken belt can destroy the engine.",
              @[@"Some engines use a chain that rarely needs replacing; check the manual.", @"Replace the water pump at the same time if driven by the belt."]],
            @[@"ac_service", @"A/C Service", @"snowflake", @0, @24, @NO, @"Checks refrigerant, cleans the evaporator and keeps the cooling strong.",
              @[@"Run the A/C a few minutes every month, even in winter.", @"Weak cooling usually means a refrigerant leak."]],
            @[@"fuel_filter", @"Fuel Filter", @"fuelpump", @40000, @0, @NO, @"Protects injectors from dirt in the fuel. Especially important for diesel.",
              @[@"Many modern gasoline cars have an in-tank filter.", @"Diesel filters also separate water."]],
            @[@"suspension", @"Suspension Check", @"car.fill", @20000, @12, @NO, @"Shock absorbers and bushings keep the tires on the road.",
              @[@"Bouncy ride or nose-dive under braking means worn shocks.", @"Listen for knocks over speed bumps."]],
        ];
        NSMutableArray *list = NSMutableArray.new;
        for (NSArray *r in rows) {
            GarageItem *i = GarageItem.new;
            i.key = r[0]; i.name = GarageText(r[1]); i.symbol = r[2];
            i.intervalKm = [r[3] doubleValue]; i.intervalMonths = [r[4] integerValue]; i.defaultPlan = [r[5] boolValue];
            i.summary = GarageText(r[6]); i.tips = GTArray(r[7]);
            [list addObject:i];
        }
        items = list;
    });
    return items;
}

+ (GarageItem *)itemForKey:(NSString *)key {
    if (!key) return nil;
    for (GarageItem *i in self.items) if ([i.key isEqualToString:key]) return i;
    return nil;
}

+ (NSArray<GarageWarningLight *> *)warningLights {
    static NSArray *lights;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *rows = @[
            @[@"Engine Oil Pressure", @"oilcan.fill", @(WarningLevelStop), @"Oil pressure is too low to protect the engine.",
              @"Stop as soon as it's safe and turn off the engine. Check the oil level; do not drive until fixed."],
            @[@"Engine Temperature", @"thermometer.sun.fill", @(WarningLevelStop), @"The engine is overheating.",
              @"Pull over, switch off the engine and let it cool. Never open the radiator cap while hot."],
            @[@"Brake System", @"exclamationmark.circle.fill", @(WarningLevelStop), @"Parking brake is on, brake fluid is low or the system has a fault.",
              @"Release the parking brake. If the light stays on, drive carefully to a workshop or call for help."],
            @[@"Battery / Charging", @"bolt.batteryblock.fill", @(WarningLevelStop), @"The alternator is not charging the battery.",
              @"Turn off non-essential electrics and drive straight to a workshop; the car may stop soon."],
            @[@"Airbag", @"person.fill.viewfinder", @(WarningLevelCaution), @"The airbag system has a fault and may not deploy.",
              @"Have it checked soon. Don't fit a child seat in front of an airbag."],
            @[@"Check Engine", @"exclamationmark.triangle.fill", @(WarningLevelCaution), @"The engine computer detected an emissions or engine fault.",
              @"Steady: book a check soon. Flashing: reduce speed and get it checked immediately."],
            @[@"ABS", @"a.circle.fill", @(WarningLevelCaution), @"Anti-lock braking is disabled. Normal brakes still work.",
              @"Brake gently and leave extra distance. Get it checked soon."],
            @[@"Tire Pressure (TPMS)", @"circle.dashed", @(WarningLevelCaution), @"One or more tires are under-inflated.",
              @"Check all tires and inflate to the recommended pressure. Look for punctures."],
            @[@"Traction / Stability Control", @"car.fill", @(WarningLevelCaution), @"Flashing: the system is working on a slippery road. Steady: it is off or faulty.",
              @"Drive smoothly. If steady and you didn't switch it off, have it checked."],
            @[@"Low Fuel", @"fuelpump.fill", @(WarningLevelInfo), @"The fuel reserve is being used.",
              @"Refuel soon. Running dry can damage the fuel pump."],
            @[@"Washer Fluid", @"drop.fill", @(WarningLevelInfo), @"Windshield washer fluid is low.",
              @"Top up with washer fluid; use a winter mix below freezing."],
            @[@"Glow Plug (Diesel)", @"flame.fill", @(WarningLevelInfo), @"Diesel glow plugs are pre-heating.",
              @"Wait until it goes out before starting. If it flashes while driving, get it checked."],
        ];
        NSMutableArray *list = NSMutableArray.new;
        for (NSArray *r in rows) {
            GarageWarningLight *l = GarageWarningLight.new;
            l.name = GarageText(r[0]); l.symbol = r[1]; l.level = [r[2] integerValue];
            l.meaning = GarageText(r[3]); l.action = GarageText(r[4]);
            [list addObject:l];
        }
        lights = list;
    });
    return lights;
}

+ (NSArray<GarageChecklist *> *)checklists {
    static NSArray *lists;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *rows = @[
            @[@"Before a Road Trip", @"map.fill", @"A 15-minute check before a long drive.",
              @[@"Check tire pressure and tread, including the spare", @"Check engine oil and coolant levels", @"Test all lights and indicators",
                @"Top up washer fluid", @"Check wiper blades", @"Pack warning triangle and first-aid kit", @"Check insurance and roadside assistance details"]],
            @[@"Winter Ready", @"snowflake", @"Prepare the car before the first frost.",
              @[@"Test the battery", @"Check coolant antifreeze strength", @"Switch to winter washer fluid", @"Consider winter tires",
                @"Replace worn wiper blades", @"Pack scraper, gloves and a blanket"]],
            @[@"Summer Ready", @"sun.max.fill", @"Before the hot season.",
              @[@"Check A/C cooling", @"Check coolant level and hoses", @"Check tire pressure (heat raises it)", @"Clean the cabin air filter"]],
            @[@"Monthly Quick Check", @"calendar", @"Five minutes, once a month.",
              @[@"Tire pressure", @"Engine oil level", @"Washer fluid", @"Lights and indicators", @"Look under the car for leaks"]],
            @[@"Used Car Inspection", @"magnifyingglass", @"When buying a second-hand car.",
              @[@"Check service history and receipts", @"Compare odometer with records", @"Look for uneven panel gaps and paint", @"Cold-start the engine and listen",
                @"Test drive on different roads", @"Check all warning lights go out after start", @"Verify VIN matches documents"]],
        ];
        NSMutableArray *list = NSMutableArray.new;
        for (NSArray *r in rows) {
            GarageChecklist *c = GarageChecklist.new;
            c.name = GarageText(r[0]); c.symbol = r[1]; c.summary = GarageText(r[2]); c.items = GTArray(r[3]);
            [list addObject:c];
        }
        lists = list;
    });
    return lists;
}

+ (UIColor *)colorForWarningLevel:(WarningLevel)level {
    AppThemeManager *t = AppThemeManager.shared;
    switch (level) {
        case WarningLevelStop:    return t.danger;
        case WarningLevelCaution: return t.warning;
        default:                  return t.success;
    }
}

@end
