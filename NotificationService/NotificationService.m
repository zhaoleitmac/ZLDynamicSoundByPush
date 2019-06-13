//
//  NotificationService.m
//  NotificationService
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import "NotificationService.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "NSString+ZLExtension.h"

typedef NS_ENUM(NSUInteger, NotificationServiceSoundPlayerType) {
    NotificationServiceSoundPlayerTypeNone = 0,
    NotificationServiceSoundPlayerTypeAVPlayer = 1,
    NotificationServiceSoundPlayerTypeAudioService = 2,
};

NSString * const kDynamicSoundIdentifier = @"DynamicSoundIdentifier";

@interface NotificationService () <AVAudioPlayerDelegate>

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@end

static void completionCallback(SystemSoundID ssID, void *clientData){}

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    NSDictionary *userInfo = request.content.userInfo;
    
    if (@available(iOS 12.1, *)) {//iOS12.1后NotificationServiceExtension被禁止使用AudioSession，无法合成音频和播放音频
        [self playWithRegisterLocalNotifications:userInfo];
    } else {
        [self playBySoundPlayType:NotificationServiceSoundPlayerTypeAudioService WithUserInfo:userInfo];
//        [self playBySystemReadWithUserInfo:userInfo];
    }
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

#pragma mark - After iOS 12.1

- (void)playWithRegisterLocalNotifications:(NSDictionary *)userInfo {
    NSArray *soundNames = [self soundNamesWithUserInfo:userInfo];
    NSInteger count = soundNames.count;
    for (int i = 0; i < count; i++) {
        NSString *soundName = soundNames[i];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self registerNotificationWithSoundName:soundName completeHandler:^(Float64 duration) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dispatch_semaphore_signal(semaphore);
                if (i == count - 1) {
                    self.contentHandler(self.bestAttemptContent);
                }
            });
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)registerNotificationWithSoundName:(NSString *)soundName completeHandler:(void (^)(Float64 duration))complete {
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"";
    content.subtitle = @"";
    content.body = @"";
    content.sound = [UNNotificationSound soundNamed:[NSString stringWithFormat:@"%@.m4a",soundName]];
    content.categoryIdentifier = [NSString stringWithFormat:@"%@%@", kDynamicSoundIdentifier, soundName];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.01 repeats:NO];
    
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"%@%@", kDynamicSoundIdentifier, soundName] content:content trigger:trigger];
    
    //获取音频持续时间，以预备下一次本地推送
    NSString *fileP = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
    NSURL *url = [NSURL fileURLWithPath:fileP];
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
    Float64 duration = CMTimeGetSeconds(audioAsset.duration);
    
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error == nil) {
            if (complete) {
                complete(duration);
            }
        }
    }];
}

#pragma mark - 音频处理

- (void)playBySoundPlayType:(NotificationServiceSoundPlayerType)type WithUserInfo:(NSDictionary *)userInfo {
    if (type) {
        NSArray *soundNames = [self soundNamesWithUserInfo:userInfo];
        NSString *folderPath = [self getFolderPathAndCleanOldFile];
        __weak typeof(self) weakSelf = self;
        [self mixSoundWithSoundArray:soundNames targetFilePath:folderPath complate:^(BOOL success, NSString *soundFilePath,Float64 duration) {
            if (success) {
                if (type == NotificationServiceSoundPlayerTypeAudioService) {
                    [weakSelf playSoundByAudioServiceWithFilePath:soundFilePath];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        weakSelf.contentHandler(weakSelf.bestAttemptContent);
                    });
                    //                    weakSelf.contentHandler(weakSelf.bestAttemptContent);
                } else if (type == NotificationServiceSoundPlayerTypeAVPlayer) {
                    [weakSelf playSoundByAVPlayerWithFilePath:soundFilePath];//结束代理回调发出推送
                }
            } else {
                weakSelf.contentHandler(weakSelf.bestAttemptContent);
            }
        }];
    }
    
}

///iOS系统直接读出
- (void)playBySystemReadWithUserInfo:(NSDictionary *)userInfo {
    NSString *amount = [self amoutWithUserInfo:userInfo];
    NSString *content = [NSString stringWithFormat:@"收款%@元", amount ? amount : @""];
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:content];
    utterance.rate = 0.4;
    utterance.voice =[AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    [self.synthesizer speakUtterance:utterance];
    self.contentHandler(self.bestAttemptContent);
}

