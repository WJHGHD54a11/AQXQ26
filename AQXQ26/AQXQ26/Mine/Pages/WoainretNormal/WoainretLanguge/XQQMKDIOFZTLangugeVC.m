//
//  XQQMKDIOFZTLangugeVC.m
//  WUHOIBDK
//
//  Created by Loooooo on 3/4/24.
//

#import "XQQMKDIOFZTLangugeVC.h"

@interface XQQMKDIOFZTLangugeVC ()
{
    NSInteger _language;
}
@property (weak, nonatomic) IBOutlet UILabel *systemLanguageLabel;

@property (weak, nonatomic) IBOutlet UIImageView *langugeAView;
@property (weak, nonatomic) IBOutlet UIImageView *langugeBView;
@property (weak, nonatomic) IBOutlet UIImageView *langugeCView;

@end

@implementation XQQMKDIOFZTLangugeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _language = LANGUAGE;
    
    [self btnStatus];
}

- (IBAction)status:(UIButton *)sender {
    if (sender.tag == _language) {
        return;
    }
    _language = sender.tag;
    [NSUserDefaults.standardUserDefaults setInteger:_language forKey:@"CurrentLanguage"];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self btnStatus];
    [NSNotificationCenter.defaultCenter postNotificationName:kLanguageNoti object:nil];
}

- (void)btnStatus {
    _langugeAView.hidden = !(_language == 0);
    _langugeBView.hidden = !(_language == 1);
    _langugeCView.hidden = !(_language == 2);
    self.navigationItem.title = LLLLLL(@"Language");
    _systemLanguageLabel.text = LLLLLL(@"FollowingSystemLanguage");
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
