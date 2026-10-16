//
//  AppConstants.h
//  WorkSpace
//
//  Shared enums, notification names and display-name helpers.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Localized string from WorkSpace.strings. Follows the in-app language choice shared with
/// the Me module ("CurrentLanguage": 0 system, 1 简体中文, 2 English).
FOUNDATION_EXPORT NSString *WSLocalized(NSString *key);
#define WSText(key) WSLocalized(key)

#pragma mark - Object kinds

typedef NS_ENUM(NSInteger, WSObjectKind) {
    WSObjectKindTask = 0,
    WSObjectKindProject,
    WSObjectKindNote,
    WSObjectKindFile,
    WSObjectKindSchedule,
    WSObjectKindTemplate,
    WSObjectKindTag,
    WSObjectKindNoteCategory,
    WSObjectKindActivity,
};

FOUNDATION_EXPORT NSString *WSObjectKindTitle(WSObjectKind kind);       // "Task", "Project"...
FOUNDATION_EXPORT NSString *WSObjectKindPluralTitle(WSObjectKind kind); // "Tasks", "Projects"...
FOUNDATION_EXPORT NSString *WSObjectKindSymbol(WSObjectKind kind);      // SF Symbol name
FOUNDATION_EXPORT NSString *WSObjectKindEntityName(WSObjectKind kind);  // Core Data entity name

#pragma mark - Tasks

typedef NS_ENUM(int16_t, TaskStatus) {
    TaskStatusToDo = 0,
    TaskStatusInProgress = 1,
    TaskStatusCompleted = 2,
    TaskStatusCancelled = 3,
};

typedef NS_ENUM(int16_t, TaskPriority) {
    TaskPriorityLow = 0,
    TaskPriorityMedium = 1,
    TaskPriorityHigh = 2,
    TaskPriorityUrgent = 3,
};

/// Shared by Task and Schedule
typedef NS_ENUM(int16_t, RepeatRule) {
    RepeatRuleNone = 0,
    RepeatRuleDaily,
    RepeatRuleWeekdays,
    RepeatRuleWeekly,
    RepeatRuleMonthly,
    RepeatRuleYearly,
};

FOUNDATION_EXPORT NSString *TaskStatusTitle(TaskStatus status);
FOUNDATION_EXPORT NSString *TaskPriorityTitle(TaskPriority priority);
FOUNDATION_EXPORT NSString *RepeatRuleTitle(RepeatRule rule);
FOUNDATION_EXPORT NSArray<NSString *> *TaskStatusTitles(void);
FOUNDATION_EXPORT NSArray<NSString *> *TaskPriorityTitles(void);
FOUNDATION_EXPORT NSArray<NSString *> *RepeatRuleTitles(void);
/// Next occurrence of `date` for a repeat rule; nil for RepeatRuleNone.
FOUNDATION_EXPORT NSDate * _Nullable RepeatRuleNextDate(RepeatRule rule, NSDate *date);

#pragma mark - Projects

typedef NS_ENUM(int16_t, ProjectStatus) {
    ProjectStatusPlanning = 0,
    ProjectStatusActive,
    ProjectStatusPaused,
    ProjectStatusCompleted,
    ProjectStatusArchived,
};

FOUNDATION_EXPORT NSString *ProjectStatusTitle(ProjectStatus status);
FOUNDATION_EXPORT NSArray<NSString *> *ProjectStatusTitles(void);

#pragma mark - Schedule

typedef NS_ENUM(int16_t, ScheduleKind) {
    ScheduleKindAppointment = 0,
    ScheduleKindMeeting,
    ScheduleKindEvent,
    ScheduleKindPersonal,
    ScheduleKindReminder,
};

typedef NS_ENUM(int16_t, ScheduleStatus) {
    ScheduleStatusPlanned = 0,
    ScheduleStatusCompleted,
    ScheduleStatusCancelled,
};

FOUNDATION_EXPORT NSString *ScheduleKindTitle(ScheduleKind kind);
FOUNDATION_EXPORT NSString *ScheduleKindSymbol(ScheduleKind kind);
FOUNDATION_EXPORT NSString *ScheduleStatusTitle(ScheduleStatus status);
FOUNDATION_EXPORT NSArray<NSString *> *ScheduleKindTitles(void);

/// Reminder offsets (minutes before start). -1 = no reminder.
FOUNDATION_EXPORT NSArray<NSNumber *> *ScheduleReminderOffsets(void);
FOUNDATION_EXPORT NSString *ScheduleReminderOffsetTitle(int32_t minutes);

#pragma mark - Templates

typedef NS_ENUM(int16_t, TemplateKind) {
    TemplateKindTask = 0,
    TemplateKindProject,
    TemplateKindChecklist,
};

FOUNDATION_EXPORT NSString *TemplateKindTitle(TemplateKind kind);
FOUNDATION_EXPORT NSArray<NSString *> *TemplateKindTitles(void);

#pragma mark - Change notification

/// Posted on the main queue after any save that changed user data.
/// userInfo[WSChangedKindsKey] = NSSet<NSNumber *> of WSObjectKind.
FOUNDATION_EXPORT NSNotificationName const WSDataDidChangeNotification;
FOUNDATION_EXPORT NSString * const WSChangedKindsKey;

#pragma mark - Activity types

FOUNDATION_EXPORT NSString * const ActivityTypeTaskCreated;
FOUNDATION_EXPORT NSString * const ActivityTypeTaskUpdated;
FOUNDATION_EXPORT NSString * const ActivityTypeTaskCompleted;
FOUNDATION_EXPORT NSString * const ActivityTypeTaskDeleted;
FOUNDATION_EXPORT NSString * const ActivityTypeProjectCreated;
FOUNDATION_EXPORT NSString * const ActivityTypeProjectUpdated;
FOUNDATION_EXPORT NSString * const ActivityTypeProjectCompleted;
FOUNDATION_EXPORT NSString * const ActivityTypeProjectDeleted;
FOUNDATION_EXPORT NSString * const ActivityTypeNoteCreated;
FOUNDATION_EXPORT NSString * const ActivityTypeNoteEdited;
FOUNDATION_EXPORT NSString * const ActivityTypeNoteDeleted;
FOUNDATION_EXPORT NSString * const ActivityTypeFileImported;
FOUNDATION_EXPORT NSString * const ActivityTypeFileDeleted;
FOUNDATION_EXPORT NSString * const ActivityTypeScheduleCreated;
FOUNDATION_EXPORT NSString * const ActivityTypeScheduleUpdated;
FOUNDATION_EXPORT NSString * const ActivityTypeScheduleCompleted;
FOUNDATION_EXPORT NSString * const ActivityTypeScheduleDeleted;
FOUNDATION_EXPORT NSString * const ActivityTypeTemplateCreated;
FOUNDATION_EXPORT NSString * const ActivityTypeTemplateUsed;
FOUNDATION_EXPORT NSString * const ActivityTypeDataImported;

/// Human readable label ("Task completed") and filter group for an activity type.
FOUNDATION_EXPORT NSString *ActivityTypeTitle(NSString *type);
FOUNDATION_EXPORT WSObjectKind ActivityTypeObjectKind(NSString *type);

NS_ASSUME_NONNULL_END
