//
//  ScheduleDetailViewController.m
//  WorkSpace
//

#import "ScheduleDetailViewController.h"
#import "ScheduleEditViewController.h"
#import "ScheduleManager.h"
#import "FavoriteManager.h"
#import "RecentManager.h"
#import "DataManager.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Schedule.h"

@interface ScheduleDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) Schedule *schedule;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *rows;
@end

@implementation ScheduleDetailViewController

- (instancetype)initWithSchedule:(Schedule *)schedule {
    if ((self = [super initWithNibName:nil bundle:nil])) _schedule = schedule;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    self.tableView.allowsSelection = NO;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];
    [DataManager.shared observeChanges:self selector:@selector(dataChanged)];
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [RecentManager.shared markOpened:self.schedule];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)dataChanged {
    if (self.schedule.isDeleted || !self.schedule.managedObjectContext) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self reload];
}

- (NSString *)timeText {
    Schedule *s = self.schedule;
    NSString *day = [Task relativeDayText:s.startTime includeTime:NO];
    if (s.allDay) return [NSString stringWithFormat:@"%@ · %@", day, WSText(@"All day")];
    NSString *start = [NSDateFormatter localizedStringFromDate:s.startTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    if (!s.endTime) return [NSString stringWithFormat:@"%@ %@", day, start];
    NSString *end = [NSDateFormatter localizedStringFromDate:s.endTime dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"%@ %@ – %@", day, start, end];
}

- (void)reload {
    Schedule *s = self.schedule;
    self.title = ScheduleKindTitle(s.kind);
    NSMutableArray *rows = NSMutableArray.new;
    [rows addObject:@[WSText(@"Time"), [self timeText]]];
    [rows addObject:@[WSText(@"Type"), ScheduleKindTitle(s.kind)]];
    [rows addObject:@[WSText(@"Status"), ScheduleStatusTitle(s.status)]];
    if (s.location.length) [rows addObject:@[WSText(@"Location"), s.location]];
    [rows addObject:@[WSText(@"Reminder"), ScheduleReminderOffsetTitle(s.reminderOffset)]];
    [rows addObject:@[WSText(@"Repeat"), RepeatRuleTitle(s.repeatRule)]];
    self.rows = rows;
    [self buildNavigationItems];
    [self.tableView reloadData];
}

- (void)buildNavigationItems {
    __weak typeof(self) weakSelf = self;
    Schedule *s = self.schedule;
    NSMutableArray *actions = NSMutableArray.new;
    void (^run)(BOOL (^)(NSError **)) = ^(BOOL (^op)(NSError **)) {
        NSError *error = nil;
        if (!op(&error)) [weakSelf ws_showError:error];
    };
    if (s.status == ScheduleStatusPlanned) {
        [actions addObject:[UIAction actionWithTitle:WSText(@"Mark as Completed") image:[UIImage ws_symbol:@"checkmark.circle"] identifier:nil handler:^(UIAction *a) {
            run(^BOOL(NSError **e) { return [ScheduleManager.shared complete:weakSelf.schedule error:e]; });
        }]];
        [actions addObject:[UIAction actionWithTitle:WSText(@"Cancel Event") image:[UIImage ws_symbol:@"xmark.circle"] identifier:nil handler:^(UIAction *a) {
            run(^BOOL(NSError **e) { return [ScheduleManager.shared cancel:weakSelf.schedule error:e]; });
        }]];
    } else {
        [actions addObject:[UIAction actionWithTitle:WSText(@"Reopen") image:[UIImage ws_symbol:@"arrow.uturn.backward"] identifier:nil handler:^(UIAction *a) {
            run(^BOOL(NSError **e) { return [ScheduleManager.shared reopen:weakSelf.schedule error:e]; });
        }]];
    }
    [actions addObject:[UIAction actionWithTitle:s.isFavorite ? WSText(@"Remove from Favorites") : WSText(@"Add to Favorites")
                                           image:[UIImage ws_symbol:s.isFavorite ? @"star.slash" : @"star"] identifier:nil handler:^(UIAction *a) {
        run(^BOOL(NSError **e) { return [FavoriteManager.shared toggleFavorite:weakSelf.schedule error:e]; });
    }]];
    UIAction *delete = [UIAction actionWithTitle:WSText(@"Delete") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) {
        [weakSelf ws_confirm:WSText(@"Delete this schedule?") message:nil destructive:WSText(@"Delete") handler:^{
            run(^BOOL(NSError **e) { return [ScheduleManager.shared deleteSchedule:weakSelf.schedule error:e]; });
        }];
    }];
    delete.attributes = UIMenuElementAttributesDestructive;
    [actions addObject:[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[delete]]];

    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:[UIMenu menuWithChildren:actions]];
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit primaryAction:[UIAction actionWithHandler:^(UIAction *a) {
        ScheduleEditViewController *editor = [[ScheduleEditViewController alloc] initWithSchedule:weakSelf.schedule day:nil];
        [weakSelf presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
    }]];
    self.navigationItem.rightBarButtonItems = @[edit, more];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.schedule.detail.length ? 3 : 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 1 ? (NSInteger)self.rows.count : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 2 ? WSText(@"Notes") : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    Schedule *s = self.schedule;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    UIListContentConfiguration *c;
    if (indexPath.section == 0) {
        c = [UIListContentConfiguration subtitleCellConfiguration];
        c.text = s.title;
        c.textProperties.font = t.fontTitle;
        c.textProperties.color = s.status == ScheduleStatusCancelled ? t.textTertiary : t.textPrimary;
        c.secondaryText = [self timeText];
        c.secondaryTextProperties.color = t.textSecondary;
        c.secondaryTextProperties.font = t.fontCallout;
        c.textToSecondaryTextVerticalPadding = 6;
        c.image = [UIImage ws_symbol:ScheduleKindSymbol(s.kind) pointSize:22 weight:UIImageSymbolWeightMedium];
        c.imageProperties.tintColor = [t colorForScheduleKind:s.kind];
    } else if (indexPath.section == 1) {
        c = [UIListContentConfiguration valueCellConfiguration];
        c.text = self.rows[indexPath.row][0];
        c.secondaryText = self.rows[indexPath.row][1];
        c.textProperties.color = t.textPrimary;
        c.secondaryTextProperties.color = t.textSecondary;
        c.prefersSideBySideTextAndSecondaryText = YES;
    } else {
        c = [UIListContentConfiguration cellConfiguration];
        c.text = s.detail;
        c.textProperties.color = t.textPrimary;
        c.textProperties.font = t.fontBody;
    }
    cell.contentConfiguration = c;
    return cell;
}

@end
