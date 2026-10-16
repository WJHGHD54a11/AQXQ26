//
//  TaskFilterViewController.m
//  WorkSpace
//

#import "TaskFilterViewController.h"
#import "WSUIKit.h"
#import "ProjectManager.h"
#import "TagManager.h"
#import "Project.h"
#import "Tag.h"

typedef NS_ENUM(NSInteger, FilterSection) {
    FilterSectionShow = 0,
    FilterSectionProject,
    FilterSectionTag,
    FilterSectionSort,
};

@interface TaskFilterViewController ()
@property (nonatomic) TaskFilter filter;
@property (nonatomic) TaskSort sort;
@property (nonatomic, strong, nullable) Project *project;
@property (nonatomic, strong, nullable) Tag *tag;
@property (nonatomic, copy) NSArray<Project *> *projects;
@property (nonatomic, copy) NSArray<Tag *> *tags;
@end

@implementation TaskFilterViewController

- (instancetype)initWithFilter:(TaskFilter)filter sort:(TaskSort)sort project:(Project *)project tag:(Tag *)tag {
    if ((self = [super initWithStyle:UITableViewStyleInsetGrouped])) {
        _filter = filter;
        _sort = sort;
        _project = project;
        _tag = tag;
        self.title = WSText(@"Filter & Sort");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"row"];
    self.projects = [ProjectManager.shared projectsInScope:ProjectListScopeAll];
    self.tags = [TagManager.shared allTags];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WSText(@"Reset") style:UIBarButtonItemStylePlain
                                                                            target:self action:@selector(reset)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WSText(@"Apply") style:UIBarButtonItemStyleDone
                                                                             target:self action:@selector(apply)];
}

- (void)reset {
    self.filter = TaskFilterAll;
    self.sort = TaskSortDueDate;
    self.project = nil;
    self.tag = nil;
    [self.tableView reloadData];
}

- (void)apply {
    // "By Project" / "By Tag" without a choice means "any project / any tag".
    if (self.onApply) self.onApply(self.filter, self.sort,
                                   self.filter == TaskFilterProject ? self.project : nil,
                                   self.filter == TaskFilterTag ? self.tag : nil);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 4; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case FilterSectionShow:    return TaskFilterTag + 1;
        case FilterSectionProject: return self.filter == TaskFilterProject ? self.projects.count + 1 : 0;
        case FilterSectionTag:     return self.filter == TaskFilterTag ? self.tags.count + 1 : 0;
        case FilterSectionSort:    return TaskSortManual + 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case FilterSectionShow:    return WSText(@"Show");
        case FilterSectionProject: return self.filter == TaskFilterProject ? WSText(@"Project") : nil;
        case FilterSectionTag:     return self.filter == TaskFilterTag ? WSText(@"Tag") : nil;
        case FilterSectionSort:    return WSText(@"Sort By");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == FilterSectionSort && self.sort == TaskSortManual) return WSText(@"Drag tasks in the list to set their order.");
    if (section == FilterSectionProject && self.filter == TaskFilterProject && self.projects.count == 0) return WSText(@"No projects yet.");
    if (section == FilterSectionTag && self.filter == TaskFilterTag && self.tags.count == 0) return WSText(@"No tags yet.");
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row" forIndexPath:indexPath];
    UIListContentConfiguration *c = cell.defaultContentConfiguration;
    c.textProperties.font = t.fontBody;
    BOOL checked = NO;
    NSInteger row = indexPath.row;

    switch (indexPath.section) {
        case FilterSectionShow:
            c.text = TaskFilterTitle(row);
            c.image = [UIImage ws_symbol:[self symbolForFilter:row]];
            c.imageProperties.tintColor = t.accent;
            checked = row == self.filter;
            break;
        case FilterSectionProject:
            if (row == 0) {
                c.text = WSText(@"Any Project");
                checked = self.project == nil;
            } else {
                Project *p = self.projects[row - 1];
                c.text = p.name;
                c.secondaryText = ProjectStatusTitle(p.status);
                c.image = [UIImage ws_symbol:@"folder.fill"];
                c.imageProperties.tintColor = [t colorForIdentifier:p.colorIdentifier];
                checked = p == self.project;
            }
            break;
        case FilterSectionTag:
            if (row == 0) {
                c.text = WSText(@"Any Tag");
                checked = self.tag == nil;
            } else {
                Tag *tag = self.tags[row - 1];
                c.text = tag.name;
                c.image = [UIImage ws_symbol:@"tag.fill"];
                c.imageProperties.tintColor = [t colorForIdentifier:tag.colorIdentifier];
                checked = tag == self.tag;
            }
            break;
        case FilterSectionSort:
            c.text = TaskSortTitle(row);
            checked = row == self.sort;
            break;
    }
    cell.contentConfiguration = c;
    cell.backgroundColor = t.surface;
    cell.tintColor = t.accent;
    cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (NSString *)symbolForFilter:(TaskFilter)filter {
    NSArray *symbols = @[@"tray.full", @"sun.max", @"calendar", @"exclamationmark.circle", @"checkmark.circle",
                         @"flag", @"folder", @"tag"];
    return filter < (NSInteger)symbols.count ? symbols[filter] : @"circle";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;
    switch (indexPath.section) {
        case FilterSectionShow:
            self.filter = row;
            break;
        case FilterSectionProject:
            self.project = row == 0 ? nil : self.projects[row - 1];
            break;
        case FilterSectionTag:
            self.tag = row == 0 ? nil : self.tags[row - 1];
            break;
        case FilterSectionSort:
            self.sort = row;
            break;
    }
    [tableView reloadData];
}

@end
