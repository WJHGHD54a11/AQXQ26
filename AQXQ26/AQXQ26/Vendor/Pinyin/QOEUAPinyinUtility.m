//
//  QOEUAPinyinUtility.m
//  WFChatUIKit
//
//  Created by dali on 2021/1/28.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "QOEUAPinyinUtility.h"
@implementation WFCUPinyinModel
@end

@interface QOEUAPinyinUtility ()
@property(nonatomic, strong)NSMutableDictionary *pinyinDict;
@end

@implementation QOEUAPinyinUtility

-(BOOL)isMatch:(NSString *)name ofPinYin:(NSString *)pinyin {
    if(!name.length)
        return NO;
    pinyin = [pinyin lowercaseString];
    
    if(!self.pinyinDict) {
        [self loadPinyin];
    }
    
    WFCUPinyinModel *model = [self getModelByName:name];
    for (NSString *jp in model.jianpin) {
        if([jp containsString:pinyin]) {
            return YES;
        }
    }
    for (NSString *qp in model.quanpin) {
        if([qp rangeOfString:pinyin].location == 0) {
            return YES;
        }
    }
    
    return NO;
}

#define MAX_COMBINATIONS 1000  // 设置合理的上限

- (WFCUPinyinModel *)getModelByName:(NSString *)name {
    WFCUPinyinModel *model = [[WFCUPinyinModel alloc] init];
    model.jianpin = [[NSMutableArray alloc] init];
    model.quanpin = [[NSMutableArray alloc] init];
    
    for (int j = 0; j < name.length; j++) {
        NSString *ch = [name substringWithRange:NSMakeRange(j, 1)];
        NSString *codepointHexStr = [[NSString stringWithFormat:@"%x", [name characterAtIndex:j]] uppercaseString];

        if ([self isChinese:ch]) {
            NSArray *pinyins = self.pinyinDict[codepointHexStr];
            if (!pinyins || pinyins.count == 0) {
                continue;
            }

            NSMutableArray *newJianpin = [[NSMutableArray alloc] init];
            NSMutableArray *newQuanpin = [[NSMutableArray alloc] init];

            if (model.jianpin.count == 0) {
                for (NSString *str in pinyins) {
                    [newJianpin addObject:[str substringToIndex:1]];
                }
            } else {
                for (NSString *str in pinyins) {
                    NSString *j = [str substringToIndex:1];
                    for (NSString *jp in model.jianpin) {
                        NSString *newJp = [jp stringByAppendingString:j];
                        [newJianpin addObject:newJp];
                        if (newJianpin.count > MAX_COMBINATIONS) break;
                    }
                }
            }

            for (NSString *str in pinyins) {
                for (NSString *qp in model.quanpin) {
                    NSString *newQp = [qp stringByAppendingString:str];
                    [newQuanpin addObject:newQp];
                    if (newQuanpin.count > MAX_COMBINATIONS) break;
                }
                [newQuanpin addObject:str];
            }

            model.jianpin = newJianpin.count > MAX_COMBINATIONS ? [newJianpin subarrayWithRange:NSMakeRange(0, MAX_COMBINATIONS)] : newJianpin;
            model.quanpin = newQuanpin.count > MAX_COMBINATIONS ? [newQuanpin subarrayWithRange:NSMakeRange(0, MAX_COMBINATIONS)] : newQuanpin;
        } else {
            ch = ch.lowercaseString;
            NSMutableArray *newJianpin = [[NSMutableArray alloc] init];
            NSMutableArray *newQuanpin = [[NSMutableArray alloc] init];

            if (model.jianpin.count == 0) {
                [newJianpin addObject:ch];
            } else {
                for (NSString *jp in model.jianpin) {
                    NSString *newJp = [jp stringByAppendingString:ch];
                    [newJianpin addObject:newJp];
                    if (newJianpin.count > MAX_COMBINATIONS) break;
                }
            }

            for (NSString *qp in model.quanpin) {
                NSString *newQp = [qp stringByAppendingString:ch];
                [newQuanpin addObject:newQp];
                if (newQuanpin.count > MAX_COMBINATIONS) break;
            }
            [newQuanpin addObject:ch];

            model.jianpin = newJianpin.count > MAX_COMBINATIONS ? [newJianpin subarrayWithRange:NSMakeRange(0, MAX_COMBINATIONS)] : newJianpin;
            model.quanpin = newQuanpin.count > MAX_COMBINATIONS ? [newQuanpin subarrayWithRange:NSMakeRange(0, MAX_COMBINATIONS)] : newQuanpin;
        }
    }
    return model;
}


