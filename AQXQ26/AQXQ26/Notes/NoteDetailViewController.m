//
//  NoteDetailViewController.m
//  WorkSpace
//

#import "NoteDetailViewController.h"
#import "NoteEditViewController.h"
#import "NoteManager.h"
#import "TagManager.h"
#import "RecentManager.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Note.h"
#import "NoteCategory.h"
#import "Project.h"

@interface NoteDetailViewController ()
@property (nonatomic, strong) Note *note;
@property (nonatomic, strong) UITextView *textView;
@end

@implementation NoteDetailViewController

- (instancetype)initWithNote:(Note *)note {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _note = note;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.surface;
    self.textView = UITextView.new;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.textContainerInset = UIEdgeInsetsMake(16, 20, 32, 20);
    self.textView.alwaysBounceVertical = YES;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
    ]];
    // Double tap to edit.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(edit)];
    tap.numberOfTapsRequired = 2;
    [self.textView addGestureRecognizer:tap];

    [DataManager.shared observeChanges:self selector:@selector(dataChanged)];
    [self render];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [RecentManager.shared markOpened:self.note];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)dataChanged {
    if (self.note.isDeleted || !self.note.managedObjectContext) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self render];
}

- (void)render {
    AppThemeManager *t = AppThemeManager.shared;
    Note *n = self.note;
    self.title = n.title;

    NSMutableAttributedString *text = NSMutableAttributedString.new;
    NSMutableParagraphStyle *titleStyle = NSMutableParagraphStyle.new;
    titleStyle.paragraphSpacing = 8;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[(n.title ?: @"") stringByAppendingString:@"\n"]
                                                                 attributes:@{NSFontAttributeName: t.fontTitle, NSForegroundColorAttributeName: t.textPrimary, NSParagraphStyleAttributeName: titleStyle}]];

    NSMutableArray *meta = NSMutableArray.new;
    if (n.isPinned) [meta addObject:@"📌"];
    if (n.isFavorite) [meta addObject:@"★"];
    [meta addObject:n.category.name ?: WSText(@"Uncategorized")];
    if (n.tags.count) [meta addObject:[@"#" stringByAppendingString:[[TagManager joinedNames:n.tags] stringByReplacingOccurrencesOfString:@", " withString:@"  #"]]];
    if (n.project) [meta addObject:[NSString stringWithFormat:WSText(@"Project: %@"), n.project.name]];
    [meta addObject:[NSString stringWithFormat:WSText(@"Edited %@"), [Task relativeDayText:n.updatedAt includeTime:YES]]];
    NSMutableParagraphStyle *metaStyle = NSMutableParagraphStyle.new;
    metaStyle.paragraphSpacing = 18;
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:[[meta componentsJoinedByString:@"  ·  "] stringByAppendingString:@"\n"]
                                                                 attributes:@{NSFontAttributeName: t.fontCaption, NSForegroundColorAttributeName: t.textSecondary, NSParagraphStyleAttributeName: metaStyle}]];

    NSMutableParagraphStyle *body = NSMutableParagraphStyle.new;
    body.lineSpacing = 4;
    NSString *content = n.content.length ? n.content : WSText(@"No additional text");
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:content
                                                                 attributes:@{NSFontAttributeName: t.fontBody,
                                                                              NSForegroundColorAttributeName: n.content.length ? t.textPrimary : t.textTertiary,
                                                                              NSParagraphStyleAttributeName: body}]];
    self.textView.attributedText = text;
    [self buildNavigationItems];
}

- (void)buildNavigationItems {
    Note *n = self.note;
    __weak typeof(self) weakSelf = self;
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    NSMutableArray *actions = [NSMutableArray arrayWithObjects:
        [UIAction actionWithTitle:n.isPinned ? WSText(@"Unpin") : WSText(@"Pin") image:[UIImage ws_symbol:n.isPinned ? @"pin.slash" : @"pin"] identifier:nil handler:^(UIAction *a) {
            NSError *error = nil;
            if (![NoteManager.shared togglePinned:weakSelf.note error:&error]) [weakSelf ws_showError:error];
        }],
        [UIAction actionWithTitle:n.isFavorite ? WSText(@"Remove from Favorites") : WSText(@"Add to Favorites") image:[UIImage ws_symbol:n.isFavorite ? @"star.slash" : @"star"] identifier:nil handler:^(UIAction *a) {
            NSError *error = nil;
            if (![NoteManager.shared toggleFavorite:weakSelf.note error:&error]) [weakSelf ws_showError:error];
        }],
        [UIAction actionWithTitle:WSText(@"Share") image:[UIImage ws_symbol:@"square.and.arrow.up"] identifier:nil handler:^(UIAction *a) {
            NSString *body = weakSelf.note.content.length ? [NSString stringWithFormat:@"%@\n\n%@", weakSelf.note.title, weakSelf.note.content] : weakSelf.note.title;
            [weakSelf ws_share:@[body ?: @""] from:weakSelf.navigationItem.rightBarButtonItems.lastObject];
        }], nil];
    if (n.project) {
        [actions addObject:[UIAction actionWithTitle:n.project.name image:[UIImage ws_symbol:@"folder"] identifier:nil handler:^(UIAction *a) {
            [AppRouter.shared open:weakSelf.note.project from:weakSelf];
        }]];
    }
    UIAction *del = [UIAction actionWithTitle:WSText(@"Delete Note") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) {
        [weakSelf ws_confirm:WSText(@"Delete this note?") message:nil destructive:WSText(@"Delete") handler:^{
            NSError *error = nil;
            if (![NoteManager.shared deleteNote:weakSelf.note error:&error]) [weakSelf ws_showError:error];
        }];
    }];
    del.attributes = UIMenuElementAttributesDestructive;
    UIMenu *menu = [UIMenu menuWithChildren:@[[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:actions], del]];
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:menu];
    self.navigationItem.rightBarButtonItems = @[edit, more];
}

- (void)edit {
    NoteEditViewController *editor = [[NoteEditViewController alloc] initWithNote:self.note category:nil project:nil];
    [self.navigationController pushViewController:editor animated:YES];
}

@end
