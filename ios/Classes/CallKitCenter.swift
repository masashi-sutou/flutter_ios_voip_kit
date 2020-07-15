//
//  CallKitCenter.swift
//  flutter_ios_voip_kit
//
//  Created by 須藤将史 on 2020/07/02.
//

import Foundation
import CallKit
import UIKit

class CallKitCenter: NSObject {

    private let controller = CXCallController()
    private let iconName: String
    private let localizedName: String
    private let supportVideo: Bool
    private let skipRecallScreen: Bool
    private var provider: CXProvider?
    private var uuid = UUID()
    private(set) var rtcChannelId: String?
    private(set) var incomingCallerId: String?
    private(set) var incomingCallerName: String?
    var answerCallAction: CXAnswerCallAction?

    override init() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let plist = NSDictionary(contentsOfFile: path)
            self.iconName = plist?["FIVKIconName"] as? String ?? "AppIcon-VoIPKit"
            self.localizedName = plist?["FIVKLocalizedName"] as? String ?? "App Name"
            self.supportVideo = plist?["FIVKSupportVideo"] as? Bool ?? false
            self.skipRecallScreen = plist?["FIVKSkipRecallScreen"] as? Bool ?? false
        } else {
            self.iconName = "AppIcon-VoIPKit"
            self.localizedName = "App Name"
            self.supportVideo = false
            self.skipRecallScreen = false
        }
        super.init()
    }

    func startCall(rtcChannelId: String, targetName: String) {
        self.uuid = UUID(uuidString: rtcChannelId)!
        let handle = CXHandle(type: .generic, value: targetName)
        let startCallAction = CXStartCallAction(call: self.uuid, handle: handle)
        startCallAction.isVideo = self.supportVideo
        let transaction = CXTransaction(action: startCallAction)
        self.controller.request(transaction) { error in
            if let error = error {
                print("❌ CXStartCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func setup(delegate: CXProviderDelegate) {
        let providerConfiguration = CXProviderConfiguration(localizedName: self.localizedName)
        providerConfiguration.supportsVideo = self.supportVideo
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 2
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: self.iconName)?.pngData()
        self.provider = CXProvider(configuration: providerConfiguration)
        self.provider?.setDelegate(delegate, queue: nil)
    }

    func incomingCall(rtcChannelId: String, callerId: String, callerName: String, completion: @escaping (Error?) -> Void) {
        self.rtcChannelId = rtcChannelId
        self.incomingCallerId = callerId
        self.incomingCallerName = callerName

        self.uuid = UUID(uuidString: rtcChannelId)!
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.hasVideo = self.supportVideo
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = true
        self.provider?.reportNewIncomingCall(with: self.uuid, update: update, completion: completion)
    }

    func acceptIncomingCall(alreadyEndCallerReason: CXCallEndedReason?) {
        guard alreadyEndCallerReason == nil else {
            self.skipRecallScreen ? self.answerCallAction?.fulfill() : self.answerCallAction?.fail()
            self.answerCallAction = nil
            return
        }

        self.answerCallAction?.fulfill()
        self.answerCallAction = nil
        self.connected()
    }

    func unansweredIncomingCall() {
        self.rtcChannelId = nil
        self.incomingCallerId = nil
        self.incomingCallerName = nil
        self.answerCallAction = nil

        self.disconnected(reason: .unanswered)
    }

    func endCall() {
        self.rtcChannelId = nil
        self.incomingCallerId = nil
        self.incomingCallerName = nil
        self.answerCallAction = nil

        self.disconnected(reason: .remoteEnded)
    }

    func connecting() {
        self.provider?.reportOutgoingCall(with: self.uuid, startedConnectingAt: nil)
    }

    private func connected() {
        self.provider?.reportOutgoingCall(with: self.uuid, connectedAt: nil)
    }

    func disconnected(reason: CXCallEndedReason) {
        self.provider?.reportCall(with: self.uuid, endedAt: nil, reason: reason)
    }
}
