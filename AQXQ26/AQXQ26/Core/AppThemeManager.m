//
//  AppThemeManager.m
//  WorkSpace
//

#import "AppThemeManager.h"

static UIColor *WSDynamic(uint32_t light, uint32_t dark) {
    UIColor *(^make)(uint32_t) = ^UIColor *(uint32_t hex) {
        return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                               green:((hex >> 8) & 0xFF) / 255.0
                                blue:(hex & 0xFF) / 255.0
                               alpha:1.0];
    };
    UIColor *l = make(light), *d = make(dark);
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? d : l;
    }];
}

@implementation AppThemeManager {
    NSDictionary<NSString *, UIColor *> *_palette;
}

+ (instancetype)shared {
    static AppThemeManager *theme;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ theme = [[self alloc] init]; });
    return theme;
}

- (instancetype)init {
    if ((self = [super init])) {
        _accent        = WSDynamic(0x4F46E5, 0x8B85FF);
        _background    = WSDynamic(0xF4F5F9, 0x0E0F13);
        _surface       = WSDynamic(0xFFFFFF, 0x1A1C22);
        _surfaceRaised = WSDynamic(0xEEF0F6, 0x262932);
        _textPrimary   = WSDynamic(0x15171C, 0xF2F3F7);
        _textSecondary = WSDynamic(0x5C6270, 0xA6ABB8);
        _textTertiary  = WSDynamic(0x9AA0AD, 0x6C7180);
        _separator     = WSDynamic(0xE3E5EC, 0x2C2F38);
        _success       = WSDynamic(0x16A34A, 0x4ADE80);
        _warning       = WSDynamic(0xD97706, 0xFBBF24);
        _danger        = WSDynamic(0xDC2626, 0xF87171);

        _palette = @{
            @"indigo": _accent,
            @"teal":   WSDynamic(0x0D9488, 0x2DD4BF),
            @"sky":    WSDynamic(0x0284C7, 0x38BDF8),
            @"amber":  WSDynamic(0xD97706, 0xFBBF24),
            @"rose":   WSDynamic(0xE11D48, 0xFB7185),
            @"violet": WSDynamic(0x7C3AED, 0xA78BFA),
            @"lime":   WSDynamic(0x65A30D, 0xA3E635),
            @"slate":  WSDynamic(0x475569, 0x94A3B8),
        };
        _paletteIdentifiers = @[@"indigo", @"teal", @"sky", @"amber", @"rose", @"violet", @"lime", @"slate"];
        _spacing = 16;
        _spacingSmall = 8;
        _cornerRadius = 14;
    }
    return self;
}

- (void)applyGlobalAppearance {
    UINavigationBarAppearance *nav = [[UINavigationBarAppearance alloc] init];
    [nav configureWithDefaultBackground];
    nav.backgroundColor = self.background;
    nav.shadowColor = UIColor.clearColor;
    nav.titleTextAttributes = @{NSForegroundColorAttributeName: self.textPrimary, NSFontAttributeName: self.fontHeadline};
    nav.largeTitleTextAttributes = @{NSForegroundColorAttributeName: self.textPrimary, NSFontAttributeName: self.fontLargeTitle};

    // Only style WorkSpace navigation stacks so the migrated Me module keeps its own look.
    Class wsNav = NSClassFromString(@"NavigationController");
    if (wsNav) {
        UINavigationBar *bar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[wsNav]];
        bar.standardAppearance = nav;
        bar.scrollEdgeAppearance = nav;
        bar.compactAppearance = nav;
        bar.tintColor = self.accent;
        bar.prefersLargeTitles = YES;
    }
}

#pragma mark - Semantic colors

- (UIColor *)colorForPriority:(TaskPriority)priority {
    switch (priority) {
        case TaskPriorityLow:    return [self colorForIdentifier:@"slate"];
        case TaskPriorityMedium: return [self colorForIdentifier:@"sky"];
        case TaskPriorityHigh:   return self.warning;
        case TaskPriorityUrgent: return self.danger;
    }
    return self.textTertiary;
}

- (UIColor *)colorForTaskStatus:(TaskStatus)status {
    switch (status) {
        case TaskStatusToDo:       return self.textTertiary;
        case TaskStatusInProgress: return self.accent;
        case TaskStatusCompleted:  return self.success;
        case TaskStatusCancelled:  return [self colorForIdentifier:@"slate"];
    }
    return self.textTertiary;
}

- (UIColor *)colorForProjectStatus:(ProjectStatus)status {
    switch (status) {
        case ProjectStatusPlanning:  return [self colorForIdentifier:@"sky"];
        case ProjectStatusActive:    return self.accent;
        case ProjectStatusPaused:    return self.warning;
        case ProjectStatusCompleted: return self.success;
        case ProjectStatusArchived:  return [self colorForIdentifier:@"slate"];
    }
    return self.textTertiary;
}

- (UIColor *)colorForScheduleKind:(ScheduleKind)kind {
    NSArray *ids = @[@"sky", @"violet", @"amber", @"rose", @"teal"];
    return [self colorForIdentifier:(kind >= 0 && kind < (NSInteger)ids.count) ? ids[kind] : nil];
}

- (UIColor *)colorForObjectKind:(WSObjectKind)kind {
    NSArray *ids = @[@"indigo", @"teal", @"amber", @"sky", @"rose", @"violet", @"lime", @"slate", @"slate"];
    return [self colorForIdentifier:(kind >= 0 && kind < (NSInteger)ids.count) ? ids[kind] : nil];
}

- (UIColor *)colorForIdentifier:(NSString *)identifier {
    return (identifier ? _palette[identifier] : nil) ?: self.accent;
}

#pragma mark - Type

- (UIFont *)wsFontForStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight {
    UIFontDescriptor *base = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    UIFont *font = [UIFont systemFontOfSize:base.pointSize weight:weight];
    UIFontDescriptor *rounded = [font.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    if (rounded) font = [UIFont fontWithDescriptor:rounded size:base.pointSize];
    return [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:font];
}

- (UIFont *)fontLargeTitle { return [self wsFontForStyle:UIFontTextStyleLargeTitle weight:UIFontWeightBold]; }
- (UIFont *)fontTitle      { return [self wsFontForStyle:UIFontTextStyleTitle3 weight:UIFontWeightSemibold]; }
- (UIFont *)fontHeadline   { return [self wsFontForStyle:UIFontTextStyleHeadline weight:UIFontWeightSemibold]; }
- (UIFont *)fontBody       { return [self wsFontForStyle:UIFontTextStyleBody weight:UIFontWeightRegular]; }
- (UIFont *)fontCallout    { return [self wsFontForStyle:UIFontTextStyleCallout weight:UIFontWeightRegular]; }
- (UIFont *)fontCaption    { return [self wsFontForStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium]; }
- (UIFont *)fontMetric     { return [self wsFontForStyle:UIFontTextStyleTitle1 weight:UIFontWeightBold]; }

- (void)styleCard:(UIView *)view {
    view.backgroundColor = self.surface;
    view.layer.cornerRadius = self.cornerRadius;
    view.layer.cornerCurve = kCACornerCurveContinuous;
    view.layer.borderWidth = 1.0 / UIScreen.mainScreen.scale;
    view.layer.borderColor = self.separator.CGColor;
}

@end
