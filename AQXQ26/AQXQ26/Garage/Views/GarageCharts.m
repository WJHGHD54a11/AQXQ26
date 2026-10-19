//
//  GarageCharts.m
//  WorkSpace
//

#import "GarageCharts.h"
#import "AppThemeManager.h"

static void GCDrawText(NSString *text, CGPoint point, UIFont *font, UIColor *color, NSTextAlignment align) {
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    CGSize size = [text sizeWithAttributes:attrs];
    CGFloat x = align == NSTextAlignmentCenter ? point.x - size.width / 2 : (align == NSTextAlignmentRight ? point.x - size.width : point.x);
    [text drawAtPoint:CGPointMake(x, point.y) withAttributes:attrs];
}

#pragma mark - Bars

@interface GarageBarChartView ()
@property (nonatomic, copy) NSArray<NSArray<NSNumber *> *> *stacks;
@property (nonatomic, copy) NSArray<UIColor *> *colors;
@property (nonatomic, copy) NSArray<NSString *> *labels;
@end

@implementation GarageBarChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)setStacks:(NSArray *)stacks colors:(NSArray *)colors labels:(NSArray *)labels {
    self.stacks = stacks; self.colors = colors; self.labels = labels;
    double total = 0;
    for (NSArray *s in stacks) for (NSNumber *n in s) total += n.doubleValue;
    self.accessibilityValue = self.valueFormatter ? self.valueFormatter(total) : nil;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    AppThemeManager *t = AppThemeManager.shared;
    if (!self.stacks.count) return;
    UIFont *small = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    CGFloat labelH = 16, topPad = 16;
    CGRect plot = CGRectMake(0, topPad, self.bounds.size.width, self.bounds.size.height - labelH - topPad);

    double maxValue = 0;
    for (NSArray *s in self.stacks) {
        double sum = 0;
        for (NSNumber *n in s) sum += n.doubleValue;
        maxValue = MAX(maxValue, sum);
    }

    // Guides at 0 / 50% / 100%
    UIBezierPath *guides = UIBezierPath.bezierPath;
    for (int i = 0; i <= 2; i++) {
        CGFloat y = round(CGRectGetMaxY(plot) - plot.size.height * i / 2.0) + 0.5;
        [guides moveToPoint:CGPointMake(0, y)];
        [guides addLineToPoint:CGPointMake(CGRectGetMaxX(plot), y)];
    }
    CGFloat dash[] = {2, 3};
    [guides setLineDash:dash count:2 phase:0];
    guides.lineWidth = 1;
    [t.separator setStroke];
    [guides stroke];
    if (maxValue > 0 && self.valueFormatter) {
        GCDrawText(self.valueFormatter(maxValue), CGPointMake(CGRectGetMaxX(plot), 0), small, t.textTertiary, NSTextAlignmentRight);
    }

    NSUInteger n = self.stacks.count;
    CGFloat slot = plot.size.width / n;
    CGFloat barW = MIN(22, slot * 0.58);
    for (NSUInteger i = 0; i < n; i++) {
        CGFloat x = slot * i + (slot - barW) / 2;
        CGFloat y = CGRectGetMaxY(plot);
        NSArray *stack = self.stacks[i];
        double sum = 0;
        for (NSNumber *v in stack) sum += v.doubleValue;
        if (sum <= 0 || maxValue <= 0) {
            UIBezierPath *stub = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y - 3, barW, 3) cornerRadius:1.5];
            [t.surfaceRaised setFill];
            [stub fill];
        } else {
            CGFloat h = plot.size.height * sum / maxValue;
            UIBezierPath *clip = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(x, y - h, barW, h) cornerRadius:MIN(6, barW / 2)];
            CGContextRef ctx = UIGraphicsGetCurrentContext();
            CGContextSaveGState(ctx);
            [clip addClip];
            CGFloat cursor = y;
            for (NSUInteger k = 0; k < stack.count; k++) {
                CGFloat part = plot.size.height * [stack[k] doubleValue] / maxValue;
                [self.colors[k % self.colors.count] setFill];
                UIRectFill(CGRectMake(x, cursor - part, barW, part));
                cursor -= part;
            }
            CGContextRestoreGState(ctx);
        }
        if (i < self.labels.count && (n <= 6 || i % 2 == (n - 1) % 2)) {
            BOOL last = i == n - 1;
            GCDrawText(self.labels[i], CGPointMake(slot * i + slot / 2, CGRectGetMaxY(plot) + 3), small,
                       last ? t.textPrimary : t.textTertiary, NSTextAlignmentCenter);
        }
    }
}

