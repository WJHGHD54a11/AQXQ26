//
//  FileCell.m
//  WorkSpace
//

#import "FileCell.h"
#import "FileManagerService.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "FileItem.h"

@interface FileCell ()
@property (nonatomic, strong) UIImageView *thumb;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *metaLabel;
@property (nonatomic, strong) UIImageView *star;
@property (nonatomic, copy) NSString *boundId;
@end

@implementation FileCell

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.backgroundConfiguration = WSListBackground();

        _thumb = UIImageView.new;
        _thumb.contentMode = UIViewContentModeCenter;
        _thumb.clipsToBounds = YES;
        _thumb.layer.cornerRadius = 9;
        _thumb.layer.cornerCurve = kCACornerCurveContinuous;
        _thumb.backgroundColor = t.surfaceRaised;
        _thumb.translatesAutoresizingMaskIntoConstraints = NO;

        _nameLabel = UILabel.new;
        _nameLabel.font = t.fontBody;
        _nameLabel.textColor = t.textPrimary;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

        _metaLabel = UILabel.new;
        _metaLabel.font = t.fontCaption;
        _metaLabel.textColor = t.textSecondary;

        UIStackView *text = [[UIStackView alloc] initWithArrangedSubviews:@[_nameLabel, _metaLabel]];
        text.axis = UILayoutConstraintAxisVertical;
        text.spacing = 2;

        _star = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"star.fill" pointSize:12 weight:UIImageSymbolWeightBold]];
        _star.tintColor = t.warning;
        [_star setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_thumb, text, _star]];
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:row];
        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_thumb.widthAnchor constraintEqualToConstant:44],
            [_thumb.heightAnchor constraintEqualToConstant:44],
            [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [row.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8],
            [row.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8],
        ]];
        [self.separatorLayoutGuide.leadingAnchor constraintEqualToAnchor:text.leadingAnchor].active = YES;
    }
    return self;
}

- (void)configureWithFile:(FileItem *)file {
    AppThemeManager *t = AppThemeManager.shared;
    self.boundId = file.uuid;
    self.nameLabel.text = file.name;
    BOOL exists = [FileManagerService.shared fileExists:file];
    NSString *meta = [NSString stringWithFormat:@"%@ · %@ · %@", file.fileExtension.uppercaseString.length ? file.fileExtension.uppercaseString : WSText(@"File"),
                      [FileManagerService sizeText:file.byteSize], [Task relativeDayText:file.modifiedAt includeTime:NO]];
    self.metaLabel.text = exists ? meta : [meta stringByAppendingFormat:@" · %@", WSText(@"Missing")];
    self.metaLabel.textColor = exists ? t.textSecondary : t.danger;
    self.star.hidden = !file.isFavorite;

    FileCategory category = [FileManagerService categoryForExtension:file.fileExtension];
    UIColor *tint = category == FileCategoryImages ? [t colorForIdentifier:@"teal"] : (category == FileCategoryDocuments ? [t colorForIdentifier:@"sky"] : [t colorForIdentifier:@"slate"]);
    self.thumb.contentMode = UIViewContentModeCenter;
    self.thumb.image = [UIImage ws_symbol:[FileManagerService symbolFor:file] pointSize:20 weight:UIImageSymbolWeightMedium];
    self.thumb.tintColor = tint;
    self.thumb.backgroundColor = [tint colorWithAlphaComponent:0.12];

    if (!exists) return;
    NSString *expected = file.uuid;
    __weak typeof(self) weakSelf = self;
    [FileManagerService.shared thumbnailFor:file size:CGSizeMake(44, 44) completion:^(UIImage *image) {
        if (!image || ![weakSelf.boundId isEqualToString:expected]) return;
        weakSelf.thumb.contentMode = UIViewContentModeScaleAspectFill;
        weakSelf.thumb.image = image;
    }];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.boundId = nil;
}

@end
