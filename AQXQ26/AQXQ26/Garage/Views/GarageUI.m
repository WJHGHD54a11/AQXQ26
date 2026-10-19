//
//  GarageUI.m
//  WorkSpace
//

#import "GarageUI.h"
#import "GarageManager.h"
#import "GarageCatalog.h"
#import "GarageCharts.h"
#import "MaintenancePlan.h"
#import "AppThemeManager.h"
#import "WSUIKit.h"

UIView *GarageSpacer(CGFloat height) {
    UIView *v = UIView.new;
    [v.heightAnchor constraintEqualToConstant:height].active = YES;
    return v;
}

UILabel *GarageLabel(NSString *text, UIFont *font, UIColor *color, NSInteger lines) {
    UILabel *l = UILabel.new;
    l.text = text; l.font = font; l.textColor = color; l.numberOfLines = lines;
    l.adjustsFontForContentSizeCategory = YES;
    return l;
}

NSString *GarageShortDate(NSDate *date) {
    static NSDateFormatter *f;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ f = NSDateFormatter.new; f.dateStyle = NSDateFormatterMediumStyle; f.timeStyle = NSDateFormatterNoStyle; });
    return date ? [f stringFromDate:date] : @"";
}

#pragma mark - Card

@implementation GarageCard {
    UIStackView *_content;
}

+ (instancetype)cardWithTitle:(NSString *)title action:(NSString *)action handler:(void (^)(void))handler {
    AppThemeManager *t = AppThemeManager.shared;
    GarageCard *card = [[self alloc] initWithFrame:CGRectZero];
    [t styleCard:card];
    UIStackView *outer = [[UIStackView alloc] init];
    outer.axis = UILayoutConstraintAxisVertical;
    outer.spacing = 12;
    outer.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:outer];
    [NSLayoutConstraint activateConstraints:@[
        [outer.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [outer.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [outer.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [outer.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];
    if (title) {
        UIStackView *header = [[UIStackView alloc] init];
        header.alignment = UIStackViewAlignmentCenter;
        UILabel *label = GarageLabel(title, t.fontHeadline, t.textPrimary, 1);
        label.accessibilityTraits = UIAccessibilityTraitHeader;
        [header addArrangedSubview:label];
        if (action && handler) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button setTitle:action forState:UIControlStateNormal];
            button.titleLabel.font = t.fontCallout;
            button.tintColor = t.accent;
            [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [button addAction:[UIAction actionWithHandler:^(UIAction *a) { handler(); }] forControlEvents:UIControlEventTouchUpInside];
            [header addArrangedSubview:button];
        }
        [outer addArrangedSubview:header];
    }
    card->_content = [[UIStackView alloc] init];
    card->_content.axis = UILayoutConstraintAxisVertical;
    card->_content.spacing = 10;
    [outer addArrangedSubview:card->_content];
    return card;
}

- (UIStackView *)content { return _content; }

- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    self.layer.borderColor = AppThemeManager.shared.separator.CGColor;
}

@end

#pragma mark - Stat tile

@implementation GarageStatTile

+ (instancetype)tileWithValue:(NSString *)value caption:(NSString *)caption symbol:(NSString *)symbol color:(UIColor *)color {
    AppThemeManager *t = AppThemeManager.shared;
    GarageStatTile *tile = [[self alloc] initWithFrame:CGRectZero];
    tile.backgroundColor = t.surfaceRaised;
    tile.layer.cornerRadius = 12;
    tile.layer.cornerCurve = kCACornerCurveContinuous;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:symbol pointSize:13 weight:UIImageSymbolWeightSemibold]];
    icon.tintColor = color;
    UILabel *v = GarageLabel(value, [UIFont monospacedDigitSystemFontOfSize:19 weight:UIFontWeightBold], t.textPrimary, 1);
    v.adjustsFontSizeToFitWidth = YES;
    v.minimumScaleFactor = 0.6;
    UILabel *c = GarageLabel(caption, t.fontCaption, t.textSecondary, 1);
    c.adjustsFontSizeToFitWidth = YES;
    c.minimumScaleFactor = 0.8;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[icon, v, c]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentLeading;
    stack.spacing = 3;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [tile addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:tile.topAnchor constant:12],
        [stack.bottomAnchor constraintEqualToAnchor:tile.bottomAnchor constant:-12],
        [stack.leadingAnchor constraintEqualToAnchor:tile.leadingAnchor constant:12],
        [stack.trailingAnchor constraintEqualToAnchor:tile.trailingAnchor constant:-8],
    ]];
    tile.isAccessibilityElement = YES;
    tile.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", caption, value];
    return tile;
}