//- (WFCUPinyinModel *)getModelByName:(NSString *)name {
//    WFCUPinyinModel *model = [[WFCUPinyinModel alloc] init];
//    model.jianpin = [[NSMutableArray alloc] init];
//    model.quanpin = [[NSMutableArray alloc] init];
//    
//    for (int j = 0; j < name.length; j++) {
//        NSString *ch = [name substringWithRange:NSMakeRange(j, 1)];
//        
//        NSString *codepointHexStr =[[NSString stringWithFormat:@"%x", [name characterAtIndex:j]] uppercaseString];
//        
//        if ([self isChinese:ch]) {
//            NSArray *pinyins = self.pinyinDict[codepointHexStr];
//            
//            NSMutableArray *temp = [[NSMutableArray alloc] init];
//            if(!model.jianpin.count) {
//                for (NSString *str in pinyins) {
//                    [temp addObject:[str substringToIndex:1]];
//                }
//            } else {
//                for (NSString *str in pinyins) {
//                    NSString *j = [str substringToIndex:1];
//                    for (NSString *jp in model.jianpin) {
//                        NSString *newJp = [jp stringByAppendingString:j];
//                        [temp addObject:newJp];
//                    }
//                }
//            }
//            model.jianpin = temp;
//            
//            temp = [[NSMutableArray alloc] init];
//            for (NSString *str in pinyins) {
//                for (NSString *qp in model.quanpin) {
//                    NSString *newqp = [qp stringByAppendingString:str];
//                    [temp addObject:newqp];
//                }
//                [temp addObject:str];
//            }
//            model.quanpin = temp;
//        }else{
//            ch = ch.lowercaseString;
//            NSMutableArray *temp = [[NSMutableArray alloc] init];
//            if(model.jianpin.count == 0) {
//                [temp addObject:ch];
//            } else {
//                for (NSString *jp in model.jianpin) {
//                    NSString *newjp = [jp stringByAppendingString:ch];
//                    [temp addObject:newjp];
//                }
//            }
//            model.jianpin = temp;
//            
//            temp = [[NSMutableArray alloc] init];
//            for (NSString *qp in model.quanpin) {
//                NSString *newqp = [qp stringByAppendingString:ch];
//                [temp addObject:newqp];
//            }
//            [temp addObject:ch];
//            model.quanpin = temp;
//        }
//    }
//    return model;
//}

- (void)loadPinyin {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.pinyinDict = [[NSMutableDictionary alloc] init];

        NSString *bundlePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"unicode_to_hanyu_pinyin" ofType:@"txt"];
        if (!bundlePath) return;

        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:&error];
        if (error || !fileContents) return;

        NSArray *allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        for (NSString *oneLine in allLinedStrings) {
            NSArray *lineComponents = [oneLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (lineComponents.count == 2) {
                NSString *str = lineComponents[1];
                str = [str substringWithRange:NSMakeRange(1, str.length - 2)];
                self.pinyinDict[lineComponents[0]] = [str componentsSeparatedByString:@","];
            }
        }
    });
}

- (BOOL)isChinese:(NSString *)text {
    static NSPredicate *predicate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *match = @"(^[\u4e00-\u9fa5]+$)";
        predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    });
    return [predicate evaluateWithObject:text];
}


//- (void)loadPinyin {
//    self.pinyinDict = [[NSMutableDictionary alloc] init];
//    NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
//    NSString *bundlePath = [resourcePath stringByAppendingPathComponent:@"unicode_to_hanyu_pinyin.txt"];
//    
//    
//    NSString* fileContents = [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:nil];
//
//    // first, separate by new line
//    NSArray* allLinedStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
//
//    for (NSString *oneLine in allLinedStrings) {
//        NSArray *lineComponents=[oneLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
//        if(lineComponents.count == 2) {
//            NSString *str = lineComponents[1];
//            str = [str substringWithRange:NSMakeRange(1, str.length-2)];
//            self.pinyinDict[lineComponents[0]] = [str componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
//        }
//    }
//}

//- (BOOL)isChinese:(NSString *)text {
//    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
//    return [predicate evaluateWithObject:text];
//}

@end
