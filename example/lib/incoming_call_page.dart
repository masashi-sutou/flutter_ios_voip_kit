import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ios_voip_kit/call_state_type.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';
import 'package:uuid/uuid.dart';

class IncomingCallPage extends StatefulWidget {
  static const routeName = '/incoming_call_page';

  @override
  _IncomingCallPageState createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  final voIPKit = FlutterIOSVoIPKit.instance;
  var dummyCallId = '123456';
  var dummyCallerName = 'Dummy Tester';
  Timer timeOutTimer;
  bool isTalking = false;

  @override
  void initState() {
    super.initState();

    voIPKit.onDidReceiveIncomingPush = (
      Map<String, dynamic> payload,
    ) async {
      // NOTE: Notifies device of VoIP notifications(PushKit) if there is a server to post to APNs.
      print('🎈 example: onDidReceiveIncomingPush $payload');
      _timeOut();
    };

    voIPKit.onDidRejectIncomingCall = (
      String channelId,
      String callerId,
    ) {
      if (isTalking) {
        return;
      }

      print('🎈 example: onDidRejectIncomingCall $channelId, $callerId');
      voIPKit.endCall();
      timeOutTimer?.cancel();

      setState(() {
        isTalking = false;
      });
    };

    voIPKit.onDidAcceptIncomingCall = (
      String channelId,
      String callerId,
    ) {
      if (isTalking) {
        return;
      }

      print('🎈 example: onDidAcceptIncomingCall $channelId, $callerId');
      voIPKit.acceptIncomingCall(callerState: CallStateType.calling);
      voIPKit.callConnected();
      timeOutTimer?.cancel();

      setState(() {
        isTalking = true;
      });
    };

    _showRequestAuthLocalNotification();
  }

  @override
  void dispose() {
    timeOutTimer?.cancel();
    voIPKit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Your Callee'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Center(
            child: isTalking
                ? const Text(
                    '🗣📞 Talking to ths caller\'s device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      FutureBuilder<String>(
                        future: voIPKit.getVoIPToken(),
                        builder: (context, snapshot) {
                          return GestureDetector(
                            onLongPress: () async {
                              if (!snapshot.hasData) {
                                return;
                              }

                              final data = ClipboardData(text: snapshot.data);
                              await Clipboard.setData(data);
                              Scaffold.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Copy to VoIP device Token for APNs',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              '📱 VoIP device Token\n（👇 long press to copy, and notify VoIP notification to callee device from your server）\n ${snapshot.hasData ? snapshot.data : '...'}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const Text(
                        '👇 Tap to show incoming call screen if there is not a server to post to APNs.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isTalking
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.cancel),
              label: const Text(
                'End call',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.red,
              onPressed: () async {
                await voIPKit.endCall();
                setState(() {
                  isTalking = false;
                });
              },
            )
          : FloatingActionButton.extended(
              icon: const Icon(Icons.ring_volume),
              label: const Text(
                'Incoming Call',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.blue,
              onPressed: () async {
                await voIPKit.testIncomingCall(
                  rtcChannelId: Uuid().v4(),
                  callerId: dummyCallId,
                  callerName: dummyCallerName,
                );
                _timeOut();
              },
            ),
    );
  }

  // NOTE: TimeOut (unansweredIncomingCall) when local notification

  void _showRequestAuthLocalNotification() async {
    await voIPKit.requestAuthLocalNotification();
  }

  void _timeOut({
    int seconds = 15,
  }) async {
    timeOutTimer = Timer(Duration(seconds: seconds), () async {
      print('🎈 example: timeOut');
      final incomingCallerName = await voIPKit.getIncomingCallerName();
      voIPKit.unansweredIncomingCall(
        skipLocalNotification: false,
        missedCallTitle: '📞 Missed call',
        missedCallBody: 'There was a call from $incomingCallerName',
      );
    });
  }
}
