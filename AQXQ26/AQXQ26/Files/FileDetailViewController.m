//
//  FileDetailViewController.m
//  WorkSpace
//

#import "FileDetailViewController.h"
#import "FileManagerService.h"
#import "FileActions.h"
#import "RecentManager.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "FileItem.h"
#import "Project.h"
#import "Task.h"
#import <objc/runtime.h>

@interface FileDetailViewController ()
@property (nonatomic, strong) FileItem *file;
@property (nonatomic, strong) UIImageView *preview;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *warningLabel;
@property (nonatomic, strong) UIStackView *infoStack;
@property (nonatomic, strong) UIStackView *buttons;
@end

@implementation FileDetailViewController

- (instancetype)initWithFile:(FileItem *)file {
    if ((self = [super initWithNibName:nil bundle:nil])) _file = file;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.view.backgroundColor = t.background;
    self.title = WSText(@"File");

    UIScrollView *scroll = UIScrollView.new;
    scroll.alwaysBounceVertical = YES;
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    self.preview = UIImageView.new;
    self.preview.contentMode = UIViewContentModeCenter;
    self.preview.clipsToBounds = YES;
    self.preview.layer.cornerRadius = 20;
    self.preview.layer.cornerCurve = kCACornerCurveContinuous;
    self.preview.userInteractionEnabled = YES;
    [self.preview addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewTapped)]];

    self.nameLabel = UILabel.new;
    self.nameLabel.font = t.fontTitle;
    self.nameLabel.textColor = t.textPrimary;
    self.nameLabel.numberOfLines = 0;
    self.nameLabel.textAlignment = NSTextAlignmentCenter;

    self.typeLabel = UILabel.new;
    self.typeLabel.font = t.fontCallout;
    self.typeLabel.textColor = t.textSecondary;
    self.typeLabel.textAlignment = NSTextAlignmentCenter;

    self.warningLabel = UILabel.new;
    self.warningLabel.font = t.fontCaption;
    self.warningLabel.textColor = t.danger;
    self.warningLabel.numberOfLines = 0;
    self.warningLabel.textAlignment = NSTextAlignmentCenter;
    self.warningLabel.text = WSText(@"The file is missing from this device. You can delete this entry and import the file again.");

    self.buttons = [[UIStackView alloc] init];
    self.buttons.distribution = UIStackViewDistributionFillEqually;
    self.buttons.spacing = 10;

    UIView *card = UIView.new;
    [t styleCard:card];
    self.infoStack = UIStackView.new;
    self.infoStack.axis = UILayoutConstraintAxisVertical;
    self.infoStack.spacing = 12;
    self.infoStack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:self.infoStack];
    [NSLayoutConstraint activateConstraints:@[
        [self.infoStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [self.infoStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [self.infoStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [self.infoStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];

    UIStackView *content = [[UIStackView alloc] initWithArrangedSubviews:@[self.preview, self.nameLabel, self.typeLabel, self.warningLabel, self.buttons, card]];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 10;
    [content setCustomSpacing:18 afterView:self.preview];
    [content setCustomSpacing:20 afterView:self.warningLabel];
    [content setCustomSpacing:20 afterView:self.buttons];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-30],
        [content.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor constant:20],
        [content.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor constant:-20],
        [self.preview.heightAnchor constraintEqualToConstant:200],
    ]];

    [DataManager.shared observeChanges:self selector:@selector(dataChanged)];
    [self render];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [RecentManager.shared markOpened:self.file];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)dataChanged {
    if (self.file.isDeleted || !self.file.managedObjectContext) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self render];
}

- (UIButton *)actionButton:(NSString *)title symbol:(NSString *)symbol handler:(void (^)(void))handler {
    UIButtonConfiguration *c = [UIButtonConfiguration tintedButtonConfiguration];
    c.title = title;
    c.image = [UIImage ws_symbol:symbol pointSize:18 weight:UIImageSymbolWeightMedium];
    c.imagePlacement = NSDirectionalRectEdgeTop;
    c.imagePadding = 6;
    c.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    c.baseForegroundColor = AppThemeManager.shared.accent;
    c.contentInsets = NSDirectionalEdgeInsetsMake(12, 4, 12, 4);
    c.titleTextAttributesTransformer = ^NSDictionary *(NSDictionary *a) {
        NSMutableDictionary *m = a.mutableCopy;
        m[NSFontAttributeName] = AppThemeManager.shared.fontCaption;
        return m;
    };
    return [UIButton buttonWithConfiguration:c primaryAction:[UIAction actionWithHandler:^(UIAction *a) { handler(); }]];
}

