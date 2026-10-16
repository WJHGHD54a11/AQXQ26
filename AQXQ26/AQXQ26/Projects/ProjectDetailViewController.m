//
//  ProjectDetailViewController.m
//  WorkSpace
//
//  Overview with live progress, then Tasks · Notes · Files. Each section has an add row.
//

#import "ProjectDetailViewController.h"
#import "ProjectEditViewController.h"
#import "ProjectManager.h"
#import "TaskManager.h"
#import "TagManager.h"
#import "FavoriteManager.h"
#import "RecentManager.h"
#import "FileImportManager.h"
#import "NoteEditViewController.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "Project.h"
#import "Note.h"
#import "FileItem.h"

typedef NS_ENUM(NSInteger, ProjectSection) {
    ProjectSectionOverview = 0,
    ProjectSectionTasks,
    ProjectSectionNotes,
    ProjectSectionFiles,
    ProjectSectionCount,
};

@interface ProjectDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong, readwrite) Project *project;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WSProgressRing *ring;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, copy) NSArray<Task *> *tasks;
@property (nonatomic, copy) NSArray<Note *> *notes;
@property (nonatomic, copy) NSArray<FileItem *> *files;
@property (nonatomic) BOOL showCompleted;
@end

@implementation ProjectDetailViewController

- (instancetype)initWithProject:(Project *)project {
    if ((self = [super initWithNibName:nil bundle:nil])) _project = project;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.view.backgroundColor = t.background;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = t.background;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];

    // Progress header
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 132)];
    self.ring = WSProgressRing.new;
    self.ring.lineWidth = 9;
    self.ring.showsPercentage = YES;
    self.ring.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressLabel = UILabel.new;
    self.progressLabel.font = t.fontCallout;
    self.progressLabel.textColor = t.textSecondary;
    self.progressLabel.numberOfLines = 0;
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:self.ring];
    [header addSubview:self.progressLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.ring.leadingAnchor constraintEqualToAnchor:header.leadingAnchor constant:36],
        [self.ring.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
        [self.ring.widthAnchor constraintEqualToConstant:96],
        [self.ring.heightAnchor constraintEqualToConstant:96],
        [self.progressLabel.leadingAnchor constraintEqualToAnchor:self.ring.trailingAnchor constant:20],
        [self.progressLabel.trailingAnchor constraintEqualToAnchor:header.trailingAnchor constant:-36],
        [self.progressLabel.centerYAnchor constraintEqualToAnchor:header.centerYAnchor],
    ]];
    self.tableView.tableHeaderView = header;

    [DataManager.shared observeChanges:self selector:@selector(dataChanged)];
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [RecentManager.shared markOpened:self.project];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIView *header = self.tableView.tableHeaderView;
    if (header && fabs(header.frame.size.width - self.tableView.bounds.size.width) > 0.5) {
        header.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 132);
        self.tableView.tableHeaderView = header;
    }
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)dataChanged {
    if (self.project.isDeleted || !self.project.managedObjectContext) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self reload];
}

