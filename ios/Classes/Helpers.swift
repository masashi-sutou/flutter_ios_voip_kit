//
//  Helpers.swift
//  flutter_ios_voip_kit
//
//  Created by Aleksey Goncharov on 15.10.2020.
//

import Foundation
import UserNotifications

extension Data {
    var hexString: String {
        map { String(format: "%02.2hhx", $0) }.joined()
    }
}

extension UNNotificationSettings {
    func toMap() -> [String: Int] {
        var result = [
            "authorizationStatus": authorizationStatus.rawValue,
            "soundSetting": soundSetting.rawValue,
            "badgeSetting": badgeSetting.rawValue,
            "alertSetting": alertSetting.rawValue,
            "notificationCenterSetting": notificationCenterSetting.rawValue,
            "lockScreenSetting": lockScreenSetting.rawValue,
            "carPlaySetting": carPlaySetting.rawValue,
            "alertStyle": alertStyle.rawValue,
        ]

        if #available(iOS 11.0, *) { result["showPreviewsSetting"] = showPreviewsSetting.rawValue }
        if #available(iOS 12.0, *) {
            result["criticalAlertSetting"] = criticalAlertSetting.rawValue
            result["providesAppNotificationSettings"] = providesAppNotificationSettings ? 1 : 0
        }
        if #available(iOS 13.0, *) { result["announcementSetting"] = announcementSetting.rawValue }

        return result
    }
}
