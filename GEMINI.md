# Flutter Broadcasts 项目指南

本项目是一个 Flutter 插件，用于在 Android 和 iOS 平台上发送和接收广播消息。它在 Android 上使用 `Intent` 广播，在 iOS 上使用 `NotificationCenter`。

## 项目概述

- **技术栈**: Flutter (Dart), Android (Kotlin), iOS (Swift)。
- **核心功能**: 跨平台订阅和发送系统级或应用级广播。
- **架构设计**: 
  - 使用单例 `MethodChannel` (`de.kevlatus.flutter_broadcasts`) 处理所有原生通信。
  - Dart 层通过 `BroadcastReceiver` 类管理订阅生命周期，每个实例拥有唯一的自增 ID。
  - 原生层负责将收到的广播消息（Intent 或 Notification）标准化后，通过 `MethodChannel` 回传给 Flutter。

## 目录结构

- `lib/`: Dart 核心逻辑。采用了 `part` / `part of` 模式组织代码。
  - `flutter_broadcasts.dart`: 公开 API 入口。
  - `src/native_channel.dart`: 内部单例，处理与原生层的低级通信。
  - `src/receiver.dart`: `BroadcastReceiver` 实现类。
  - `src/broadcast.dart`: `BroadcastMessage` 数据模型。
- `android/`: Android 原生实现。
  - `FlutterBroadcastsPlugin.kt`: 处理广播注册、注销和发送。
- `ios/`: iOS 原生实现。
  - `SwiftFlutterBroadcastsPlugin.swift`: 使用 `NotificationCenter` 监听和发布通知。
- `example/`: 插件使用示例应用。
- `test/`: 单元测试。

## 开发与运行

### 环境准备
- Flutter SDK
- Android SDK & Xcode (用于原生开发)

### 常用命令
- **安装依赖**: `flutter pub get`
- **运行测试**: `flutter test`
- **运行示例**: `cd example && flutter run`
- **分析代码**: `flutter analyze`

## 开发规范

### Dart 开发
- **代码组织**: 保持 `part` 文件的结构，避免直接在 `src/` 下创建独立的 library 文件。
- **消息标准化**: 所有通过通道传递的数据应在原生层进行标准化，以符合 `StandardMessageCodec` 的要求。

### 原生开发
- **Android**: 注意广播接收器的注册和解绑，防止内存泄漏。
- **iOS**: 使用 `NotificationObserverManager` 管理观察者，确保在插件销毁或接收器停止时正确移除监听。

### 类型转换
- **Timestamp**: 发送和接收时均包含毫秒级时间戳。
- **Data**: 广播携带的数据在各平台间应尽量保持为简单的 Map 结构。

## 注意事项
- 本插件旨在提供通用的原生广播接口。对于特定业务的广播，建议在业务层封装。
- iOS 的 `NotificationCenter` 与 Android 的全局广播在行为上可能存在差异，开发时需注意测试。
