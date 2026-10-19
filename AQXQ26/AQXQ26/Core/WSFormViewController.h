//
//  WSFormViewController.h
//  WorkSpace
//
//  Base for every edit screen. Subclasses describe rows declaratively in
//  -buildSections and read values back in -save. Keeps form code small and
//  consistent across Task / Project / Note / Schedule / Template editors.
//

#import <UIKit/UIKit.h>
#import "WSUIKit.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WSFormRowType) {
    WSFormRowText,        // single-line field
    WSFormRowTextArea,    // multi-line field
    WSFormRowChoice,      // one of `options`, shown as a menu
    WSFormRowDate,        // optional date (switch + inline picker)
    WSFormRowToggle,
    WSFormRowTags,        // comma separated tag names with suggestions
    WSFormRowList,        // editable list of strings (checklist / default tasks)
    WSFormRowColor,       // palette identifier
    WSFormRowButton,      // tappable row (navigation / action)
};

@interface WSFormRow : NSObject
@property (nonatomic) WSFormRowType type;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, copy, nullable) NSString *symbol;
/// Text: NSString. Choice: NSNumber index. Date: NSDate or nil. Toggle: NSNumber BOOL.
/// Tags / List: NSArray<NSString *>. Color: NSString. Button: subtitle NSString.
@property (nonatomic, strong, nullable) id value;
@property (nonatomic, copy, nullable) NSArray<NSString *> *options;
@property (nonatomic) UIDatePickerMode dateMode;
@property (nonatomic) BOOL dateRequired;               // hides the on/off switch
@property (nonatomic, copy, nullable) void (^onTap)(WSFormRow *row);
@property (nonatomic, copy, nullable) void (^onChange)(WSFormRow *row);
@property (nonatomic) BOOL destructive;
/// Keyboard for WSFormRowText (default UIKeyboardTypeDefault).
@property (nonatomic) UIKeyboardType keyboardType;

+ (instancetype)type:(WSFormRowType)type key:(NSString *)key title:(NSString *)title value:(nullable id)value;
@end

@interface WSFormSection : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *footer;
@property (nonatomic, copy) NSArray<WSFormRow *> *rows;
+ (instancetype)title:(nullable NSString *)title rows:(NSArray<WSFormRow *> *)rows;
@end

@interface WSFormViewController : UITableViewController

/// Override. Called once in viewDidLoad and again on -reloadForm.
- (NSArray<WSFormSection *> *)buildSections;
/// Override. Return NO (after showing an error) to keep the form open.
- (BOOL)save;

- (void)reloadForm;
- (nullable WSFormRow *)rowForKey:(NSString *)key;
- (nullable id)formValueForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (void)setFormValue:(nullable id)value forKey:(NSString *)key;

/// Presented modally inside a navigation controller with Cancel / Save.
- (UINavigationController *)embeddedInNavigation;
@property (nonatomic, copy, nullable) NSString *saveTitle;
/// Called after a successful save, before dismissal.
@property (nonatomic, copy, nullable) void (^onSaved)(void);
/// When YES, Cancel asks before discarding edits.
@property (nonatomic, readonly) BOOL hasChanges;

@end

NS_ASSUME_NONNULL_END
