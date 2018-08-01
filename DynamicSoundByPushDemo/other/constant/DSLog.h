//
//  DSLog.h
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/7/30.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define DSDebugLog(format, ...) (printf("\r\n<------LOG BEGIN------>\r\n[fileName:%s]\r\n" "[functionName:%s]\r\n" "[codeRow:%d]\r\n%s\r\n<-------LOG END------->\r\n\r\n", [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String]))
#else
#define DSDebugLog(format, ...)
#endif

#define DS_MEMORAY_CHECK_DEBUG_LOG DSDebugLog(@"<%@,%p> is dealoc.Memory safe", self.class, self)
