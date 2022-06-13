import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_ios_voip_kit/call_state_type.dart';
import 'package:flutter_ios_voip_kit/channel_type.dart';

import 'notifications_settings.dart';

final MethodChannel _channel = MethodChannel(ChannelType.method.name);

typedef IncomingPush = void Function(Map<String, dynamic> payload);
typedef IncomingAction = void Function(String uuid, String callerId);
typedef OnUpdatePushToken = void Function(String token);
typedef OnAudioSessionStateChanged = void Function(bool active);

class FlutterIOSVoIPKit {
  static FlutterIOSVoIPKit get instance => _getInstance();
  static FlutterIOSVoIPKit? _instance;
  static FlutterIOSVoIPKit _getInstance() {
    if (_instance == null) {
      _instance = FlutterIOSVoIPKit._internal();
    }

    return _instance!;
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

  /// [onDidReceiveIncomingPush] is not called when the app is not running, because app is not yet running when didReceiveIncomingPushWith is called.
  IncomingPush? onDidReceiveIncomingPush;

  /// [onDidAcceptIncomingCall] and [onDidRejectIncomingCall] can be called even if the app is not running.
  /// This is because the app is already running when the incoming call screen is displayed for CallKit.
  /// If not called, make sure the app is calling [onDidAcceptIncomingCall] and [onDidRejectIncomingCall] in the Dart class(ex: main.dart) that is called immediately after the app is launched.
  IncomingAction? onDidAcceptIncomingCall;
  IncomingAction? onDidRejectIncomingCall;
  OnUpdatePushToken? onDidUpdatePushToken;

  OnAudioSessionStateChanged? onAudioSessionStateChanged;

  StreamSubscription<dynamic>? _eventSubscription;

  Future<void> dispose() async {
    print('🎈 dispose');

    await _eventSubscription?.cancel();
  }

  /// method channel

  Future<String?> getVoIPToken() async {
    print('🎈 getVoIPToken');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('getVoIPToken');
  }

  Future<String?> getIncomingCallerName() async {
    print('🎈 getIncomingCallerName');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('getIncomingCallerName');
  }

  Future<String?> startCall({
    required String uuid,
    required String targetName,
  }) async {
    print('🎈 startCall');

    if (Platform.isAndroid) {
      return null;
    }

    return await _channel.invokeMethod('startCall', {
      'uuid': uuid,
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
    required CallStateType callerState,
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
    required String missedCallTitle,
    required String missedCallBody,
  }) async {
    print(
      '🎈 unansweredIncomingCall $skipLocalNotification, $missedCallTitle, $missedCallBody',
    );

    if (Platform.isAndroid) {
      return;
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
      return;
    }

    return await _channel.invokeMethod('callConnected');
  }

  Future<bool> requestAuthLocalNotification() async {
    print('🎈 requestAuthLocalNotification');

    if (Platform.isAndroid) {
      throw PlatformException(code: 'android-not-supported');
    }

    final result = await _channel.invokeMethod('requestAuthLocalNotification');
    return result['granted'];
  }

  Future<NotificationSettings> getLocalNotificationsSettings() async {
    print('🎈 getLocalNotificationsSettings');

    if (Platform.isAndroid) {
      throw PlatformException(code: 'android-not-supported');
    }

    final result = await _channel.invokeMethod('getLocalNotificationsSettings');
    return NotificationSettings.createFromMap(result);
  }

  Future<void> testIncomingCall({
    required String uuid,
    required String callerId,
    required String callerName,
  }) async {
    print('🎈 testIncomingCall: $uuid, $callerId, $callerName');

    final isRelease = const bool.fromEnvironment('dart.vm.product');
    if (Platform.isAndroid || isRelease) {
      return null;
    }

    return await _channel.invokeMethod('testIncomingCall', {
      'uuid': uuid,
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

        onDidReceiveIncomingPush!(
          Map<String, dynamic>.from(map['payload'] as Map),
        );
        break;
      case 'onDidAcceptIncomingCall':
        print('🎈 onDidAcceptIncomingCall($onDidAcceptIncomingCall): $map');

        if (onDidAcceptIncomingCall == null) {
          return;
        }

        onDidAcceptIncomingCall!(
          map['uuid'],
          map['incoming_caller_id'],
        );
        break;
      case 'onDidRejectIncomingCall':
        print('🎈 onDidRejectIncomingCall($onDidRejectIncomingCall): $map');

        if (onDidRejectIncomingCall == null) {
          return;
        }

        onDidRejectIncomingCall!(
          map['uuid'],
          map['incoming_caller_id'],
        );
        break;

      case 'onDidUpdatePushToken':
        final String token = map['token'];
        print('🎈 onDidUpdatePushToken $token');

        if (onDidUpdatePushToken == null) {
          return;
        }

        onDidUpdatePushToken!(token);
        break;
      case 'onDidActivateAudioSession':
        print('🎈 onDidActivateAudioSession');
        if (onAudioSessionStateChanged != null)
          onAudioSessionStateChanged!(true);
        break;
      case 'onDidDeactivateAudioSession':
        print('🎈 onDidDeactivateAudioSession');
        if (onAudioSessionStateChanged != null)
          onAudioSessionStateChanged!(false);
        break;
    }
  }

  void _errorListener(Object obj) {
    print('🎈 onError: $obj');
  }
}
