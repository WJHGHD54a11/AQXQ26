//
//  Activity.m
//  WorkSpace
//

#import "Activity.h"


@implementation Activity

+ (NSFetchRequest<Activity *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"Activity"];
}

@dynamic uuid, type, title, detail, objectId, objectKind, createdAt;

@end
