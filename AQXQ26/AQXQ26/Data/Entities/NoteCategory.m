//
//  NoteCategory.m
//  WorkSpace
//

#import "NoteCategory.h"
#import "Note.h"

@implementation NoteCategory

+ (NSFetchRequest<NoteCategory *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"NoteCategory"];
}

@dynamic uuid, name, colorIdentifier, sortIndex, createdAt, notes;

@end
