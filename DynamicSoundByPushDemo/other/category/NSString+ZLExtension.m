//
//  NSString+ZLExtension.m
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import "NSString+ZLExtension.h"

@implementation NSString (ZLExtension)

- (NSArray <NSString *> *)operateMoney {
    if (self.length > 10 || self.length < 3) {
        return nil;
    }
    NSMutableArray *temp = [NSMutableArray array];
    NSMutableArray *arrayOfTracks = [NSMutableArray array];
    if (self && self.length) {
        //把字符串每个字符放入数组中
        for (NSInteger i=0; i<self.length; i++) {
            NSString *charStr = [self substringWithRange:NSMakeRange(i, 1)];
            [temp addObject:charStr];
        }
        //在数组中插入相应文字
        NSArray *unitArray = @[@"thousand", @"hundred", @"ten", @"ten_thousand", @"thousand", @"hundred", @"ten"];
        NSInteger mark = temp.count - 3;
        NSInteger unitCount = unitArray.count;
        BOOL startZero = NO;
        NSInteger count = temp.count - 3;
        for (NSInteger i = 0; i < count; i++) {
            if (i == 0) {
                [arrayOfTracks addObject:temp[i]];
                [arrayOfTracks addObject:unitArray[unitCount - mark]];
            } else {
                if ([temp[i] isEqualToString:@"0"]) {
                    if (startZero == NO) {
                        [arrayOfTracks addObject:@"0"];
                        startZero = YES;
                    }
                    if ([unitArray[unitCount - mark] isEqualToString:@"ten_thousand"]) {//如果是万位，必须加入万
                        [arrayOfTracks replaceObjectAtIndex:arrayOfTracks.count-1 withObject:unitArray[unitCount - mark]];
                        startZero = NO;
                        
                    }
                } else {
                    startZero = NO;
                    [arrayOfTracks addObject:temp[i]];
                    [arrayOfTracks addObject:unitArray[unitCount - mark]];
                }
            }
            mark--;
        }
        if ([temp[temp.count - 3] isEqualToString:@"0"]) {
            if (startZero) {
                arrayOfTracks = [NSMutableArray arrayWithArray:[arrayOfTracks subarrayWithRange:NSMakeRange(0, arrayOfTracks.count - 1)]];
            }
            if (temp.count == 3) {
                [arrayOfTracks addObject:temp[temp.count - 3]];
            }
        } else {
            [arrayOfTracks addObject:temp[temp.count - 3]];
        }
        
        if ([temp[temp.count - 2] isEqualToString:@"0"]) {      //小数点第一位是0
            if (![temp[temp.count - 1] isEqualToString:@"0"]) { //小数点第二位不是0
                [arrayOfTracks addObject:@"point"];
                [arrayOfTracks addObject:temp[temp.count - 2]];
                [arrayOfTracks addObject:temp[temp.count - 1]];
            }
        } else {                                                //小数点第一位不是0
            [arrayOfTracks addObject:@"point"];
            [arrayOfTracks addObject:temp[temp.count - 2]];
            if (![temp[temp.count - 1] isEqualToString:@"0"]) { //小数点第二位不是0
                [arrayOfTracks addObject:temp[temp.count - 1]];
            }
            
        }
        [arrayOfTracks addObject:@"yuan"];
        [arrayOfTracks insertObject:@"receive" atIndex:0];
        
        
    }
    return arrayOfTracks.copy;
}

@end
