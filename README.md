# ZLDynamicSoundByPush
该工程是实现APNs推送生成动态语音播放（例如支付金额播放）Demo，无论在应用前台还是后台都可以实现。
该Demo分为iOS 10前和iOS 10后两种实现。

## 分为两种实现的原因
iOS 10前的实现是利用静默推送（content-available = 1）在后台通过推送内容合成语音保存在本地，将该APNs和合成语音配置为本地通知（UILocalNotification）后发出。iOS 11系统对静默推送进行了限制，不能再预期地收到每一条静默推送。
iOS 10后使用的是iOS 10新的API-UNNotificationServiceExtension，UNNotificationServiceExtension可以在推送到达应用前配置推送，在其限制时间内播放合成的语音。

## Requirements
·开启后台模式的Audio和Remote notification。
·正确配置推送证书和UNNotificationServiceExtension推送证书。

## 推送格式
### iOS 10前
```json
{"aps":{"content-available":1},"data":{"money":"0.01"}}
```
content-available必填且为1，不填入alert、sound字段。

### iOS 10后
```json
{"aps":{"mutable-content":1, "alert":"收款0.01元"},"data":{"money":"0.01"}}
```
mutable-available必填且为1，alert等选填（UNNotificationServiceExtension中可修改）。

注：data内容可变，但代码中解析也要做相应改变。

## Features
iOS 10前的实现可以使语音有序地播放不会被打断，在高频推送情况下，保证了前一个播放结束才会播放下一个。iOS 10后暂未实现该功能。

## notice
在ZLNotificationSevice.m中有三处“//do something...”。分别是在iOS 10前的本地推送逻辑的前台处理和后台点击通知栏处理，iOS 10后的远程推送处理（不区分前后台）。
在此三处代码中可以用来写收到推送后的逻辑，例如弹窗提醒。
