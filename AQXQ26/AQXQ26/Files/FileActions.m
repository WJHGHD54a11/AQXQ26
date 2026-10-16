//
//  FileActions.m
//  WorkSpace
//

#import "FileActions.h"
#import "FileManagerService.h"
#import "FilePreviewViewController.h"
#import "FavoriteManager.h"
#import "WSUIKit.h"
#import "FileItem.h"

@implementation FileActions

+ (void)rename:(FileItem *)file from:(UIViewController *)vc {
    [vc ws_promptTitle:WSText(@"Rename File") message:nil placeholder:WSText(@"File name") text:file.name action:WSText(@"Rename") handler:^(NSString *text) {
        NSError *error = nil;
        if (![FileManagerService.shared rename:file to:text error:&error]) [vc ws_showError:error];
    }];
}

+ (void)move:(FileItem *)file from:(UIViewController *)vc {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:WSText(@"Move to Folder")
                                                                   message:file.folder.length ? [NSString stringWithFormat:WSText(@"Currently in %@"), file.folder] : nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    void (^moveTo)(NSString *) = ^(NSString *folder) {
        NSError *error = nil;
        if (![FileManagerService.shared move:file toFolder:folder error:&error]) [vc ws_showError:error];
        else [vc ws_toast:folder.length ? [NSString stringWithFormat:WSText(@"Moved to %@"), folder] : WSText(@"Moved to All Files")];
    };
    if (file.folder.length) {
        [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"No Folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { moveTo(nil); }]];
    }
    for (NSString *folder in [FileManagerService.shared folders]) {
        if ([folder isEqualToString:file.folder]) continue;
        [sheet addAction:[UIAlertAction actionWithTitle:folder style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { moveTo(folder); }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"New Folder…") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [vc ws_promptTitle:WSText(@"New Folder") message:nil placeholder:WSText(@"Folder name") text:nil action:WSText(@"Move") handler:^(NSString *text) {
            moveTo(text);
        }];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:WSText(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = vc.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(vc.view.bounds), CGRectGetMidY(vc.view.bounds), 1, 1);
    [vc presentViewController:sheet animated:YES completion:nil];
}

+ (BOOL)ensureExists:(FileItem *)file from:(UIViewController *)vc {
    if ([FileManagerService.shared fileExists:file]) return YES;
    [vc ws_showMessage:WSText(@"The file is missing from this device. You can delete this entry and import the file again.")
                 title:WSText(@"File Not Found")];
    return NO;
}

+ (void)share:(FileItem *)file from:(UIViewController *)vc source:(id)source {
    if (![self ensureExists:file from:vc]) return;
    // Share a copy with the real name so the receiver doesn't see the internal UUID name.
    NSURL *stored = [FileManagerService.shared urlFor:file];
    NSURL *tempDir = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:tempDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *name = file.name.length ? file.name : stored.lastPathComponent;
    if (file.fileExtension.length && ![name.pathExtension.lowercaseString isEqualToString:file.fileExtension.lowercaseString]) {
        name = [name stringByAppendingPathExtension:file.fileExtension];
    }
    NSURL *named = [tempDir URLByAppendingPathComponent:name];
    BOOL copied = [NSFileManager.defaultManager copyItemAtURL:stored toURL:named error:nil];
    [vc ws_share:@[copied ? named : stored] from:source];
}

+ (void)preview:(FileItem *)file among:(NSArray<FileItem *> *)files from:(UIViewController *)vc {
    if (![self ensureExists:file from:vc]) return;
    if (![FilePreviewViewController canPreview:file]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WSText(@"Preview Not Available")
                                                                       message:WSText(@"This file type can't be previewed here. You can open it in another app with Share.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:WSText(@"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self share:file from:vc source:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WSText(@"OK") style:UIAlertActionStyleCancel handler:nil]];
        [vc presentViewController:alert animated:YES completion:nil];
        return;
    }
    NSArray *list = files.count ? files : @[file];
    NSUInteger index = [list indexOfObject:file];
    FilePreviewViewController *preview = [[FilePreviewViewController alloc] initWithFiles:list index:index == NSNotFound ? 0 : index];
    [vc presentViewController:preview animated:YES completion:nil];
}

+ (void)confirmDelete:(FileItem *)file from:(UIViewController *)vc completion:(void (^)(void))completion {
    [vc ws_confirm:[NSString stringWithFormat:WSText(@"Delete “%@”?"), file.name]
           message:WSText(@"The file will be removed from WorkSpace and this device.")
       destructive:WSText(@"Delete") handler:^{
        NSError *error = nil;
        if ([FileManagerService.shared deleteFile:file error:&error]) {
            if (completion) completion();
        } else {
            [vc ws_showError:error];
        }
    }];
}

+ (void)toggleFavorite:(FileItem *)file from:(UIViewController *)vc {
    NSError *error = nil;
    if (![FavoriteManager.shared toggleFavorite:file error:&error]) [vc ws_showError:error];
}

+ (UIMenu *)menuFor:(FileItem *)file among:(NSArray<FileItem *> *)files from:(UIViewController *)vc {
    __weak UIViewController *weakVC = vc;
    UIAction *preview = [UIAction actionWithTitle:WSText(@"Preview") image:[UIImage ws_symbol:@"eye"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self preview:file among:files from:weakVC];
    }];
    UIAction *share = [UIAction actionWithTitle:WSText(@"Share") image:[UIImage ws_symbol:@"square.and.arrow.up"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self share:file from:weakVC source:nil];
    }];
    UIAction *fav = [UIAction actionWithTitle:file.isFavorite ? WSText(@"Remove from Favorites") : WSText(@"Add to Favorites")
                                        image:[UIImage ws_symbol:file.isFavorite ? @"star.slash" : @"star"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self toggleFavorite:file from:weakVC];
    }];
    UIAction *rename = [UIAction actionWithTitle:WSText(@"Rename") image:[UIImage ws_symbol:@"pencil"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self rename:file from:weakVC];
    }];
    UIAction *move = [UIAction actionWithTitle:WSText(@"Move to Folder") image:[UIImage ws_symbol:@"folder"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self move:file from:weakVC];
    }];
    UIAction *del = [UIAction actionWithTitle:WSText(@"Delete") image:[UIImage ws_symbol:@"trash"] identifier:nil handler:^(UIAction *a) {
        if (weakVC) [self confirmDelete:file from:weakVC completion:nil];
    }];
    del.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithChildren:@[[UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[preview, share, fav]],
                                      [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[rename, move]], del]];
}

@end
