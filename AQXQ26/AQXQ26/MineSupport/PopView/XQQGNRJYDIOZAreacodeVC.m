//
//  XQQGNRJYDIOZAreacodeVC.m
//  WUHOIBDK
//
//  Created by Ruby on 12/29/23.
//  Copyright © 2023 WildFireChat. All rights reserved.
//

#import "XQQGNRJYDIOZAreacodeVC.h"

@interface XQQGNRJYDIOZAreacodeVC ()<UITableViewDataSource,UITableViewDelegate,UISearchResultsUpdating> {
    UITableView *_tableView;
    UISearchController *_searchController;
    NSDictionary *_sortedNameDict;
    NSArray *_indexArray;
    NSMutableArray *_results;
}

@end

@implementation XQQGNRJYDIOZAreacodeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _results = [NSMutableArray arrayWithCapacity:1];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, WIDTH, HEIGHT) style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.rowHeight = 50.0;
    _tableView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.dimsBackgroundDuringPresentation = NO;
    if (@available(iOS 13, *)) {
        _searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        UIImage* searchBarBg = [UIImage imageWithColor:RGBA(0xF6F6F6) size:CGSizeMake(self.view.frame.size.width - 15 * 2, 36) cornerRadius:10];
        [_searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [_searchController.searchBar setValue:LLLLLL(@"Cancel") forKey:@"_cancelButtonText"];
    }
    if (@available(iOS 9.1, *)) {
        _searchController.obscuresBackgroundDuringPresentation = NO;
    }
    [_searchController.searchBar setPlaceholder:LLLLLL(@"Search")];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    } else {
        _searchController.searchBar.backgroundImage = UIImage.new;
        _searchController.searchBar.backgroundColor = UIColor.whiteColor;

        _tableView.tableHeaderView = _searchController.searchBar;
        _tableView.tableHeaderView.backgroundColor = UIColor.whiteColor;
    }
    // 这句话可以解决 self.tableView.tableHeaderView = _searchController.searchBar 导致的搜索栏下滑灰色的问题
    _tableView.backgroundView = UIView.new;
    
    self.definesPresentationContext = YES;
    
    if ([XQQCommonHelper.main isChinese]) {
        self.navigationItem.title = @"选择国家区号";
        NSString *plistPathCH = [[NSBundle mainBundle] pathForResource:@"AreaCodeName" ofType:@"plist"];
        _sortedNameDict = [[NSDictionary alloc] initWithContentsOfFile:plistPathCH];
    }else {
        self.navigationItem.title = @"Select the country code";
        NSString *plistPathCH = [[NSBundle mainBundle] pathForResource:@"AreaCodeNameEn" ofType:@"plist"];
        _sortedNameDict = [[NSDictionary alloc] initWithContentsOfFile:plistPathCH];
    }
    
    _indexArray = [[NSArray alloc] initWithArray:[[_sortedNameDict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }]];
    
}

- (NSString *)showCodeStringIndex:(NSIndexPath *)indexPath {
    NSString *showCodeSting;
    if (_searchController.isActive) {
        if (_results.count > indexPath.row) {
            showCodeSting = [_results objectAtIndex:indexPath.row];
        }
    } else {
        if (_indexArray.count > indexPath.section) {
            NSArray *sectionArray = [_sortedNameDict valueForKey:[_indexArray objectAtIndex:indexPath.section]];
            if (sectionArray.count > indexPath.row) {
                showCodeSting = [sectionArray objectAtIndex:indexPath.row];
            }
        }
    }
    return showCodeSting;
}



#pragma mark - UITableViewDelegate && UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_searchController.isActive) {
        return 1;
    } else {
        return [_sortedNameDict allKeys].count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_searchController.isActive) {
         return [_results count];
    } else {
        if (_indexArray.count > section) {
            NSArray *array = [_sortedNameDict objectForKey:[_indexArray objectAtIndex:section]];
            return array.count;
        }
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.textLabel.font = PINGFANG_M(16);
        cell.textLabel.textColor = RGBA(0x222222);
        cell.detailTextLabel.font = PINGFANG_R(14);
        cell.detailTextLabel.textColor = RGBA(0x3478F6);
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSArray *strings = [[self showCodeStringIndex:indexPath] componentsSeparatedByString:@"+"];
    cell.textLabel.text = strings.firstObject;
    cell.detailTextLabel.text = UNString(@"+%@ ", strings.lastObject);
    return cell;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (_searchController.isActive) {
        return nil;
    }
    if (tableView == _tableView) {
        return _indexArray;
    }else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
//    view.backgroundColor = UIColor.redColor;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (tableView == _tableView) {
        return index;
    }else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_indexArray.count && _indexArray.count > section) {
        return [_indexArray objectAtIndex:section];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == _tableView) {
        if (_searchController.isActive) {
            if (section == 0) {
                return 0;
            }
        }
        return 30;
    } else {
        return 0;
    }
}


#pragma mark - 选择国际获取代码
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * originText = [self showCodeStringIndex:indexPath];
    NSArray  * array = [originText componentsSeparatedByString:@"+"];
    NSString * countryName = [array.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString * code = array.lastObject;
    
    if (self.deleagete && [self.deleagete respondsToSelector:@selector(returnCountryName:code:)]) {
        [self.deleagete returnCountryName:countryName code:code];
    }
    
    if (self.returnCountryCodeBlock != nil) {
        self.returnCountryCodeBlock(countryName,code);
    }
    
//    if (_searchController.active) {
//        _searchController.active = NO;
//        [_searchController.searchBar resignFirstResponder];
//        WS(weakself)
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [weakself.navigationController popViewControllerAnimated:YES];
//        });
//    }else {
        [self.navigationController popViewControllerAnimated:YES];
//    }
}




#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    // 1. 获取当前的输入模式
    if (@available(iOS 13.0, *)) {
        UITextInputMode *currentInputMode = searchController.searchBar.searchTextField.textInputMode;
        NSString *keyboardLanguage = currentInputMode.primaryLanguage;
        // 2. 判断是否是中文键盘（可能是 zh-Hans、zh-Hant 等）
        BOOL isChineseKeyboard = [keyboardLanguage hasPrefix:@"zh"];

        // 3. 获取 markedTextRange
        UITextRange *markedRange = searchController.searchBar.searchTextField.markedTextRange;
        // 4. 只有当【使用中文键盘】且【没有拼音未上屏】时才触发搜索
        if (isChineseKeyboard && markedRange != nil) {
            return;
        }
    } else {
        // Fallback on earlier versions
    }
    if (_results.count > 0) {
        [_results removeAllObjects];
    }
    NSString *inputText = searchController.searchBar.text;
    
    QOEUAPinyinUtility *pu = QOEUAPinyinUtility.new;
    BOOL isChinese = [pu isChinese:inputText];
    
    __weak __typeof(self)weakSelf = self;
    [_sortedNameDict.allValues enumerateObjectsUsingBlock:^(NSArray * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if ([obj.lowercaseString containsString:inputText.lowercaseString]) {
                [strongSelf->_results addObject:obj];
            }else if (!isChinese) {
                if ([pu isMatch:obj ofPinYin:inputText]) {
                    [strongSelf->_results addObject:obj];
                }
            }
        }];
    }];
    [_tableView reloadData];
}

- (void)dealloc {
    NSLog(@"dealloc------%@",NSStringFromClass(self.class));
}

@end
