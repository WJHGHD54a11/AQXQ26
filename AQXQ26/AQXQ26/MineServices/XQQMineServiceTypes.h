//
//  XQQMineServiceTypes.h
//  AQXQ26
//
//  「我的」模块迁移用：原工程里散落在 XQQChatClient 中、页面直接用到的枚举和通知名。
//  数值与原 SDK 保持一致，后续接入 SDK 时删除本文件对应部分即可。
//

#import <Foundation/Foundation.h>

#ifndef XQQ_MINE_SDK_TYPES_DEFINED
#define XQQ_MINE_SDK_TYPES_DEFINED

typedef NS_ENUM(NSInteger, ModifyMyInfoType) {
    Modify_DisplayName = 0,
    Modify_Portrait = 1,
    Modify_Gender = 2,
    Modify_Mobile = 3,
    Modify_Email = 4,
    Modify_Address = 5,
    Modify_Company = 6,
    Modify_Social = 7,
    Modify_Extra = 8,
    Modify_FriendAlias = 9,
    Modify_Sign = 10
};

typedef NS_ENUM(NSInteger, ModifyGroupInfoType) {
    Modify_Group_Name = 0,
    Modify_Group_Portrait = 1,
    Modify_Group_Extra = 2,
    Modify_Group_Mute = 3,
    Modify_Group_JoinType = 4,
    Modify_Group_PrivateChat = 5,
    Modify_Group_Searchable = 6,
    Modify_Group_History_Message = 7,
    Modify_Group_Max_Member_Count = 8
};

typedef NS_ENUM(NSInteger, WFCCMediaType) {
    Media_Type_GENERAL = 0,
    Media_Type_IMAGE = 1,
    Media_Type_VOICE = 2,
    Media_Type_VIDEO = 3,
    Media_Type_FILE = 4,
    Media_Type_PORTRAIT = 5,
    Media_Type_FAVORITE = 6,
    Media_Type_STICKER = 7,
    Media_Type_MOMENTS = 8
};

typedef NS_ENUM(NSInteger, WFCCConversationType) {
    Single_Type,
    Group_Type,
    Chatroom_Type,
    Channel_Type,
    Things_Type,
    SecretChat_Type,
};

// 原 XQQChatUIKit/Enum/XQQHIOWIVEnum.h（ObjectModel.h 用到）
typedef NS_ENUM(NSInteger, WFCUGroupMemberSourceType) {
    GroupMemberSource_Unknown = 0,
    GroupMemberSource_Search,
    GroupMemberSource_Invite,
    GroupMemberSource_QrCode,
    GroupMemberSource_Card,
};

// 原 XQQNetworkService.h
#ifndef Platform_iOS
#define Platform_iOS 2
#endif

// 原 XQQChatUIKit/Predefine.h
#ifndef RGBCOLOR
#define RGBCOLOR(r, g, b) [UIColor colorWithRed:(r) / 255.0f green:(g) / 255.0f blue:(b) / 255.0f alpha:1]
#endif

/// 与原 XQQNetworkService 同名同值，页面靠这两个通知刷新
FOUNDATION_EXPORT NSString *kUserInfoUpdated;
FOUNDATION_EXPORT NSString *kGroupInfoUpdated;
FOUNDATION_EXPORT NSString *kFriendListUpdated;

#endif
