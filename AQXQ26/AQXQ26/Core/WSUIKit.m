//
//  WSUIKit.m
//  WorkSpace
//

#import "WSUIKit.h"

#pragma mark - Chip bar

@implementation WSChipBar {
    UIScrollView *_scroll;
    UIStackView *_stack;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _scroll = UIScrollView.new;
        _scroll.showsHorizontalScrollIndicator = NO;
        _scroll.alwaysBounceHorizontal = YES;
        _scroll.translatesAutoresizingMaskIntoConstraints = NO;
        _stack = UIStackView.new;
        _stack.spacing = 8;
        _stack.alignment = UIStackViewAlignmentCenter;
        _stack.translatesAutoresizingMaskIntoConstraints = NO;
        [_scroll addSubview:_stack];
        [self addSubview:_scroll];
        [NSLayoutConstraint activateConstraints:@[
            [_scroll.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_scroll.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_scroll.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_scroll.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.heightAnchor constraintEqualToConstant:46],
            [_stack.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor constant:16],
            [_stack.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor constant:-16],
            [_stack.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor],
            [_stack.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor],
            [_stack.heightAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.heightAnchor],
        ]];
    }
    return self;
}

- (UIButton *)chip:(NSString *)title selected:(BOOL)selected symbol:(NSString *)symbol handler:(void (^)(void))handler {
    AppThemeManager *t = AppThemeManager.shared;
    UIButtonConfiguration *c = selected ? [UIButtonConfiguration filledButtonConfiguration] : [UIButtonConfiguration grayButtonConfiguration];
    c.title = title;
    c.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    c.baseBackgroundColor = selected ? t.accent : t.surfaceRaised;
    c.baseForegroundColor = selected ? UIColor.whiteColor : t.textPrimary;
    c.contentInsets = NSDirectionalEdgeInsetsMake(6, 14, 6, 14);
    if (symbol) { c.image = [UIImage ws_symbol:symbol pointSize:12 weight:UIImageSymbolWeightSemibold]; c.imagePadding = 4; }
    c.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *attrs) {
        NSMutableDictionary *m = attrs.mutableCopy;
        m[NSFontAttributeName] = t.fontCaption;
        return m;
    };
    UIButton *b = [UIButton buttonWithConfiguration:c primaryAction:[UIAction actionWithHandler:^(UIAction *a) { handler(); }]];
    b.accessibilityTraits = selected ? (UIAccessibilityTraitButton | UIAccessibilityTraitSelected) : UIAccessibilityTraitButton;
    return b;
}

- (void)setTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    for (UIView *v in _stack.arrangedSubviews) [v removeFromSuperview];
    __weak typeof(self) weakSelf = self;
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        [self->_stack addArrangedSubview:[self chip:title selected:(NSInteger)idx == selectedIndex symbol:nil handler:^{
            [weakSelf setTitles:titles selectedIndex:idx];
            if (weakSelf.onSelect) weakSelf.onSelect(idx);
        }]];
    }];
    if (self.accessoryTitle.length) {
        [_stack addArrangedSubview:[self chip:self.accessoryTitle selected:NO symbol:@"slider.horizontal.3" handler:^{
            if (weakSelf.onAccessory) weakSelf.onAccessory();
        }]];
    }
}

@end

#pragma mark - Empty state

@interface WSEmptyStateView ()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, copy) void (^action)(void);
@end

@implementation WSEmptyStateView

+ (instancetype)viewWithSymbol:(NSString *)symbol title:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle action:(void (^)(void))action {
    WSEmptyStateView *v = [[self alloc] initWithFrame:CGRectZero];
    AppThemeManager *t = AppThemeManager.shared;

    UIView *badge = UIView.new;
    badge.backgroundColor = [t.accent colorWithAlphaComponent:0.12];
    badge.layer.cornerRadius = 36;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    v.iconView = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:symbol pointSize:30 weight:UIImageSymbolWeightMedium]];
    v.iconView.tintColor = t.accent;
    v.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    [badge addSubview:v.iconView];

    v.titleLabel = UILabel.new;
    v.titleLabel.font = t.fontTitle;
    v.titleLabel.textColor = t.textPrimary;
    v.titleLabel.textAlignment = NSTextAlignmentCenter;
    v.titleLabel.text = title;

    v.messageLabel = UILabel.new;
    v.messageLabel.font = t.fontCallout;
    v.messageLabel.textColor = t.textSecondary;
    v.messageLabel.textAlignment = NSTextAlignmentCenter;
    v.messageLabel.numberOfLines = 0;
    v.messageLabel.text = message;
    v.messageLabel.hidden = message.length == 0;

    NSMutableArray *views = [NSMutableArray arrayWithObjects:badge, v.titleLabel, v.messageLabel, nil];
    if (actionTitle.length && action) {
        UIButtonConfiguration *config = [UIButtonConfiguration filledButtonConfiguration];
        config.title = actionTitle;
        config.baseBackgroundColor = t.accent;
        config.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        config.contentInsets = NSDirectionalEdgeInsetsMake(10, 20, 10, 20);
        v.button = [UIButton buttonWithConfiguration:config primaryAction:[UIAction actionWithHandler:^(UIAction *a) { action(); }]];
        v.action = action;
        [views addObject:v.button];
    }
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:views];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 10;
    [stack setCustomSpacing:18 afterView:badge];
    if (v.button) [stack setCustomSpacing:20 afterView:v.messageLabel];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [v addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [badge.widthAnchor constraintEqualToConstant:72], [badge.heightAnchor constraintEqualToConstant:72],
        [v.iconView.centerXAnchor constraintEqualToAnchor:badge.centerXAnchor],
        [v.iconView.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor],
        [stack.centerXAnchor constraintEqualToAnchor:v.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:v.centerYAnchor constant:-30],
        [stack.leadingAnchor constraintGreaterThanOrEqualToAnchor:v.leadingAnchor constant:32],
        [stack.trailingAnchor constraintLessThanOrEqualToAnchor:v.trailingAnchor constant:-32],
    ]];
    return v;
}

