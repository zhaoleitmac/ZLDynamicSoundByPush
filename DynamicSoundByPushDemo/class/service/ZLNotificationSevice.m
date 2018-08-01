//
//  ZLNotificationSevice.m
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import "ZLNotificationSevice.h"
#import <UserNotifications/UserNotifications.h>
#import "ZLSoundService.h"
#import "DSConstant.h"
#import "NSString+ZLExtension.h"

@implementation ZLNotificationSevice

DS_SINGLETON_IMPLEMENTATION

- (void)receiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (BEFORE_IOS_10) {
        [self scheduleSoundNotificationWithUserInfo:userInfo fetchCompletionHandler:completionHandler];
    } else {
        //do something...
    }
}

- (void)scheduleSoundNotificationWithUserInfo:(NSDictionary *)userInfo
                       fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSDictionary *data = userInfo[@"data"];
    NSString *money = data[@"money"];
    NSString *notifyTitle = [NSString stringWithFormat:@"收款%@元", money];
    NSArray *soundList = [money operateMoney];
    if (soundList.count) {
        if (soundList.count > 1) {
            [self scheduleDynamicSoundNotificationWithSoundArray:soundList notifyTitle:notifyTitle userInfo:userInfo complete:completionHandler];
        } else {
            [self scheduleStaticSoundNotificationWithSound:soundList.firstObject notifyTitle:notifyTitle userInfo:userInfo];
            completionHandler(UIBackgroundFetchResultNewData);
        }
    }
}

- (void)scheduleDynamicSoundNotificationWithSoundArray:(NSArray<NSString *> *)soundArray
                                           notifyTitle:(NSString *)notifyTitle
                                              userInfo:(NSDictionary *)userInfo
                                              complete:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [self sendLocalNotificationWithSoundArray:soundArray userInfo:userInfo notifyTitle:notifyTitle complete:completionHandler];
}

- (void)sendLocalNotificationWithSoundArray:(NSArray<NSString *> *)soundArray
                                   userInfo:(NSDictionary *)userInfo
                                notifyTitle:(NSString *)notifyTitle
                                   complete:(void (^)(UIBackgroundFetchResult))completionHandler{

    [[ZLSoundService sharedInstance] mixSoundWithSoundArray:soundArray complete:^(BOOL success, NSString *fileName, NSTimeInterval notiInterval) {
        if (success) {
            NSMutableDictionary *userInfoM = [NSMutableDictionary dictionaryWithDictionary:userInfo];
            [userInfoM setObject:LocalNotificationTypeCustomSound forKey:kLocalSoundNotificationType];
            [userInfoM setObject:fileName forKey:kSoundName];
            
            UILocalNotification *noti = [[UILocalNotification alloc] init];
            noti.soundName = fileName;
            noti.userInfo = userInfoM.copy;
            noti.alertBody = notifyTitle.copy;

            UIApplication *application = [UIApplication sharedApplication];
            if (notiInterval) {
                noti.fireDate = [[NSDate date] dateByAddingTimeInterval:notiInterval];
                [application scheduleLocalNotification:noti];
            }else{
                [application presentLocalNotificationNow:noti];
            }

        } else {
            [self scheduleStaticSoundNotificationWithSound:defaultSoundName notifyTitle:notifyTitle userInfo:userInfo];

        }
    }];
}

- (void)scheduleStaticSoundNotificationWithSound:(NSString *)soundName
                                     notifyTitle:(NSString *)notifyTitle
                                        userInfo:(NSDictionary *)userInfo {
    [[ZLSoundService sharedInstance] configSound:soundName callback:^(NSString *fileName, NSTimeInterval notiInterval) {
        NSMutableDictionary *userInfoM = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        [userInfoM setObject:LocalNotificationTypeCustomSound forKey:kLocalSoundNotificationType];
        [userInfoM setObject:fileName forKey:kSoundName];
        
        UILocalNotification *noti = [[UILocalNotification alloc] init];
        noti.soundName = fileName;
        noti.userInfo = userInfoM.copy;
        noti.alertBody = notifyTitle.copy;
        
        UIApplication *application = [UIApplication sharedApplication];
        if (notiInterval) {
            noti.fireDate = [[NSDate date] dateByAddingTimeInterval:notiInterval];
            [application scheduleLocalNotification:noti];
        }else{
            [application presentLocalNotificationNow:noti];
        }
    }];
}

- (void)receiveLocalNotification:(NSDictionary *)userInfo {
    
    if (BEFORE_IOS_10) { //在iOS10之前才有远程推送转本地推送，以下是iOS10本地推送独有的逻辑
        BOOL isCustomSound = [[userInfo objectForKey:kLocalSoundNotificationType] isEqualToString:LocalNotificationTypeCustomSound];
        NSString *soundName = [userInfo objectForKey:kSoundName];
        if (isCustomSound && soundName.length) {
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {//应用在前台运行，不会以通知栏通知用户，以语音提示
                [[ZLSoundService sharedInstance] playSoundWithFileName:soundName];
                //do something...
            } else {//通过手动点击通知栏进入
                //do something...
            }
        }
    }
}

@end
