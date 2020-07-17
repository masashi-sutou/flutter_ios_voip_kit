import Flutter
import UIKit
import UserNotifications

public class SwiftFlutterIOSVoIPKitPlugin: NSObject {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: FlutterPluginChannelType.method.name,  binaryMessenger: registrar.messenger())
        let plugin = SwiftFlutterIOSVoIPKitPlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }

    init(messenger: FlutterBinaryMessenger) {
        self.voIPCenter = VoIPCenter(eventChannel: FlutterEventChannel(name: FlutterPluginChannelType.event.name, binaryMessenger: messenger))
        super.init()
        self.notificationCenter.delegate = self
    }

    // MARK: - VoIPCenter

    private let voIPCenter: VoIPCenter

    // MARK: - Local Notification

    private let notificationCenter = UNUserNotificationCenter.current()
    private let options: UNAuthorizationOptions = [.alert]

    // MARK: - method channel

    private func getVoIPToken(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(self.voIPCenter.token)
    }

    private func getIncomingCallerName(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(self.voIPCenter.callKitCenter.incomingCallerName)
    }

    private func startCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let rtcChannelId = args["rtcChannelId"] as? String,
            let targetName = args["targetName"] as? String else {
                result(FlutterError(code: "InvalidArguments startCall", message: nil, details: nil))
                return
        }
        self.voIPCenter.callKitCenter.startCall(rtcChannelId: rtcChannelId, targetName: targetName)
        result(nil)
    }

    private func endCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.voIPCenter.callKitCenter.endCall()
        result(nil)
    }

    private func acceptIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let callerState = args["callerState"] as? String else {
                result(FlutterError(code: "InvalidArguments acceptIncomingCall", message: nil, details: nil))
                return
        }
        self.voIPCenter.callKitCenter.acceptIncomingCall(alreadyEndCallerReason: callerState == "calling" ? nil : .failed)
        result(nil)
    }

    private func unansweredIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let skipLocalNotification = args["skipLocalNotification"] as? Bool else {
                result(FlutterError(code: "InvalidArguments unansweredIncomingCall", message: nil, details: nil))
                return
        }

        self.voIPCenter.callKitCenter.unansweredIncomingCall()

        if (skipLocalNotification) {
            result(nil)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = args["missedCallTitle"] as? String ?? "Missed Call"
        content.body = args["missedCallBody"] as? String ?? "There was a call"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2,
                                                        repeats: false)
        let request = UNNotificationRequest(identifier: "unansweredIncomingCall",
                                            content: content,
                                            trigger: trigger)
        self.notificationCenter.add(request) { (error) in
            if let error = error {
                print("❌ unansweredIncomingCall local notification error: \(error.localizedDescription)")
            }
        }

        result(nil)
    }

    private func callConnected(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.voIPCenter.callKitCenter.callConnected()
        result(nil)
    }

    public func requestAuthLocalNotification(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.notificationCenter.requestAuthorization(options: self.options) { (_, _) in }
        result(nil)
    }

    private func testIncomingCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let rtcChannelId = args["rtcChannelId"] as? String,
            let callerId = args["callerId"] as? String,
            let callerName = args["callerName"] as? String else {
                result(FlutterError(code: "InvalidArguments testIncomingCall", message: nil, details: nil))
                return
        }

        self.voIPCenter.callKitCenter.incomingCall(rtcChannelId: rtcChannelId,
                                                   callerId: callerId,
                                                   callerName: callerName) { (error) in
            if let error = error {
                print("❌ testIncomingCall error: \(error.localizedDescription)")
                result(FlutterError(code: "testIncomingCall",
                                    message: error.localizedDescription,
                                    details: nil))
                return
            }
            result(nil)
        }
    }
}

extension SwiftFlutterIOSVoIPKitPlugin: UNUserNotificationCenterDelegate {

    // MARK: - Local Notification

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // notify when foreground
        completionHandler([.alert])
    }
}

extension SwiftFlutterIOSVoIPKitPlugin: FlutterPlugin {

    private enum MethodChannel: String {
        case getVoIPToken
        case getIncomingCallerName
        case startCall
        case endCall
        case acceptIncomingCall
        case unansweredIncomingCall
        case callConnected
        case requestAuthLocalNotification
        case testIncomingCall
    }

    // MARK: - FlutterPlugin（method channel）

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = MethodChannel(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        switch method {
            case .getVoIPToken:
                self.getVoIPToken(call, result: result)
            case .getIncomingCallerName:
                self.getIncomingCallerName(call, result: result)
            case .startCall:
                self.startCall(call, result: result)
            case .endCall:
                self.endCall(call, result: result)
            case .acceptIncomingCall:
                self.acceptIncomingCall(call, result: result)
            case .unansweredIncomingCall:
                self.unansweredIncomingCall(call, result: result)
            case .callConnected:
                self.callConnected(call, result: result)
            case .requestAuthLocalNotification:
                self.requestAuthLocalNotification(call, result: result)
            case .testIncomingCall:
                self.testIncomingCall(call, result: result)
        }
    }
}
