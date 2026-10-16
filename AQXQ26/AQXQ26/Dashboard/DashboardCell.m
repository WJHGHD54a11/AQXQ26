//
//  DashboardCell.m
//  WorkSpace
//

#import "DashboardCell.h"
#import "WSUIKit.h"

@interface DashboardMetricCell ()
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UIImageView *icon;
@end

@implementation DashboardMetricCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        [t styleCard:self.contentView];
        _icon = UIImageView.new;
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        _valueLabel = UILabel.new;
        _valueLabel.font = t.fontMetric;
        _valueLabel.textColor = t.textPrimary;
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.6;
        _captionLabel = UILabel.new;
        _captionLabel.font = t.fontCaption;
        _captionLabel.textColor = t.textSecondary;
        _captionLabel.numberOfLines = 2;
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_icon, _valueLabel, _captionLabel]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentLeading;
        stack.spacing = 2;
        [stack setCustomSpacing:8 afterView:_icon];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [stack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}

- (void)configureValue:(NSString *)value caption:(NSString *)caption symbol:(NSString *)symbol color:(UIColor *)color {
    self.valueLabel.text = value;
    self.captionLabel.text = caption;
    self.icon.image = [UIImage ws_symbol:symbol pointSize:15 weight:UIImageSymbolWeightSemibold];
    self.icon.tintColor = color;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", caption, value];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.contentView.alpha = highlighted ? 0.6 : 1;
}

@end

@implementation DashboardCell

- (void)configureTitle:(NSString *)title subtitle:(NSString *)subtitle symbol:(NSString *)symbol color:(UIColor *)color accessory:(NSString *)accessory {
    AppThemeManager *t = AppThemeManager.shared;
    self.backgroundConfiguration = WSListBackground();
    UIListContentConfiguration *c = [UIListContentConfiguration subtitleCellConfiguration];
    c.text = title;
    c.textProperties.font = t.fontBody;
    c.textProperties.color = t.textPrimary;
    c.textProperties.numberOfLines = 1;
    c.secondaryText = subtitle;
    c.secondaryTextProperties.font = t.fontCaption;
    c.secondaryTextProperties.color = t.textSecondary;
    c.image = [UIImage ws_symbol:symbol pointSize:18 weight:UIImageSymbolWeightMedium];
    c.imageProperties.tintColor = color;
    c.imageProperties.reservedLayoutSize = CGSizeMake(28, 28);
    self.contentConfiguration = c;
    if (accessory.length) {
        UILabel *label = UILabel.new;
        label.text = accessory;
        label.font = t.fontCaption;
        label.textColor = t.textTertiary;
        UICellAccessoryCustomView *custom = [[UICellAccessoryCustomView alloc] initWithCustomView:label placement:UICellAccessoryPlacementTrailing];
        self.accessories = @[custom];
    } else {
        self.accessories = @[];
    }
}

@end
