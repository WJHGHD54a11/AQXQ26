//
//  NoteCell.h
//  WorkSpace
//

#import <UIKit/UIKit.h>

@class Note;

NS_ASSUME_NONNULL_BEGIN

@interface NoteCell : UICollectionViewListCell
- (void)configureWithNote:(Note *)note;
@end

NS_ASSUME_NONNULL_END
