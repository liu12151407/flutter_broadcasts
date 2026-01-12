part of 'flutter_broadcasts.dart';

/// A message, which is sent by or to the native broadcast system.
///
/// It must have a [name] and may optionally contain a [Map] of user-provided
/// [data].
class BroadcastMessage {
  /// The [BroadcastReceiver._id] of the [BroadcastReceiver], which is
  /// subscribing to messages of this type.
  final int? _receiverId;

  /// A name, which specifies the type of this message.
  ///
  /// On Android, the [name] is retrieved from [Intent.getAction](https://developer.android.com/reference/android/content/Intent#getAction())
  /// and subscribed to using [IntentFilter.addAction](https://developer.android.com/reference/android/content/IntentFilter#addAction(java.lang.String)).
  ///
  /// On iOS, the [name] is retrieved from [NSNotification.name](https://developer.apple.com/documentation/foundation/nsnotification/1416472-name)
  /// and subscribed to using [NotificationCenter.addObserver](https://developer.apple.com/documentation/foundation/notificationcenter/1411723-addobserver).
  final String name;

  /// Optional user-provided data for this message.
  ///
  /// On Android, [data] is retrieved from [Intent.getExtras](https://developer.android.com/reference/android/content/Intent#getExtras())
  /// and sent using [Intent.putExtra](https://developer.android.com/reference/android/content/Intent#putExtra(java.lang.String,%20android.os.Parcelable)).
  ///
  /// On iOS, [data] is retrieved from [NSNotification.userInfo](https://developer.apple.com/documentation/foundation/nsnotification/1409222-userinfo)
  /// and sent using the same property.
  final Map<String, dynamic>? data;

  /// Optional flags for the message.
  ///
  /// Currently only supported on Android.
  /// See [Intent.setFlags](https://developer.android.com/reference/android/content/Intent#setFlags(int)).
  final List<int>? flags;

  /// Optional categories for the message.
  ///
  /// Currently only supported on Android.
  /// See [Intent.addCategory](https://developer.android.com/reference/android/content/Intent#addCategory(java.lang.String)).
  final List<String>? categories;

  /// The timestamp when this message was sent or retrieved.
  ///
  /// For incoming messages from a [BroadcastReceiver], this corresponds to the
  /// time at which a message was received.
  ///
  /// For outgoing messages, this is set during [sendBroadcast]. If the
  /// receiver of the sent message also uses this package, the _send_ timestamp
  /// is available in [data] and the _receive_ timestamp is set to this
  /// field.
  ///
  /// The reason for this is that neither Android, nor iOS provide a
  /// standardized way for message timestamps. Therefore, the described logic
  /// tries its best to record consistent timestamps. If you rely on this
  /// information, you should also check the docs for the messages you receive
  /// for hints about timestamps.
  final DateTime? timestamp;

  /// Creates a new [BroadcastMessage], which can be sent using [sendBroadcast].
  BroadcastMessage({
    required this.name,
    this.data,
    this.flags,
    this.categories,
  })  : assert(name.isNotEmpty, 'BroadcastMessage name cannot be empty'),
        timestamp = DateTime.now(),
        _receiverId = null;

  BroadcastMessage.fromMap(Map<dynamic, dynamic> map)
      : _receiverId = map['receiverId'] as int?,
        name = map['name'] as String? ?? '',
        data = map['data'] != null
            ? Map<String, dynamic>.from(map['data'] as Map)
            : null,
        flags = map['flags'] != null ? List<int>.from(map['flags'] as List) : null,
        categories = map['categories'] != null
            ? List<String>.from(map['categories'] as List)
            : null,
        timestamp = map.containsKey('timestamp') && map['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
            : null {
    if (name.isEmpty) {
      throw ArgumentError('BroadcastMessage name cannot be empty');
    }
  }

  /// Creates a [Map] containing all information about this message.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'receiverId': _receiverId,
        'name': name,
        'data': data,
        'flags': flags,
        'categories': categories,
        'timestamp': timestamp?.millisecondsSinceEpoch,
      };

  @override
  String toString() {
    return toMap().toString();
  }

  @override
  int get hashCode => Object.hash(
        _receiverId,
        name,
        data != null
            ? Object.hashAllUnordered(
                data!.entries.map((e) => Object.hash(e.key, e.value)))
            : null,
        flags != null ? Object.hashAll(flags!) : null,
        categories != null ? Object.hashAll(categories!) : null,
        timestamp,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BroadcastMessage &&
            _receiverId == other._receiverId &&
            name == other.name &&
            mapEquals(data, other.data) &&
            listEquals(flags, other.flags) &&
            listEquals(categories, other.categories) &&
            timestamp == other.timestamp;
  }
}

Future<void> sendBroadcast(BroadcastMessage message) {
  return _BroadcastChannel.instance.sendBroadcast(message);
}
