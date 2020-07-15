import 'package:flutter/material.dart';
import 'package:flutter_ios_voip_kit_example/incoming_call_page.dart';
import 'package:flutter_ios_voip_kit_example/outgoing_call_page.dart';

void main() {
  runApp(MaterialApp(
    routes: <String, WidgetBuilder>{
      OutgoingCallPage.routeName: (_) => OutgoingCallPage(),
      IncomingCallPage.routeName: (_) => IncomingCallPage(),
    },
    home: SelectCallRoll(),
  ));
}

class SelectCallRoll extends StatefulWidget {
  @override
  _SelectCallRollState createState() => _SelectCallRollState();
}

class _SelectCallRollState extends State<SelectCallRoll> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select call roll'),
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
