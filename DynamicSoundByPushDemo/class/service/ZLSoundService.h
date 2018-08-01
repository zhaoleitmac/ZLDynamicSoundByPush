//
//  ZLSoundService.h
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSConstant.h"

#define soundLocalNotificationDelay 0.5

#define defaultSoundName @"default"


@interface ZLSoundService : NSObject

DS_SINGLETON_DECLARE

- (void)mixSoundWithSoundArray:(NSArray<NSString *> *)soundArray
                      complete:(void(^)(BOOL success, NSString *fileName, NSTimeInterval notiInterval))complete;

- (void)configSound:(NSString *)soundName callback:(void(^)(NSString *fileName, NSTimeInterval notiInterval))callback;

- (void)playSoundWithFileName:(NSString *)fileName;

@end
