# flutter_ios_voip_kit

One-to-one video call using CallKit and PushKit with flutter iOS app.

## Motivation

We need to use CallKit to handle incoming VoIP notifications from iOS 13. [Check the WWDC2019 video for more information](https://developer.apple.com/videos/play/wwdc2019/707/). So instead of using CallKit and PushKit separately, there is a growing need to use them together. However, there are still few VoIP notification samples on the net that use CallKit and PushKit (especially for Flutter). I decided to create a flutter plugin with the minimum required functions. **You can use this plugin, but the actual purpose is to help you create a VoIPKit tailored to your service.**

## Requirement

- iOS only, not support Android.
- iOS 10 or above.
- one-to-one call only, not support group call.
- need to a server for pushing VoIP notification with APNs.
- to actually make a video or call, you need to link to a service such as WebRTC（ex: Agora, SkyWay, Amazon Kinesis Video Streams）.

## Usage

### 1. install

- Add `flutter_ios_voip_kit` as a dependency in your pubspec.yaml file.

### 2. setting Capability in Xcode

1. Select Background Modes > Voice over IP and Remote notifications is ON.
1. Select Push Notifications.
1. Changed `ios/Runner/Info.plist` after selected Capability.

```
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>voip</string>
</array>
```

### 2. edit Info.plist

- Edit `ios/Runner/Info.plist` as below.

```
<key>FIVKIconName</key>
<string>AppIcon-VoIPKit</string>
<key>FIVKLocalizedName</key>
<string>VoIP-Kit</string>
<key>FIVKSupportVideo</key>
<true/>
<key>FIVKSkipRecallScreen</key>
<true/>
```

### 3. add New Image set for CallKit

- Add an icon（.png or .pdf） `ios/Runner/Assets.xcassets/AppIcon-VoIPKit` to use on the screen when a call comes in while locked iPhone.

### 4. create VoIP Services Certificate

- Visit the Apple Developer https://developer.apple.com/certificates and create a new VoIP Services Certificate.
- [Check Voice Over IP (VoIP) Best Practices Figure 11-2 for more information](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html).

### 5. request VoIP notification APNs from your server

- See Apple document.
- https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns
- add data(payload) like a below.

```
{
    "aps": {
        "alert": {
          "rtc_channel_id": <WebRTC service provides stream channel id>,
          "incoming_caller_id": <your service user id>,
          "incoming_caller_name": <your service user name>,
        }
    }
}
```


## Try out example app

- It is possible to try the example app with some features without a server.
- [There is also a example that can confirm the operation of flutter_ios_voip_kit using SkyWay](https://github.com/masashi-sutou/flutter_ios_webrtc_kit)

Select call role | 🤙 Caller page | 🔔 Callee page
:-: | :-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87527220-c5a57280-c6c6-11ea-9357-434d13617e77.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87527233-c9d19000-c6c6-11ea-8bad-892cb1763189.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87527237-cb02bd00-c6c6-11ea-9eb6-0120e3bd800e.png width=180/>

🔔 Callee(incoming call) | 🔔 Callee(incoming call locked) | 🔔 Callee(recall)
:-: | :-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87534922-a829d600-c6d1-11ea-8190-19441e6bec69.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87535275-30a87680-c6d2-11ea-8d1e-8bf85c56f356.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87549570-f4ccdb80-c6e8-11ea-95cc-179c2b633464.png width=180/>

🔔 Callee(unanswered local notification) | 🔔 Callee(unanswered local notification)
:-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87621935-ed471a00-c75c-11ea-988c-d4e3bbac798e.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87621936-ee784700-c75c-11ea-8260-9a290a0b62ec.png width=180/>


## Q&A

### Does CallKit have a call and outgoing call screen?

- No. CallKit support incoming call screen only. You need to make your own a call and outgoing call screens.

### Can I use remote push device token instead of VoIP device token?

- No. Since the specifications of VoIP token and push token are different, it is necessary to manage them separately in your database.

### Can't get VoIP token on iOS13

- Please uninstall the app, restart the terminal and reinstall the app. You can get it after a while.

### Don't receive VoIP notifications

- Please check the following items.
   1. Is the VoIP device token correct?
   1. Did you set your app’s bundle ID with `.voip` to apns-topic?
   1. Did you set `voip` to apns-push-type?
   1. Is the APNs endpoint（Development or Production） correct?
   1. For iOS13, VoIP notifications may not be received if call kit call fails many times. Please uninstall the app, restart the terminal and reinstall the app.

### No icon is displayed on the incoming call screen when locked

- The icon image should be a square with side length of 40 points. The color is ignored. Please design with the difference of alpha.

## Reference

- https://developer.apple.com/documentation/callkit
- https://developer.apple.com/documentation/pushkit
- https://developer.apple.com/documentation/callkit/making_and_receiving_voip_calls_with_callkit
