# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter plugin for sending and receiving broadcasts using Android Intents and iOS NotificationCenter. The API mimics Android's BroadcastReceiver pattern.

**Current Status**: Android implementation is complete; iOS is not yet implemented (see README.md Roadmap).

## Common Commands

```bash
# Run tests
flutter test

# Install dependencies
flutter pub get

# Run example app
cd example && flutter run
```

## Architecture

### Part File Structure

The Dart layer uses Dart's `part` directive to organize code across multiple files under a single library:

- `lib/flutter_broadcasts.dart` - Entry point, exports `src/flutter_broadcasts.dart`
- `lib/src/flutter_broadcasts.dart` - Main library file that declares `part` files
- `lib/src/broadcast.dart` - `BroadcastMessage` class and `sendBroadcast()` function
- `lib/src/receiver.dart` - `BroadcastReceiver` class for subscribing to broadcasts
- `lib/src/native_channel.dart` - `_BroadcastChannel` singleton for native communication

**Key pattern**: All `part of 'flutter_broadcasts.dart'` files share the same library scope.

### Native Communication Pattern

The plugin uses a **singleton MethodChannel** pattern to avoid conflicts between identically named channels:

- `_BroadcastChannel` singleton manages all native communication via `de.kevlatus.flutter_broadcasts` channel
- `_listenForBroadcasts()` creates a broadcast stream that listens for `receiveBroadcast` method calls from native
- Each `BroadcastReceiver` gets filtered messages by `_id` from the global stream

### Platform Method Channel Calls

**Dart → Native:**
- `startReceiver`: Start listening for broadcasts (args: `{id, names}`)
- `stopReceiver`: Stop listening (args: `{id, names}`)
- `sendBroadcast`: Send a broadcast (args: `{name, data}`)

**Native → Dart:**
- `receiveBroadcast`: Deliver received broadcast to Flutter layer

### Android Implementation

File: `android/src/main/kotlin/de/kevlatus/flutter_broadcasts/FlutterBroadcastsPlugin.kt`

Key classes:
- `CustomBroadcastReceiver` - Wraps Android's BroadcastReceiver, registers with IntentFilter
- `BroadcastManager` - Manages receiver lifecycle and maintains receiver map
- `MethodCallHandlerImpl` - Handles method calls from Flutter via MethodChannel
- `FlutterBroadcastsPlugin` - FlutterPlugin entry point, initializes components

**Data normalization**: The `normalize()` function (line 224) converts Android types to Flutter-compatible StandardMessageCodec types.

### iOS Implementation

Status: **Not implemented** (placeholder files only in `ios/Classes/`)

## Development Notes

- **Receiver IDs**: Auto-incrementing static `BroadcastReceiver._index` generates unique IDs
- **Broadcast Streams**: Uses `StreamController.broadcast()` for multiple listeners
- **Error handling**: Native methods return `null` on success, or error `String` on failure (wrapped in `FlutterError`)
- **Timestamp handling**: Outgoing messages get send timestamp; incoming messages get receive timestamp (see `BroadcastMessage.timestamp` docs)
