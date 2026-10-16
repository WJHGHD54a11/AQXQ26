//
//  XQQMKDIOFZTUserInfoBirthdayView.m
//  WildFireChat
//
//  Created by wtb on 2025/3/30.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "XQQMKDIOFZTUserInfoBirthdayView.h"
#import <objc/runtime.h> // 新增：检查记录挂在关联对象上

@interface XQQMKDIOFZTUserInfoBirthdayView()<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIView *pickerContainerView;
@property (nonatomic, strong) UIPickerView *datePicker;
@property (nonatomic, strong) NSArray *years;
@property (nonatomic, strong) NSArray *months;
@property (nonatomic, strong) NSArray *days;
@property (nonatomic, assign) NSInteger selectedYear;
@property (nonatomic, assign) NSInteger selectedMonth;
@property (nonatomic, assign) NSInteger selectedDay;
@property (nonatomic, assign) NSInteger startYear;
@end

// 新增：生日选择的检查记录，只读取状态、不修改选中值和回调，实现在文件尾部
@interface XQQMKDIOFZTUserInfoBirthdayView (XQQSelectionCheck)
- (void)xqq_recordShow;       // 新增
- (void)xqq_checkBeforeConfirm; // 新增
@end


@implementation XQQMKDIOFZTUserInfoBirthdayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.startYear = 1900;
        [self setupDateData];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithHexString:@"#000000" alpha:0.5];
    [self showDatePicker];
}


// 初始化年、月、日数据
- (void)setupDateData {
    NSMutableArray *yearsArray = [NSMutableArray array];
    for (NSInteger year = 1900; year <= 2100; year++) {
        [yearsArray addObject:[NSString stringWithFormat:@"%ld%@", year,LLLLLL(@"Year")]];
    }
    self.years = yearsArray;
    self.months = @[LLLLLL(@"Jan"),
                    LLLLLL(@"Feb"),
                    LLLLLL(@"Mar"),
                    LLLLLL(@"Apr"),
                    LLLLLL(@"May"),
                    LLLLLL(@"Jun"),
                    LLLLLL(@"Jul"),
                    LLLLLL(@"Aug"),
                    LLLLLL(@"Sept"),
                    LLLLLL(@"Oct"),
                    LLLLLL(@"Nov"),
                    LLLLLL(@"Dec")];
    
    [self updateDaysForYear:2025 month:3];
}

// 根据年份和月份更新日期数组
- (void)updateDaysForYear:(NSInteger)year month:(NSInteger)month {
    NSInteger daysInMonth = [self daysInMonth:month year:year];
    NSMutableArray *daysArray = [NSMutableArray array];
    for (NSInteger day = 1; day <= daysInMonth; day++) {
        [daysArray addObject:[NSString stringWithFormat:@"%ld%@", day,LLLLLL(@"Day")]];
    }
    self.days = daysArray;
}

// 计算某年某月有多少天
- (NSInteger)daysInMonth:(NSInteger)month year:(NSInteger)year {
    if (month == 2) {
        return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    return (month == 4 || month == 6 || month == 9 || month == 11) ? 30 : 31;
}

- (void)show {
    id<UIApplicationDelegate> dele = [UIApplication sharedApplication].delegate;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [dele.window addSubview:self];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:dele.window.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:dele.window.trailingAnchor],
        [self.bottomAnchor constraintEqualToAnchor:dele.window.bottomAnchor],
        [self.topAnchor constraintEqualToAnchor:dele.window.topAnchor]
    ]];
    [self xqq_recordShow]; // 新增
}

