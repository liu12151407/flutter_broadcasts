import 'package:flutter/material.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BroadcastReceiver _receiver;
  final List<BroadcastMessage> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _receiver = BroadcastReceiver(
      names: <String>[
        "de.kevlatus.flutter_broadcasts_example.demo_action",
        "custom.ios.object.action",
      ],
    );
    _receiver.start();
    _receiver.messages.listen((message) {
      setState(() {
        _receivedMessages.insert(0, message);
      });
    });
  }

  @override
  void dispose() {
    _receiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Broadcasts Full Demo'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    child: Text('Send Simple'),
                    onPressed: () {
                      sendBroadcast(
                        BroadcastMessage(
                          name: "de.kevlatus.flutter_broadcasts_example.demo_action",
                          data: {"type": "simple", "value": 123},
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: Text('Send Android Advanced'),
                    onPressed: () {
                      sendBroadcast(
                        BroadcastMessage(
                          name: "de.kevlatus.flutter_broadcasts_example.demo_action",
                          data: {"type": "advanced"},
                          flags: [
                            AndroidIntentFlags.flagReceiverForeground,
                            AndroidIntentFlags.flagIncludeStoppedPackages,
                          ],
                          categories: ["demo.category"],
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: Text('Send iOS Object'),
                    onPressed: () {
                      sendBroadcast(
                        BroadcastMessage(
                          name: "custom.ios.object.action",
                          iosObject: "my_special_sender",
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedMessages.length,
                itemBuilder: (context, index) {
                  final msg = _receivedMessages[index];
                  return ListTile(
                    isThreeLine: true,
                    title: Text(msg.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Data: ${msg.data}\n"
                      "Flags: ${msg.flags ?? 'None'}, Categories: ${msg.categories ?? 'None'}\n"
                      "iOS Object: ${msg.iosObject ?? 'None'}"
                    ),
                    trailing: Text(
                      "${msg.timestamp?.hour}:${msg.timestamp?.minute}:${msg.timestamp?.second}",
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}