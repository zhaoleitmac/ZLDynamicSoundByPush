//
//  ZLSoundService.m
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/8/1.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import "ZLSoundService.h"
#import <AVFoundation/AVFoundation.h>
#import<AudioToolbox/AudioToolbox.h>
#import "DSLog.h"

#define kLastLocalNotification @"LastLocalNotification"

@interface ZLSoundService ()

@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) NSDateFormatter *formatter;

@end

@implementation ZLSoundService

DS_SINGLETON_IMPLEMENTATION


- (NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
    }
    return _formatter;
}

//拼接文件
- (void)mixSoundWithSoundArray:(NSArray<NSString *> *)soundArray
                      complete:(void(^)(BOOL success, NSString *fileName, NSTimeInterval notiInterval))complete {
    
    NSString *folderPath = [self getFolderPath];
    [self removeOverdueFileWithSoundPath:folderPath];
    
    NSMutableArray *mUrls = [NSMutableArray arrayWithCapacity:soundArray.count];
    for (NSString *soundName in soundArray) {
        NSString *fileP = nil;
        fileP = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
        if(!fileP){
            fileP = [[NSBundle mainBundle] pathForResource:soundName ofType:@"caf"];
        }
        if (!fileP.length) {
            complete(NO, nil, 0);
            return;
        }
        NSURL *url = [NSURL fileURLWithPath:fileP];
        [mUrls addObject:url];
    }
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *track = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray<NSURL *> *urls = mUrls.copy;
    Float64 soundDuration = 0;
    for (NSInteger i = 0; i<urls.count; i++) {
        NSURL *url = [urls objectAtIndex:i];
        AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
        CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        AVAssetTrack *aTrack = [audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        [track insertTimeRange:audioTimeRange ofTrack:aTrack atTime:CMTimeMakeWithSeconds(soundDuration, 0) error:nil];
        soundDuration += CMTimeGetSeconds(audioAsset.duration);
    }
    [AVAssetExportSession exportPresetsCompatibleWithAsset:mixComposition];
    
    AVAssetExportSession *export = [[AVAssetExportSession alloc]initWithAsset:mixComposition presetName:AVAssetExportPresetAppleM4A];
    export.outputFileType = @"com.apple.m4a-audio";
    
    NSDate *currentDateTemp = [NSDate date];
    NSString *fileName = [[self.formatter stringFromDate:currentDateTemp] stringByAppendingString:@"temp"];
    NSString *soundFilePath = [folderPath stringByAppendingPathComponent:fileName];
    NSURL *soundFileUrl = [NSURL fileURLWithPath:soundFilePath];
    export.outputURL = soundFileUrl;
    [export exportAsynchronouslyWithCompletionHandler:^{
        NSError *error = export.error;
        BOOL result = YES;
        if (error) {
            result = NO;
            DSDebugLog(@"拼接音频失败..... soundArray :%@,error :%@",soundArray,error);
        }
        void (^completeAction)(void) = ^(void) {
            NSDate *currentDate = [NSDate date];
            NSTimeInterval notiInterval = [self delayOfSoundLocalNotificationWithCompareTime:currentDate];
            NSDate *endTime = [NSDate dateWithTimeInterval:(notiInterval + soundDuration + soundLocalNotificationDelay) sinceDate:currentDate];
            [self updateLastLocalNotificationDate:endTime];
            NSString *nFileName = [self renameFileWithFilePath:folderPath originalName:fileName newName:[self.formatter stringFromDate:endTime]];
            if (complete) {
                complete(result, nFileName, notiInterval);
            }
        };
        if ([NSThread isMainThread]) {
            completeAction();
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                completeAction();
            });
        }
    }];
}


