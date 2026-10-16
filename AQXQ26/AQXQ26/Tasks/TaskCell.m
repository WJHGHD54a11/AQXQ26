//
//  TaskCell.m
//  WorkSpace
//

#import "TaskCell.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Project.h"

@interface TaskCell ()
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) WSPillLabel *priorityPill;
@property (nonatomic, strong) UIImageView *favoriteIcon;
@property (nonatomic, strong) UIView *projectDot;
@end

@implementation TaskCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.backgroundConfiguration = WSListBackground();

        _checkButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _checkButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_checkButton addTarget:self action:@selector(toggleTapped) forControlEvents:UIControlEventTouchUpInside];

        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontBody;
        _titleLabel.numberOfLines = 2;

        _projectDot = UIView.new;
        _projectDot.layer.cornerRadius = 4;
        _projectDot.translatesAutoresizingMaskIntoConstraints = NO;

        _metaLabel = UILabel.new;
        _metaLabel.font = t.fontCaption;
        _metaLabel.textColor = t.textSecondary;
        _metaLabel.numberOfLines = 1;

        UIStackView *meta = [[UIStackView alloc] initWithArrangedSubviews:@[_projectDot, _metaLabel]];
        meta.spacing = 6;
        meta.alignment = UIStackViewAlignmentCenter;

        UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, meta]];
        text.axis = UILayoutConstraintAxisVertical;
        text.spacing = 3;

        _priorityPill = WSPillLabel.new;
        _favoriteIcon = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"star.fill" pointSize:11 weight:UIImageSymbolWeightBold]];
        _favoriteIcon.tintColor = t.warning;
        [_favoriteIcon setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        UIStackView *trailing = [[UIStackView alloc] initWithArrangedSubviews:@[_favoriteIcon, _priorityPill]];
        trailing.axis = UILayoutConstraintAxisVertical;
        trailing.alignment = UIStackViewAlignmentTrailing;
        trailing.spacing = 4;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_checkButton, text, trailing]];
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:row];

        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_checkButton.widthAnchor constraintEqualToConstant:30],
            [_checkButton.heightAnchor constraintEqualToConstant:30],
            [_projectDot.widthAnchor constraintEqualToConstant:8],
            [_projectDot.heightAnchor constraintEqualToConstant:8],
            [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [row.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
            [row.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],
        ]];
        // Separator starts after the check button.
        [self.separatorLayoutGuide.leadingAnchor constraintEqualToAnchor:text.leadingAnchor].active = YES;
    }
    return self;
}

- (void)configureWithTask:(Task *)task showProject:(BOOL)showProject {
    AppThemeManager *t = AppThemeManager.shared;
    BOOL done = task.status == TaskStatusCompleted;
    BOOL cancelled = task.status == TaskStatusCancelled;

    NSString *symbol = done ? @"checkmark.circle.fill" : (cancelled ? @"xmark.circle" : (task.status == TaskStatusInProgress ? @"circle.lefthalf.filled" : @"circle"));
    [self.checkButton setImage:[UIImage ws_symbol:symbol pointSize:22 weight:UIImageSymbolWeightRegular] forState:UIControlStateNormal];
    self.checkButton.tintColor = done ? t.success : (task.isOverdue ? t.danger : [t colorForPriority:task.priority]);
    self.checkButton.accessibilityLabel = done ? WSText(@"Mark as not completed") : WSText(@"Mark as completed");

    NSMutableDictionary *attrs = [@{NSFontAttributeName: t.fontBody, NSForegroundColorAttributeName: (done || cancelled) ? t.textTertiary : t.textPrimary} mutableCopy];
    if (done || cancelled) attrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:task.title ?: @"" attributes:attrs];

    NSMutableArray *parts = NSMutableArray.new;
    NSString *due = task.dueText;
    if (due) [parts addObject:due];
    if (task.repeatRule != RepeatRuleNone) [parts addObject:@"↻"];
    if (showProject && task.project) [parts addObject:task.project.name];
    if (task.parent) [parts addObject:[NSString stringWithFormat:WSText(@"in %@"), task.parent.title]];
    if (task.checklistItems.count) {
        [parts addObject:[NSString stringWithFormat:@"☑︎ %lu/%lu", (unsigned long)task.checklistDoneCount, (unsigned long)task.checklistItems.count]];
    }
    if (task.subtasks.count) {
        [parts addObject:[NSString stringWithFormat:@"⤷ %lu/%lu", (unsigned long)task.subtaskDoneCount, (unsigned long)task.subtasks.count]];
    }
    if (task.attachments.count) [parts addObject:[NSString stringWithFormat:@"📎 %lu", (unsigned long)task.attachments.count]];
    if (task.reminderDate && task.isOpen) [parts addObject:@"🔔"];
    self.metaLabel.text = [parts componentsJoinedByString:@"  ·  "];
    self.metaLabel.textColor = task.isOverdue ? t.danger : t.textSecondary;
    self.metaLabel.hidden = parts.count == 0;

    self.projectDot.hidden = !(showProject && task.project);
    self.projectDot.backgroundColor = [t colorForIdentifier:task.project.colorIdentifier];

    BOOL showPriority = task.isOpen && task.priority >= TaskPriorityHigh;
    [self.priorityPill setText:showPriority ? TaskPriorityTitle(task.priority) : nil color:[t colorForPriority:task.priority]];
    self.favoriteIcon.hidden = !task.isFavorite;

    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", task.title, TaskStatusTitle(task.status)];
    self.accessibilityValue = self.metaLabel.text;
}

- (void)toggleTapped {
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];
    if (self.onToggleComplete) self.onToggleComplete();
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onToggleComplete = nil;
}

@end
