import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ios_voip_kit/call_state_type.dart';
import 'package:flutter_ios_voip_kit/channel_type.dart';

final MethodChannel _channel = MethodChannel(ChannelType.method.name);

typedef IncomingPush = void Function(
  Map<String, dynamic> payload,
);

typedef IncomingAction = void Function(
  String channelId,
  String callerId,
);

class FlutterIOSVoIPKit {
  static FlutterIOSVoIPKit get instance => _getInstance();
  static FlutterIOSVoIPKit _instance;
  static FlutterIOSVoIPKit _getInstance() {
    if (_instance == null) {
      _instance = FlutterIOSVoIPKit._internal();
    }
    return _instance;
  }

  factory FlutterIOSVoIPKit() => _getInstance();

  FlutterIOSVoIPKit._internal() {
    if (Platform.isAndroid) {
      return;
    }

    _eventSubscription = EventChannel(ChannelType.event.name)
        .receiveBroadcastStream()
        .listen(_eventListener, onError: _errorListener);
  }

  IncomingPush onDidReceiveIncomingPush;
  IncomingAction onDidAcceptIncomingCall;
  IncomingAction onDidRejectIncomingCall;
  StreamSubscription<dynamic> _eventSubscription;

  Future<void> dispose() async {
    print('🎈 dispose');

    await _eventSubscription?.cancel();
  }

  /// method channel

  Future<String> getVoIPToken() async {
    print('🎈 getVoIPToken');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('getVoIPToken');
  }

  Future<String> getIncomingCallerName() async {
    print('🎈 getIncomingCallerName');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('getIncomingCallerName');
  }

  Future<void> startCall({
    @required String rtcChannelId,
    @required String targetName,
  }) async {
    print('🎈 startCall');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('startCall', {
      'rtcChannelId': rtcChannelId,
      'targetName': targetName,
    });
  }

  Future<void> endCall() async {
    print('🎈 endCall');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('endCall');
  }

  Future<void> acceptIncomingCall({
    @required CallStateType callerState,
  }) async {
    print('🎈 acceptIncomingCall');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('acceptIncomingCall', {
      'callerState': callerState.value,
    });
  }

  Future<void> unansweredIncomingCall({
    bool skipLocalNotification = false,
    @required String missedCallTitle,
    @required String missedCallBody,
  }) async {
    print(
      '🎈 unansweredIncomingCall $skipLocalNotification, $missedCallTitle, $missedCallBody',
    );

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('unansweredIncomingCall', {
      'skipLocalNotification': skipLocalNotification,
      'missedCallTitle': missedCallTitle,
      'missedCallBody': missedCallBody,
    });
  }

  Future<void> callConnected() async {
    print('🎈 callConnected');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('callConnected');
  }

  Future<void> requestAuthLocalNotification() async {
    print('🎈 requestAuthLocalNotification');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('requestAuthLocalNotification');
  }

  Future<void> testIncomingCall({
    @required String rtcChannelId,
    @required String callerId,
    @required String callerName,
  }) async {
    print('🎈 testIncomingCall: $rtcChannelId, $callerId, $callerName');

    final isRelease = const bool.fromEnvironment('dart.vm.product');
    if (Platform.isAndroid || isRelease) {
      return null;
    }

    return await _channel.invokeMethod('testIncomingCall', {
      'rtcChannelId': rtcChannelId,
      'callerId': callerId,
      'callerName': callerName,
    });
  }

  /// event channel

  void _eventListener(dynamic event) {
    print('🎈 _eventListener');

    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'onDidReceiveIncomingPush':
        print('🎈 onDidReceiveIncomingPush($onDidReceiveIncomingPush): $map');

        if (onDidReceiveIncomingPush == null) {
          return;
        }

        onDidReceiveIncomingPush(
          Map<String, dynamic>.from(map['payload'] as Map),
        );
        break;
      case 'onDidAcceptIncomingCall':
        print('🎈 onDidAcceptIncomingCall($onDidAcceptIncomingCall): $map');

        if (onDidAcceptIncomingCall == null) {
          return;
        }

        onDidAcceptIncomingCall(
          map['rtc_channel_id'],
          map['incoming_caller_id'],
        );
        break;
      case 'onDidRejectIncomingCall':
        print('🎈 onDidRejectIncomingCall($onDidRejectIncomingCall): $map');

        if (onDidRejectIncomingCall == null) {
          return;
        }

        onDidRejectIncomingCall(
          map['rtc_channel_id'],
          map['incoming_caller_id'],
        );
        break;
    }
  }

  void _errorListener(Object obj) {
    print('🎈 onError: $obj');
  }
}