// 显示时间选择器
- (void)showDatePicker {
    if (!self.pickerContainerView) {
        self.pickerContainerView = [[UIView alloc] init];
        self.pickerContainerView.backgroundColor = [UIColor whiteColor];
        _pickerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        _pickerContainerView.layer.cornerRadius = 20;
        [self addSubview:self.pickerContainerView];
        [NSLayoutConstraint activateConstraints:@[
            [_pickerContainerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_pickerContainerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_pickerContainerView.heightAnchor constraintEqualToConstant:290],
            [_pickerContainerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];
        
        // 添加"取消"按钮
        UIButton *cancelButton = [[UIButton alloc] init];
        cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        [cancelButton setTitle:LLLLLL(@"Cancel") forState:UIControlStateNormal];
        [cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(hideDatePicker) forControlEvents:UIControlEventTouchUpInside];
        [self.pickerContainerView addSubview:cancelButton];
        [NSLayoutConstraint activateConstraints:@[
            [cancelButton.leadingAnchor constraintEqualToAnchor:self.pickerContainerView.leadingAnchor constant:5],
            [cancelButton.widthAnchor constraintEqualToConstant:50],
            [cancelButton.heightAnchor constraintEqualToConstant:30],
            [cancelButton.topAnchor constraintEqualToAnchor:self.pickerContainerView.topAnchor constant:5]
        ]];

        // 添加"确定"按钮
        UIButton *confirmButton = [[UIButton alloc] init];
        confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
        [confirmButton setTitle:LLLLLL(@"AlertButton") forState:UIControlStateNormal];
        [confirmButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        [confirmButton addTarget:self action:@selector(confirmDateSelection) forControlEvents:UIControlEventTouchUpInside];
        [self.pickerContainerView addSubview:confirmButton];
        [NSLayoutConstraint activateConstraints:@[
            [confirmButton.trailingAnchor constraintEqualToAnchor:self.pickerContainerView.trailingAnchor constant:-5],
            [confirmButton.widthAnchor constraintEqualToConstant:50],
            [confirmButton.heightAnchor constraintEqualToConstant:30],
            [confirmButton.topAnchor constraintEqualToAnchor:self.pickerContainerView.topAnchor constant:5]
        ]];


        // 添加 UIPickerView
        self.datePicker = [[UIPickerView alloc] init];
        _datePicker.translatesAutoresizingMaskIntoConstraints = NO;
        self.datePicker.delegate = self;
        self.datePicker.dataSource = self;
        [self.pickerContainerView addSubview:self.datePicker];
        [NSLayoutConstraint activateConstraints:@[
            [self.datePicker.trailingAnchor constraintEqualToAnchor:self.pickerContainerView.trailingAnchor],
            [self.datePicker.leadingAnchor constraintEqualToAnchor:self.pickerContainerView.leadingAnchor],
            [self.datePicker.heightAnchor constraintEqualToConstant:200],
            [self.datePicker.topAnchor constraintEqualToAnchor:self.pickerContainerView.topAnchor constant:50]
        ]];

        // 选中默认值
        self.selectedYear = 2025;
        self.selectedMonth = 3;
        self.selectedDay = 18;
        [self.datePicker selectRow:[self.years indexOfObject:[NSString stringWithFormat:@"2025%@",LLLLLL(@"Year")]] inComponent:0 animated:NO];
        [self.datePicker selectRow:2 inComponent:1 animated:NO];
        [self.datePicker selectRow:17 inComponent:2 animated:NO];
    }
}

// 隐藏时间选择器
- (void)hideDatePicker {
    [self removeFromSuperview];
}

// 确认选择的时间
- (void)confirmDateSelection {
    [self xqq_checkBeforeConfirm]; // 新增
    // 创建日期组件
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = self.selectedYear;
    components.month = self.selectedMonth;
    components.day = self.selectedDay;
    
    // 获取当前时区的日历
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *selectedDate = [calendar dateFromComponents:components];
    
    // 转换成时间戳（毫秒级，13位）
    NSTimeInterval timestamp = [selectedDate timeIntervalSince1970] * 1000;
    NSLog(@"选择的日期: %ld年%ld月%ld日, 时间戳: %.0f",
          (long)self.selectedYear, (long)self.selectedMonth, (long)self.selectedDay, timestamp);
    if (self.selectD) {
        self.selectD(timestamp);
    }
    [self hideDatePicker];
}

- (void)setInitialDateWithTimestamp:(NSTimeInterval)timestamp {
    NSDate *date;
    
    // 如果时间戳为 0，默认显示当前日期
    if (timestamp == 0) {
        date = [NSDate date]; // 获取当前时间
    } else {
        date = [NSDate dateWithTimeIntervalSince1970:timestamp / 1000]; // 13位时间戳转换为 NSDate
    }

    // 获取年、月、日
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                               fromDate:date];

    // 赋值给 picker 选中的日期
    self.selectedYear = components.year;
    self.selectedMonth = components.month;
    self.selectedDay = components.day;

    // 刷新 pickerView 显示正确的选中项
    [self.datePicker reloadAllComponents];

    // 让 pickerView 选中当前的年、月、日
    [self.datePicker selectRow:(self.selectedYear - self.startYear) inComponent:0 animated:YES];
    [self.datePicker selectRow:(self.selectedMonth - 1) inComponent:1 animated:YES];
    [self.datePicker selectRow:(self.selectedDay - 1) inComponent:2 animated:YES];
}



#pragma mark - UIPickerView 数据源和代理方法

// 列数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3; // 年、月、日
}

// 每列行数
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        return self.years.count;
    } else if (component == 1) {
        return self.months.count;
    } else {
        return self.days.count;
    }
}

