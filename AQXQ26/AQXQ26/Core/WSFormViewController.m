//
//  WSFormViewController.m
//  WorkSpace
//

#import "WSFormViewController.h"
#import "TagManager.h"
#import "Tag.h"

@implementation WSFormRow

+ (instancetype)type:(WSFormRowType)type key:(NSString *)key title:(NSString *)title value:(id)value {
    WSFormRow *row = [[self alloc] init];
    row.type = type;
    row.key = key;
    row.title = title;
    row.value = value;
    row.dateMode = UIDatePickerModeDateAndTime;
    return row;
}

@end

@implementation WSFormSection

+ (instancetype)title:(NSString *)title rows:(NSArray<WSFormRow *> *)rows {
    WSFormSection *s = [[self alloc] init];
    s.title = title;
    s.rows = rows;
    return s;
}

@end

#pragma mark - Cells

/// Text field / text view cell. The row is the source of truth; the cell writes back on change.
@interface WSFormTextCell : UITableViewCell <UITextViewDelegate>
@property (nonatomic, strong) UITextField *field;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholder;
@property (nonatomic, weak) WSFormRow *row;
@property (nonatomic, copy) void (^changed)(void);
- (void)bind:(WSFormRow *)row;
@end

@implementation WSFormTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = t.surface;

        _field = UITextField.new;
        _field.font = t.fontBody;
        _field.textColor = t.textPrimary;
        _field.clearButtonMode = UITextFieldViewModeWhileEditing;
        _field.returnKeyType = UIReturnKeyDone;
        _field.translatesAutoresizingMaskIntoConstraints = NO;
        __weak typeof(self) weakSelf = self;
        [_field addAction:[UIAction actionWithHandler:^(UIAction *a) {
            weakSelf.row.value = weakSelf.field.text;
            if (weakSelf.changed) weakSelf.changed();
        }] forControlEvents:UIControlEventEditingChanged];
        [_field addAction:[UIAction actionWithHandler:^(UIAction *a) { [weakSelf.field resignFirstResponder]; }]
         forControlEvents:UIControlEventEditingDidEndOnExit];

        _textView = UITextView.new;
        _textView.font = t.fontBody;
        _textView.textColor = t.textPrimary;
        _textView.backgroundColor = UIColor.clearColor;
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
        _textView.scrollEnabled = NO;
        _textView.delegate = self;
        _textView.translatesAutoresizingMaskIntoConstraints = NO;

        _placeholder = UILabel.new;
        _placeholder.font = t.fontBody;
        _placeholder.textColor = t.textTertiary;
        _placeholder.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:_field];
        [self.contentView addSubview:_textView];
        [self.contentView addSubview:_placeholder];
        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [_field.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [_field.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [_field.topAnchor constraintEqualToAnchor:m.topAnchor],
            [_field.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
            [_field.heightAnchor constraintGreaterThanOrEqualToConstant:28],
            [_textView.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [_textView.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [_textView.topAnchor constraintEqualToAnchor:m.topAnchor],
            [_textView.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
            [_textView.heightAnchor constraintGreaterThanOrEqualToConstant:96],
            [_placeholder.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [_placeholder.topAnchor constraintEqualToAnchor:m.topAnchor],
        ]];
    }
    return self;
}

- (void)bind:(WSFormRow *)row {
    self.row = row;
    BOOL area = row.type == WSFormRowTextArea;
    self.field.hidden = area;
    self.textView.hidden = !area;
    self.field.placeholder = row.placeholder ?: row.title;
    self.field.text = row.value;
    self.field.keyboardType = row.keyboardType;
    self.field.accessibilityLabel = row.title;
    self.textView.text = row.value;
    self.textView.accessibilityLabel = row.title;
    self.placeholder.text = row.placeholder ?: row.title;
    self.placeholder.hidden = !area || [row.value length] > 0;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.row.value = textView.text;
    self.placeholder.hidden = textView.text.length > 0;
    if (self.changed) self.changed();
    // Grow with content.
    UITableView *table = (UITableView *)self.superview;
    while (table && ![table isKindOfClass:UITableView.class]) table = (UITableView *)table.superview;
    [UIView performWithoutAnimation:^{
        [table beginUpdates];
        [table endUpdates];
    }];
}

@end

/// Optional date: title, switch and an inline compact picker.
@interface WSFormDateCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *toggle;
@property (nonatomic, strong) UIDatePicker *picker;
@property (nonatomic, weak) WSFormRow *row;
@property (nonatomic, copy) void (^changed)(void);
- (void)bind:(WSFormRow *)row;
@end

@implementation WSFormDateCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        AppThemeManager *t = AppThemeManager.shared;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = t.surface;
        _titleLabel = UILabel.new;
        _titleLabel.font = t.fontBody;
        _titleLabel.textColor = t.textPrimary;
        _picker = UIDatePicker.new;
        _picker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        _picker.tintColor = t.accent;
        _picker.minuteInterval = 5;
        _toggle = UISwitch.new;
        _toggle.onTintColor = t.accent;

        __weak typeof(self) weakSelf = self;
        [_picker addAction:[UIAction actionWithHandler:^(UIAction *a) {
            weakSelf.row.value = weakSelf.picker.date;
            if (weakSelf.changed) weakSelf.changed();
        }] forControlEvents:UIControlEventValueChanged];
        [_toggle addAction:[UIAction actionWithHandler:^(UIAction *a) {
            if (weakSelf.toggle.on) {
                weakSelf.row.value = weakSelf.picker.date;
            } else {
                weakSelf.row.value = nil;
            }
            weakSelf.picker.hidden = !weakSelf.toggle.on;
            if (weakSelf.changed) weakSelf.changed();
        }] forControlEvents:UIControlEventValueChanged];

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, UIView.new, _picker, _toggle]];
        row.spacing = 8;
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:row];
        UILayoutGuide *m = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [row.leadingAnchor constraintEqualToAnchor:m.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:m.trailingAnchor],
            [row.topAnchor constraintEqualToAnchor:m.topAnchor],
            [row.bottomAnchor constraintEqualToAnchor:m.bottomAnchor],
            [row.heightAnchor constraintGreaterThanOrEqualToConstant:34],
        ]];
    }
    return self;
}

