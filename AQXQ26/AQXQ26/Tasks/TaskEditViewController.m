//
//  TaskEditViewController.m
//  WorkSpace
//

#import "TaskEditViewController.h"
#import "TaskManager.h"
#import "ProjectManager.h"
#import "ReminderManager.h"
#import "Task.h"
#import "Project.h"

@interface TaskEditViewController ()
@property (nonatomic, strong, nullable) Task *task;
@property (nonatomic, strong, nullable) Task *parent;
@property (nonatomic, strong) TaskDraft *draft;
/// Index 0 = no project; the rest map to this array.
@property (nonatomic, copy) NSArray<Project *> *projectChoices;
@property (nonatomic, strong, readwrite, nullable) Task *savedTask;
@end

@implementation TaskEditViewController

- (instancetype)initWithTask:(Task *)task project:(Project *)project parent:(Task *)parent {
    if ((self = [super init])) {
        _task = task;
        _draft = [TaskDraft draftFromTask:task];
        if (!task) {
            _draft.parent = parent;
            // A subtask lives in its parent's project unless one was given explicitly.
            _draft.project = project ?: parent.project;
        }
        _parent = _draft.parent;

        NSMutableArray *projects = [[ProjectManager.shared projectsInScope:ProjectListScopeCurrent] mutableCopy];
        if (_draft.project && ![projects containsObject:_draft.project]) [projects insertObject:_draft.project atIndex:0];
        _projectChoices = projects;

        self.title = task ? WSText(@"Edit Task") : (parent ? WSText(@"New Subtask") : WSText(@"New Task"));
        self.saveTitle = task ? WSText(@"Save") : WSText(@"Add");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    TaskDraft *d = self.draft;

    WSFormRow *title = [WSFormRow type:WSFormRowText key:@"title" title:WSText(@"Title") value:d.title];
    title.placeholder = WSText(@"What needs to be done?");
    WSFormRow *detail = [WSFormRow type:WSFormRowTextArea key:@"detail" title:WSText(@"Description") value:d.detail];
    detail.placeholder = WSText(@"Description");

    WSFormRow *status = [WSFormRow type:WSFormRowChoice key:@"status" title:WSText(@"Status") value:@(d.status)];
    status.options = TaskStatusTitles();
    status.symbol = @"circle.dashed";
    WSFormRow *priority = [WSFormRow type:WSFormRowChoice key:@"priority" title:WSText(@"Priority") value:@(d.priority)];
    priority.options = TaskPriorityTitles();
    priority.symbol = @"flag";
    WSFormRow *category = [WSFormRow type:WSFormRowText key:@"category" title:WSText(@"Category") value:d.category];
    category.placeholder = WSText(@"Category (optional)");

    WSFormRow *due = [WSFormRow type:WSFormRowDate key:@"due" title:WSText(@"Due Date") value:d.dueDate];
    due.symbol = @"calendar";
    WSFormRow *reminder = [WSFormRow type:WSFormRowDate key:@"reminder" title:WSText(@"Reminder") value:d.reminderDate];
    reminder.symbol = @"bell";
    WSFormRow *repeat = [WSFormRow type:WSFormRowChoice key:@"repeat" title:WSText(@"Repeat") value:@(d.repeatRule)];
    repeat.options = RepeatRuleTitles();
    repeat.symbol = @"repeat";

    NSMutableArray *projectNames = [NSMutableArray arrayWithObject:WSText(@"No Project")];
    for (Project *p in self.projectChoices) [projectNames addObject:p.name ?: @""];
    NSUInteger projectIndex = d.project ? [self.projectChoices indexOfObject:d.project] : NSNotFound;
    WSFormRow *project = [WSFormRow type:WSFormRowChoice key:@"project" title:WSText(@"Project")
                                   value:@(projectIndex == NSNotFound ? 0 : projectIndex + 1)];
    project.options = projectNames;
    project.symbol = @"folder";

    WSFormRow *tags = [WSFormRow type:WSFormRowTags key:@"tags" title:WSText(@"Tags") value:d.tagNames];
    tags.symbol = @"tag";

    NSMutableArray *organize = [NSMutableArray arrayWithObjects:status, priority, category, nil];
    // Subtasks follow their parent's project, so only top-level tasks pick one.
    if (!self.parent) [organize addObject:project];
    [organize addObject:tags];

    NSMutableArray *sections = [NSMutableArray arrayWithObjects:
        [WSFormSection title:nil rows:@[title, detail]],
        [WSFormSection title:WSText(@"Organize") rows:organize],
        nil];

    WSFormSection *schedule = [WSFormSection title:WSText(@"Schedule") rows:@[due, reminder, repeat]];
    schedule.footer = WSText(@"Repeating tasks move to their next date when completed.");
    [sections addObject:schedule];

    if (!self.task) {
        WSFormRow *checklist = [WSFormRow type:WSFormRowList key:@"checklist" title:WSText(@"Checklist") value:d.checklistTitles];
        checklist.symbol = @"checklist";
        [sections addObject:[WSFormSection title:WSText(@"Checklist") rows:@[checklist]]];
    }

    WSFormRow *notes = [WSFormRow type:WSFormRowTextArea key:@"notes" title:WSText(@"Notes") value:d.notes];
    notes.placeholder = WSText(@"Notes");
    [sections addObject:[WSFormSection title:WSText(@"Notes") rows:@[notes]]];

    if (self.parent) {
        WSFormSection *s = sections.firstObject;
        s.footer = [NSString stringWithFormat:WSText(@"Subtask of “%@”"), self.parent.title];
    }
    return sections;
}

- (NSString *)optionalString:(NSString *)key {
    NSString *s = [self stringForKey:key];
    return s.length ? s : nil;
}

- (BOOL)save {
    TaskDraft *d = self.draft;
    d.title = [self stringForKey:@"title"];
    d.detail = [self optionalString:@"detail"];
    d.notes = [self optionalString:@"notes"];
    d.category = [self optionalString:@"category"];
    d.status = (TaskStatus)[[self formValueForKey:@"status"] integerValue];
    d.priority = (TaskPriority)[[self formValueForKey:@"priority"] integerValue];
    d.repeatRule = (RepeatRule)[[self formValueForKey:@"repeat"] integerValue];
    d.dueDate = [self formValueForKey:@"due"];
    d.reminderDate = [self formValueForKey:@"reminder"];
    d.tagNames = [self formValueForKey:@"tags"] ?: @[];
    if (!self.task) d.checklistTitles = [self formValueForKey:@"checklist"] ?: @[];
    if (!self.parent) {
        NSInteger i = [[self formValueForKey:@"project"] integerValue];
        d.project = (i > 0 && i - 1 < (NSInteger)self.projectChoices.count) ? self.projectChoices[i - 1] : nil;
    }

    if (d.title.length == 0) {
        [self ws_showMessage:WSText(@"Please enter a title.") title:nil];
        return NO;
    }
    if (d.repeatRule != RepeatRuleNone && !d.dueDate) {
        [self ws_showMessage:WSText(@"A repeating task needs a due date.") title:nil];
        return NO;
    }

    NSError *error = nil;
    if (self.task) {
        if (![TaskManager.shared updateTask:self.task with:d error:&error]) {
            [self ws_showError:error];
            return NO;
        }
        self.savedTask = self.task;
    } else {
        Task *created = [TaskManager.shared createTask:d error:&error];
        if (!created) {
            [self ws_showError:error];
            return NO;
        }
        self.savedTask = created;
    }

    if (d.reminderDate || d.dueDate) [self checkNotificationPermission:(d.reminderDate != nil)];
    return YES;
}

/// Data is already saved; only tell the user when a reminder they set can't be delivered.
- (void)checkNotificationPermission:(BOOL)userSetReminder {
    UIViewController *presenter = self.presentingViewController;
    [ReminderManager.shared ensureAuthorization:^(BOOL granted) {
        if (granted || !userSetReminder || !presenter) return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [presenter ws_showMessage:WSText(@"The task was saved, but notifications are turned off for WorkSpace. Enable them in Settings to get reminders.")
                                title:WSText(@"Notifications Off")];
        });
    }];
}

@end
