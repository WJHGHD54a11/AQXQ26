//
//  ProjectEditViewController.m
//  WorkSpace
//

#import "ProjectEditViewController.h"
#import "ProjectManager.h"
#import "Project.h"

@interface ProjectEditViewController ()
@property (nonatomic, strong, nullable) Project *project;
@property (nonatomic, strong) ProjectDraft *draft;
@property (nonatomic, strong, readwrite, nullable) Project *savedProject;
@end

@implementation ProjectEditViewController

- (instancetype)initWithProject:(Project *)project {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _project = project;
        _draft = [ProjectDraft draftFromProject:project];
        self.title = project ? WSText(@"Edit Project") : WSText(@"New Project");
    }
    return self;
}

- (NSArray<WSFormSection *> *)buildSections {
    ProjectDraft *d = self.draft;
    WSFormRow *name = [WSFormRow type:WSFormRowText key:@"name" title:WSText(@"Name") value:d.name];
    name.placeholder = WSText(@"Project name");
    WSFormRow *detail = [WSFormRow type:WSFormRowTextArea key:@"detail" title:WSText(@"Description") value:d.detail];
    WSFormRow *status = [WSFormRow type:WSFormRowChoice key:@"status" title:WSText(@"Status") value:@(d.status)];
    status.options = ProjectStatusTitles();
    WSFormRow *priority = [WSFormRow type:WSFormRowChoice key:@"priority" title:WSText(@"Priority") value:@(d.priority)];
    priority.options = TaskPriorityTitles();
    WSFormRow *start = [WSFormRow type:WSFormRowDate key:@"start" title:WSText(@"Start Date") value:d.startDate];
    start.dateMode = UIDatePickerModeDate;
    WSFormRow *due = [WSFormRow type:WSFormRowDate key:@"due" title:WSText(@"Due Date") value:d.dueDate];
    due.dateMode = UIDatePickerModeDate;
    WSFormRow *color = [WSFormRow type:WSFormRowColor key:@"color" title:WSText(@"Color") value:d.colorIdentifier];
    WSFormRow *tags = [WSFormRow type:WSFormRowTags key:@"tags" title:WSText(@"Tags") value:d.tagNames];
    return @[[WSFormSection title:nil rows:@[name, detail]],
             [WSFormSection title:WSText(@"Details") rows:@[status, priority, start, due]],
             [WSFormSection title:WSText(@"Organize") rows:@[color, tags]]];
}

- (BOOL)save {
    ProjectDraft *d = self.draft;
    d.name = [self stringForKey:@"name"];
    d.detail = [self stringForKey:@"detail"];
    d.status = (ProjectStatus)[[self formValueForKey:@"status"] integerValue];
    d.priority = (TaskPriority)[[self formValueForKey:@"priority"] integerValue];
    d.startDate = [self formValueForKey:@"start"];
    d.dueDate = [self formValueForKey:@"due"];
    d.colorIdentifier = [self formValueForKey:@"color"] ?: @"indigo";
    d.tagNames = [self formValueForKey:@"tags"] ?: @[];
    if (d.startDate && d.dueDate && [d.dueDate compare:d.startDate] == NSOrderedAscending) {
        [self ws_showMessage:WSText(@"The due date must be after the start date.") title:nil];
        return NO;
    }
    NSError *error = nil;
    BOOL ok;
    if (self.project) {
        ok = [ProjectManager.shared updateProject:self.project with:d error:&error];
    } else {
        self.savedProject = [ProjectManager.shared createProject:d error:&error];
        ok = self.savedProject != nil;
    }
    if (!ok) [self ws_showError:error];
    return ok;
}

@end
