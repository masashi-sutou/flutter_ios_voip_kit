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

- Visit the Apple Developer https://developer.apple.com/certificates and create a new VoIP Services Certificate(`.cer`). [Check Voice Over IP (VoIP) Best Practices Figure 11-2 for more information](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html).
- Create `.p12` from `.cer` with KeyChainAccess, and `.pem` with openssl.

Create `.p12` from `.cer` with KeyChainAccess |
:-: |
<img src=https://user-images.githubusercontent.com/6649643/88076945-aa9a9d00-cbb5-11ea-9309-5f7f7df8d3b5.png width=520/> |

```
openssl pkcs12 -in voip_services.p12 -out voip_services.pem -nodes -clcerts
```
> If you're running OpenSSL version 3 or later, please note that you may need to include the "-legacy" option.
> ```
> openssl pkcs12 -legacy -in voip_services.p12 -out voip_services.pem -nodes -clcerts
> ```

### 5. request VoIP notification APNs from your server

- See Apple document.
- https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns
- Add data(payload) like a below.

```
{
    "aps": {
        "alert": {
          "uuid": <Version 4 UUID (e.g.: https://www.uuidgenerator.net/version4) >,
          "incoming_caller_id": <your service user id>,
          "incoming_caller_name": <your service user name>,
        }
    }
}
```

- You can use curl to test VoIP notifications as follows.

```
curl -v \
-d '{"aps":{"alert":{"uuid":"982cf533-7b1b-4cf6-a6e0-004aab68c503","incoming_caller_id":"0123456789","incoming_caller_name":"Tester"}}}' \
-H "apns-push-type: voip" \
-H "apns-expiration: 0" \
-H "apns-priority: 0" \
-H "apns-topic: <your app’s bundle ID>.voip" \
--http2 \
--cert ./voip_services.pem \
https://api.sandbox.push.apple.com/3/device/<VoIP device Token for your iPhone>
```

## Try out example app

- It is possible to try the example app with some features without a server.
- [There is also a example that can confirm the operation of flutter_ios_voip_kit using SkyWay](https://github.com/masashi-sutou/flutter_ios_webrtc_kit)

Select call role | 🤙 Caller page | 🔔 Callee page
:-: | :-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87527220-c5a57280-c6c6-11ea-9357-434d13617e77.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87527233-c9d19000-c6c6-11ea-8bad-892cb1763189.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87527237-cb02bd00-c6c6-11ea-9eb6-0120e3bd800e.png width=180/>

🔔 Callee(incoming call) | 🔔 Callee(locked) | 🔔 Callee(locked) | 🔔 Callee(recall)
:-: | :-: | :-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/87534922-a829d600-c6d1-11ea-8190-19441e6bec69.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/88077993-df5b2400-cbb6-11ea-8730-d7c28def7366.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/88077978-db2f0680-cbb6-11ea-8777-9f1e59cee987.png width=180/> | <img src=https://user-images.githubusercontent.com/6649643/87549570-f4ccdb80-c6e8-11ea-95cc-179c2b633464.png width=180/>

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
- If created in PDF, checked `Preserve Vector Data` for Resizing and change `Single Scale` for Scales.

create icon (e.g.: sketch) | Xcode Image Set
:-: | :-:
<img src=https://user-images.githubusercontent.com/6649643/88074708-b8025800-cbb2-11ea-9a69-3365766ff3f4.png width=320/> | <img src=https://user-images.githubusercontent.com/6649643/88073817-9785ce00-cbb1-11ea-8a62-8b68276d9209.png width=560/>

## Reference

- https://developer.apple.com/documentation/callkit
- https://developer.apple.com/documentation/pushkit
- https://developer.apple.com/documentation/callkit/making_and_receiving_voip_calls_with_callkit