- (void)setTitle:(NSString *)title { self.titleLabel.text = title; }
- (NSString *)title { return self.titleLabel.text ?: @""; }
- (void)setMessage:(NSString *)message {
    self.messageLabel.text = message;
    self.messageLabel.hidden = message.length == 0;
}
- (NSString *)message { return self.messageLabel.text; }

@end

#pragma mark - Pill

@implementation WSPillLabel {
    UIEdgeInsets _insets;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _insets = UIEdgeInsetsMake(3, 8, 3, 8);
        self.font = AppThemeManager.shared.fontCaption;
        self.layer.cornerRadius = 9;
        self.layer.masksToBounds = YES;
        [self setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    }
    return self;
}

- (void)setText:(NSString *)text color:(UIColor *)color {
    self.text = text;
    self.textColor = color;
    self.backgroundColor = [color colorWithAlphaComponent:0.14];
    self.hidden = text.length == 0;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _insets)];
}

- (CGSize)intrinsicContentSize {
    CGSize s = [super intrinsicContentSize];
    return CGSizeMake(s.width + _insets.left + _insets.right, s.height + _insets.top + _insets.bottom);
}

@end

#pragma mark - Progress ring

@implementation WSProgressRing {
    CAShapeLayer *_track, *_bar;
    UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _lineWidth = 6;
        _tintColorForRing = AppThemeManager.shared.accent;
        _track = CAShapeLayer.layer;
        _bar = CAShapeLayer.layer;
        for (CAShapeLayer *l in @[_track, _bar]) {
            l.fillColor = UIColor.clearColor.CGColor;
            l.lineCap = kCALineCapRound;
            [self.layer addSublayer:l];
        }
        _label = UILabel.new;
        _label.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
        _label.textColor = AppThemeManager.shared.textPrimary;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.adjustsFontSizeToFitWidth = YES;
        _label.minimumScaleFactor = 0.6;
        [self addSubview:_label];
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat r = (MIN(self.bounds.size.width, self.bounds.size.height) - self.lineWidth) / 2;
    CGPoint c = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:c radius:r startAngle:-M_PI_2 endAngle:M_PI * 1.5 clockwise:YES];
    _track.path = _bar.path = path.CGPath;
    _track.lineWidth = _bar.lineWidth = self.lineWidth;
    _label.frame = CGRectInset(self.bounds, self.lineWidth + 2, self.lineWidth + 2);
    [self refresh];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    [self refresh];
}

- (void)setProgress:(CGFloat)progress { _progress = MAX(0, MIN(1, progress)); [self refresh]; }
- (void)setTintColorForRing:(UIColor *)c { _tintColorForRing = c; [self refresh]; }
- (void)setShowsPercentage:(BOOL)show { _showsPercentage = show; [self refresh]; }

- (void)refresh {
    _track.strokeColor = [self.tintColorForRing colorWithAlphaComponent:0.16].CGColor;
    _bar.strokeColor = self.tintColorForRing.CGColor;
    _bar.strokeEnd = self.progress;
    NSString *pct = [NSString stringWithFormat:@"%.0f%%", self.progress * 100];
    _label.hidden = !self.showsPercentage;
    _label.text = pct;
    self.accessibilityValue = pct;
}

@end

#pragma mark - Section header

@implementation WSSectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontHeadline;
        _titleLabel.textColor = t.textPrimary;
        _titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
        _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _actionButton.titleLabel.font = t.fontCallout;
        _actionButton.tintColor = t.accent;
        [_actionButton addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, UIView.new, _actionButton]];
        row.alignment = UIStackViewAlignmentLastBaseline;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:row];
        [NSLayoutConstraint activateConstraints:@[
            [row.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
            [row.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
            [row.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
            [row.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-6],
        ]];
    }
    return self;
}

- (void)setTitle:(NSString *)title action:(NSString *)action {
    self.titleLabel.text = title;
    [self.actionButton setTitle:action forState:UIControlStateNormal];
    self.actionButton.hidden = action.length == 0;
}

- (void)tapped { if (self.onAction) self.onAction(); }

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onAction = nil;
}