- (NSString *)getFolderPath {
    NSString *libPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject;
    NSString *soundDirtPath = [libPath stringByAppendingPathComponent:@"Sounds"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:soundDirtPath];
    if (!isExist) {
        [fileManager createDirectoryAtPath:soundDirtPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return soundDirtPath;
}

///删除当前时间前已经播完的音频数据
- (void)removeOverdueFileWithSoundPath:(NSString *)soundDirtPath {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *existFiles = [fileManager contentsOfDirectoryAtPath:soundDirtPath error:nil];
    
    for (NSString *existFile in existFiles) {
        NSDate *existFileDate = [self.formatter dateFromString:existFile];
        NSDate *currentDate = [NSDate date];
        if ([existFileDate isEqualToDate:[currentDate earlierDate:existFileDate]]) {
            [fileManager removeItemAtPath:[soundDirtPath stringByAppendingPathComponent:existFile] error:nil];
        }
    }
}

- (NSString *)renameFileWithFilePath:(NSString *)path originalName:(NSString *)originalName newName:(NSString *)newName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *originalFolder = [path stringByAppendingPathComponent:originalName];
    NSString *newFolder = [path stringByAppendingPathComponent:newName];
    [manager moveItemAtPath:originalFolder toPath:newFolder error:nil];
    [manager removeItemAtPath:originalFolder error:nil];
    return newName;
}

- (void)updateLastLocalNotificationDate:(NSDate *)endTime {
    NSDate *originalDate = [self lastLocalNotificationDate];
    NSDate *newLastDate = nil;
    if (originalDate) {
        newLastDate = [originalDate laterDate:endTime];
    } else {
        newLastDate = endTime;
    }
    if (endTime == newLastDate) {
        NSString *newLastDateStr = [self.formatter stringFromDate:newLastDate];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:newLastDateStr forKey:kLastLocalNotification];
        [userDefaults synchronize];
    }
}

//算出延迟播放时间
- (NSTimeInterval)delayOfSoundLocalNotificationWithCompareTime:(NSDate *)date {
    NSTimeInterval notiInterval = 0;
    NSDate *lastLocalNotificationDate = [self lastLocalNotificationDate];
    if (date == [date earlierDate:lastLocalNotificationDate]) {
        notiInterval = [lastLocalNotificationDate timeIntervalSinceDate:date];
    }
    return notiInterval;
}

//获取时间播放结束最晚的本地推送时间
- (NSDate *)lastLocalNotificationDate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *lastLocalNotificationDateString = [userDefaults objectForKey:kLastLocalNotification];
    return [self.formatter dateFromString:lastLocalNotificationDateString];
}

- (void)configSound:(NSString *)soundName callback:(void(^)(NSString *fileName, NSTimeInterval notiInterval))callback {
    if ([soundName rangeOfString:@"."].length) {
        NSArray *arr = [soundName componentsSeparatedByString:@"."];
        if (arr.count) {
            soundName = arr[0];
        }
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.caf", soundName];
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"caf"];
    if(!path.length){
        fileName = [NSString stringWithFormat:@"%@.m4a", soundName];
        path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"m4a"];
    }
    if (!path.length) {
        fileName = [NSString stringWithFormat:@"%@.caf", defaultSoundName];
        path = [[NSBundle mainBundle] pathForResource:defaultSoundName ofType:@"caf"];
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    Float64 soundDuration = CMTimeGetSeconds([[AVURLAsset alloc]initWithURL:url options:nil].duration);
    NSTimeInterval interval = 0;
    NSDate *lastLocalNotificationDate = [self lastLocalNotificationDate];
    NSDate *currentDate = [NSDate date];
    if (currentDate == [currentDate earlierDate:lastLocalNotificationDate]) {
        interval = [lastLocalNotificationDate timeIntervalSinceDate:currentDate];
    }
    NSDate *endTime = [NSDate dateWithTimeInterval:(interval + soundDuration + soundLocalNotificationDelay) sinceDate:currentDate];
    [self updateLastLocalNotificationDate:endTime];
    if (callback) {
        callback(fileName, interval);
    }
}

- (void)playSoundWithFileName:(NSString *)fileName {
    NSString *filePath = [[self getFolderPath] stringByAppendingPathComponent:fileName];
    NSURL *soundUrl = [NSURL fileURLWithPath:filePath];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    if (self.player.prepareToPlay) {
        [self.player play];
    }
}

@end
