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
    private(set) var uuidString: String?
    private(set) var incomingCallerId: String?
    private(set) var incomingCallerName: String?
    private var isReceivedIncomingCall: Bool = false
    private var isCallConnected: Bool = false
    private var maximumCallGroups: Int = 1
    var answerCallAction: CXAnswerCallAction?

    var isCalleeBeforeAcceptIncomingCall: Bool {
        return self.isReceivedIncomingCall && !self.isCallConnected
    }

    override init() {
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let plist = NSDictionary(contentsOfFile: path)
            self.iconName = plist?["FIVKIconName"] as? String ?? "AppIcon-VoIPKit"
            self.localizedName = plist?["FIVKLocalizedName"] as? String ?? "App Name"
            self.supportVideo = plist?["FIVKSupportVideo"] as? Bool ?? false
            self.skipRecallScreen = plist?["FIVKSkipRecallScreen"] as? Bool ?? false
            self.maximumCallGroups = plist?["FIVKMaximumCallGroups"] as? Int ?? 1
        } else {
            self.iconName = "AppIcon-VoIPKit"
            self.localizedName = "App Name"
            self.supportVideo = false
            self.skipRecallScreen = false
        }
        super.init()
    }

    func setup(delegate: CXProviderDelegate) {
        let providerConfiguration = CXProviderConfiguration(localizedName: self.localizedName)
        providerConfiguration.supportsVideo = self.supportVideo
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = maximumCallGroups
        providerConfiguration.supportedHandleTypes = [.generic]
        providerConfiguration.iconTemplateImageData = UIImage(named: self.iconName)?.pngData()
        self.provider = CXProvider(configuration: providerConfiguration)
        self.provider?.setDelegate(delegate, queue: nil)
    }

    func startCall(uuidString: String, targetName: String) {
        self.uuid = UUID(uuidString: uuidString)!
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

    func incomingCall(uuidString: String, callerId: String, callerName: String, completion: @escaping (Error?) -> Void) {
        self.uuidString = uuidString
        self.incomingCallerId = callerId
        self.incomingCallerName = callerName
        self.isReceivedIncomingCall = true

        self.uuid = UUID(uuidString: uuidString)!
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: callerName)
        update.hasVideo = self.supportVideo
        update.supportsHolding = false
        update.supportsGrouping = false
        update.supportsUngrouping = true
        self.provider?.reportNewIncomingCall(with: self.uuid, update: update, completion: { error in
            if (error == nil) {
                self.connectedOutgoingCall()
            }

            completion(error)
        })
    }

    func acceptIncomingCall(alreadyEndCallerReason: CXCallEndedReason?) {
        guard alreadyEndCallerReason == nil else {
            self.skipRecallScreen ? self.answerCallAction?.fulfill() : self.answerCallAction?.fail()
            self.answerCallAction = nil
            return
        }

        self.answerCallAction?.fulfill()
        self.answerCallAction = nil
    }

    func unansweredIncomingCall() {
        self.disconnected(reason: .unanswered)
    }

    func endCall() {
        let endCallAction = CXEndCallAction(call: self.uuid)
        let transaction = CXTransaction(action: endCallAction)
        self.controller.request(transaction) { error in
            if let error = error {
                print("❌ CXEndCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func callConnected() {
        self.isCallConnected = true
    }

    func connectingOutgoingCall() {
        self.provider?.reportOutgoingCall(with: self.uuid, startedConnectingAt: nil)
    }

    private func connectedOutgoingCall() {
        self.provider?.reportOutgoingCall(with: self.uuid, connectedAt: nil)
    }

    func disconnected(reason: CXCallEndedReason) {
        self.uuidString = nil
        self.incomingCallerId = nil
        self.incomingCallerName = nil
        self.answerCallAction = nil
        self.isReceivedIncomingCall = false
        self.isCallConnected = false

        self.provider?.reportCall(with: self.uuid, endedAt: nil, reason: reason)
    }
}
