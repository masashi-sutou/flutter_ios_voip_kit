import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ios_voip_kit/flutter_ios_voip_kit.dart';

import 'incoming_call_page.dart';
import 'outgoing_call_page.dart';

enum ExampleAction { RequestAuthorization, GetSettings }

extension on ExampleAction {
  String get title {
    switch (this) {
      case ExampleAction.RequestAuthorization:
        return 'Authorize Notifications';
      case ExampleAction.GetSettings:
        return 'Check Settings';
      default:
        return 'Unknown';
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    FlutterIOSVoIPKit.instance.onDidUpdatePushToken = (token) {
      print('🎈 example: onDidUpdatePushToken token = $token');
    };
    runApp(MaterialApp(
      routes: <String, WidgetBuilder>{
        OutgoingCallPage.routeName: (_) => OutgoingCallPage(),
        IncomingCallPage.routeName: (_) => IncomingCallPage(),
      },
      home: SelectCallRoll(),
    ));
  }, (object, stackTrace) {});
}

class SelectCallRoll extends StatefulWidget {
  @override
  _SelectCallRollState createState() => _SelectCallRollState();
}

class _SelectCallRollState extends State<SelectCallRoll> {
  void _performExampleAction(ExampleAction action) async {
    switch (action) {
      case ExampleAction.RequestAuthorization:
        final granted = await FlutterIOSVoIPKit.instance.requestAuthLocalNotification();
        print('🎈 example: requestAuthLocalNotification granted = $granted');
        break;
      case ExampleAction.GetSettings:
        final settings = await FlutterIOSVoIPKit.instance.getLocalNotificationsSettings();
        print('🎈 example: getLocalNotificationsSettings settings: \n$settings');

        showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text('Settings'),
                content: Text('$settings'),
                actions: [
                  FlatButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Ok'),
                  )
                ],
              );
            });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select call roll'),
        actions: [
          PopupMenuButton<ExampleAction>(
            icon: Icon(Icons.more_vert),
            onSelected: (action) => _performExampleAction(action),
            itemBuilder: (BuildContext context) {
              return ExampleAction.values.map((ExampleAction choice) {
                return PopupMenuItem<ExampleAction>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text(
                  '📱 To try out the example app, you need two iPhones with iOS 10 or later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                _button(isCaller: true),
                _button(isCaller: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _button({
    @required bool isCaller,
  }) {
    return SizedBox(
      width: 140,
      height: 140,
      child: RawMaterialButton(
        padding: EdgeInsets.zero,
        elevation: 8.0,
        shape: CircleBorder(),
        fillColor: Colors.blue,
        onPressed: () {
          Navigator.pushNamed(
            context,
            isCaller ? OutgoingCallPage.routeName : IncomingCallPage.routeName,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(
              isCaller ? Icons.call : Icons.ring_volume,
              size: 32,
            ),
            Text(
              isCaller ? '🤙 Caller' : '🔔 Callee',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
