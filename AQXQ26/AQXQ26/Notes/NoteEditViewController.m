//
//  NoteEditViewController.m
//  WorkSpace
//
//  Writing surface. Saves automatically when leaving or going to background;
//  an untouched empty note is never created.
//

#import "NoteEditViewController.h"
#import "NoteManager.h"
#import "NoteCategoryManager.h"
#import "TagManager.h"
#import "DataManager.h"
#import "WSUIKit.h"
#import "Note.h"
#import "NoteCategory.h"
#import "Project.h"

@interface NoteEditViewController () <UITextViewDelegate>
@property (nonatomic, strong, nullable) Note *note;
@property (nonatomic, strong, nullable) NoteCategory *category;
@property (nonatomic, strong, nullable) Project *project;
@property (nonatomic, copy) NSArray<NSString *> *tagNames;
@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UITextView *bodyView;
@property (nonatomic, strong) UILabel *bodyPlaceholder;
@property (nonatomic, strong) UIButton *categoryButton;
@property (nonatomic, strong) UIButton *tagsButton;
@property (nonatomic) BOOL dirty;
@end

@implementation NoteEditViewController

- (instancetype)initWithNote:(Note *)note category:(NoteCategory *)category project:(Project *)project {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _note = note;
        _category = note ? note.category : category;
        _project = note ? note.project : project;
        _tagNames = note ? ([[note.tags valueForKey:@"name"] allObjects] ?: @[]) : @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.view.backgroundColor = t.surface;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.title = self.note ? WSText(@"Edit Note") : WSText(@"New Note");

    self.titleField = UITextField.new;
    self.titleField.font = t.fontTitle;
    self.titleField.textColor = t.textPrimary;
    self.titleField.placeholder = WSText(@"Title");
    self.titleField.text = self.note.title;
    self.titleField.returnKeyType = UIReturnKeyNext;
    __weak typeof(self) weakSelf = self;
    [self.titleField addAction:[UIAction actionWithHandler:^(UIAction *a) { weakSelf.dirty = YES; }] forControlEvents:UIControlEventEditingChanged];
    [self.titleField addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf.bodyView becomeFirstResponder]; }] forControlEvents:UIControlEventEditingDidEndOnExit];

    self.categoryButton = [self metaButton];
    self.tagsButton = [self metaButton];
    [self.tagsButton addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf editTags]; }] forControlEvents:UIControlEventTouchUpInside];
    self.categoryButton.showsMenuAsPrimaryAction = YES;
    UIStackView *meta = [[UIStackView alloc] initWithArrangedSubviews:@[self.categoryButton, self.tagsButton, UIView.new]];
    meta.spacing = 8;

    UIView *line = UIView.new;
    line.backgroundColor = t.separator;
    [line.heightAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale].active = YES;

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[self.titleField, meta, line]];
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 10;
    header.translatesAutoresizingMaskIntoConstraints = NO;

    self.bodyView = UITextView.new;
    self.bodyView.font = t.fontBody;
    self.bodyView.textColor = t.textPrimary;
    self.bodyView.backgroundColor = UIColor.clearColor;
    self.bodyView.text = self.note.content;
    self.bodyView.delegate = self;
    self.bodyView.alwaysBounceVertical = YES;
    self.bodyView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.bodyView.textContainer.lineFragmentPadding = 0;
    self.bodyView.translatesAutoresizingMaskIntoConstraints = NO;

    self.bodyPlaceholder = UILabel.new;
    self.bodyPlaceholder.text = WSText(@"Start writing…");
    self.bodyPlaceholder.font = t.fontBody;
    self.bodyPlaceholder.textColor = t.textTertiary;
    self.bodyPlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    self.bodyPlaceholder.hidden = self.bodyView.text.length > 0;

    [self.view addSubview:header];
    [self.view addSubview:self.bodyView];
    [self.view addSubview:self.bodyPlaceholder];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [header.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [header.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [header.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [self.bodyView.topAnchor constraintEqualToAnchor:header.bottomAnchor constant:12],
        [self.bodyView.leadingAnchor constraintEqualToAnchor:header.leadingAnchor],
        [self.bodyView.trailingAnchor constraintEqualToAnchor:header.trailingAnchor],
        [self.bodyView.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor],
        [self.bodyPlaceholder.topAnchor constraintEqualToAnchor:self.bodyView.topAnchor constant:8],
        [self.bodyPlaceholder.leadingAnchor constraintEqualToAnchor:self.bodyView.leadingAnchor],
    ]];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    self.navigationItem.rightBarButtonItem = done;
    if (self.navigationController.viewControllers.firstObject == self) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped)];
    }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(autosave) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self refreshMeta];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.note && self.titleField.text.length == 0) [self.titleField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Back button / swipe back: keep what was written.
    if (self.isMovingFromParentViewController) [self autosave];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (UIButton *)metaButton {
    UIButtonConfiguration *c = [UIButtonConfiguration grayButtonConfiguration];
    c.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    c.contentInsets = NSDirectionalEdgeInsetsMake(5, 12, 5, 12);
    c.imagePadding = 4;
    c.baseForegroundColor = AppThemeManager.shared.textSecondary;
    return [UIButton buttonWithConfiguration:c primaryAction:nil];
}

#pragma mark - Meta (category / tags)

- (void)refreshMeta {
    AppThemeManager *t = AppThemeManager.shared;
    UIButtonConfiguration *c = self.categoryButton.configuration;
    c.title = self.category.name ?: WSText(@"No Category");
    c.image = [UIImage ws_symbol:@"tray" pointSize:12 weight:UIImageSymbolWeightMedium];
    c.baseForegroundColor = self.category ? [t colorForIdentifier:self.category.colorIdentifier] : t.textSecondary;
    self.categoryButton.configuration = c;
    self.categoryButton.menu = [self categoryMenu];

    UIButtonConfiguration *tc = self.tagsButton.configuration;
    tc.title = self.tagNames.count ? [self.tagNames componentsJoinedByString:@", "] : WSText(@"Add Tags");
    tc.image = [UIImage ws_symbol:@"tag" pointSize:12 weight:UIImageSymbolWeightMedium];
    self.tagsButton.configuration = tc;
}

- (UIMenu *)categoryMenu {
    __weak typeof(self) weakSelf = self;
    NSMutableArray *items = NSMutableArray.new;
    UIAction *none = [UIAction actionWithTitle:WSText(@"No Category") image:nil identifier:nil handler:^(UIAction *a) {
        weakSelf.category = nil; weakSelf.dirty = YES; [weakSelf refreshMeta];
    }];
    none.state = self.category ? UIMenuElementStateOff : UIMenuElementStateOn;
    [items addObject:none];
    for (NoteCategory *cat in [NoteCategoryManager.shared allCategories]) {
        UIAction *a = [UIAction actionWithTitle:cat.name image:nil identifier:nil handler:^(UIAction *action) {
            weakSelf.category = cat; weakSelf.dirty = YES; [weakSelf refreshMeta];
        }];
        a.state = cat == self.category ? UIMenuElementStateOn : UIMenuElementStateOff;
        [items addObject:a];
    }
    UIAction *add = [UIAction actionWithTitle:WSText(@"New Category…") image:[UIImage ws_symbol:@"plus"] identifier:nil handler:^(UIAction *a) {
        [weakSelf ws_promptTitle:WSText(@"New Category") message:nil placeholder:WSText(@"Name") text:nil action:WSText(@"Create") handler:^(NSString *text) {
            NSError *error = nil;
            NoteCategory *created = [NoteCategoryManager.shared createCategory:text color:nil error:&error];
            if (!created) { [weakSelf ws_showError:error]; return; }
            weakSelf.category = created; weakSelf.dirty = YES; [weakSelf refreshMeta];
        }];
    }];
    return [UIMenu menuWithChildren:@[[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:items], add]];
}

- (void)editTags {
    __weak typeof(self) weakSelf = self;
    [self ws_promptTitle:WSText(@"Tags") message:WSText(@"Separate tags with commas.") placeholder:WSText(@"work, ideas")
                    text:[self.tagNames componentsJoinedByString:@", "] action:WSText(@"Done") handler:^(NSString *text) {
        NSMutableArray *names = NSMutableArray.new;
        for (NSString *part in [text componentsSeparatedByString:@","]) {
            NSString *clean = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (clean.length && ![names containsObject:clean]) [names addObject:clean];
        }
        weakSelf.tagNames = names; weakSelf.dirty = YES; [weakSelf refreshMeta];
    }];
}

#pragma mark - Saving

- (void)textViewDidChange:(UITextView *)textView {
    self.dirty = YES;
    self.bodyPlaceholder.hidden = textView.text.length > 0;
}

- (BOOL)isBlank {
    NSCharacterSet *ws = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    return [self.titleField.text stringByTrimmingCharactersInSet:ws].length == 0 && [self.bodyView.text stringByTrimmingCharactersInSet:ws].length == 0;
}

/// Returns NO only when saving failed.
- (BOOL)commit {
    if (!self.dirty) return YES;
    if (self.note.isDeleted) return YES;
    if (!self.note && [self isBlank]) return YES;
    NSError *error = nil;
    if (self.note) {
        if (![NoteManager.shared updateNote:self.note title:self.titleField.text ?: @"" content:self.bodyView.text category:self.category tags:self.tagNames error:&error]) {
            [self ws_showError:error];
            return NO;
        }
    } else {
        Note *created = [NoteManager.shared createNoteWithTitle:self.titleField.text ?: @"" content:self.bodyView.text category:self.category
                                                           tags:self.tagNames project:self.project error:&error];
        if (!created) { [self ws_showError:error]; return NO; }
        self.note = created;
    }
    self.dirty = NO;
    if (self.onSaved) self.onSaved(self.note);
    return YES;
}

- (void)autosave {
    [self commit];
}

- (void)doneTapped {
    [self.view endEditing:YES];
    if (![self commit]) return;
    [self close];
}

- (void)cancelTapped {
    if (!self.dirty || (!self.note && [self isBlank])) { [self close]; return; }
    __weak typeof(self) weakSelf = self;
    [self ws_confirm:WSText(@"Discard Changes?") message:nil destructive:WSText(@"Discard") handler:^{
        weakSelf.dirty = NO;
        [weakSelf close];
    }];
}

- (void)close {
    if (self.navigationController.viewControllers.firstObject == self) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
