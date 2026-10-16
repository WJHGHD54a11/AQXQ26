//
//  ScheduleCell.m
//  WorkSpace
//

#import "ScheduleCell.h"
#import "WSUIKit.h"
#import "Schedule.h"
#import "Task+Logic.h"

@interface ScheduleCell ()
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UILabel *endLabel;
@property (nonatomic, strong) UIView *kindBar;
@property (nonatomic, strong) UIImageView *kindIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) WSPillLabel *statusPill;
@end

@implementation ScheduleCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.backgroundConfiguration = WSListBackground();

        _startLabel = UILabel.new;
        _startLabel.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightSemibold];
        _startLabel.textColor = t.textPrimary;
        _startLabel.textAlignment = NSTextAlignmentRight;
        _startLabel.adjustsFontSizeToFitWidth = YES;
        _startLabel.minimumScaleFactor = 0.7;
        _endLabel = UILabel.new;
        _endLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightRegular];
        _endLabel.textColor = t.textTertiary;
        _endLabel.textAlignment = NSTextAlignmentRight;
        _endLabel.adjustsFontSizeToFitWidth = YES;
        UIStackView *time = [[UIStackView alloc] initWithArrangedSubviews:@[_startLabel, _endLabel]];
        time.axis = UILayoutConstraintAxisVertical;
        time.spacing = 2;
        time.translatesAutoresizingMaskIntoConstraints = NO;

        _kindBar = UIView.new;
        _kindBar.layer.cornerRadius = 2;
        _kindBar.translatesAutoresizingMaskIntoConstraints = NO;

        _kindIcon = UIImageView.new;
        _kindIcon.contentMode = UIViewContentModeScaleAspectFit;
        [_kindIcon setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontHeadline;
        _titleLabel.numberOfLines = 2;
        UIStackView *titleRow = [[UIStackView alloc] initWithArrangedSubviews:@[_kindIcon, _titleLabel]];
        titleRow.spacing = 6;
        titleRow.alignment = UIStackViewAlignmentFirstBaseline;

        _metaLabel = UILabel.new;
        _metaLabel.font = t.fontCaption;
        _metaLabel.textColor = t.textSecondary;
        _metaLabel.numberOfLines = 2;

        UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[titleRow, _metaLabel]];
        text.axis = UILayoutConstraintAxisVertical;
        text.spacing = 4;

        _statusPill = WSPillLabel.new;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[time, _kindBar, text, _statusPill]];
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:row];

        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [time.widthAnchor constraintEqualToConstant:58],
            [_kindBar.widthAnchor constraintEqualToConstant:4],
            [_kindBar.heightAnchor constraintEqualToAnchor:row.heightAnchor],
            [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [row.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [row.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
        [self.separatorLayoutGuide.leadingAnchor constraintEqualToAnchor:text.leadingAnchor].active = YES;
    }
    return self;
}

- (NSString *)timeText:(NSDate *)date {
    return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
}

- (void)configureWithSchedule:(Schedule *)schedule showDate:(BOOL)showDate {
    AppThemeManager *t = AppThemeManager.shared;
    UIColor *kindColor = [t colorForScheduleKind:schedule.kind];
    BOOL planned = schedule.status == ScheduleStatusPlanned;

    if (schedule.allDay) {
        self.startLabel.text = WSText(@"All day");
        self.endLabel.text = nil;
    } else {
        self.startLabel.text = [self timeText:schedule.startTime];
        self.endLabel.text = schedule.endTime ? [self timeText:schedule.endTime] : nil;
    }
    self.endLabel.hidden = self.endLabel.text.length == 0;

    self.kindBar.backgroundColor = planned ? kindColor : [kindColor colorWithAlphaComponent:0.35];
    self.kindIcon.image = [UIImage ws_symbol:ScheduleKindSymbol(schedule.kind) pointSize:13 weight:UIImageSymbolWeightSemibold];
    self.kindIcon.tintColor = kindColor;

    NSMutableDictionary *attrs = [@{NSFontAttributeName: t.fontHeadline,
                                    NSForegroundColorAttributeName: planned ? t.textPrimary : t.textTertiary} mutableCopy];
    if (schedule.status == ScheduleStatusCancelled) attrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:schedule.title ?: @"" attributes:attrs];

    NSMutableArray *parts = NSMutableArray.new;
    if (showDate) [parts addObject:[Task relativeDayText:schedule.startTime includeTime:NO]];
    [parts addObject:ScheduleKindTitle(schedule.kind)];
    if (schedule.location.length) [parts addObject:[@"⌖ " stringByAppendingString:schedule.location]];
    if (schedule.reminderOffset >= 0 && planned) [parts addObject:@"🔔"];
    if (schedule.repeatRule != RepeatRuleNone) [parts addObject:[@"↻ " stringByAppendingString:RepeatRuleTitle(schedule.repeatRule)]];
    if (schedule.isFavorite) [parts addObject:@"★"];
    self.metaLabel.text = [parts componentsJoinedByString:@"  ·  "];

    BOOL ended = planned && !schedule.allDay && [(schedule.endTime ?: schedule.startTime) compare:NSDate.date] == NSOrderedAscending;
    BOOL now = planned && !schedule.allDay && !ended && [schedule.startTime compare:NSDate.date] != NSOrderedDescending;
    if (schedule.status == ScheduleStatusCompleted) [self.statusPill setText:WSText(@"Done") color:t.success];
    else if (schedule.status == ScheduleStatusCancelled) [self.statusPill setText:WSText(@"Cancelled") color:t.textTertiary];
    else if (now) [self.statusPill setText:WSText(@"Now") color:kindColor];
    else if (ended) [self.statusPill setText:WSText(@"Missed") color:t.warning];
    else [self.statusPill setText:nil color:t.textTertiary];

    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", schedule.title, self.startLabel.text];
    self.accessibilityValue = self.metaLabel.text;
}

@end