@end

#pragma mark - Donut

@interface GarageDonutView ()
@property (nonatomic, copy) NSArray<NSNumber *> *values;
@property (nonatomic, copy) NSArray<UIColor *> *colors;
@property (nonatomic, copy) NSString *title, *subtitle;
@end

@implementation GarageDonutView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setValues:(NSArray *)values colors:(NSArray *)colors title:(NSString *)title subtitle:(NSString *)subtitle {
    self.values = values; self.colors = colors; self.title = title; self.subtitle = subtitle;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    AppThemeManager *t = AppThemeManager.shared;
    CGFloat side = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat line = side * 0.13;
    CGPoint c = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat r = side / 2 - line / 2 - 1;

    UIBezierPath *track = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:0 endAngle:2 * M_PI clockwise:YES];
    track.lineWidth = line;
    [t.surfaceRaised setStroke];
    [track stroke];

    double total = 0;
    for (NSNumber *v in self.values) total += MAX(0, v.doubleValue);
    if (total > 0) {
        CGFloat gap = self.values.count > 1 ? 0.035 : 0;
        CGFloat start = -M_PI_2;
        for (NSUInteger i = 0; i < self.values.count; i++) {
            CGFloat sweep = 2 * M_PI * MAX(0, self.values[i].doubleValue) / total;
            if (sweep <= gap) { start += sweep; continue; }
            UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start + gap / 2
                                                             endAngle:start + sweep - gap / 2 clockwise:YES];
            arc.lineWidth = line;
            arc.lineCapStyle = kCGLineCapButt;
            [self.colors[i % self.colors.count] setStroke];
            [arc stroke];
            start += sweep;
        }
    }
    UIFont *titleFont = [UIFont systemFontOfSize:MAX(13, side * 0.13) weight:UIFontWeightBold];
    UIFont *subFont = [UIFont systemFontOfSize:MAX(10, side * 0.075) weight:UIFontWeightMedium];
    CGFloat titleH = self.title ? titleFont.lineHeight : 0, subH = self.subtitle ? subFont.lineHeight : 0;
    CGFloat y = c.y - (titleH + subH) / 2;
    if (self.title) GCDrawText(self.title, CGPointMake(c.x, y), titleFont, t.textPrimary, NSTextAlignmentCenter);
    if (self.subtitle) GCDrawText(self.subtitle, CGPointMake(c.x, y + titleH), subFont, t.textSecondary, NSTextAlignmentCenter);
}

@end

#pragma mark - Line

@interface GarageLineChartView ()
@property (nonatomic, copy) NSArray<NSNumber *> *values;
@property (nonatomic, copy) NSArray<NSString *> *labels;
@property (nonatomic, copy) NSString *unit;
@end

