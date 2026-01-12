part of 'flutter_broadcasts.dart';

/// Common Android Intent flags for use with [BroadcastMessage.flags].
///
/// See [Android Intent documentation](https://developer.android.com/reference/android/content/Intent)
/// for more details.
abstract class AndroidIntentFlags {
  /// If set, when sending a broadcast only registered receivers will be called -- no BroadcastReceiver components will be launched.
  static const int flagReceiverRegisteredOnly = 0x40000000;

  /// If set, when this broadcast is being delivered that is already in-flight, the new broadcast will be allowed to replace the current one.
  static const int flagReceiverReplacePending = 0x20000000;

  /// If set, when this broadcast is being delivered, it will be allowed to run at a higher priority with a shorter timeout.
  static const int flagReceiverForeground = 0x10000000;

  /// If this is a ordered broadcast, the receivers are not allowed to abort the broadcast.
  static const int flagReceiverNoAbort = 0x08000000;

  /// If set, the broadcast will be visible to receivers in Instant Apps.
  static const int flagReceiverVisibleToInstantApps = 0x00200000;

  /// If set, the broadcast will be delivered to receivers in stopped packages.
  static const int flagIncludeStoppedPackages = 0x00000020;

  /// If set, the broadcast will not be delivered to receivers in stopped packages.
  static const int flagExcludeStoppedPackages = 0x00000010;
}
