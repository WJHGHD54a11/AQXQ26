//
//  FileItem.h
//  WorkSpace
//
//  Core Data entity. Domain helpers live in FileItem+Logic (when present).
//

#import <CoreData/CoreData.h>
#import "AppConstants.h"

@class Project, Task;

NS_ASSUME_NONNULL_BEGIN

@interface FileItem : NSManagedObject

+ (NSFetchRequest<FileItem *> *)fetchRequest;

@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *fileExtension;
@property (nonatomic, nullable, copy) NSString *typeIdentifier;
@property (nonatomic, copy) NSString *storedName;
@property (nonatomic, nullable, copy) NSString *folder;
@property (nonatomic, assign) int64_t byteSize;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *modifiedAt;
@property (nonatomic, nullable, strong) NSDate *lastOpenedAt;

@property (nonatomic, nullable, strong) Project *project;
@property (nonatomic, nullable, strong) Task *task;

@end

NS_ASSUME_NONNULL_END