- (void)bind:(WSFormRow *)row {
    self.row = row;
    self.titleLabel.text = row.title;
    self.picker.datePickerMode = row.dateMode;
    NSDate *date = row.value;
    if (!date && row.dateRequired) { date = NSDate.date; row.value = date; }
    self.picker.date = date ?: [self defaultDate];
    self.toggle.hidden = row.dateRequired;
    self.toggle.on = date != nil;
    self.picker.hidden = !self.toggle.on && !row.dateRequired;
    self.toggle.accessibilityLabel = row.title;
}

/// Tomorrow 9:00 is the most common "set a date" intent.
- (NSDate *)defaultDate {
    NSCalendar *cal = NSCalendar.currentCalendar;
    NSDate *tomorrow = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:NSDate.date options:0];
    return [cal dateBySettingHour:9 minute:0 second:0 ofDate:tomorrow options:0];
}

@end

#pragma mark - List editor

/// Edits an ordered list of strings (checklist items / default tasks).
@interface WSFormListEditor : UITableViewController
@property (nonatomic, strong) NSMutableArray<NSString *> *items;
@property (nonatomic, copy) void (^onDone)(NSArray<NSString *> *items);
@end

@implementation WSFormListEditor

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"item"];
    self.tableView.editing = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self action:@selector(add)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.onDone) self.onDone(self.items);
}