- (void)reload {
    AppThemeManager *t = AppThemeManager.shared;
    Project *p = self.project;
    self.title = p.name;
    ProjectProgress progress = [ProjectManager.shared progressFor:p];
    self.ring.tintColorForRing = [t colorForIdentifier:p.colorIdentifier];
    self.ring.progress = progress.fraction;
    NSMutableString *text = [NSMutableString stringWithFormat:WSText(@"%lu of %lu tasks completed"), (unsigned long)progress.completed, (unsigned long)progress.total];
    if (progress.overdue) [text appendFormat:@"\n%@", [NSString stringWithFormat:WSText(@"%lu overdue"), (unsigned long)progress.overdue]];
    self.progressLabel.text = text;

    NSArray *all = [ProjectManager.shared tasksFor:p];
    self.tasks = self.showCompleted ? all : [all filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status < %d", TaskStatusCompleted]];
    self.notes = [ProjectManager.shared notesFor:p];
    self.files = [ProjectManager.shared filesFor:p];
    [self buildNavigationItems];
    [self.tableView reloadData];
}

- (void)buildNavigationItems {
    __weak typeof(self) weakSelf = self;
    Project *p = self.project;
    NSMutableArray *statusActions = NSMutableArray.new;
    for (ProjectStatus s = ProjectStatusPlanning; s <= ProjectStatusArchived; s++) {
        UIAction *a = [UIAction actionWithTitle:ProjectStatusTitle(s) image:nil identifier:nil handler:^(UIAction *x) {
            NSError *error = nil;
            if (![ProjectManager.shared setStatus:s forProject:weakSelf.project error:&error]) [weakSelf ws_showError:error];
        }];
        a.state = p.status == s ? UIMenuElementStateOn : UIMenuElementStateOff;
        [statusActions addObject:a];
    }
    BOOL archived = p.status == ProjectStatusArchived;
    UIAction *archive = [UIAction actionWithTitle:archived ? WSText(@"Restore") : WSText(@"Archive")
                                            image:[UIImage ws_symbol:archived ? @"arrow.uturn.backward" : @"archivebox"] identifier:nil handler:^(UIAction *a) {
        NSError *error = nil;
        BOOL ok = archived ? [ProjectManager.shared restore:weakSelf.project error:&error] : [ProjectManager.shared archive:weakSelf.project error:&error];
        if (!ok) [weakSelf ws_showError:error];
    }];
    UIAction *favorite = [UIAction actionWithTitle:p.isFavorite ? WSText(@"Remove from Favorites") : WSText(@"Add to Favorites")
                                             image:[UIImage ws_symbol:p.isFavorite ? @"star.slash" : @"star"] identifier:nil handler:^(UIAction *a) {
        NSError *error = nil;
        if (![FavoriteManager.shared toggleFavorite:weakSelf.project error:&error]) [weakSelf ws_showError:error];
    }];
    UIAction *delete = [UIAction actionWithTitle:WSText(@"Delete Project") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) {
        [weakSelf confirmDelete];
    }];
    delete.attributes = UIMenuElementAttributesDestructive;
    UIMenu *menu = [UIMenu menuWithChildren:@[
        [UIMenu menuWithTitle:WSText(@"Status") image:[UIImage ws_symbol:@"flag"] identifier:nil options:0 children:statusActions],
        favorite, archive,
        [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[delete]],
    ]];
    UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:menu];
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit primaryAction:[UIAction actionWithHandler:^(UIAction *a) {
        ProjectEditViewController *editor = [[ProjectEditViewController alloc] initWithProject:weakSelf.project];
        [weakSelf presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
    }]];
    self.navigationItem.rightBarButtonItems = @[edit, more];
}

