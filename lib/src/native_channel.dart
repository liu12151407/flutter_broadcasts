part of 'flutter_broadcasts.dart';

/// An internal singleton for managing the communication to the native platform.
///
/// Since identically named [MethodChannel]s interfere with each other, this
/// singleton handles all communication to the platform and forwards messages to
/// the appropriate [BroadcastReceiver].
class _BroadcastChannel {
  static const String _channelName = 'de.kevlatus.flutter_broadcasts';
  static const MethodChannel _channel = MethodChannel(_channelName);
  static _BroadcastChannel instance = _BroadcastChannel();

  final Map<int, StreamController<BroadcastMessage>> _receivers = {};

  _BroadcastChannel() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'receiveBroadcast') {
      final message = BroadcastMessage.fromMap(call.arguments);
      if (message._receiverId != null) {
        _receivers[message._receiverId]?.add(message);
      }
    }
  }

  Future<Stream<BroadcastMessage>> startReceiver(BroadcastReceiver receiver) async {
    _receivers.putIfAbsent(
      receiver._id,
      () => StreamController<BroadcastMessage>.broadcast(),
    );

    try {
      final String? result =
          await _channel.invokeMethod('startReceiver', receiver.toMap());

      if (result != null) {
        throw FlutterError('Failed to start receiver: $result');
      }
    } on PlatformException catch (e) {
      throw FlutterError('Platform error starting receiver: ${e.message}');
    }

    return _receivers[receiver._id]!.stream;
  }

  /// Stops listening on a given [BroadcastReceiver].
  Future<void> stopReceiver(BroadcastReceiver receiver) async {
    try {
      final String? result =
          await _channel.invokeMethod('stopReceiver', receiver.toMap());

      if (result != null) {
        throw FlutterError('Failed to stop receiver: $result');
      }
    } on PlatformException catch (e) {
      throw FlutterError('Platform error stopping receiver: ${e.message}');
    } finally {
      final controller = _receivers.remove(receiver._id);
      await controller?.close();
    }
  }

  /// Sends the given broadcast [message] natively.
  Future<void> sendBroadcast(BroadcastMessage message) async {
    try {
      final String? result = await _channel.invokeMethod(
        "sendBroadcast",
        message.toMap(),
      );

      if (result != null) {
        throw FlutterError('Failed to send broadcast: $result');
      }
    } on PlatformException catch (e) {
      throw FlutterError('Platform error sending broadcast: ${e.message}');
    }
  }
}
