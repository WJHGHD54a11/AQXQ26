//
//  ProjectCell.m
//  WorkSpace
//

#import "ProjectCell.h"
#import "ProjectManager.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Project.h"

@interface ProjectCell ()
@property (nonatomic, strong) UIView *colorBar;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) WSPillLabel *statusPill;
@property (nonatomic, strong) WSProgressRing *ring;
@end

@implementation ProjectCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.backgroundConfiguration = WSListBackground();
        _colorBar = UIView.new;
        _colorBar.layer.cornerRadius = 2;
        _colorBar.translatesAutoresizingMaskIntoConstraints = NO;

        _nameLabel = UILabel.new;
        _nameLabel.font = t.fontHeadline;
        _nameLabel.textColor = t.textPrimary;
        _nameLabel.numberOfLines = 2;
        _metaLabel = UILabel.new;
        _metaLabel.font = t.fontCaption;
        _metaLabel.textColor = t.textSecondary;
        _statusPill = WSPillLabel.new;
        UIStackView *pillRow = [[UIStackView alloc] initWithArrangedSubviews:@[_statusPill, UIView.new]];

        UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[_nameLabel, _metaLabel, pillRow]];
        text.axis = UILayoutConstraintAxisVertical;
        text.spacing = 4;

        _ring = WSProgressRing.new;
        _ring.lineWidth = 5;
        _ring.showsPercentage = YES;
        _ring.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_colorBar, text, _ring]];
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:row];
        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_colorBar.widthAnchor constraintEqualToConstant:4],
            [_colorBar.heightAnchor constraintEqualToAnchor:text.heightAnchor],
            [_ring.widthAnchor constraintEqualToConstant:52],
            [_ring.heightAnchor constraintEqualToConstant:52],
            [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [row.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
            [row.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12],
        ]];
    }
    return self;
}

- (void)configureWithProject:(Project *)project {
    AppThemeManager *t = AppThemeManager.shared;
    UIColor *color = [t colorForIdentifier:project.colorIdentifier];
    ProjectProgress p = [ProjectManager.shared progressFor:project];
    self.colorBar.backgroundColor = color;
    self.nameLabel.text = project.isFavorite ? [@"★ " stringByAppendingString:project.name ?: @""] : project.name;

    NSMutableArray *parts = [NSMutableArray arrayWithObject:[NSString stringWithFormat:WSText(@"%lu of %lu tasks"), (unsigned long)p.completed, (unsigned long)p.total]];
    if (p.overdue) [parts addObject:[NSString stringWithFormat:WSText(@"%lu overdue"), (unsigned long)p.overdue]];
    if (project.dueDate) [parts addObject:[NSString stringWithFormat:WSText(@"Due %@"), [Task relativeDayText:project.dueDate includeTime:NO]]];
    self.metaLabel.text = [parts componentsJoinedByString:@" · "];
    self.metaLabel.textColor = p.overdue ? t.danger : t.textSecondary;

    [self.statusPill setText:ProjectStatusTitle(project.status) color:[t colorForProjectStatus:project.status]];
    self.ring.tintColorForRing = color;
    self.ring.progress = p.fraction;
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@, %@", project.name, ProjectStatusTitle(project.status), self.metaLabel.text];
}

@end