@end

#pragma mark - Row

@implementation GarageRow {
    UIView *_bubble;
    UIImageView *_icon;
    WSProgressRing *_ring;
    UILabel *_trailing;
}

+ (instancetype)rowWithSymbol:(NSString *)symbol color:(UIColor *)color title:(NSString *)title
                     subtitle:(NSString *)subtitle trailing:(NSString *)trailing {
    AppThemeManager *t = AppThemeManager.shared;
    GarageRow *row = [[self alloc] initWithFrame:CGRectZero];
    row->_bubble = UIView.new;
    row->_bubble.backgroundColor = [color colorWithAlphaComponent:0.15];
    row->_bubble.layer.cornerRadius = 10;
    row->_bubble.userInteractionEnabled = NO;
    row->_icon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:symbol pointSize:15 weight:UIImageSymbolWeightSemibold]];
    row->_icon.tintColor = color;
    row->_icon.contentMode = UIViewContentModeCenter;
    row->_icon.translatesAutoresizingMaskIntoConstraints = NO;
    [row->_bubble addSubview:row->_icon];

    UILabel *titleLabel = GarageLabel(title, t.fontBody, t.textPrimary, 1);
    UILabel *sub = GarageLabel(subtitle, t.fontCaption, t.textSecondary, 2);
    sub.hidden = subtitle.length == 0;
    UIStackView *texts = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, sub]];
    texts.axis = UILayoutConstraintAxisVertical;
    texts.spacing = 2;
    texts.userInteractionEnabled = NO;
    row->_trailing = GarageLabel(trailing, [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold], t.textPrimary, 1);
    row->_trailing.textAlignment = NSTextAlignmentRight;
    row->_trailing.hidden = trailing.length == 0;
    [row->_trailing setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [row->_trailing setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

    UIStackView *h = [[UIStackView alloc] initWithArrangedSubviews:@[row->_bubble, texts, row->_trailing]];
    h.alignment = UIStackViewAlignmentCenter;
    h.spacing = 12;
    h.userInteractionEnabled = NO;
    h.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:h];
    [NSLayoutConstraint activateConstraints:@[
        [row->_bubble.widthAnchor constraintEqualToConstant:36],
        [row->_bubble.heightAnchor constraintEqualToConstant:36],
        [row->_icon.centerXAnchor constraintEqualToAnchor:row->_bubble.centerXAnchor],
        [row->_icon.centerYAnchor constraintEqualToAnchor:row->_bubble.centerYAnchor],
        [h.topAnchor constraintEqualToAnchor:row.topAnchor constant:2],
        [h.bottomAnchor constraintEqualToAnchor:row.bottomAnchor constant:-2],
        [h.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],
        [h.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],
    ]];
    [row addAction:[UIAction actionWithHandler:^(UIAction *a) { if (row.onTap) row.onTap(); }] forControlEvents:UIControlEventTouchUpInside];
    row.isAccessibilityElement = YES;
    row.accessibilityTraits = UIAccessibilityTraitButton;
    NSMutableArray *parts = [NSMutableArray arrayWithObject:title];
    if (subtitle.length) [parts addObject:subtitle];
    if (trailing.length) [parts addObject:trailing];
    row.accessibilityLabel = [parts componentsJoinedByString:@", "];
    return row;
}

- (UILabel *)trailingLabel { return _trailing; }

- (void)showRing:(CGFloat)progress color:(UIColor *)color {
    if (!_ring) {
        _ring = [[WSProgressRing alloc] initWithFrame:CGRectZero];
        _ring.lineWidth = 3.5;
        _ring.userInteractionEnabled = NO;
        _ring.translatesAutoresizingMaskIntoConstraints = NO;
        [_bubble addSubview:_ring];
        [NSLayoutConstraint activateConstraints:@[
            [_ring.topAnchor constraintEqualToAnchor:_bubble.topAnchor],
            [_ring.bottomAnchor constraintEqualToAnchor:_bubble.bottomAnchor],
            [_ring.leadingAnchor constraintEqualToAnchor:_bubble.leadingAnchor],
            [_ring.trailingAnchor constraintEqualToAnchor:_bubble.trailingAnchor],
        ]];
    }
    _bubble.backgroundColor = UIColor.clearColor;
    _icon.image = [_icon.image imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:12 weight:UIImageSymbolWeightBold]];
    _icon.tintColor = color;
    _ring.tintColorForRing = color;
    _ring.progress = MAX(0.02, progress);
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted && self.onTap ? 0.55 : 1;
}

