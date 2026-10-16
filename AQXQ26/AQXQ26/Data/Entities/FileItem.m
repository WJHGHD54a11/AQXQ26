//
//  FileItem.m
//  WorkSpace
//

#import "FileItem.h"
#import "Project.h"
#import "Task.h"

@implementation FileItem

+ (NSFetchRequest<FileItem *> *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"FileItem"];
}

@dynamic uuid, name, fileExtension, typeIdentifier, storedName, folder, byteSize, isFavorite, createdAt, modifiedAt, lastOpenedAt, project, task;

@end
