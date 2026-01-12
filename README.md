[![](https://img.shields.io/pub/v/flutter_broadcasts)](https://pub.dev/packages/flutter_broadcasts)

# Flutter Broadcasts

A plugin for sending and receiving broadcasts with Android intents and iOS notifications. The API is inspired by Android's [BroadcastReceivers](https://developer.android.com/reference/android/content/BroadcastReceiver) and uses the [NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter) internally on iOS.

## Usage

### Receiving Broadcasts

To subscribe to broadcasts, create a `BroadcastReceiver` with the names (Actions on Android, Notification Names on iOS) you want to listen to.

```dart
// Simple receiver
BroadcastReceiver receiver = BroadcastReceiver(
  names: <String>[
    "de.kevlatus.broadcast.demo",
    "android.intent.action.BATTERY_CHANGED", // Standard Android action
  ],
);

// Start listening
await receiver.start();

// Listen to the message stream
receiver.messages.listen((BroadcastMessage message) {
  print("Received ${message.name} with data: ${message.data}");
});

// Stop listening when done
await receiver.stop();
```

#### Android Specifics: Categories & Security

On Android, you can also specify categories for filtering and control whether the receiver is exported to other apps.

```dart
BroadcastReceiver receiver = BroadcastReceiver(
  names: ["custom.action"],
  categories: ["custom.category"],
  isExported: false, // Set to true to allow other apps to trigger this receiver
);
```

### Sending Broadcasts

To send a broadcast, use the top-level `sendBroadcast` function.

```dart
await sendBroadcast(
  BroadcastMessage(
    name: "de.kevlatus.broadcast.demo",
    data: {
      "my_key": "my_value",
      "number": 42,
    },
  ),
);
```

#### Android Specifics: Flags & Categories

You can provide Android-specific flags and categories when sending a broadcast.

```dart
await sendBroadcast(
  BroadcastMessage(
    name: "custom.action",
    categories: ["custom.category"],
    flags: [
      AndroidIntentFlags.flagReceiverForeground,
      AndroidIntentFlags.flagIncludeStoppedPackages,
    ],
  ),
);
```

## Features & Implementation Status

| Feature | Android | iOS |
|---------|---------|-----|
| Basic Broadcasts (Names) | ✅ | ✅ |
| Custom Data (Extras/UserInfo) | ✅ | ✅ |
| Timestamping | ✅ | ✅ |
| Intent Categories | ✅ | ❌ |
| Intent Flags | ✅ | ❌ |
| Exported/Private Receivers | ✅ (API 33+) | N/A |
| Recursive Bundle/Map Support | ✅ | ✅ |
| iOS Object Filtering | ❌ | ✅ |
| Android Explicit Broadcasts | ✅ | ❌ |

## Contributions

Contributions are much appreciated. This package is intended to remain a generic wrapper around native broadcast systems.

If you have any ideas for extending this package to other platforms or improving existing ones, feel free to [open a pull request](https://github.com/kevlatus/flutter_broadcasts/pulls) or [raise an issue](https://github.com/kevlatus/flutter_broadcasts/issues).