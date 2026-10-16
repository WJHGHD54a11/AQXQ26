//
//  XQQBUOIWNDefine.h
//  QXQ
//
//  Created by Loooooo on 9/28/23.
//

#ifndef XQQBUOIWNDefine_h
#define XQQBUOIWNDefine_h


#define ShareAppDelegate  ([UIApplication sharedApplication].delegate)

#define kCurrentVersion     @"CurrentVersion"
#define BundleVersion [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentVersion]
//获取当前版本号
#define BUNDLE_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]

//#define TabBarHeight (IS_IPAD ? (IS_NOTCHED_SCREEN ? 65 : (IOS_VERSION >= 12.0 ? 50 : 49)) : (IS_LANDSCAPE ? PreferredValueForVisualDevice(49, 32) : 49) + SafeAreaInsetsConstantForDeviceWithNotch.bottom)
#define TabBarHeight ([UIApplication.sharedApplication statusBarFrame].size.height)

// 弱引用self
#define WS(weakself)  __weak __typeof(&*self) weakself = self;

#define HEIGHT [[UIScreen mainScreen] bounds].size.height
#define WIDTH [[UIScreen mainScreen] bounds].size.width
#define NavigationHeight (HEIGHT >= 812.0 ? 88.0 : 64.0)
#define WIDTH_SCALE(width)  (width/375.0*WIDTH)

#define RGBA(RGB)  [UIColor colorWithRed:((CGFloat)((RGB & 0xFF0000)>>16))/255.0 green:((CGFloat)((RGB & 0xFF00)>>8))/255.0 blue:((CGFloat)(RGB & 0xFF))/255.0 alpha:1]

//#define MAINCOLOR  RGBA(0x82DF67)
#define MAINCOLOR  RGBA(0x5CE253)


#define   ISLOGIN     [[NSUserDefaults standardUserDefaults] boolForKey:@"IS_LOGIN"]
#define   ISREVIEW     [[NSUserDefaults standardUserDefaults] boolForKey:kAppStatus]


#define kPageSize  10

#define IMAGENAME(x) [UIImage imageNamed:x]
#define URL(url) [NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]

#define UNString(x, y) [NSString stringWithFormat:x, y]

#define PINGFANG_M(s)    [UIFont fontWithName:@"PingFangSC-Medium" size:s];
#define PINGFANG_R(s)    [UIFont fontWithName:@"PingFangSC-Regular" size:s];


#define ViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]];

#define ViewRadius(View, Radius)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];

#define ShadowView(View, Radius, ShadowColor)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:NO];\
[View.layer setShadowColor:[ShadowColor CGColor]];\
[View.layer setShadowOpacity:0.3];\
[View.layer setShadowRadius:2.0];\
[View.layer setShadowOffset:CGSizeMake(1.0, 1.0)];


// 防止多次调用
#define kPreventRepeatClickTime(_seconds_) \
static BOOL shouldPrevent; \
if (shouldPrevent) return; \
shouldPrevent = YES; \
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_seconds_) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ \
shouldPrevent = NO; \
});\

// 群管理 - 阅后即焚 - 消息销毁时间 单位秒
#define     BURN_TIMES      @[@5, @10, @30, @60, @(60*60), @(6*60*60), @(12*60*60), @(24*3600), @(3*24*3600), @(7*24*3600)]
// 安全锁 - 自动锁定时间  单位分钟
#define     LOCK_TIMES      @[@1, @5, @10, @(15), @(60), @(5*60), @(12*60)]


// 0 跟随系统   1 中文   2 英文
#define   LANGUAGE     [NSUserDefaults.standardUserDefaults integerForKey:@"CurrentLanguage"]
#define   kLanguageNoti     @"kLanguageNotification"
// 0304新增
#define LLLLLL(key)   ((LANGUAGE == 0) ? NSLocalizedStringFromTable(key, @"InfoPlist", nil) : [[NSBundle bundleWithPath:[NSBundle.mainBundle pathForResource:(LANGUAGE==1?@"zh-Hans":@"en") ofType:@"lproj"]] localizedStringForKey:key value:nil table:@"InfoPlist"])


// 0815 外观 新增
// 对话气泡颜色
#define BubbleColors @[RGBA(0xFAB1B1), RGBA(0xFDDCAC), RGBA(0xF1EA78), RGBA(0x9AF294), RGBA(0xACD2FD), RGBA(0x95A0F5), RGBA(0xC595E6)]
// 聊天背景图片背景颜色
#define ChatBgImgColors @[RGBA(0xD5F5E1), RGBA(0xD5EFFE), RGBA(0xE0D7F3), RGBA(0xF4CECE)]



#define VersionNUM  @"1.0.59"

#endif /* XQQBUOIWNDefine_h */