- (UIView *)infoRow:(NSString *)title value:(NSString *)value tap:(void (^)(void))tap {
    AppThemeManager *t = AppThemeManager.shared;
    UILabel *k = UILabel.new;
    k.text = title;
    k.font = t.fontCallout;
    k.textColor = t.textSecondary;
    [k setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    UILabel *v = UILabel.new;
    v.text = value;
    v.font = t.fontCallout;
    v.textColor = tap ? t.accent : t.textPrimary;
    v.textAlignment = NSTextAlignmentRight;
    v.numberOfLines = 2;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[k, v]];
    row.spacing = 12;
    if (tap) {
        row.userInteractionEnabled = YES;
        UITapGestureRecognizer *g = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
        [g addTarget:self action:@selector(infoRowTapped:)];
        objc_setAssociatedObject(row, @"tap", tap, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [row addGestureRecognizer:g];
    }
    return row;
}

- (void)infoRowTapped:(UITapGestureRecognizer *)g {
    void (^tap)(void) = objc_getAssociatedObject(g.view, @"tap");
    if (tap) tap();
}

- (void)render {
    AppThemeManager *t = AppThemeManager.shared;
    FileItem *f = self.file;
    FileManagerService *svc = FileManagerService.shared;
    BOOL exists = [svc fileExists:f];

    self.nameLabel.text = f.name;
    self.typeLabel.text = [NSString stringWithFormat:@"%@ · %@", [FileManagerService typeDescriptionFor:f], [FileManagerService sizeText:f.byteSize]];
    self.warningLabel.hidden = exists;

    FileCategory cat = [FileManagerService categoryForExtension:f.fileExtension];
    UIColor *tint = cat == FileCategoryImages ? [t colorForIdentifier:@"teal"] : (cat == FileCategoryDocuments ? [t colorForIdentifier:@"sky"] : [t colorForIdentifier:@"slate"]);
    self.preview.backgroundColor = [tint colorWithAlphaComponent:0.12];
    self.preview.tintColor = tint;
    self.preview.contentMode = UIViewContentModeCenter;
    self.preview.image = [UIImage ws_symbol:[FileManagerService symbolFor:f] pointSize:56 weight:UIImageSymbolWeightLight];
    if (exists) {
        __weak typeof(self) weakSelf = self;
        NSString *uuid = f.uuid;
        [svc thumbnailFor:f size:CGSizeMake(400, 400) completion:^(UIImage *image) {
            if (!image || ![weakSelf.file.uuid isEqualToString:uuid]) return;
            weakSelf.preview.contentMode = UIViewContentModeScaleAspectFit;
            weakSelf.preview.image = image;
        }];
    }

    __weak typeof(self) weakSelf = self;
    for (UIView *v in self.buttons.arrangedSubviews) [v removeFromSuperview];
    [self.buttons addArrangedSubview:[self actionButton:WSText(@"Preview") symbol:@"eye" handler:^{ [weakSelf previewTapped]; }]];
    [self.buttons addArrangedSubview:[self actionButton:WSText(@"Share") symbol:@"square.and.arrow.up" handler:^{
        [FileActions share:weakSelf.file from:weakSelf source:weakSelf.buttons];
    }]];
    [self.buttons addArrangedSubview:[self actionButton:f.isFavorite ? WSText(@"Favorited") : WSText(@"Favorite")
                                                 symbol:f.isFavorite ? @"star.fill" : @"star" handler:^{
        [FileActions toggleFavorite:weakSelf.file from:weakSelf];
    }]];

    for (UIView *v in self.infoStack.arrangedSubviews) [v removeFromSuperview];
    NSDateFormatter *df = NSDateFormatter.new;
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Name") value:f.name tap:nil]];
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Kind") value:[FileManagerService typeDescriptionFor:f] tap:nil]];
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Size") value:[FileManagerService sizeText:f.byteSize] tap:nil]];
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Created") value:[df stringFromDate:f.createdAt] tap:nil]];
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Modified") value:[df stringFromDate:f.modifiedAt] tap:nil]];
    [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Location") value:f.folder.length ? f.folder : WSText(@"All Files") tap:^{
        [FileActions move:weakSelf.file from:weakSelf];
    }]];
    if (f.project) {
        [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Project") value:f.project.name tap:^{
            [AppRouter.shared open:weakSelf.file.project from:weakSelf];
        }]];
    }
    if (f.task) {
        [self.infoStack addArrangedSubview:[self infoRow:WSText(@"Task") value:f.task.title tap:^{
            [AppRouter.shared open:weakSelf.file.task from:weakSelf];
        }]];
    }

    UIMenu *more = [UIMenu menuWithChildren:@[
        [UIAction actionWithTitle:WSText(@"Rename") image:[UIImage ws_symbol:@"pencil"] identifier:nil handler:^(UIAction *a) { [FileActions rename:weakSelf.file from:weakSelf]; }],
        [UIAction actionWithTitle:WSText(@"Move to Folder") image:[UIImage ws_symbol:@"folder"] identifier:nil handler:^(UIAction *a) { [FileActions move:weakSelf.file from:weakSelf]; }],
        [UIAction actionWithTitle:WSText(@"Delete") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) {
            [FileActions confirmDelete:weakSelf.file from:weakSelf completion:nil];
        }],
    ]];
    ((UIAction *)more.children.lastObject).attributes = UIMenuElementAttributesDestructive;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:more];
}

- (void)previewTapped {
    [FileActions preview:self.file among:nil from:self];
}

@end
