//
//  FlutterPluginChannelType.swift
//  flutter_ios_voip_kit
//
//  Created by 須藤将史 on 2020/07/02.
//
import Foundation

enum FlutterPluginChannelType {
    case method
    case event

    var name: String {
        switch self {
        case .method:
            return "flutter_ios_voip_kit"
        case .event:
            return "flutter_ios_voip_kit/event"
        }
    }
}
