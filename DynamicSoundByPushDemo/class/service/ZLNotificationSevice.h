//
//  ZLNotificationSevice.h
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSConstant.h"

#define kSoundName @"soundName"

#define kLocalSoundNotificationType @"localSoundNotificationType"

#define LocalNotificationTypeCustomSound @"CustomSound"

@interface ZLNotificationSevice : NSObject

DS_SINGLETON_DECLARE

///处理远程通知
-(void)receiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (void)receiveLocalNotification:(NSDictionary *)userInfo;

@end