- (void)add {
    [self ws_promptTitle:WSText(@"New Item") message:nil placeholder:WSText(@"Title") text:nil action:WSText(@"Add") handler:^(NSString *text) {
        [self.items addObject:text];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.items.count - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.items.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"item" forIndexPath:indexPath];
    UIListContentConfiguration *c = cell.defaultContentConfiguration;
    c.text = self.items[indexPath.row];
    c.textProperties.font = AppThemeManager.shared.fontBody;
    cell.contentConfiguration = c;
    cell.backgroundColor = AppThemeManager.shared.surface;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.items.count ? WSText(@"Tap an item to rename it. Drag to reorder.") : WSText(@"No items yet. Tap + to add one.");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self ws_promptTitle:WSText(@"Rename") message:nil placeholder:nil text:self.items[indexPath.row] action:WSText(@"Save") handler:^(NSString *text) {
        self.items[indexPath.row] = text;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete) return;
    [self.items removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    NSString *item = self.items[from.row];
    [self.items removeObjectAtIndex:from.row];
    [self.items insertObject:item atIndex:to.row];
}

@end

#pragma mark - Tag picker

/// Multi-select of existing tags plus "New Tag".
@interface WSFormTagPicker : UITableViewController
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *selected;
@property (nonatomic, copy) NSArray<NSString *> *allNames;
@property (nonatomic, copy) void (^onDone)(NSArray<NSString *> *names);
@end

@implementation WSFormTagPicker

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = AppThemeManager.shared.background;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"tag"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WSText(@"New Tag") style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(add)];
    NSMutableOrderedSet *names = [NSMutableOrderedSet orderedSetWithArray:[[TagManager.shared allTags] valueForKey:@"name"]];
    [names addObjectsFromArray:self.selected.array]; // tags typed earlier but not saved yet
    self.allNames = names.array;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.onDone) self.onDone(self.selected.array);
}

- (void)add {
    [self ws_promptTitle:WSText(@"New Tag") message:nil placeholder:WSText(@"Tag name") text:nil action:WSText(@"Add") handler:^(NSString *text) {
        NSString *existing = [self.allNames filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ==[c] %@", text]].firstObject;
        NSString *name = existing ?: text;
        if (!existing) self.allNames = [self.allNames arrayByAddingObject:name];
        [self.selected addObject:name];
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.allNames.count; }

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.allNames.count ? nil : WSText(@"No tags yet. Tap New Tag to create one.");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tag" forIndexPath:indexPath];
    NSString *name = self.allNames[indexPath.row];
    Tag *tag = [TagManager.shared tagNamed:name];
    UIListContentConfiguration *c = cell.defaultContentConfiguration;
    c.text = name;
    c.image = [UIImage ws_symbol:@"tag.fill"];
    c.imageProperties.tintColor = [AppThemeManager.shared colorForIdentifier:tag.colorIdentifier];
    cell.contentConfiguration = c;
    cell.backgroundColor = AppThemeManager.shared.surface;
    cell.accessoryType = [self.selected containsObject:name] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.tintColor = AppThemeManager.shared.accent;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *name = self.allNames[indexPath.row];
    if ([self.selected containsObject:name]) [self.selected removeObject:name];
    else [self.selected addObject:name];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end

#pragma mark - Form

@interface WSFormViewController ()
@property (nonatomic, copy) NSArray<WSFormSection *> *sections;
@property (nonatomic, readwrite) BOOL hasChanges;
@end

@implementation WSFormViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppThemeManager *t = AppThemeManager.shared;
    self.tableView.backgroundColor = t.background;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 52;
    [self.tableView registerClass:WSFormTextCell.class forCellReuseIdentifier:@"text"];
    [self.tableView registerClass:WSFormDateCell.class forCellReuseIdentifier:@"date"];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"value"];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self action:@selector(cancelTapped)];
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:self.saveTitle ?: WSText(@"Save") style:UIBarButtonItemStyleDone
                                                            target:self action:@selector(saveTapped)];
    self.navigationItem.rightBarButtonItem = save;
    self.sections = [self buildSections];
}

- (UINavigationController *)embeddedInNavigation {
    UINavigationController *nav = [[NSClassFromString(@"NavigationController") ?: UINavigationController.class alloc] initWithRootViewController:self];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.presentationController.delegate = (id<UIAdaptivePresentationControllerDelegate>)self;
    return nav;
}

- (NSArray<WSFormSection *> *)buildSections { return @[]; }
- (BOOL)save { return YES; }

- (void)reloadForm {
    self.sections = [self buildSections];
    [self.tableView reloadData];
}

- (WSFormRow *)rowForKey:(NSString *)key {
    for (WSFormSection *s in self.sections) for (WSFormRow *r in s.rows) if ([r.key isEqualToString:key]) return r;
    return nil;
}

