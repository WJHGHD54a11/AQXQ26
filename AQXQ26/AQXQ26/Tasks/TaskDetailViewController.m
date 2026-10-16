//
//  TaskDetailViewController.m
//  WorkSpace
//
//  Sections: Overview · Checklist · Subtasks · Attachments · Notes.
//  Checklist and subtasks are edited in place; everything saves immediately.
//

#import "TaskDetailViewController.h"
#import "TaskEditViewController.h"
#import "TaskManager.h"
#import "TagManager.h"
#import "FavoriteManager.h"
#import "RecentManager.h"
#import "FileImportManager.h"
#import "DataManager.h"
#import "AppRouter.h"
#import "WSUIKit.h"
#import "Task+Logic.h"
#import "ChecklistItem.h"
#import "Project.h"
#import "FileItem.h"

typedef NS_ENUM(NSInteger, TaskDetailSection) {
    TaskDetailSectionOverview = 0,
    TaskDetailSectionChecklist,
    TaskDetailSectionSubtasks,
    TaskDetailSectionAttachments,
    TaskDetailSectionNotes,
    TaskDetailSectionCount,
};

@interface TaskDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong, readwrite) Task *task;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSArray<NSString *> *> *overviewRows;   // @[title, value]
@property (nonatomic, copy) NSArray<ChecklistItem *> *checklist;
@property (nonatomic, copy) NSArray<Task *> *subtasks;
@property (nonatomic, copy) NSArray<FileItem *> *attachments;
@end

@implementation TaskDetailViewController

- (instancetype)initWithTask:(Task *)task {
    if ((self = [super initWithNibName:nil bundle:nil])) _task = task;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = AppThemeManager.shared.background;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = AppThemeManager.shared.background;
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
    [RecentManager.shared markOpened:self.task];
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (void)dataChanged {
    if (self.task.isDeleted || !self.task.managedObjectContext) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self reload];
}

#pragma mark - Data

- (void)reload {
    Task *task = self.task;
    self.title = task.title;
    NSMutableArray *rows = NSMutableArray.new;
    [rows addObject:@[WSText(@"Status"), TaskStatusTitle(task.status)]];
    [rows addObject:@[WSText(@"Priority"), TaskPriorityTitle(task.priority)]];
    [rows addObject:@[WSText(@"Due"), task.dueText ?: WSText(@"None")]];
    if (task.reminderDate) [rows addObject:@[WSText(@"Reminder"), [Task relativeDayText:task.reminderDate includeTime:YES]]];
    if (task.repeatRule != RepeatRuleNone) [rows addObject:@[WSText(@"Repeat"), RepeatRuleTitle(task.repeatRule)]];
    [rows addObject:@[WSText(@"Project"), task.project.name ?: WSText(@"None")]];
    if (task.parent) [rows addObject:@[WSText(@"Parent Task"), task.parent.title]];
    if (task.category.length) [rows addObject:@[WSText(@"Category"), task.category]];
    if (task.tags.count) [rows addObject:@[WSText(@"Tags"), [TagManager joinedNames:task.tags]]];
    if (task.completedAt) [rows addObject:@[WSText(@"Completed"), [Task relativeDayText:task.completedAt includeTime:YES]]];
    self.overviewRows = rows;

    self.checklist = [TaskManager.shared orderedChecklist:task];
    self.subtasks = [task.subtasks.allObjects sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]]];
    self.attachments = [task.attachments.allObjects sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]]];
    [self buildNavigationItems];
    [self.tableView reloadData];
}