@end

#pragma mark - Alerts

@implementation UIViewController (WSAlerts)

- (void)ws_showError:(NSError *)error {
    if (!error) return;
    [self ws_showMessage:error.localizedDescription title:WSText(@"Something went wrong")];
}

- (void)ws_showMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WSText(@"OK") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)ws_confirm:(NSString *)title message:(NSString *)message destructive:(NSString *)action handler:(void (^)(void))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:action style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { handler(); }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)ws_promptTitle:(NSString *)title message:(NSString *)message placeholder:(NSString *)placeholder text:(NSString *)text
                action:(NSString *)action handler:(void (^)(NSString *))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakAlert = alert;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:action style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *value = [weakAlert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (value.length) handler(value);
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = placeholder;
        field.text = text;
        field.clearButtonMode = UITextFieldViewModeWhileEditing;
        field.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [field addAction:[UIAction actionWithHandler:^(UIAction *a) {
            ok.enabled = [field.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length > 0;
        }] forControlEvents:UIControlEventEditingChanged];
    }];
    ok.enabled = text.length > 0;
    [alert addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:ok];
    alert.preferredAction = ok;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)ws_toast:(NSString *)text {
    UIView *host = self.view.window ?: self.view;
    AppThemeManager *t = AppThemeManager.shared;
    UILabel *label = UILabel.new;
    label.text = text;
    label.font = t.fontCallout;
    label.textColor = UIColor.whiteColor;
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark]];
    blur.layer.cornerRadius = 18;
    blur.layer.cornerCurve = kCACornerCurveContinuous;
    blur.clipsToBounds = YES;
    blur.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [blur.contentView addSubview:label];
    [host addSubview:blur];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:blur.leadingAnchor constant:18],
        [label.trailingAnchor constraintEqualToAnchor:blur.trailingAnchor constant:-18],
        [label.topAnchor constraintEqualToAnchor:blur.topAnchor constant:10],
        [label.bottomAnchor constraintEqualToAnchor:blur.bottomAnchor constant:-10],
        [blur.centerXAnchor constraintEqualToAnchor:host.centerXAnchor],
        [blur.bottomAnchor constraintEqualToAnchor:host.safeAreaLayoutGuide.bottomAnchor constant:-72],
        [blur.widthAnchor constraintLessThanOrEqualToAnchor:host.widthAnchor constant:-48],
    ]];
    blur.alpha = 0;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text);
    [UIView animateWithDuration:0.2 animations:^{ blur.alpha = 1; } completion:^(BOOL f) {
        [UIView animateWithDuration:0.25 delay:1.6 options:0 animations:^{ blur.alpha = 0; } completion:^(BOOL done) { [blur removeFromSuperview]; }];
    }];
}

- (void)ws_share:(NSArray *)items from:(id)source {
    if (items.count == 0) return;
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    UIPopoverPresentationController *pop = share.popoverPresentationController;
    if ([source isKindOfClass:UIBarButtonItem.class]) pop.barButtonItem = source;
    else if ([source isKindOfClass:UIView.class]) { pop.sourceView = source; pop.sourceRect = [source bounds]; }
    else { pop.sourceView = self.view; pop.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1); }
    [self presentViewController:share animated:YES completion:nil];
}

@end

@implementation UIImage (WSSymbols)

+ (UIImage *)ws_symbol:(NSString *)name {
    return [UIImage systemImageNamed:name] ?: [UIImage systemImageNamed:@"circle"];
}

+ (UIImage *)ws_symbol:(NSString *)name pointSize:(CGFloat)size weight:(UIImageSymbolWeight)weight {
    UIImageSymbolConfiguration *c = [UIImageSymbolConfiguration configurationWithPointSize:size weight:weight];
    return [[UIImage systemImageNamed:name] imageByApplyingSymbolConfiguration:c] ?: [UIImage systemImageNamed:@"circle" withConfiguration:c];
}

@end

UIBackgroundConfiguration *WSListBackground(void) {
    UIBackgroundConfiguration *bg = [UIBackgroundConfiguration listGroupedCellConfiguration];
    bg.backgroundColor = AppThemeManager.shared.surface;
    return bg;
}

UICollectionViewCompositionalLayout *WSListLayout(UICollectionLayoutListSwipeActionsConfigurationProvider trailing,
                                                  UICollectionLayoutListSwipeActionsConfigurationProvider leading,
                                                  BOOL headers) {
    UICollectionLayoutListConfiguration *config = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    config.backgroundColor = AppThemeManager.shared.background;
    config.trailingSwipeActionsConfigurationProvider = trailing;
    config.leadingSwipeActionsConfigurationProvider = leading;
    config.headerMode = headers ? UICollectionLayoutListHeaderModeSupplementary : UICollectionLayoutListHeaderModeNone;
    config.separatorConfiguration.color = AppThemeManager.shared.separator;
    return [UICollectionViewCompositionalLayout layoutWithListConfiguration:config];
}
