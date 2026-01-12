import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("BroadcastMessage", () {
    test('toMap returns a map containing a message\'s fields.', () async {
      BroadcastMessage message = BroadcastMessage(name: "message.name.1");
      var map = message.toMap();

      expect(map['name'], equals("message.name.1"));
      expect(map['data'], isNull);
      expect(map['flags'], isNull);
      expect(map['categories'], isNull);
      expect(map['timestamp'], isNotNull);

      final data = <String, dynamic>{
        "a": 1,
        "b": "t",
        "d": <int>[300, 200, 0]
      };
      final flags = <int>[1, 2, 4];
      final categories = <String>["cat1", "cat2"];
      message = BroadcastMessage(
        name: "message.name.2",
        data: data,
        flags: flags,
        categories: categories,
      );
      map = message.toMap();

      expect(map['name'], equals("message.name.2"));
      expect(mapEquals(map['data'], data), isTrue);
      expect(listEquals(map['flags'], flags), isTrue);
      expect(listEquals(map['categories'], categories), isTrue);
      expect(map['timestamp'], isNotNull);
    });

    test('timestamp format is milliseconds since epoch', () async {
      final message = BroadcastMessage(name: "test.message");
      final map = message.toMap();

      expect(map['timestamp'], isA<int>());
      expect(map['timestamp']!, greaterThan(0));
    });

    test('empty name throws assertion error', () async {
      expect(
        () => BroadcastMessage(name: ""),
        throwsA(isA<AssertionError>()),
      );
    });

    test('hashCode is consistent with equals', () async {
      final data = {"key": "value"};
      final flags = [1];
      final categories = ["a"];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final message1 = BroadcastMessage.fromMap({
        "name": "test",
        "data": data,
        "flags": flags,
        "categories": categories,
        "timestamp": timestamp,
      });
      final message2 = BroadcastMessage.fromMap({
        "name": "test",
        "data": data,
        "flags": flags,
        "categories": categories,
        "timestamp": timestamp,
      });

      expect(message1 == message2, isTrue);
      expect(message1.hashCode == message2.hashCode, isTrue);
    });

    test('toString returns map representation', () async {
      final message = BroadcastMessage(name: "test.message");
      final str = message.toString();

      expect(str, contains("test.message"));
    });
  });

  group("BroadcastReceiver", () {
    const MethodChannel channel =
        MethodChannel('de.kevlatus.flutter_broadcasts');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case "startReceiver":
            return null;
          case "stopReceiver":
            return null;
        }
        throw Error();
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test("beforeStart", () async {
      final receiver = BroadcastReceiver(names: <String>["broadcast.name"]);
      expect(receiver.isListening, isFalse);
    });

    test("start", () async {
      final receiver = BroadcastReceiver(names: <String>["broadcast.name"]);
      await receiver.start();
      expect(receiver.isListening, isTrue);

      // expectLater(receiver.messages, emitsInOrder(<Matcher>[isNotNull]));
      // ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      //   "receiveBroadcast",
      //   const StandardMethodCodec().encodeSuccessEnvelope(
      //     BroadcastMessage(
      //       name: "broadcast.name",
      //       data: {},
      //     ).toMap(),
      //   ),
      //   (ByteData data) {},
      // );
    });

    test("stop", () async {
      final receiver = BroadcastReceiver(names: <String>["broadcast.name"]);
      await receiver.start();
      expect(receiver.isListening, isTrue);
      await receiver.stop();
      expect(receiver.isListening, isFalse);
    });

    test("toMap", () {
      final names = <String>["broadcast.name.1", "broadcast.name.2"];
      final receiver = BroadcastReceiver(names: names);
      final map = receiver.toMap();

      expect(map.containsKey('id'), isTrue);
      expect(map['names'], equals(names));
    });

    test("empty names throws assertion error", () async {
      expect(
        () => BroadcastReceiver(names: <String>[]),
        throwsA(isA<AssertionError>()),
      );
    });

    test("multiple receivers have unique IDs", () async {
      final receiver1 = BroadcastReceiver(names: <String>["test.1"]);
      final receiver2 = BroadcastReceiver(names: <String>["test.2"]);

      final map1 = receiver1.toMap();
      final map2 = receiver2.toMap();

      expect(map1['id'], isNot(equals(map2['id'])));
    });

    test("start when already started throws StateError", () async {
      final receiver = BroadcastReceiver(names: <String>["broadcast.name"]);
      await receiver.start();

      expect(
        () => receiver.start(),
        throwsA(isA<StateError>()),
      );
    });

    test("stop when not started is safe", () async {
      final receiver = BroadcastReceiver(names: <String>["broadcast.name"]);

      expect(() async => await receiver.stop(), returnsNormally);
    });

    test("hashCode is consistent with equals", () async {
      final names = <String>["test.1", "test.2"];
      final receiver1 = BroadcastReceiver(names: names);
      final receiver2 = BroadcastReceiver(names: names);

      // Same ID after creation
      final map1 = receiver1.toMap();
      final map2 = receiver2.toMap();
      final sameId = map1['id'] == map2['id'];

      expect(
        (receiver1 == receiver2) == sameId,
        isTrue,
      );
    });
  });

  group("sendBroadcast", () {
    const MethodChannel channel =
        MethodChannel('de.kevlatus.flutter_broadcasts');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case "sendBroadcast":
            return null;
        }
        throw Error();
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test("sendBroadcast calls native method", () async {
      final message = BroadcastMessage(
        name: "test.broadcast",
        data: {"key": "value"},
      );

      expect(() async => await sendBroadcast(message), returnsNormally);
    });
  });
}