@implementation GarageLineChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setValues:(NSArray *)values labels:(NSArray *)labels unit:(NSString *)unit {
    self.values = values; self.labels = labels; self.unit = unit;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    AppThemeManager *t = AppThemeManager.shared;
    UIFont *small = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    NSUInteger n = self.values.count;
    if (n < 2) {
        GCDrawText(n ? @"…" : @"", CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)), small, t.textTertiary, NSTextAlignmentCenter);
        return;
    }
    CGRect plot = CGRectInset(CGRectMake(0, 18, self.bounds.size.width, self.bounds.size.height - 36), 6, 0);
    double minV = DBL_MAX, maxV = -DBL_MAX, sum = 0;
    NSUInteger minI = 0, maxI = 0;
    for (NSUInteger i = 0; i < n; i++) {
        double v = self.values[i].doubleValue;
        sum += v;
        if (v < minV) { minV = v; minI = i; }
        if (v > maxV) { maxV = v; maxI = i; }
    }
    double pad = MAX((maxV - minV) * 0.25, 0.5);
    double lo = minV - pad, hi = maxV + pad;
    CGPoint (^pt)(NSUInteger) = ^CGPoint(NSUInteger i) {
        CGFloat x = plot.origin.x + plot.size.width * i / (n - 1);
        CGFloat y = CGRectGetMaxY(plot) - plot.size.height * (self.values[i].doubleValue - lo) / (hi - lo);
        return CGPointMake(x, y);
    };

    // Smooth path (Catmull-Rom → Bézier)
    UIBezierPath *line = UIBezierPath.bezierPath;
    [line moveToPoint:pt(0)];
    for (NSUInteger i = 0; i + 1 < n; i++) {
        CGPoint p0 = pt(i == 0 ? 0 : i - 1), p1 = pt(i), p2 = pt(i + 1), p3 = pt(MIN(i + 2, n - 1));
        CGPoint c1 = CGPointMake(p1.x + (p2.x - p0.x) / 6, p1.y + (p2.y - p0.y) / 6);
        CGPoint c2 = CGPointMake(p2.x - (p3.x - p1.x) / 6, p2.y - (p3.y - p1.y) / 6);
        [line addCurveToPoint:p2 controlPoint1:c1 controlPoint2:c2];
    }

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIBezierPath *fill = [line copy];
    [fill addLineToPoint:CGPointMake(pt(n - 1).x, CGRectGetMaxY(plot))];
    [fill addLineToPoint:CGPointMake(pt(0).x, CGRectGetMaxY(plot))];
    [fill closePath];
    CGContextSaveGState(ctx);
    [fill addClip];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = @[(id)[t.accent colorWithAlphaComponent:0.28].CGColor, (id)[t.accent colorWithAlphaComponent:0.0].CGColor];
    CGGradientRef g = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, g, CGPointMake(0, plot.origin.y), CGPointMake(0, CGRectGetMaxY(plot)), 0);
    CGGradientRelease(g);
    CGColorSpaceRelease(space);
    CGContextRestoreGState(ctx);

    // Average guide
    double avg = sum / n;
    CGFloat ay = CGRectGetMaxY(plot) - plot.size.height * (avg - lo) / (hi - lo);
    UIBezierPath *guide = UIBezierPath.bezierPath;
    [guide moveToPoint:CGPointMake(plot.origin.x, ay)];
    [guide addLineToPoint:CGPointMake(CGRectGetMaxX(plot), ay)];
    CGFloat dash[] = {3, 3};
    [guide setLineDash:dash count:2 phase:0];
    [t.textTertiary setStroke];
    [guide stroke];
    GCDrawText([NSString stringWithFormat:@"%.1f %@", avg, self.unit], CGPointMake(plot.origin.x, ay - 15), small, t.textSecondary, NSTextAlignmentLeft);

    line.lineWidth = 2.5;
    line.lineJoinStyle = kCGLineJoinRound;
    [t.accent setStroke];
    [line stroke];

    for (NSNumber *idx in @[@(minI), @(maxI)]) {
        CGPoint p = pt(idx.unsignedIntegerValue);
        UIColor *c = idx.unsignedIntegerValue == minI ? t.success : t.warning;
        UIBezierPath *dot = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - 4.5, p.y - 4.5, 9, 9)];
        [t.surface setFill]; [dot fill];
        dot.lineWidth = 2.5; [c setStroke]; [dot stroke];
        NSString *label = [NSString stringWithFormat:@"%.1f", self.values[idx.unsignedIntegerValue].doubleValue];
        CGFloat ly = idx.unsignedIntegerValue == minI ? p.y + 6 : p.y - 18;
        NSTextAlignment al = p.x < 30 ? NSTextAlignmentLeft : (p.x > self.bounds.size.width - 30 ? NSTextAlignmentRight : NSTextAlignmentCenter);
        GCDrawText(label, CGPointMake(p.x, ly), [UIFont systemFontOfSize:10 weight:UIFontWeightBold], c, al);
    }
    if (self.labels.count == n) {
        GCDrawText(self.labels.firstObject, CGPointMake(plot.origin.x, CGRectGetMaxY(plot) + 4), small, t.textTertiary, NSTextAlignmentLeft);
        GCDrawText(self.labels.lastObject, CGPointMake(CGRectGetMaxX(plot), CGRectGetMaxY(plot) + 4), small, t.textTertiary, NSTextAlignmentRight);
    }
}

@end

#pragma mark - Gauge

@implementation GarageGaugeView

+ (UIColor *)colorForHealth:(CGFloat)health {
    AppThemeManager *t = AppThemeManager.shared;
    if (health < 0.15) return t.danger;
    if (health < 0.4) return t.warning;
    return t.success;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        _lineWidth = 12;
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)setValue:(CGFloat)value {
    _value = MAX(0, MIN(1, value));
    self.accessibilityValue = [NSString stringWithFormat:@"%.0f%%", _value * 100];
    [self setNeedsDisplay];
}

