## 0.1.0

* PR(#45)
  * migrate plugin to flutter 2 with null-safety

## 0.0.5

* PR(#19)
  * added ability to configure `FIVKMaximumCallGroups(maximumCallGroups)` setting using Info.plist.
  * added return value to `requestAuthLocalNotification` function.
  * added `getLocalNotificationsSettings` function which returns NotificationSettings object.
  * added `onDidUpdatePushToken` callback.
    * It may be used if you want to increase robustness of your application (sometimes iOS can change this token, so its good to know about this).

## 0.0.4+1

* fix example app

## 0.0.4

* rename `rtc_channel_id` to `uuid`.
* update document how to post VoIP notification with curl.
* update document how to create icon for CallKit.

## 0.0.3+1

* added doc comment to callback events.

## 0.0.3

* fix onDidRejectIncomingCall be called after call connected
* rename reportOutgoingCall to avoid misunderstanding

## 0.0.2

* fix error start call action
* update README.md

## 0.0.1+3

* fix EndCal and example app

## 0.0.1+2

* fix example app

## 0.0.1+1

* update README.md

## 0.0.1

* Initial release
