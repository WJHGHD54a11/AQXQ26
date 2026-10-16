//
//  NoteCell.m
//  WorkSpace
//

#import "NoteCell.h"
#import "WSUIKit.h"
#import "NoteManager.h"
#import "TagManager.h"
#import "Task+Logic.h"
#import "Note.h"
#import "NoteCategory.h"

@interface NoteCell ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *previewLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIView *categoryDot;
@property (nonatomic, strong) UILabel *categoryLabel;
@property (nonatomic, strong) UILabel *tagsLabel;
@property (nonatomic, strong) UIImageView *pinIcon;
@property (nonatomic, strong) UIImageView *favoriteIcon;
@end

@implementation NoteCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.backgroundConfiguration = WSListBackground();

        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontHeadline;
        _titleLabel.textColor = t.textPrimary;

        _pinIcon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"pin.fill" pointSize:11 weight:UIImageSymbolWeightBold]];
        _pinIcon.tintColor = t.accent;
        _favoriteIcon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"star.fill" pointSize:11 weight:UIImageSymbolWeightBold]];
        _favoriteIcon.tintColor = t.warning;
        for (UIView *v in @[_pinIcon, _favoriteIcon]) {
            [v setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
            [v setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        }

        _dateLabel = UILabel.new;
        _dateLabel.font = t.fontCaption;
        _dateLabel.textColor = t.textTertiary;
        [_dateLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_dateLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        UIStackView *top = [[UIStackView alloc] initWithArrangedSubviews:@[_pinIcon, _titleLabel, _favoriteIcon, _dateLabel]];
        top.spacing = 6;
        top.alignment = UIStackViewAlignmentCenter;

        _previewLabel = UILabel.new;
        _previewLabel.font = t.fontCallout;
        _previewLabel.textColor = t.textSecondary;
        _previewLabel.numberOfLines = 2;

        _categoryDot = UIView.new;
        _categoryDot.layer.cornerRadius = 3.5;
        _categoryDot.translatesAutoresizingMaskIntoConstraints = NO;
        _categoryLabel = UILabel.new;
        _categoryLabel.font = t.fontCaption;
        _categoryLabel.textColor = t.textSecondary;
        [_categoryLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        _tagsLabel = UILabel.new;
        _tagsLabel.font = t.fontCaption;
        _tagsLabel.textColor = t.accent;

        UIStackView *meta = [[UIStackView alloc] initWithArrangedSubviews:@[_categoryDot, _categoryLabel, _tagsLabel]];
        meta.spacing = 6;
        meta.alignment = UIStackViewAlignmentCenter;
        [meta setCustomSpacing:4 afterView:_categoryDot];
        [meta setCustomSpacing:10 afterView:_categoryLabel];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[top, _previewLabel, meta]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 4;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:stack];

        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_categoryDot.widthAnchor constraintEqualToConstant:7],
            [_categoryDot.heightAnchor constraintEqualToConstant:7],
            [stack.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [stack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [stack.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (void)configureWithNote:(Note *)note {
    AppThemeManager *t = AppThemeManager.shared;
    self.titleLabel.text = note.title.length ? note.title : WSText(@"Untitled");
    self.pinIcon.hidden = !note.isPinned;
    self.favoriteIcon.hidden = !note.isFavorite;
    self.dateLabel.text = [Task relativeDayText:note.updatedAt ?: note.createdAt includeTime:NO];

    NSString *preview = [NoteManager previewOf:note];
    self.previewLabel.text = preview.length ? preview : WSText(@"No additional text");
    self.previewLabel.textColor = preview.length ? t.textSecondary : t.textTertiary;

    NoteCategory *category = note.category;
    self.categoryDot.backgroundColor = category ? [t colorForIdentifier:category.colorIdentifier] : t.textTertiary;
    self.categoryLabel.text = category ? category.name : WSText(@"Uncategorized");

    NSString *tags = [TagManager joinedNames:note.tags];
    self.tagsLabel.text = tags.length ? [@"#" stringByAppendingString:[tags stringByReplacingOccurrencesOfString:@", " withString:@"  #"]] : nil;
    self.tagsLabel.hidden = tags.length == 0;

    NSMutableArray *a11y = [NSMutableArray arrayWithObject:self.titleLabel.text];
    if (note.isPinned) [a11y addObject:WSText(@"Pinned")];
    if (note.isFavorite) [a11y addObject:WSText(@"Favorite")];
    [a11y addObject:self.categoryLabel.text];
    if (preview.length) [a11y addObject:preview];
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = [a11y componentsJoinedByString:@", "];
    self.accessibilityValue = self.dateLabel.text;
}

@end
