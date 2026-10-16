//
//  NoteEditViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Note, NoteCategory, Project;

NS_ASSUME_NONNULL_BEGIN

/// Full-screen writing view: title, body, category menu, tags. Autosaves on leave.
@interface NoteEditViewController : UIViewController
- (instancetype)initWithNote:(nullable Note *)note category:(nullable NoteCategory *)category project:(nullable Project *)project;
@property (nonatomic, copy, nullable) void (^onSaved)(Note *note);
@end

NS_ASSUME_NONNULL_END
