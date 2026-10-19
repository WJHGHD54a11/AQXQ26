//
//  TripHeatmapView.m
//  WorkSpace
//

#import "TripHeatmapView.h"
#import "AppThemeManager.h"
#import "AppConstants.h"

@interface TripHeatmapView ()
@property (nonatomic, copy) NSDictionary<NSDate *, NSNumber *> *values;
@property (nonatomic) NSInteger weeks;
@end

@implementation TripHeatmapView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        _tint = AppThemeManager.shared.accent;
        _weeks = 26;
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)setDailyValues:(NSDictionary *)values weeks:(NSInteger)weeks {
    self.values = values;
    self.weeks = MAX(4, weeks);
    NSUInteger active = 0;
    for (NSNumber *v in values.allValues) if (v.doubleValue > 0) active++;
    self.accessibilityValue = [NSString stringWithFormat:WSText(@"%lu days with trips"), (unsigned long)active];
    [self setNeedsDisplay];
}

- (void)setTint:(UIColor *)tint { _tint = tint; [self setNeedsDisplay]; }

/// 0 = none, 1…4 by quartile of the active days.
- (NSInteger)levelFor:(double)km thresholds:(double *)t {
    if (km <= 0) return 0;
    if (km <= t[0]) return 1;
    if (km <= t[1]) return 2;
    if (km <= t[2]) return 3;
    return 4;
}

- (void)drawRect:(CGRect)rect {
    AppThemeManager *t = AppThemeManager.shared;
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *today = [cal startOfDayForDate:NSDate.date];
    // Column = week (Monday first), row = weekday.
    NSInteger todayRow = ([cal component:NSCalendarUnitWeekday fromDate:today] + 5) % 7;
    NSDate *firstMonday = [cal dateByAddingUnit:NSCalendarUnitDay value:-(todayRow + 7 * (self.weeks - 1)) toDate:today options:0];

    NSArray *sorted = [[self.values.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"doubleValue > 0"]]
                       sortedArrayUsingSelector:@selector(compare:)];
    double thresholds[3] = {DBL_MAX, DBL_MAX, DBL_MAX};
    if (sorted.count) {
        for (int i = 0; i < 3; i++) thresholds[i] = [sorted[MIN(sorted.count - 1, sorted.count * (i + 1) / 4)] doubleValue];
    }

    CGFloat labelW = 0, labelH = 14;
    UIFont *small = [UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
    CGFloat gap = 3;
    CGFloat cell = floor(MIN((self.bounds.size.width - labelW - gap * (self.weeks - 1)) / self.weeks,
                             (self.bounds.size.height - labelH - gap * 6) / 7));
    CGFloat gridW = cell * self.weeks + gap * (self.weeks - 1);
    CGFloat x0 = floor((self.bounds.size.width - gridW) / 2);

    NSDateFormatter *mf = NSDateFormatter.new;
    [mf setLocalizedDateFormatFromTemplate:@"MMM"];
    NSInteger lastMonth = -1;
    for (NSInteger w = 0; w < self.weeks; w++) {
        NSDate *monday = [cal dateByAddingUnit:NSCalendarUnitDay value:w * 7 toDate:firstMonday options:0];
        NSInteger month = [cal component:NSCalendarUnitMonth fromDate:monday];
        if (month != lastMonth && w < self.weeks - 2) {
            NSDictionary *attrs = @{NSFontAttributeName: small, NSForegroundColorAttributeName: t.textTertiary};
            [[mf stringFromDate:monday] drawAtPoint:CGPointMake(x0 + w * (cell + gap), 0) withAttributes:attrs];
            lastMonth = month;
        }
        for (NSInteger r = 0; r < 7; r++) {
            NSDate *day = [cal dateByAddingUnit:NSCalendarUnitDay value:r toDate:monday options:0];
            if ([day compare:today] == NSOrderedDescending) continue;
            NSInteger level = [self levelFor:self.values[day].doubleValue thresholds:thresholds];
            UIColor *color = level == 0 ? t.surfaceRaised : [self.tint colorWithAlphaComponent:0.2 + 0.2 * level];
            CGRect box = CGRectMake(x0 + w * (cell + gap), labelH + r * (cell + gap), cell, cell);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:box cornerRadius:MIN(3, cell / 4)];
            [color setFill];
            [path fill];
            if ([day isEqualToDate:today]) {
                path.lineWidth = 1.5;
                [t.textPrimary setStroke];
                [path stroke];
            }
        }
    }
}

@end