- (void)setCaption:(NSString *)caption { _caption = [caption copy]; self.accessibilityLabel = caption; [self setNeedsDisplay]; }

- (void)drawRect:(CGRect)rect {
    AppThemeManager *t = AppThemeManager.shared;
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    CGFloat r = MIN(w / 2, h * 0.86) - self.lineWidth / 2 - 1;
    CGPoint c = CGPointMake(w / 2, r + self.lineWidth / 2 + 1);
    CGFloat start = M_PI * 0.8, end = M_PI * 2.2;

    UIBezierPath *track = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start endAngle:end clockwise:YES];
    track.lineWidth = self.lineWidth; track.lineCapStyle = kCGLineCapRound;
    [t.surfaceRaised setStroke]; [track stroke];

    if (self.value > 0.005) {
        UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:start
                                                         endAngle:start + (end - start) * self.value clockwise:YES];
        arc.lineWidth = self.lineWidth; arc.lineCapStyle = kCGLineCapRound;
        [[GarageGaugeView colorForHealth:self.value] setStroke]; [arc stroke];
    }
    UIFont *big = [UIFont systemFontOfSize:MAX(16, r * 0.5) weight:UIFontWeightBold];
    NSString *pct = [NSString stringWithFormat:@"%.0f%%", self.value * 100];
    GCDrawText(pct, CGPointMake(c.x, c.y - big.lineHeight * 0.62), big, t.textPrimary, NSTextAlignmentCenter);
    if (self.caption) {
        UIFont *cap = [UIFont systemFontOfSize:MAX(10, r * 0.2) weight:UIFontWeightSemibold];
        GCDrawText(self.caption, CGPointMake(c.x, c.y + big.lineHeight * 0.38), cap, t.textSecondary, NSTextAlignmentCenter);
    }
}

@end

#pragma mark - Car

@implementation GarageCarView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        _bodyColor = AppThemeManager.shared.accent;
        self.isAccessibilityElement = NO;
    }
    return self;
}

- (void)setBodyColor:(UIColor *)bodyColor { _bodyColor = bodyColor; [self setNeedsDisplay]; }