- (void)confirmDelete {
    __weak typeof(self) weakSelf = self;
    NSUInteger taskCount = self.project.tasks.count;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:WSText(@"Delete this project?")
                                                                   message:taskCount ? WSText(@"Choose what happens to its tasks.") : nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    void (^run)(BOOL) = ^(BOOL deleteTasks) {
        NSError *error = nil;
        if (![ProjectManager.shared deleteProject:weakSelf.project deleteTasks:deleteTasks error:&error]) [weakSelf ws_showError:error];
    };
    if (taskCount) {
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Delete Project, Keep Tasks") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { run(NO); }]];
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Delete Project and Tasks") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { run(YES); }]];
    } else {
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) { run(NO); }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItems.lastObject;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return ProjectSectionCount; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((ProjectSection)section) {
        case ProjectSectionOverview: return 1;
        case ProjectSectionTasks:    return (NSInteger)self.tasks.count + 2;   // + add, + show/hide completed
        case ProjectSectionNotes:    return (NSInteger)self.notes.count + 1;
        case ProjectSectionFiles:    return (NSInteger)self.files.count + 1;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((ProjectSection)section) {
        case ProjectSectionTasks: return WSText(@"Tasks");
        case ProjectSectionNotes: return WSText(@"Notes");
        case ProjectSectionFiles: return WSText(@"Files");
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    UIListContentConfiguration *c = [UIListContentConfiguration subtitleCellConfiguration];
    c.textProperties.font = t.fontBody;
    c.textProperties.color = t.textPrimary;
    c.secondaryTextProperties.font = t.fontCaption;
    c.secondaryTextProperties.color = t.textSecondary;
    NSInteger row = indexPath.row;
    Project *p = self.project;

    void (^addRow)(NSString *) = ^(NSString *title) {
        c.text = title;
        c.textProperties.color = t.accent;
        c.image = [UIImage ws_symbol:@"plus.circle.fill"];
        c.imageProperties.tintColor = t.accent;
    };

    switch ((ProjectSection)indexPath.section) {
        case ProjectSectionOverview: {
            NSMutableArray *lines = NSMutableArray.new;
            [lines addObject:[NSString stringWithFormat:@"%@ · %@ %@", ProjectStatusTitle(p.status), TaskPriorityTitle(p.priority), WSText(@"priority")]];
            if (p.startDate || p.dueDate) {
                NSString *start = p.startDate ? [Task relativeDayText:p.startDate includeTime:NO] : @"—";
                NSString *due = p.dueDate ? [Task relativeDayText:p.dueDate includeTime:NO] : @"—";
                [lines addObject:[NSString stringWithFormat:@"%@ → %@", start, due]];
            }
            if (p.tags.count) [lines addObject:[@"#" stringByAppendingString:[TagManager joinedNames:p.tags]]];
            c.text = p.detail.length ? p.detail : WSText(@"No description");
            c.textProperties.color = p.detail.length ? t.textPrimary : t.textTertiary;
            c.secondaryText = [lines componentsJoinedByString:@"\n"];
            c.textToSecondaryTextVerticalPadding = 8;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case ProjectSectionTasks: {
            if (row == (NSInteger)self.tasks.count) { addRow(WSText(@"Add Task")); break; }
            if (row == (NSInteger)self.tasks.count + 1) {
                c = [UIListContentConfiguration cellConfiguration];
                c.text = self.showCompleted ? WSText(@"Hide Completed") : WSText(@"Show Completed");
                c.textProperties.font = t.fontCallout;
                c.textProperties.color = t.textSecondary;
                c.textProperties.alignment = UIListContentTextAlignmentCenter;
                break;
            }
            Task *task = self.tasks[row];
            BOOL done = task.status == TaskStatusCompleted;
            c.text = task.title;
            c.textProperties.color = done ? t.textTertiary : t.textPrimary;
            NSMutableArray *meta = NSMutableArray.new;
            if (task.dueText) [meta addObject:task.dueText];
            [meta addObject:TaskPriorityTitle(task.priority)];
            if (task.checklistItems.count) [meta addObject:[NSString stringWithFormat:@"☑︎ %lu/%lu", (unsigned long)task.checklistDoneCount, (unsigned long)task.checklistItems.count]];
            c.secondaryText = [meta componentsJoinedByString:@" · "];
            if (task.isOverdue) c.secondaryTextProperties.color = t.danger;
            c.image = [UIImage ws_symbol:done ? @"checkmark.circle.fill" : @"circle"];
            c.imageProperties.tintColor = done ? t.success : [t colorForPriority:task.priority];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case ProjectSectionNotes: {
            if (row == (NSInteger)self.notes.count) { addRow(WSText(@"Add Note")); break; }
            Note *note = self.notes[row];
            c.text = note.title;
            c.secondaryText = [Task relativeDayText:note.updatedAt includeTime:NO];
            c.image = [UIImage ws_symbol:@"note.text"];
            c.imageProperties.tintColor = [t colorForObjectKind:WSObjectKindNote];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case ProjectSectionFiles: {
            if (row == (NSInteger)self.files.count) { addRow(WSText(@"Import File")); break; }
            FileItem *file = self.files[row];
            c.text = file.name;
            c.image = [UIImage ws_symbol:@"doc"];
            c.imageProperties.tintColor = [t colorForObjectKind:WSObjectKindFile];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        default: break;
    }
    cell.contentConfiguration = c;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;
    __weak typeof(self) weakSelf = self;
    switch ((ProjectSection)indexPath.section) {
        case ProjectSectionTasks:
            if (row == (NSInteger)self.tasks.count) [AppRouter.shared presentNewTaskFrom:self project:self.project parent:nil];
            else if (row == (NSInteger)self.tasks.count + 1) { self.showCompleted = !self.showCompleted; [self reload]; }
            else [AppRouter.shared open:self.tasks[row] from:self];
            break;
        case ProjectSectionNotes:
            if (row == (NSInteger)self.notes.count) {
                NoteEditViewController *editor = [[NoteEditViewController alloc] initWithNote:nil category:nil project:self.project];
                [self.navigationController pushViewController:editor animated:YES];
            } else [AppRouter.shared open:self.notes[row] from:self];
            break;
        case ProjectSectionFiles:
            if (row == (NSInteger)self.files.count) {
                [FileImportManager.shared presentPickerFrom:self project:self.project task:nil folder:nil completion:^(FileImportResult *result) {
                    if (result.failedNames.count) [weakSelf ws_showMessage:[NSString stringWithFormat:WSText(@"Could not import: %@"), [result.failedNames componentsJoinedByString:@", "]] title:WSText(@"Import")];
                }];
            } else [AppRouter.shared open:self.files[row] from:self];
            break;
        default: break;
    }
}

/// Swipe to complete a task right from the project.
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != ProjectSectionTasks || indexPath.row >= (NSInteger)self.tasks.count) return nil;
    Task *task = self.tasks[indexPath.row];
    BOOL done = task.status == TaskStatusCompleted;
    UIContextualAction *toggle = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:done ? WSText(@"Reopen") : WSText(@"Complete")
                                                                       handler:^(UIContextualAction *a, UIView *v, void (^finish)(BOOL)) {
        NSError *error = nil;
        BOOL ok = [TaskManager.shared toggleCompleted:task error:&error];
        if (!ok) [self ws_showError:error];
        finish(ok);
    }];
    toggle.backgroundColor = AppThemeManager.shared.success;
    toggle.image = [UIImage ws_symbol:done ? @"arrow.uturn.backward" : @"checkmark"];
    return [UISwipeActionsConfiguration configurationWithActions:@[toggle]];
}

@end