- (id)formValueForKey:(NSString *)key { return [self rowForKey:key].value; }

- (NSString *)stringForKey:(NSString *)key {
    id v = [self rowForKey:key].value;
    return [v isKindOfClass:NSString.class] ? [v stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
}

- (void)setFormValue:(id)value forKey:(NSString *)key {
    WSFormRow *row = [self rowForKey:key];
    row.value = value;
    NSIndexPath *path = [self indexPathFor:row];
    if (path) [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSIndexPath *)indexPathFor:(WSFormRow *)row {
    for (NSUInteger s = 0; s < self.sections.count; s++) {
        NSUInteger r = [self.sections[s].rows indexOfObject:row];
        if (r != NSNotFound) return [NSIndexPath indexPathForRow:r inSection:s];
    }
    return nil;
}

- (void)rowChanged:(WSFormRow *)row {
    self.hasChanges = YES;
    self.modalInPresentation = YES; // swipe-down would lose edits; Cancel asks instead
    if (row.onChange) row.onChange(row);
}

#pragma mark - Actions

- (void)saveTapped {
    [self.view endEditing:YES];
    if (![self save]) return;
    if (self.onSaved) self.onSaved();
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelTapped {
    [self.view endEditing:YES];
    if (!self.hasChanges) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Discard Changes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Keep Editing") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    [self cancelTapped];
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return self.sections.count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.sections[section].rows.count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return self.sections[section].title; }
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section { return self.sections[section].footer; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WSFormRow *row = self.sections[indexPath.section].rows[indexPath.row];
    __weak typeof(self) weakSelf = self;
    switch (row.type) {
        case WSFormRowText:
        case WSFormRowTextArea: {
            WSFormTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"text" forIndexPath:indexPath];
            [cell bind:row];
            cell.changed = ^{ [weakSelf rowChanged:row]; };
            return cell;
        }
        case WSFormRowDate: {
            WSFormDateCell *cell = [tableView dequeueReusableCellWithIdentifier:@"date" forIndexPath:indexPath];
            [cell bind:row];
            cell.changed = ^{ [weakSelf rowChanged:row]; };
            return cell;
        }
        default:
            return [self valueCellFor:row at:indexPath];
    }
}

- (UITableViewCell *)valueCellFor:(WSFormRow *)row at:(NSIndexPath *)indexPath {
    AppThemeManager *t = AppThemeManager.shared;
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"value" forIndexPath:indexPath];
    cell.backgroundColor = t.surface;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    UIListContentConfiguration *c = [UIListContentConfiguration valueCellConfiguration];
    c.text = row.title;
    c.textProperties.font = t.fontBody;
    c.textProperties.color = row.destructive ? t.danger : (row.type == WSFormRowButton && !row.value ? t.accent : t.textPrimary);
    c.secondaryTextProperties.font = t.fontCallout;
    c.secondaryTextProperties.color = t.textSecondary;
    if (row.symbol) {
        c.image = [UIImage ws_symbol:row.symbol];
        c.imageProperties.tintColor = row.destructive ? t.danger : t.accent;
    }

    switch (row.type) {
        case WSFormRowChoice: {
            NSInteger i = [row.value integerValue];
            c.secondaryText = (i >= 0 && i < (NSInteger)row.options.count) ? row.options[i] : nil;
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage ws_symbol:@"chevron.up.chevron.down" pointSize:12 weight:UIImageSymbolWeightSemibold]];
            cell.accessoryView.tintColor = t.textTertiary;
            break;
        }
        case WSFormRowToggle: {
            UISwitch *toggle = UISwitch.new;
            toggle.onTintColor = t.accent;
            toggle.on = [row.value boolValue];
            __weak typeof(self) weakSelf = self;
            [toggle addAction:[UIAction actionWithHandler:^(UIAction *a) {
                row.value = @(toggle.on);
                [weakSelf rowChanged:row];
            }] forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
        case WSFormRowTags: {
            NSArray *tags = row.value;
            c.secondaryText = tags.count ? [tags componentsJoinedByString:@", "] : WSText(@"None");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case WSFormRowList: {
            NSArray *items = row.value;
            c.secondaryText = [NSString stringWithFormat:WSText(@"%lu items"), (unsigned long)items.count];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case WSFormRowColor: {
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
            dot.layer.cornerRadius = 11;
            dot.backgroundColor = [t colorForIdentifier:row.value];
            cell.accessoryView = dot;
            break;
        }
        case WSFormRowButton:
            c.secondaryText = row.value;
            cell.accessoryType = row.onTap && row.value ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            break;
        default:
            break;
    }
    cell.contentConfiguration = c;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WSFormRow *row = self.sections[indexPath.section].rows[indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    switch (row.type) {
        case WSFormRowChoice:  [self presentChoice:row from:cell]; break;
        case WSFormRowTags:    [self presentTags:row]; break;
        case WSFormRowList:    [self presentList:row]; break;
        case WSFormRowColor:   [self presentColor:row from:cell]; break;
        case WSFormRowButton:  if (row.onTap) row.onTap(row); break;
        case WSFormRowText:
        case WSFormRowTextArea: {
            WSFormTextCell *text = (WSFormTextCell *)cell;
            if (row.type == WSFormRowText) [text.field becomeFirstResponder]; else [text.textView becomeFirstResponder];
            break;
        }
        default: break;
    }
}

- (void)presentChoice:(WSFormRow *)row from:(UIView *)source {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:row.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [row.options enumerateObjectsUsingBlock:^(NSString *option, NSUInteger idx, BOOL *stop) {
        UIAlertAction *a = [UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            row.value = @(idx);
            [self rowChanged:row];
            NSIndexPath *p = [self indexPathFor:row];
            if (p) [self.tableView reloadRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationNone];
        }];
        if ((NSInteger)idx == [row.value integerValue]) [a setValue:@YES forKey:@"checked"];
        [sheet addAction:a];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = source;
    sheet.popoverPresentationController.sourceRect = source.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentColor:(WSFormRow *)row from:(UIView *)source {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:row.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *identifier in AppThemeManager.shared.paletteIdentifiers) {
        UIAlertAction *a = [UIAlertAction actionWithTitle:WSText(identifier.capitalizedString) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            row.value = identifier;
            [self rowChanged:row];
            NSIndexPath *p = [self indexPathFor:row];
            if (p) [self.tableView reloadRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationNone];
        }];
        UIImage *swatch = [[UIImage ws_symbol:@"circle.fill"] imageWithTintColor:[AppThemeManager.shared colorForIdentifier:identifier]
                                                                  renderingMode:UIImageRenderingModeAlwaysOriginal];
        [a setValue:swatch forKey:@"image"];
        [sheet addAction:a];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = source;
    sheet.popoverPresentationController.sourceRect = source.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)presentTags:(WSFormRow *)row {
    WSFormTagPicker *picker = [[WSFormTagPicker alloc] initWithStyle:UITableViewStyleInsetGrouped];
    picker.title = row.title;
    picker.selected = [NSMutableOrderedSet orderedSetWithArray:row.value ?: @[]];
    __weak typeof(self) weakSelf = self;
    picker.onDone = ^(NSArray<NSString *> *names) {
        if ([names isEqualToArray:row.value ?: @[]]) return;
        row.value = names;
        [weakSelf rowChanged:row];
        NSIndexPath *p = [weakSelf indexPathFor:row];
        if (p) [weakSelf.tableView reloadRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationNone];
    };
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)presentList:(WSFormRow *)row {
    WSFormListEditor *editor = [[WSFormListEditor alloc] initWithStyle:UITableViewStyleInsetGrouped];
    editor.title = row.title;
    editor.items = [NSMutableArray arrayWithArray:row.value ?: @[]];
    __weak typeof(self) weakSelf = self;
    editor.onDone = ^(NSArray<NSString *> *items) {
        if ([items isEqualToArray:row.value ?: @[]]) return;
        row.value = items;
        [weakSelf rowChanged:row];
        NSIndexPath *p = [weakSelf indexPathFor:row];
        if (p) [weakSelf.tableView reloadRowsAtIndexPaths:@[p] withRowAnimation:UITableViewRowAnimationNone];
    };
    [self.navigationController pushViewController:editor animated:YES];
}

@end