- (void)buildNavigationItems {
    __weak typeof(self) weakSelf = self;
    Task *task = self.task;
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit primaryAction:[UIAction actionWithHandler:^(UIAction *a) {
        TaskEditViewController *editor = [[TaskEditViewController alloc] initWithTask:weakSelf.task project:nil parent:nil];
        [weakSelf presentViewController:editor.embeddedInNavigation animated:YES completion:nil];
    }]];

    NSMutableArray *statusActions = NSMutableArray.new;
    for (TaskStatus s = TaskStatusToDo; s <= TaskStatusCancelled; s++) {
        UIAction *a = [UIAction actionWithTitle:TaskStatusTitle(s) image:nil identifier:nil handler:^(UIAction *x) { [weakSelf setStatus:s]; }];
        a.state = task.status == s ? UIMenuElementStateOn : UIMenuElementStateOff;
        [statusActions addObject:a];
    }
    NSMutableArray *priorityActions = NSMutableArray.new;
    for (TaskPriority p = TaskPriorityLow; p <= TaskPriorityUrgent; p++) {
        UIAction *a = [UIAction actionWithTitle:TaskPriorityTitle(p) image:nil identifier:nil handler:^(UIAction *x) {
            NSError *error = nil;
            if (![TaskManager.shared setPriority:p forTask:weakSelf.task error:&error]) [weakSelf ws_showError:error];
        }];
        a.state = task.priority == p ? UIMenuElementStateOn : UIMenuElementStateOff;
        [priorityActions addObject:a];
    }
    UIAction *deleteAction = [UIAction actionWithTitle:WSText(@"Delete Task") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) { [weakSelf confirmDelete]; }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    UIMenu *more = [UIMenu menuWithChildren:@[
        [UIMenu menuWithTitle:WSText(@"Status") image:[UIImage ws_symbol:@"circle.lefthalf.filled"] identifier:nil options:0 children:statusActions],
        [UIMenu menuWithTitle:WSText(@"Priority") image:[UIImage ws_symbol:@"flag"] identifier:nil options:0 children:priorityActions],
        [UIAction actionWithTitle:task.isFavorite ? WSText(@"Remove from Favorites") : WSText(@"Add to Favorites")
                            image:[UIImage ws_symbol:task.isFavorite ? @"star.slash" : @"star"] identifier:nil handler:^(UIAction *a) {
            NSError *error = nil;
            if (![FavoriteManager.shared toggleFavorite:weakSelf.task error:&error]) [weakSelf ws_showError:error];
        }],
        [UIAction actionWithTitle:WSText(@"Duplicate") image:[UIImage ws_symbol:@"plus.square.on.square"] identifier:nil handler:^(UIAction *a) {
            NSError *error = nil;
            Task *copy = [TaskManager.shared duplicateTask:weakSelf.task error:&error];
            if (copy) [AppRouter.shared open:copy from:weakSelf]; else [weakSelf ws_showError:error];
        }],
        [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[
            deleteAction]],
    ]];
    UIBarButtonItem *menu = [[UIBarButtonItem alloc] initWithImage:[UIImage ws_symbol:@"ellipsis.circle"] menu:more];
    self.navigationItem.rightBarButtonItems = @[edit, menu];
}

#pragma mark - Actions

- (void)setStatus:(TaskStatus)status {
    NSError *error = nil;
    if (![TaskManager.shared setStatus:status forTask:self.task error:&error]) [self ws_showError:error];
}

- (void)confirmDelete {
    NSString *message = self.task.subtasks.count ? WSText(@"Its subtasks and checklist will be deleted too.") : nil;
    __weak typeof(self) weakSelf = self;
    [self ws_confirm:WSText(@"Delete this task?") message:message destructive:WSText(@"Delete") handler:^{
        NSError *error = nil;
        if (![TaskManager.shared deleteTask:weakSelf.task error:&error]) [weakSelf ws_showError:error];
    }];
}

- (void)addChecklistItem {
    __weak typeof(self) weakSelf = self;
    [self ws_promptTitle:WSText(@"New Checklist Item") message:nil placeholder:WSText(@"Item") text:nil action:WSText(@"Add") handler:^(NSString *text) {
        NSError *error = nil;
        if (![TaskManager.shared addChecklistItem:text toTask:weakSelf.task error:&error]) [weakSelf ws_showError:error];
    }];
}

- (void)renameChecklistItem:(ChecklistItem *)item {
    __weak typeof(self) weakSelf = self;
    [self ws_promptTitle:WSText(@"Edit Item") message:nil placeholder:WSText(@"Item") text:item.title action:WSText(@"Save") handler:^(NSString *text) {
        NSError *error = nil;
        if (![TaskManager.shared renameChecklistItem:item to:text error:&error]) [weakSelf ws_showError:error];
    }];
}

