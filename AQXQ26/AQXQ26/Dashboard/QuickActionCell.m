//
//  QuickActionCell.m
//  WorkSpace
//

#import "QuickActionCell.h"
#import "WSUIKit.h"

@interface QuickActionCell ()
@property (nonatomic, strong) UIView *badge;
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation QuickActionCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        _badge = UIView.new;
        _badge.layer.cornerRadius = 16;
        _badge.layer.cornerCurve = kCACornerCurveContinuous;
        _badge.translatesAutoresizingMaskIntoConstraints = NO;
        _icon = UIImageView.new;
        _icon.contentMode = UIViewContentModeCenter;
        _icon.translatesAutoresizingMaskIntoConstraints = NO;
        [_badge addSubview:_icon];
        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontCaption;
        _titleLabel.textColor = t.textPrimary;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_badge];
        [self.contentView addSubview:_titleLabel];
        [NSLayoutConstraint activateConstraints:@[
            [_badge.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_badge.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
            [_badge.widthAnchor constraintEqualToConstant:52],
            [_badge.heightAnchor constraintEqualToConstant:52],
            [_icon.centerXAnchor constraintEqualToAnchor:_badge.centerXAnchor],
            [_icon.centerYAnchor constraintEqualToAnchor:_badge.centerYAnchor],
            [_titleLabel.topAnchor constraintEqualToAnchor:_badge.bottomAnchor constant:6],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        ]];
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}

- (void)configureTitle:(NSString *)title symbol:(NSString *)symbol color:(UIColor *)color {
    self.titleLabel.text = title;
    self.icon.image = [UIImage ws_symbol:symbol pointSize:20 weight:UIImageSymbolWeightSemibold];
    self.icon.tintColor = color;
    self.badge.backgroundColor = [color colorWithAlphaComponent:0.14];
    self.accessibilityLabel = title;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.contentView.alpha = highlighted ? 0.55 : 1;
}

@end
