//
//  VoIPCenter.swift
//  flutter_ios_voip_kit
//
//  Created by 須藤将史 on 2020/07/02.
//

import Foundation
import Flutter
import PushKit
import CallKit

extension String {
    internal init(deviceToken: Data) {
        self = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
    }
}

class VoIPCenter: NSObject {

    // MARK: - event channel

    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    private enum EventChannel: String {
        case onDidReceiveIncomingPush
        case onDidAcceptIncomingCall
        case onDidRejectIncomingCall
    }

    // MARK: - PushKit

    private let didUpdateTokenKey = "Did_Update_VoIP_Device_Token"
    private let pushRegistry: PKPushRegistry

    var token: String? {
        if let didUpdateDeviceToken = UserDefaults.standard.data(forKey: didUpdateTokenKey) {
            let token = String(deviceToken: didUpdateDeviceToken)
            print("🎈 VoIP didUpdateDeviceToken: \(token)")
            return token
        }

        guard let cacheDeviceToken = self.pushRegistry.pushToken(for: .voIP) else {
            return nil
        }

        let token = String(deviceToken: cacheDeviceToken)
        print("🎈 VoIP cacheDeviceToken: \(token)")
        return token
    }

    // MARK: - CallKit

    let callKitCenter: CallKitCenter

    init(eventChannel: FlutterEventChannel) {
        self.eventChannel = eventChannel
        self.pushRegistry = PKPushRegistry(queue: .main)
        self.pushRegistry.desiredPushTypes = [.voIP]
        self.callKitCenter = CallKitCenter()
        super.init()
        self.eventChannel.setStreamHandler(self)
        self.pushRegistry.delegate = self
        self.callKitCenter.setup(delegate: self)
    }
}

extension VoIPCenter: PKPushRegistryDelegate {

    // MARK: - PKPushRegistryDelegate

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("🎈 VoIP didUpdate pushCredentials")
        UserDefaults.standard.set(pushCredentials.token, forKey: didUpdateTokenKey)
    }

    // NOTE: iOS11 or more support

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("🎈 VoIP didReceiveIncomingPushWith completion: \(payload.dictionaryPayload)")

        let info = self.parse(payload: payload)
        let callerName = info?["incoming_caller_name"] as! String
        self.callKitCenter.incomingCall(rtcChannelId: info?["rtc_channel_id"] as! String,
                                        callerId: info?["incoming_caller_id"] as! String,
                                        callerName: callerName) { error in
            if let error = error {
                print("❌ reportNewIncomingCall error: \(error.localizedDescription)")
                return
            }
            self.eventSink?(["event": EventChannel.onDidReceiveIncomingPush.rawValue,
                             "payload": info as Any,
                             "incoming_caller_name": callerName])
            completion()
        }
    }

    // NOTE: iOS10 support

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        print("🎈 VoIP didReceiveIncomingPushWith: \(payload.dictionaryPayload)")

        let info = self.parse(payload: payload)
        let callerName = info?["incoming_caller_name"] as! String
        self.callKitCenter.incomingCall(rtcChannelId: info?["rtc_channel_id"] as! String,
                                        callerId: info?["incoming_caller_id"] as! String,
                                        callerName: callerName) { error in
            if let error = error {
                print("❌ reportNewIncomingCall error: \(error.localizedDescription)")
                return
            }
            self.eventSink?(["event": EventChannel.onDidReceiveIncomingPush.rawValue,
                             "incoming_caller_name": callerName])
        }
    }

    private func parse(payload: PKPushPayload) -> [String: Any]? {
        do {
            let data = try JSONSerialization.data(withJSONObject: payload.dictionaryPayload, options: .prettyPrinted)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let aps = json?["aps"] as? [String: Any]
            return aps?["alert"] as? [String: Any]
        } catch let error as NSError {
            print("❌ VoIP parsePayload: \(error.localizedDescription)")
            return nil
        }
    }
}

extension VoIPCenter: CXProviderDelegate {

    // MARK:  - CXProviderDelegate

    public func providerDidReset(_ provider: CXProvider) {
        print("🚫 VoIP providerDidReset")
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("🤙 VoIP CXStartCallAction")
        self.callKitCenter.connectingOutgoingCall()
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("✅ VoIP CXAnswerCallAction")
        self.callKitCenter.answerCallAction = action
        self.eventSink?(["event": EventChannel.onDidAcceptIncomingCall.rawValue,
                         "rtc_channel_id": self.callKitCenter.rtcChannelId as Any,
                         "incoming_caller_id": self.callKitCenter.incomingCallerId as Any])
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("❎ VoIP CXEndCallAction")
        if (self.callKitCenter.isCalleeBeforeAcceptIncomingCall) {
            self.eventSink?(["event": EventChannel.onDidRejectIncomingCall.rawValue,
                             "rtc_channel_id": self.callKitCenter.rtcChannelId as Any,
                             "incoming_caller_id": self.callKitCenter.incomingCallerId as Any])
        }

        self.callKitCenter.disconnected(reason: .remoteEnded)
        action.fulfill()
    }
}

extension VoIPCenter: FlutterStreamHandler {

    // MARK: - FlutterStreamHandler（event channel）

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
