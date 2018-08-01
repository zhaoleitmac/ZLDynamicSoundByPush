//
//  SPConstant.h
//  DynamicSoundByPushDemo
//
//  Created by 赵雷 on 2018/7/30.
//  Copyright © 2018年 赵雷. All rights reserved.
//

#import <UIKit/UIKit.h>

///systerm version
#define AFTER_IOS_10 [[UIDevice currentDevice].systemVersion floatValue] >= 10.0
#define BEFORE_IOS_10 [[UIDevice currentDevice].systemVersion floatValue] < 10.0

///weak/strong reference
#define DSSelfWeakly __weak typeof(self) __DSWeakSelf = self;
#define DSSelfStrongly __strong typeof(__DSWeakSelf) self = __DSWeakSelf;

//singleton
#define DS_SINGLETON_DECLARE \
+(instancetype)sharedInstance;

#define DS_SINGLETON_IMPLEMENTATION \
+(instancetype)sharedInstance{ \
return [self new]; \
} \
\
+(instancetype)allocWithZone:(struct _NSZone *)zone{ \
static id instance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
instance = [super allocWithZone:zone]; \
}); \
return instance; \
}\
\
-(instancetype)init{\
static dispatch_once_t onceToken;\
static typeof(self) instance;\
dispatch_once(&onceToken, ^{\
instance = [super init];\
});\
return instance;\
}