/// Drawn in a 240×100 design space and scaled to fit.
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat s = MIN(self.bounds.size.width / 240.0, self.bounds.size.height / 100.0);
    CGContextTranslateCTM(ctx, (self.bounds.size.width - 240 * s) / 2, (self.bounds.size.height - 100 * s) / 2);
    CGContextScaleCTM(ctx, s, s);

    // Ground shadow
    UIBezierPath *shadow = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(18, 86, 204, 10)];
    [[UIColor colorWithWhite:0 alpha:0.18] setFill];
    [shadow fill];

    // Body
    UIBezierPath *body = UIBezierPath.bezierPath;
    [body moveToPoint:CGPointMake(14, 74)];
    [body addCurveToPoint:CGPointMake(22, 54) controlPoint1:CGPointMake(10, 64) controlPoint2:CGPointMake(14, 56)];
    [body addLineToPoint:CGPointMake(62, 48)];
    [body addCurveToPoint:CGPointMake(96, 24) controlPoint1:CGPointMake(74, 38) controlPoint2:CGPointMake(84, 27)];
    [body addCurveToPoint:CGPointMake(158, 24) controlPoint1:CGPointMake(116, 19) controlPoint2:CGPointMake(140, 19)];
    [body addCurveToPoint:CGPointMake(196, 48) controlPoint1:CGPointMake(172, 28) controlPoint2:CGPointMake(184, 40)];
    [body addCurveToPoint:CGPointMake(226, 58) controlPoint1:CGPointMake(212, 50) controlPoint2:CGPointMake(222, 52)];
    [body addCurveToPoint:CGPointMake(228, 76) controlPoint1:CGPointMake(230, 63) controlPoint2:CGPointMake(231, 72)];
    [body addLineToPoint:CGPointMake(14, 78)];
    [body closePath];

    CGContextSaveGState(ctx);
    [body addClip];
    CGFloat r, g, b, a;
    if (![self.bodyColor getRed:&r green:&g blue:&b alpha:&a]) { r = g = b = 0.4; a = 1; }
    UIColor *light = [UIColor colorWithRed:MIN(1, r + 0.22) green:MIN(1, g + 0.22) blue:MIN(1, b + 0.22) alpha:1];
    UIColor *dark = [UIColor colorWithRed:r * 0.62 green:g * 0.62 blue:b * 0.62 alpha:1];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSArray *colors = @[(id)light.CGColor, (id)self.bodyColor.CGColor, (id)dark.CGColor];
    CGFloat stops[] = {0, 0.45, 1};
    CGGradientRef grad = CGGradientCreateWithColors(space, (__bridge CFArrayRef)colors, stops);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, 20), CGPointMake(0, 80), 0);
    CGGradientRelease(grad);
    CGColorSpaceRelease(space);
    // Shoulder highlight
    UIBezierPath *shine = UIBezierPath.bezierPath;
    [shine moveToPoint:CGPointMake(26, 57)];
    [shine addLineToPoint:CGPointMake(222, 60)];
    shine.lineWidth = 1.6;
    [[UIColor colorWithWhite:1 alpha:0.35] setStroke];
    [shine stroke];
    CGContextRestoreGState(ctx);

    // Windows
    UIBezierPath *win = UIBezierPath.bezierPath;
    [win moveToPoint:CGPointMake(72, 48)];
    [win addCurveToPoint:CGPointMake(100, 29) controlPoint1:CGPointMake(82, 39) controlPoint2:CGPointMake(90, 31)];
    [win addLineToPoint:CGPointMake(124, 27)];
    [win addLineToPoint:CGPointMake(124, 48)];
    [win closePath];
    [win moveToPoint:CGPointMake(130, 27)];
    [win addLineToPoint:CGPointMake(154, 28)];
    [win addCurveToPoint:CGPointMake(184, 48) controlPoint1:CGPointMake(166, 31) controlPoint2:CGPointMake(176, 40)];
    [win addLineToPoint:CGPointMake(130, 48)];
    [win closePath];
    [[UIColor colorWithRed:0.16 green:0.2 blue:0.28 alpha:0.92] setFill];
    [win fill];
    UIBezierPath *glare = UIBezierPath.bezierPath;
    [glare moveToPoint:CGPointMake(92, 46)];
    [glare addLineToPoint:CGPointMake(108, 30)];
    [glare addLineToPoint:CGPointMake(116, 30)];
    [glare addLineToPoint:CGPointMake(100, 46)];
    [glare closePath];
    [[UIColor colorWithWhite:1 alpha:0.16] setFill];
    [glare fill];

    // Door line, handle, lights
    UIBezierPath *door = UIBezierPath.bezierPath;
    [door moveToPoint:CGPointMake(127, 30)];
    [door addLineToPoint:CGPointMake(127, 76)];
    door.lineWidth = 1;
    [[UIColor colorWithWhite:0 alpha:0.18] setStroke];
    [door stroke];
    [[UIColor colorWithWhite:1 alpha:0.5] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(138, 55, 12, 3) cornerRadius:1.5] fill];
    [[UIColor colorWithRed:1 green:0.93 blue:0.7 alpha:1] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(216, 58, 10, 5) cornerRadius:2.5] fill];
    [[UIColor colorWithRed:0.95 green:0.25 blue:0.25 alpha:1] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(14, 56, 7, 6) cornerRadius:2] fill];

    // Wheels
    for (NSNumber *cx in @[@60, @184]) {
        CGFloat x = cx.doubleValue;
        [[UIColor colorWithWhite:0 alpha:0.35] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x - 21, 56, 42, 42)] fill];  // arch shadow
        [[UIColor colorWithWhite:0.12 alpha:1] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x - 18, 60, 36, 36)] fill];
        [[UIColor colorWithWhite:0.78 alpha:1] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x - 10, 68, 20, 20)] fill];
        [[UIColor colorWithWhite:0.55 alpha:1] setStroke];
        for (int k = 0; k < 5; k++) {
            CGFloat ang = k * 2 * M_PI / 5 - M_PI_2;
            UIBezierPath *spoke = UIBezierPath.bezierPath;
            [spoke moveToPoint:CGPointMake(x, 78)];
            [spoke addLineToPoint:CGPointMake(x + cos(ang) * 9, 78 + sin(ang) * 9)];
            spoke.lineWidth = 2.2;
            spoke.lineCapStyle = kCGLineCapRound;
            [spoke stroke];
        }
        [[UIColor colorWithWhite:0.35 alpha:1] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(x - 3, 75, 6, 6)] fill];
    }
}

@end