#pragma mark - tool func
//获取阅读内容
- (NSString *)amoutWithUserInfo:(NSDictionary *)userInfo {
    NSDictionary *data = userInfo[@"data"];
    NSString *money = data[@"money"];
    return money;
}
//提取语音文件名
- (NSArray <NSString *> *)soundNamesWithUserInfo:(NSDictionary *)userInfo {
    NSDictionary *data = userInfo[@"data"];
    NSString *money = data[@"money"];
    NSArray *soundList = [money operateMoney];
    return soundList;
}

- (NSString *)getFolderPathAndCleanOldFile {
    NSString *libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
    NSString *soundDirtPath = [libPath stringByAppendingPathComponent:@"Sounds"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:soundDirtPath];
    if (!isExist) {
        [fileManager createDirectoryAtPath:soundDirtPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSArray<NSString *> *existFiles = [fileManager contentsOfDirectoryAtPath:soundDirtPath error:nil];
    
    for (NSString *existFile in existFiles) {
        [fileManager removeItemAtPath:[soundDirtPath stringByAppendingPathComponent:existFile] error:nil];
    }
    return soundDirtPath;
}

//拼接文件
- (void)mixSoundWithSoundArray:(NSArray<NSString *>*)soundArray
                targetFilePath:(NSString *)targetFilePath
                      complate:(void(^)(BOOL success, NSString *soundFilePath,Float64 duration))complate {
    NSMutableArray *mUrls = [NSMutableArray arrayWithCapacity:soundArray.count];
    for (NSString *soundName in soundArray) {
        NSString *fileP = nil;
        fileP = [[NSBundle mainBundle]pathForResource:soundName ofType:@"m4a"];
        if(!fileP){
            fileP = [[NSBundle mainBundle]pathForResource:soundName ofType:@"caf"];
        }
        
        if (!fileP.length) {
            complate(NO, [NSString stringWithFormat:@"无法找到%@", soundName],0);
            return;
        }
        NSURL *url = [NSURL fileURLWithPath:fileP];
        [mUrls addObject:url];
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *track = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray<NSURL *> *urls = mUrls.copy;
    Float64 tempDuration = 0;
    for (NSInteger i = 0; i<urls.count; i++) {
        NSURL *url = [urls objectAtIndex:i];
        AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        AVAssetTrack *aTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        [track insertTimeRange:audioTimeRange ofTrack:aTrack atTime:CMTimeMakeWithSeconds(tempDuration, 0) error:nil];
        tempDuration += CMTimeGetSeconds(audioAsset.duration);
    }
    [AVAssetExportSession exportPresetsCompatibleWithAsset:mixComposition];
    
    AVAssetExportSession *export = [[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
    export.outputFileType = @"com.apple.m4a-audio";
    
    NSString *fileName = @"temp.m4a";
    NSString *soundFilePath = [targetFilePath stringByAppendingPathComponent:fileName];
    NSURL *soundFileUrl = [NSURL fileURLWithPath:soundFilePath];
    
    export.outputURL = soundFileUrl;
    [export exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = export.error;
        BOOL result = YES;
        if (error) {
            result = NO;
            NSLog(@"拼接音频失败..... soundArray :%@,error :%@",soundArray,error);
        }
        complate(result, soundFilePath,tempDuration);
    }];
}

- (void)playSoundByAVPlayerWithFilePath:(NSString *)filePath {
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    NSURL *soundUrl = [NSURL fileURLWithPath:filePath];
    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:soundUrl error:nil];
    self.player.delegate = self;
    if (self.player.prepareToPlay) {
        [self.player play];
    }
}

SystemSoundID ditaVoice;

- (void)playSoundByAudioServiceWithFilePath:(NSString *)filePath {
    
    NSURL *soundUrl = [NSURL fileURLWithPath:filePath];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(soundUrl),&ditaVoice);
    AudioServicesAddSystemSoundCompletion(ditaVoice,NULL,NULL,(void *)completionCallback,NULL);
    AudioServicesPlayAlertSound(ditaVoice);
}

#pragma mark- AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    if (self.contentHandler) {
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
