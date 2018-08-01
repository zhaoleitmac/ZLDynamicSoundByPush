//
//  AppDelegate.m
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#import "DSConstant.h"
#import "DSLog.h"
#import "ZLNotificationSevice.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self registerToAPNS];

    return YES;
}

#pragma mark - register to APNS
///向APNS发起注册请求
- (void)registerToAPNS {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                DSDebugLog(@"注册成功");
                if(!error){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                    });
                }
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    DSDebugLog(@"%@", settings);
                }];
            } else {
                DSDebugLog(@"注册失败");
            }
        }];
    } else {
        UIApplication *application = [UIApplication sharedApplication];
        UIUserNotificationSettings *nSetting = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge  categories:nil];
        [application registerUserNotificationSettings:nSetting];
        [application registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // 注册APNS成功, 注册deviceToken
    NSString *token = [[[deviceToken.description stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    DSDebugLog(@"Registration success, the token is %@", token);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // 注册APNS失败.
    DSDebugLog(@"Registration failed! the error is %@", error.domain);
}

#pragma mark - Push Handle Before iOS 10

///RemoteNotification
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{

    [[ZLNotificationSevice sharedInstance] receiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

///LocalNotification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [[ZLNotificationSevice sharedInstance] receiveLocalNotification:notification.userInfo];
}

#pragma mark - Push Handle After iOS 10

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler  API_AVAILABLE(ios(10.0)) {
    UNNotificationRequest *request = notification.request;
    NSDictionary *userInfo = request.content.userInfo;
    if ([request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {//远程推送，不需要展示alert
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound);
        [[ZLNotificationSevice sharedInstance] receiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {}];
    }

}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    UNNotification *notification = response.notification;
    UNNotificationRequest *request = notification.request;
    NSDictionary *userInfo = request.content.userInfo;
    if ([request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {//远程推送
        [[ZLNotificationSevice sharedInstance] receiveRemoteNotification:userInfo fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            completionHandler();
        }];
    }
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