- (void)importAttachment {
    __weak typeof(self) weakSelf = self;
    [FileImportManager.shared presentPickerFrom:self project:self.task.project task:self.task folder:nil completion:^(FileImportResult *result) {
        if (result.failedNames.count) {
            [weakSelf ws_showMessage:[NSString stringWithFormat:WSText(@"Could not import: %@"), [result.failedNames componentsJoinedByString:@", "]]
                               title:WSText(@"Import")];
        }
    }];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return TaskDetailSectionCount; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ((TaskDetailSection)section) {
        case TaskDetailSectionOverview:    return 1 + (NSInteger)self.overviewRows.count;   // header row + fields
        case TaskDetailSectionChecklist:   return (NSInteger)self.checklist.count + 1;      // + add
        case TaskDetailSectionSubtasks:    return (NSInteger)self.subtasks.count + (self.task.parent ? 0 : 1);
        case TaskDetailSectionAttachments: return (NSInteger)self.attachments.count + 1;
        case TaskDetailSectionNotes:       return 1;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ((TaskDetailSection)section) {
        case TaskDetailSectionChecklist:
            return self.checklist.count ? [NSString stringWithFormat:@"%@ · %lu/%lu", WSText(@"Checklist"),
                                           (unsigned long)self.task.checklistDoneCount, (unsigned long)self.checklist.count] : WSText(@"Checklist");
        case TaskDetailSectionSubtasks:
            return self.task.parent ? nil : (self.task.subtaskProgressText ?: WSText(@"Subtasks"));
        case TaskDetailSectionAttachments: return WSText(@"Attachments");
        case TaskDetailSectionNotes:       return WSText(@"Notes");
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = t.surface;
    UIListContentConfiguration *c = [UIListContentConfiguration valueCellConfiguration];
    c.textProperties.font = t.fontBody;
    c.textProperties.color = t.textPrimary;
    c.secondaryTextProperties.color = t.textSecondary;
    NSInteger row = indexPath.row;

    switch ((TaskDetailSection)indexPath.section) {
        case TaskDetailSectionOverview: {
            if (row == 0) {
                c = [UIListContentConfiguration subtitleCellConfiguration];
                c.text = self.task.title;
                c.textProperties.font = t.fontTitle;
                c.textProperties.color = t.textPrimary;
                c.secondaryText = self.task.detail;
                c.secondaryTextProperties.color = t.textSecondary;
                c.secondaryTextProperties.font = t.fontCallout;
                c.textToSecondaryTextVerticalPadding = 6;
                BOOL done = self.task.status == TaskStatusCompleted;
                c.image = [UIImage ws_symbol:done ? @"checkmark.circle.fill" : @"circle" pointSize:24 weight:UIImageSymbolWeightRegular];
                c.imageProperties.tintColor = done ? t.success : [t colorForPriority:self.task.priority];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessibilityHint = done ? WSText(@"Mark as not completed") : WSText(@"Mark as completed");
                break;
            }
            NSArray *pair = self.overviewRows[row - 1];
            c.text = pair[0];
            c.secondaryText = pair[1];
            if ([pair[0] isEqualToString:WSText(@"Due")] && self.task.isOverdue) c.secondaryTextProperties.color = t.danger;
            BOOL linked = ([pair[0] isEqualToString:WSText(@"Project")] && self.task.project) || [pair[0] isEqualToString:WSText(@"Parent Task")];
            cell.accessoryType = linked ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            cell.selectionStyle = linked ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            break;
        }
        case TaskDetailSectionChecklist: {
            if (row == (NSInteger)self.checklist.count) { [self configureAdd:&c title:WSText(@"Add Item")]; break; }
            ChecklistItem *item = self.checklist[row];
            c = [UIListContentConfiguration cellConfiguration];
            c.text = item.title;
            c.textProperties.color = item.completed ? t.textTertiary : t.textPrimary;
            c.image = [UIImage ws_symbol:item.completed ? @"checkmark.square.fill" : @"square"];
            c.imageProperties.tintColor = item.completed ? t.success : t.textTertiary;
            break;
        }
        case TaskDetailSectionSubtasks: {
            if (row == (NSInteger)self.subtasks.count) { [self configureAdd:&c title:WSText(@"Add Subtask")]; break; }
            Task *sub = self.subtasks[row];
            c = [UIListContentConfiguration subtitleCellConfiguration];
            c.text = sub.title;
            c.textProperties.color = sub.isOpen ? t.textPrimary : t.textTertiary;
            c.secondaryText = [@[TaskPriorityTitle(sub.priority), sub.dueText ?: @""] componentsJoinedByString:sub.dueText ? @" · " : @""];
            c.secondaryTextProperties.color = sub.isOverdue ? t.danger : t.textSecondary;
            c.image = [UIImage ws_symbol:sub.status == TaskStatusCompleted ? @"checkmark.circle.fill" : @"circle"];
            c.imageProperties.tintColor = sub.status == TaskStatusCompleted ? t.success : [t colorForPriority:sub.priority];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case TaskDetailSectionAttachments: {
            if (row == (NSInteger)self.attachments.count) { [self configureAdd:&c title:WSText(@"Attach File")]; break; }
            FileItem *file = self.attachments[row];
            c = [UIListContentConfiguration subtitleCellConfiguration];
            c.text = file.name;
            c.secondaryText = file.fileExtension.uppercaseString;
            c.secondaryTextProperties.color = t.textSecondary;
            c.image = [UIImage ws_symbol:@"paperclip"];
            c.imageProperties.tintColor = t.accent;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case TaskDetailSectionNotes: {
            c = [UIListContentConfiguration cellConfiguration];
            c.text = self.task.notes.length ? self.task.notes : WSText(@"No notes. Tap Edit to add some.");
            c.textProperties.color = self.task.notes.length ? t.textPrimary : t.textTertiary;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        default: break;
    }
    cell.contentConfiguration = c;
    return cell;
}

- (void)configureAdd:(UIListContentConfiguration **)c title:(NSString *)title {
    UIListContentConfiguration *add = [UIListContentConfiguration cellConfiguration];
    add.text = title;
    add.textProperties.color = AppThemeManager.shared.accent;
    add.image = [UIImage ws_symbol:@"plus.circle.fill"];
    add.imageProperties.tintColor = AppThemeManager.shared.accent;
    *c = add;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;
    NSError *error = nil;
    switch ((TaskDetailSection)indexPath.section) {
        case TaskDetailSectionOverview: {
            if (row == 0) { if (![TaskManager.shared toggleCompleted:self.task error:&error]) [self ws_showError:error]; return; }
            NSString *key = self.overviewRows[row - 1][0];
            if ([key isEqualToString:WSText(@"Project")] && self.task.project) [AppRouter.shared open:self.task.project from:self];
            else if ([key isEqualToString:WSText(@"Parent Task")]) [AppRouter.shared open:self.task.parent from:self];
            return;
        }
        case TaskDetailSectionChecklist:
            if (row == (NSInteger)self.checklist.count) [self addChecklistItem];
            else if (![TaskManager.shared toggleChecklistItem:self.checklist[row] error:&error]) [self ws_showError:error];
            return;
        case TaskDetailSectionSubtasks:
            if (row == (NSInteger)self.subtasks.count) [AppRouter.shared presentNewTaskFrom:self project:self.task.project parent:self.task];
            else [AppRouter.shared open:self.subtasks[row] from:self];
            return;
        case TaskDetailSectionAttachments:
            if (row == (NSInteger)self.attachments.count) [self importAttachment];
            else [AppRouter.shared open:self.attachments[row] from:self];
            return;
        default: return;
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    __weak typeof(self) weakSelf = self;
    if (indexPath.section == TaskDetailSectionChecklist && row < (NSInteger)self.checklist.count) {
        ChecklistItem *item = self.checklist[row];
        UIContextualAction *del = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Delete")
                                                                        handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
            NSError *error = nil;
            BOOL ok = [TaskManager.shared deleteChecklistItem:item error:&error];
            if (!ok) [weakSelf ws_showError:error];
            done(ok);
        }];
        UIContextualAction *edit = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:WSText(@"Edit")
                                                                         handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
            [weakSelf renameChecklistItem:item];
            done(YES);
        }];
        edit.backgroundColor = AppThemeManager.shared.accent;
        return [UISwipeActionsConfiguration configurationWithActions:@[del, edit]];
    }
    if (indexPath.section == TaskDetailSectionAttachments && row < (NSInteger)self.attachments.count) {
        FileItem *file = self.attachments[row];
        UIContextualAction *detach = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:WSText(@"Remove")
                                                                           handler:^(UIContextualAction *a, UIView *v, void (^done)(BOOL)) {
            NSError *error = nil;
            BOOL ok = [TaskManager.shared detachFile:file fromTask:weakSelf.task error:&error];
            if (!ok) [weakSelf ws_showError:error];
            done(ok);
        }];
        return [UISwipeActionsConfiguration configurationWithActions:@[detach]];
    }
    return nil;
}

// Checklist rows can be dragged to reorder.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == TaskDetailSectionChecklist && indexPath.row < (NSInteger)self.checklist.count;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)source toProposedIndexPath:(NSIndexPath *)proposed {
    if (proposed.section != TaskDetailSectionChecklist) return source;
    NSInteger last = (NSInteger)self.checklist.count - 1;
    return [NSIndexPath indexPathForRow:MIN(proposed.row, last) inSection:TaskDetailSectionChecklist];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)destination {
    NSError *error = nil;
    if (![TaskManager.shared moveChecklistItemInTask:self.task from:source.row to:destination.row error:&error]) [self ws_showError:error];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath { return NO; }

@end