@end

GarageRow *GarageRowForPlan(PlanStatus *s) {
    UIColor *color = [GarageGaugeView colorForHealth:s.health];
    GarageRow *row = [GarageRow rowWithSymbol:s.item.symbol ?: @"wrench.fill" color:color
                                        title:s.item.name ?: s.plan.itemKey
                                     subtitle:s.remainingText
                                     trailing:[NSString stringWithFormat:@"%.0f%%", s.health * 100]];
    row.trailingLabel.textColor = color;
    [row showRing:s.health color:color];
    return row;
}

GarageRow *GarageRowForEntry(GarageTimelineEntry *e) {
    AppThemeManager *t = AppThemeManager.shared;
    UIColor *color = [t colorForIdentifier:ServiceCategoryColor(e.category)];
    NSMutableArray *sub = [NSMutableArray arrayWithObject:GarageShortDate(e.date)];
    if (e.odometer > 0) [sub addObject:[GarageManager formatDistance:e.odometer]];
    if (e.subtitle.length) [sub addObject:e.subtitle];
    return [GarageRow rowWithSymbol:ServiceCategorySymbol(e.category) color:color title:e.title
                           subtitle:[sub componentsJoinedByString:@" · "]
                           trailing:e.cost > 0 ? [GarageManager formatCost:e.cost] : nil];
}

#pragma mark - Quick button

@implementation GarageQuickButton

+ (instancetype)buttonWithSymbol:(NSString *)symbol title:(NSString *)title color:(UIColor *)color handler:(void (^)(void))handler {
    AppThemeManager *t = AppThemeManager.shared;
    GarageQuickButton *b = [[self alloc] initWithFrame:CGRectZero];
    UIView *circle = UIView.new;
    circle.backgroundColor = [color colorWithAlphaComponent:0.14];
    circle.layer.cornerRadius = 24;
    circle.userInteractionEnabled = NO;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:symbol pointSize:18 weight:UIImageSymbolWeightSemibold]];
    icon.tintColor = color;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [circle addSubview:icon];
    UILabel *label = GarageLabel(title, [UIFont systemFontOfSize:12 weight:UIFontWeightMedium], t.textPrimary, 2);
    label.textAlignment = NSTextAlignmentCenter;
    UIStackView *v = [[UIStackView alloc] initWithArrangedSubviews:@[circle, label]];
    v.axis = UILayoutConstraintAxisVertical;
    v.alignment = UIStackViewAlignmentCenter;
    v.spacing = 6;
    v.userInteractionEnabled = NO;
    v.translatesAutoresizingMaskIntoConstraints = NO;
    [b addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [circle.widthAnchor constraintEqualToConstant:48], [circle.heightAnchor constraintEqualToConstant:48],
        [icon.centerXAnchor constraintEqualToAnchor:circle.centerXAnchor], [icon.centerYAnchor constraintEqualToAnchor:circle.centerYAnchor],
        [v.topAnchor constraintEqualToAnchor:b.topAnchor], [v.bottomAnchor constraintEqualToAnchor:b.bottomAnchor],
        [v.leadingAnchor constraintEqualToAnchor:b.leadingAnchor], [v.trailingAnchor constraintEqualToAnchor:b.trailingAnchor],
    ]];
    [b addAction:[UIAction actionWithHandler:^(UIAction *a) { handler(); }] forControlEvents:UIControlEventTouchUpInside];
    b.isAccessibilityElement = YES;
    b.accessibilityTraits = UIAccessibilityTraitButton;
    b.accessibilityLabel = title;
    return b;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.55 : 1;
}

@end

#pragma mark - Scroll stack

@implementation GarageScrollStack {
    UIStackView *_stack;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.alwaysBounceVertical = YES;
        self.backgroundColor = AppThemeManager.shared.background;
        _stack = [[UIStackView alloc] init];
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 16;
        _stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_stack];
        UILayoutGuide *content = self.contentLayoutGuide, *frameGuide = self.frameLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:8],
            [_stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24],
            [_stack.leadingAnchor constraintEqualToAnchor:frameGuide.leadingAnchor constant:16],
            [_stack.trailingAnchor constraintEqualToAnchor:frameGuide.trailingAnchor constant:-16],
        ]];
    }
    return self;
}

- (UIStackView *)stack { return _stack; }

- (void)removeAllCards {
    for (UIView *v in _stack.arrangedSubviews) { [_stack removeArrangedSubview:v]; [v removeFromSuperview]; }
}

@end
