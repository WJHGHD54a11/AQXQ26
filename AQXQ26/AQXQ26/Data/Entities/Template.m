//
//  Template.m
//  WorkSpace
//

#import "Template.h"


@implementation Template

+ (NSFetchRequest<Template *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Template"];
}

@dynamic uuid, name, detail, kind, payload, useCount, isFavorite, createdAt, updatedAt;

@end
