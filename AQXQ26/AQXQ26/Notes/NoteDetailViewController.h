//
//  NoteDetailViewController.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Note;

NS_ASSUME_NONNULL_BEGIN

/// Read view with metadata, pin / favorite / share / edit / delete.
@interface NoteDetailViewController : UIViewController
- (instancetype)initWithNote:(Note *)note;
@end

NS_ASSUME_NONNULL_END