// 每行的内容
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        return self.years[row];
    } else if (component == 1) {
        return self.months[row];
    } else {
        return self.days[row];
    }
}

// 选中某一行
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        self.selectedYear = 1900 + row;
    } else if (component == 1) {
        self.selectedMonth = row + 1;
    } else {
        self.selectedDay = row + 1;
    }

    // 更新日期选项
    [self updateDaysForYear:self.selectedYear month:self.selectedMonth];
    [self.datePicker reloadComponent:2];
}
@end

#pragma mark - 新增：选择检查

// 新增：记录挂在关联对象上，日志只在 Debug 下输出，不影响选中值和回调
static const void *kXQQBirthdayCheckKey = &kXQQBirthdayCheckKey; // 新增

@implementation XQQMKDIOFZTUserInfoBirthdayView (XQQSelectionCheck)

// 新增：弹出时记下时间，用来算从弹出到确认用了多久
- (void)xqq_recordShow {
    objc_setAssociatedObject(self, kXQQBirthdayCheckKey, @(CACurrentMediaTime()), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 新增：点"确定"、生成时间戳之前检查选中的日期，只记录不修正：
// - 日溢出：先选 31 日再把月份滚到 2 月，日这一列已经变成 28 天，但 selectedDay 还是 31，
//   日历会把 2 月 31 日顺延成 3 月初，保存下去的生日和滚轮上看到的不一样
// - 显示不一致：滚轮当前停留的行和 selectedYear / Month / Day 不对应
// - 未来日期：选中的日期晚于今天
- (void)xqq_checkBeforeConfirm {
    NSInteger maxDay = [self daysInMonth:self.selectedMonth year:self.selectedYear];
    BOOL dayOverflow = self.selectedDay > maxDay;
    BOOL pickerMismatch = [self.datePicker selectedRowInComponent:0] != self.selectedYear - self.startYear ||
                          [self.datePicker selectedRowInComponent:1] != self.selectedMonth - 1 ||
                          [self.datePicker selectedRowInComponent:2] != MIN(self.selectedDay, maxDay) - 1;
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = self.selectedYear;
    components.month = self.selectedMonth;
    components.day = MIN(self.selectedDay, maxDay);
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
    BOOL inFuture = date && [date compare:[NSDate date]] == NSOrderedDescending;
#ifdef DEBUG
    NSNumber *shownAt = objc_getAssociatedObject(self, kXQQBirthdayCheckKey);
    NSLog(@"[BirthdayView] confirm %ld-%ld-%ld dayOverflow=%d (max %ld) pickerMismatch=%d inFuture=%d after %.1fs",
          (long)self.selectedYear, (long)self.selectedMonth, (long)self.selectedDay, dayOverflow, (long)maxDay,
          pickerMismatch, inFuture, shownAt ? CACurrentMediaTime() - shownAt.doubleValue : 0);
#else
    (void)dayOverflow; (void)pickerMismatch; (void)inFuture;
#endif
}

@end
