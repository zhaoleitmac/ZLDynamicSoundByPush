# ZLDynamicSoundByPush
该工程是实现APNs推送生成动态语音播放（例如支付金额播放）Demo，无论在应用前台还是后台都可以实现。  
该Demo分为iOS 10前、iOS 10后iOS 12.1前和iOS 12.1后三种实现。  

## 分为三种实现的原因
● iOS 10前的实现是利用静默推送（content-available = 1）在后台通过推送内容合成语音保存在本地，将该APNs和合成语音配置为本地通知（UILocalNotification）后发出。iOS 11系统对静默推送进行了限制，不能再预期地收到每一条静默推送。  
● iOS 10后iOS 12.1前使用的是iOS 10新的API-UNNotificationServiceExtension，UNNotificationServiceExtension可以在推送到达应用前配置推送，在其限制时间内播放合成的语音。  
● iOS 12.1后苹果禁止了在UNNotificationServiceExtension中使用使用AudioSession，无法合成音频和播放音频，原实现已不能满足需求。该实现也是在UNNotificationServiceExtension中，在其限制时间内相继计划与语音片段对应的（与语音片段等数量个）本地推送（UNTimeIntervalNotificationTrigger），本地推送相继触发（间隔时间为上一个语音片段的总时间），多个语音连续播放模拟成一个连续语音。  

## Requirements
● 开启后台模式的Audio和Remote notification。  
● 正确配置推送证书和UNNotificationServiceExtension推送证书。  

## 推送格式
### iOS 10前
```json
{"aps":{"content-available":1},"data":{"money":"001"}}
```
content-available必填且为1，不填入alert、sound字段。

### iOS 10后（含iOS 12.1后）
```json
{"aps":{"mutable-content":1, "alert":"收款0.01元"},"data":{"money":"001"}}
```
mutable-available必填且为1，alert等选填（UNNotificationServiceExtension中可修改）。  

注：  
● 以上001（money字段）表示0.01元。  
● data内容可变，但代码中解析也要做相应改变。

## Features
iOS 10前的实现可以使语音有序地播放不会被打断，在高频推送情况下，保证了前一个播放结束才会播放下一个。iOS 10后暂未实现该功能。

## notice
● 在ZLNotificationSevice.m中有三处“//do something...”。分别是在iOS 10前的本地推送逻辑的前台处理和后台点击通知栏处理，iOS 10后的远程推送处理（不区分前后台）。
在此三处代码中可以用来写收到推送后的逻辑，例如弹窗提醒。  
● 由于iOS 12.1后的实现会产生若干个本地推送（UNTimeIntervalNotificationTrigger），而设备收到含有语音的本地推送会伴随着震动，所以该实现的缺点即是语音伴随着若干个震动（与本地推送数量相等），影响用户体验。  
