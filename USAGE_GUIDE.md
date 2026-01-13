# Flutter Broadcasts 使用指南

> 基于 Android Intent 和 iOS NotificationCenter 的跨平台广播通信插件

## 目录

- [快速开始](#快速开始)
- [核心概念](#核心概念)
- [API 参考](#api-参考)
- [平台特性](#平台特性)
- [使用示例](#使用示例)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)

---

## 快速开始

### 安装插件

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  flutter_broadcasts: ^0.4.0
```

然后运行：

```bash
flutter pub get
```

### 第一个示例

以下是最简单的广播接收和发送示例：

```dart
import 'package:flutter_broadcasts/flutter_broadcasts.dart';

// 1. 创建广播接收器
final receiver = BroadcastReceiver(
  names: ['com.example.my_action'],
);

// 2. 开始监听
await receiver.start();

// 3. 监听消息流
receiver.messages.listen((message) {
  print('收到广播: ${message.name}');
  print('数据: ${message.data}');
});

// 4. 发送广播
await sendBroadcast(BroadcastMessage(
  name: 'com.example.my_action',
  data: {'key': 'value'},
));

// 5. 停止监听（使用完毕后）
await receiver.stop();
```

---

## 核心概念

### BroadcastReceiver（广播接收器）

`BroadcastReceiver` 类用于订阅和接收来自原生平台的广播消息。其设计灵感来自 Android 的同名组件。

**主要特点：**
- 可同时监听多个广播名称（Actions）
- 支持跨平台通信
- 基于 Stream 的消息传递
- 自动资源管理

### BroadcastMessage（广播消息）

`BroadcastMessage` 类表示一个广播消息，包含：

| 属性 | 类型 | 说明 |
|------|------|------|
| `name` | `String` | 广播名称（必需），Android 上对应 Action，iOS 上对应 Notification Name |
| `data` | `Map<String, dynamic>?` | 可选的用户数据，Android 上对应 Extras，iOS 上对应 UserInfo |
| `timestamp` | `DateTime?` | 时间戳，发送时自动记录 |
| `flags` | `List<int>?` | Android Intent 标志（仅 Android） |
| `categories` | `List<String>?` | Android Intent 类别（仅 Android） |
| `iosObject` | `String?` | iOS 过滤对象（仅 iOS） |
| `androidPackage` | `String?` | Android 目标包名（仅 Android） |

### sendBroadcast（发送广播）

顶级函数，用于向原生平台发送广播消息。

---

## API 参考

### BroadcastReceiver 类

#### 构造函数

```dart
BroadcastReceiver({
  required List<String> names,    // 必需：要监听的广播名称列表
  List<String>? categories,       // 可选：Android 类别过滤器
  bool isExported = false,        // 可选：是否导出到其他应用（Android API 33+）
  String? iosObject,              // 可选：iOS 对象过滤器
})
```

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `names` | `List<String>` | 监听的广播名称列表 |
| `categories` | `List<String>?` | Android 类别过滤器 |
| `isExported` | `bool` | 是否导出到其他应用 |
| `iosObject` | `String?` | iOS 对象过滤器 |
| `isListening` | `bool` | 是否正在监听（只读） |
| `messages` | `Stream<BroadcastMessage>` | 消息流（只读） |

#### 方法

```dart
// 开始监听广播
Future<void> start()

// 停止监听广播
Future<void> stop()
```

#### 使用示例

```dart
// 创建接收器
final receiver = BroadcastReceiver(
  names: ['action1', 'action2'],
  categories: ['category1'],  // Android
  isExported: false,          // Android
  iosObject: 'myObject',      // iOS
);

// 启动监听
await receiver.start();

// 订阅消息
final subscription = receiver.messages.listen((message) {
  print('收到: ${message.name}');
});

// 取消订阅（可选，stop() 会自动处理）
await subscription.cancel();

// 停止监听
await receiver.stop();
```

### BroadcastMessage 类

#### 构造函数

```dart
BroadcastMessage({
  required String name,                // 必需：广播名称
  Map<String, dynamic>? data,          // 可选：附加数据
  List<int>? flags,                    // 可选：Android Intent 标志
  List<String>? categories,            // 可选：Android Intent 类别
  String? iosObject,                   // 可选：iOS 对象过滤器
  String? androidPackage,              // 可选：Android 目标包名
})
```

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `name` | `String` | 广播名称 |
| `data` | `Map<String, dynamic>?` | 附加数据 |
| `flags` | `List<int>?` | Android Intent 标志 |
| `categories` | `List<String>?` | Android Intent 类别 |
| `iosObject` | `String?` | iOS 对象过滤器 |
| `androidPackage` | `String?` | Android 目标包名 |
| `timestamp` | `DateTime?` | 时间戳（自动设置） |

#### 使用示例

```dart
// 创建简单消息
final message1 = BroadcastMessage(
  name: 'com.example.action',
  data: {'key': 'value'},
);

// 创建 Android 高级消息
final message2 = BroadcastMessage(
  name: 'com.example.advanced',
  data: {'count': 42},
  flags: [
    AndroidIntentFlags.flagReceiverForeground,
    AndroidIntentFlags.flagIncludeStoppedPackages,
  ],
  categories: ['com.example.category'],
  androidPackage: 'com.example.target',
);

// 创建 iOS 对象过滤消息
final message3 = BroadcastMessage(
  name: 'com.example.ios',
  iosObject: 'myObject',
);
```

### sendBroadcast 函数

```dart
Future<void> sendBroadcast(BroadcastMessage message)
```

发送广播消息到原生平台。

#### 参数

- `message`: 要发送的 `BroadcastMessage` 对象

#### 返回值

- `Future<void>`: 发送完成后的 Future

#### 使用示例

```dart
// 发送简单广播
await sendBroadcast(BroadcastMessage(
  name: 'com.example.simple',
  data: {'message': 'Hello World'},
));

// 发送 Android 广播
await sendBroadcast(BroadcastMessage(
  name: 'com.example.android',
  flags: [AndroidIntentFlags.flagReceiverForeground],
  categories: ['com.example.category'],
));

// 发送 iOS 广播
await sendBroadcast(BroadcastMessage(
  name: 'com.example.ios',
  iosObject: 'myObject',
));
```

### AndroidIntentFlags 类

Android Intent 标志常量，用于 `BroadcastMessage.flags`。

| 常量 | 值 | 说明 |
|------|------|------|
| `flagReceiverRegisteredOnly` | 0x40000000 | 仅发送给已注册的接收器 |
| `flagReceiverReplacePending` | 0x20000000 | 替换待处理的广播 |
| `flagReceiverForeground` | 0x10000000 | 前台优先级，更短超时 |
| `flagReceiverNoAbort` | 0x08000000 | 接收器不允许中止广播 |
| `flagReceiverVisibleToInstantApps` | 0x00200000 | 对 Instant Apps 可见 |
| `flagIncludeStoppedPackages` | 0x00000020 | 包含已停止的包 |
| `flagExcludeStoppedPackages` | 0x00000010 | 排除已停止的包 |

---

## 平台特性

### 功能对照表

| 功能 | Android | iOS | 说明 |
|------|---------|-----|------|
| 基本广播（名称） | ✅ | ✅ | 通过 name 订阅和发送 |
| 自定义数据 | ✅ | ✅ | data 字段传递数据 |
| 时间戳 | ✅ | ✅ | 自动记录发送/接收时间 |
| Intent Categories | ✅ | ❌ | Android 类别过滤 |
| Intent Flags | ✅ | ❌ | Android Intent 标志 |
| Exported/Private Receivers | ✅ (API 33+) | N/A | 接收器导出控制 |
| 嵌套 Bundle/Map | ✅ | ✅ | 支持复杂数据结构 |
| iOS Object 过滤 | ❌ | ✅ | iOS 对象级别过滤 |
| Android 显式广播 | ✅ | ❌ | 通过 androidPackage 指定目标 |

### Android 特定功能

#### 1. Intent Categories（类别）

用于更精细地过滤广播：

```dart
final receiver = BroadcastReceiver(
  names: ['com.example.action'],
  categories: ['com.example.category1', 'com.example.category2'],
);

await receiver.start();
```

发送带类别的广播：

```dart
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  categories: ['com.example.category1'],
));
```

#### 2. Intent Flags（标志）

控制广播行为：

```dart
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  flags: [
    AndroidIntentFlags.flagReceiverForeground,  // 前台优先级
    AndroidIntentFlags.flagIncludeStoppedPackages,  // 包含已停止应用
  ],
));
```

#### 3. Exported Receivers（导出控制）

控制接收器是否对其他应用可见（Android API 33+）：

```dart
final receiver = BroadcastReceiver(
  names: ['com.example.action'],
  isExported: false,  // 仅应用内可见
);

await receiver.start();
```

#### 4. 显式广播（指定包名）

向特定应用发送广播：

```dart
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  androidPackage: 'com.example.target.app',
));
```

### iOS 特定功能

#### Object 过滤

基于发送者对象过滤通知：

```dart
// 接收器：仅接收特定对象的通知
final receiver = BroadcastReceiver(
  names: ['com.example.action'],
  iosObject: 'mySpecialObject',
);

await receiver.start();

// 发送器：指定对象
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  iosObject: 'mySpecialObject',
));
```

---

## 使用示例

### 示例 1：基本广播通信

```dart
import 'package:flutter/material.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';

class BasicBroadcastExample extends StatefulWidget {
  @override
  _BasicBroadcastExampleState createState() => _BasicBroadcastExampleState();
}

class _BasicBroadcastExampleState extends State<BasicBroadcastExample> {
  late BroadcastReceiver _receiver;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupReceiver();
  }

  void _setupReceiver() {
    // 创建接收器
    _receiver = BroadcastReceiver(
      names: ['com.example.basic_action'],
    );

    // 启动监听
    _receiver.start().then((_) {
      setState(() {
        _logs.add('接收器已启动');
      });
    });

    // 监听消息
    _receiver.messages.listen((message) {
      setState(() {
        _logs.add('收到: ${message.name} - 数据: ${message.data}');
      });
    });
  }

  Future<void> _sendBroadcast() async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.basic_action',
      data: {
        'message': 'Hello from Flutter!',
        'timestamp': DateTime.now().toIso8601String(),
      },
    ));
    setState(() {
      _logs.add('已发送广播');
    });
  }

  @override
  void dispose() {
    _receiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('基本广播示例')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _sendBroadcast,
            child: Text('发送广播'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 示例 2：多频道监听

```dart
class MultiChannelExample extends StatefulWidget {
  @override
  _MultiChannelExampleState createState() => _MultiChannelExampleState();
}

class _MultiChannelExampleState extends State<MultiChannelExample> {
  late BroadcastReceiver _receiver;
  final Map<String, List<BroadcastMessage>> _messagesByChannel = {
    'news': [],
    'weather': [],
    'alerts': [],
  };

  @override
  void initState() {
    super.initState();
    _receiver = BroadcastReceiver(
      names: [
        'com.example.news',
        'com.example.weather',
        'com.example.alerts',
      ],
    );
    _receiver.start();
    _receiver.messages.listen(_handleMessage);
  }

  void _handleMessage(BroadcastMessage message) {
    setState(() {
      // 根据消息名称分类存储
      if (message.name.contains('news')) {
        _messagesByChannel['news']!.add(message);
      } else if (message.name.contains('weather')) {
        _messagesByChannel['weather']!.add(message);
      } else if (message.name.contains('alerts')) {
        _messagesByChannel['alerts']!.add(message);
      }
    });
  }

  Future<void> _sendToChannel(String channel) async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.$channel',
      data: {
        'channel': channel,
        'content': '这是 $channel 频道的消息',
      },
    ));
  }

  @override
  void dispose() {
    _receiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('多频道监听')),
      body: Column(
        children: [
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () => _sendToChannel('news'),
                child: Text('发送新闻'),
              ),
              ElevatedButton(
                onPressed: () => _sendToChannel('weather'),
                child: Text('发送天气'),
              ),
              ElevatedButton(
                onPressed: () => _sendToChannel('alerts'),
                child: Text('发送警报'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                _buildChannelSection('新闻', _messagesByChannel['news']!),
                _buildChannelSection('天气', _messagesByChannel['weather']!),
                _buildChannelSection('警报', _messagesByChannel['alerts']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSection(String title, List<BroadcastMessage> messages) {
    return ExpansionTile(
      title: Text('$title (${messages.length})'),
      children: messages
          .map((msg) => ListTile(
                title: Text(msg.data?['content'] ?? '无内容'),
                subtitle: Text(msg.timestamp?.toString() ?? ''),
              ))
          .toList(),
    );
  }
}
```

### 示例 3：Android 高级功能

```dart
class AndroidAdvancedExample extends StatefulWidget {
  @override
  _AndroidAdvancedExampleState createState() => _AndroidAdvancedExampleState();
}

class _AndroidAdvancedExampleState extends State<AndroidAdvancedExample> {
  late BroadcastReceiver _receiver;
  final List<BroadcastMessage> _receivedMessages = [];

  @override
  void initState() {
    super.initState();
    _setupReceiver();
  }

  void _setupReceiver() {
    _receiver = BroadcastReceiver(
      names: ['com.example.advanced'],
      categories: ['com.example.priority'],  // 类别过滤
      isExported: false,  // 仅应用内
    );
    _receiver.start();
    _receiver.messages.listen((message) {
      setState(() {
        _receivedMessages.add(message);
      });
    });
  }

  Future<void> _sendWithFlags() async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.advanced',
      data: {'type': 'high_priority'},
      flags: [
        AndroidIntentFlags.flagReceiverForeground,  // 前台优先级
        AndroidIntentFlags.flagIncludeStoppedPackages,  // 包含已停止应用
      ],
      categories: ['com.example.priority'],
    ));
  }

  Future<void> _sendRegisteredOnly() async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.advanced',
      data: {'type': 'registered_only'},
      flags: [AndroidIntentFlags.flagReceiverRegisteredOnly],
    ));
  }

  @override
  void dispose() {
    _receiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Android 高级功能')),
      body: Column(
        children: [
          Wrap(
            children: [
              ElevatedButton(
                onPressed: _sendWithFlags,
                child: Text('发送前台广播'),
              ),
              ElevatedButton(
                onPressed: _sendRegisteredOnly,
                child: Text('发送仅注册广播'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _receivedMessages.length,
              itemBuilder: (context, index) {
                final msg = _receivedMessages[index];
                return Card(
                  child: ListTile(
                    title: Text(msg.data?['type'] ?? '未知类型'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flags: ${msg.flags ?? 'None'}'),
                        Text('Categories: ${msg.categories ?? 'None'}'),
                        Text('Time: ${msg.timestamp}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 示例 4：iOS 对象过滤

```dart
class IOSObjectExample extends StatefulWidget {
  @override
  _IOSObjectExampleState createState() => _IOSObjectExampleState();
}

class _IOSObjectExampleState extends State<IOSObjectExample> {
  late BroadcastReceiver _receiver1;
  late BroadcastReceiver _receiver2;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupReceivers();
  }

  void _setupReceivers() {
    // 接收器 1：仅接收来自 'sender1' 的通知
    _receiver1 = BroadcastReceiver(
      names: ['com.example.ios'],
      iosObject: 'sender1',
    );
    _receiver1.start();
    _receiver1.messages.listen((message) {
      setState(() {
        _logs.add('接收器 1 收到: ${message.iosObject}');
      });
    });

    // 接收器 2：仅接收来自 'sender2' 的通知
    _receiver2 = BroadcastReceiver(
      names: ['com.example.ios'],
      iosObject: 'sender2',
    );
    _receiver2.start();
    _receiver2.messages.listen((message) {
      setState(() {
        _logs.add('接收器 2 收到: ${message.iosObject}');
      });
    });
  }

  Future<void> _sendAsSender1() async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.ios',
      iosObject: 'sender1',
      data: {'message': '来自 Sender 1'},
    ));
  }

  Future<void> _sendAsSender2() async {
    await sendBroadcast(BroadcastMessage(
      name: 'com.example.ios',
      iosObject: 'sender2',
      data: {'message': '来自 Sender 2'},
    ));
  }

  @override
  void dispose() {
    _receiver1.stop();
    _receiver2.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('iOS 对象过滤')),
      body: Column(
        children: [
          Wrap(
            children: [
              ElevatedButton(
                onPressed: _sendAsSender1,
                child: Text('作为 Sender 1 发送'),
              ),
              ElevatedButton(
                onPressed: _sendAsSender2,
                child: Text('作为 Sender 2 发送'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 示例 5：完整的生产环境示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_broadcasts/flutter_broadcasts.dart';

class ProductionExample extends StatefulWidget {
  @override
  _ProductionExampleState createState() => _ProductionExampleState();
}

class _ProductionExampleState extends State<ProductionExample> {
  late BroadcastReceiver _broadcastReceiver;
  late BroadcastReceiver _systemReceiver;
  final List<BroadcastMessage> _messages = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeReceivers();
  }

  Future<void> _initializeReceivers() async {
    try {
      // 自定义广播接收器
      _broadcastReceiver = BroadcastReceiver(
        names: [
          'com.example.action.update',
          'com.example.action.delete',
        ],
        isExported: false,
      );

      // 系统广播接收器（例如电池变化）
      _systemReceiver = BroadcastReceiver(
        names: [
          'android.intent.action.BATTERY_CHANGED',
        ],
      );

      // 启动监听
      await Future.wait([
        _broadcastReceiver.start(),
        _systemReceiver.start(),
      ]);

      // 监听自定义广播
      _broadcastReceiver.messages.listen(_handleCustomMessage);

      // 监听系统广播
      _systemReceiver.messages.listen(_handleSystemMessage);

      setState(() {
        _isListening = true;
      });
    } catch (e) {
      _showError('初始化失败: $e');
    }
  }

  void _handleCustomMessage(BroadcastMessage message) {
    setState(() {
      _messages.insert(0, message);
      // 保持最多 100 条消息
      if (_messages.length > 100) {
        _messages.removeLast();
      }
    });
  }

  void _handleSystemMessage(BroadcastMessage message) {
    // 处理系统广播
    if (message.name.contains('BATTERY')) {
      final level = message.data?['level'] as int?;
      if (level != null && level < 20) {
        _showError('电量低: $level%');
      }
    }
  }

  Future<void> _sendUpdate() async {
    try {
      await sendBroadcast(BroadcastMessage(
        name: 'com.example.action.update',
        data: {
          'id': 123,
          'content': '更新内容',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));
    } catch (e) {
      _showError('发送失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    // 确保停止所有接收器
    _broadcastReceiver.stop();
    _systemReceiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('生产环境示例'),
        actions: [
          Icon(
            _isListening ? Icons.wifi : Icons.wifi_off,
            color: _isListening ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text('发送更新'),
                    onPressed: _sendUpdate,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('清空消息'),
                    onPressed: () {
                      setState(() {
                        _messages.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      '暂无消息',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            message.name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('数据:'),
                                  SizedBox(height: 8),
                                  if (message.data != null)
                                    ...message.data!.entries.map((entry) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: 16),
                                        child: Text(
                                          '${entry.key}: ${entry.value}',
                                        ),
                                      );
                                    }).toList()
                                  else
                                    Text('无'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '未知时间';
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
```

---

## 最佳实践

### 1. 资源管理

#### 始终在适当的生命周期管理接收器

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late BroadcastReceiver _receiver;

  @override
  void initState() {
    super.initState();
    _receiver = BroadcastReceiver(names: ['com.example.action']);
    _receiver.start();
  }

  @override
  void dispose() {
    // ⚠️ 重要：始终在 dispose 中停止接收器
    _receiver.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### 2. 错误处理

#### 捕获异步错误

```dart
// 启动时捕获错误
try {
  await _receiver.start();
} catch (e) {
  print('启动接收器失败: $e');
  // 处理错误或显示用户友好的消息
}

// 监听时捕获错误
_receiver.messages.listen(
  (message) {
    // 处理消息
  },
  onError: (error) {
    print('接收消息错误: $error');
  },
);

// 发送时捕获错误
try {
  await sendBroadcast(message);
} catch (e) {
  print('发送广播失败: $e');
}
```

### 3. 性能考虑

#### 避免在消息流中执行重操作

```dart
// ❌ 不好的做法：阻塞消息流
receiver.messages.listen((message) {
  // 重操作会阻塞后续消息处理
  heavyComputation();
});

// ✅ 好的做法：异步处理
receiver.messages.listen((message) {
  Future.microtask(() {
    heavyComputation();
  });
});
```

#### 限制消息数量

```dart
class MessageManager {
  final List<BroadcastMessage> _messages = [];
  static const int _maxMessages = 100;

  void addMessage(BroadcastMessage message) {
    _messages.insert(0, message);
    if (_messages.length > _maxMessages) {
      _messages.removeLast();
    }
  }
}
```

### 4. 命名规范

#### 使用反向域名表示法

```dart
// ✅ 好的做法
final receiver = BroadcastReceiver(
  names: [
    'com.company.app.action.update',
    'com.company.app.action.delete',
  ],
);

// ❌ 不好的做法
final receiver = BroadcastReceiver(
  names: [
    'update',
    'delete',
  ],
);
```

### 5. 数据验证

#### 验证接收的数据

```dart
receiver.messages.listen((message) {
  // 验证数据结构
  if (message.data != null) {
    final id = message.data!['id'];
    if (id is int && id > 0) {
      // 处理有效数据
      processId(id);
    } else {
      print('无效的 ID: $id');
    }
  }
});
```

### 6. 平台兼容性

#### 检查平台特性

```dart
import 'dart:io' show Platform;

Future<void> sendPlatformSpecific() async {
  final message = BroadcastMessage(
    name: 'com.example.action',
  );

  if (Platform.isAndroid) {
    // Android 特定功能
    message.flags = [AndroidIntentFlags.flagReceiverForeground];
    message.categories = ['com.example.category'];
  } else if (Platform.isIOS) {
    // iOS 特定功能
    message.iosObject = 'myObject';
  }

  await sendBroadcast(message);
}
```

### 7. 测试建议

#### 模拟广播进行测试

```dart
class BroadcastTest {
  late BroadcastReceiver _receiver;
  bool _receivedExpectedMessage = false;

  Future<void> setUp() async {
    _receiver = BroadcastReceiver(names: ['test.action']);
    await _receiver.start();
  }

  Future<bool> test() async {
    // 监听消息
    final subscription = _receiver.messages.listen((message) {
      if (message.name == 'test.action' &&
          message.data?['test'] == true) {
        _receivedExpectedMessage = true;
      }
    });

    // 发送测试消息
    await sendBroadcast(BroadcastMessage(
      name: 'test.action',
      data: {'test': true},
    ));

    // 等待消息
    await Future.delayed(Duration(seconds: 1));

    // 清理
    await subscription.cancel();
    await _receiver.stop();

    return _receivedExpectedMessage;
  }
}
```

---

## 故障排除

### 问题 1：接收器无法接收消息

**症状：** 发送广播后，接收器没有收到消息。

**可能原因和解决方案：**

1. **检查接收器是否已启动**
   ```dart
   if (!receiver.isListening) {
     print('接收器未启动，正在启动...');
     await receiver.start();
   }
   ```

2. **验证广播名称是否匹配**
   ```dart
   // 确保名称完全一致
   const actionName = 'com.example.action';

   final receiver = BroadcastReceiver(names: [actionName]);
   await sendBroadcast(BroadcastMessage(name: actionName));
   ```

3. **检查类别过滤（Android）**
   ```dart
   // 如果接收器设置了类别，发送时也需要包含
   final receiver = BroadcastReceiver(
     names: ['com.example.action'],
     categories: ['com.example.category'],  // 必须匹配
   );

   await sendBroadcast(BroadcastMessage(
     name: 'com.example.action',
     categories: ['com.example.category'],  // 必须包含
   ));
   ```

### 问题 2：Android 接收器被其他应用触发

**症状：** 接收器收到了来自其他应用的不相关广播。

**解决方案：**

```dart
final receiver = BroadcastReceiver(
  names: ['com.example.action'],
  isExported: false,  // 设置为 false，仅应用内可见
);
```

### 问题 3：内存泄漏

**症状：** 应用内存持续增长。

**解决方案：**

1. **确保在 dispose 中停止接收器**
   ```dart
   @override
   void dispose() {
     receiver.stop();  // 必须调用
     super.dispose();
   }
   ```

2. **取消 Stream 订阅**
   ```dart
   StreamSubscription? _subscription;

   @override
   void initState() {
     super.initState();
     _subscription = receiver.messages.listen((message) {
       // 处理消息
     });
   }

   @override
   void dispose() {
     _subscription?.cancel();  // 取消订阅
     receiver.stop();
     super.dispose();
   }
   ```

### 问题 4：时间戳不一致

**症状：** 发送和接收的时间戳差异很大。

**说明：** 这是正常行为，因为：
- 发送的时间戳在 `data` 字段中
- 接收的时间戳在 `timestamp` 字段中
- 两者之间的差异反映了网络或系统延迟

```dart
receiver.messages.listen((message) {
  print('发送时间: ${message.data?['sendTime']}');
  print('接收时间: ${message.timestamp}');
  print('延迟: ${message.timestamp?.difference(DateTime.parse(message.data?['sendTime']))}');
});
```

### 问题 5：复杂数据结构丢失

**症状：** 发送的嵌套 Map 或 List 接收后为空。

**解决方案：**

使用可序列化的数据结构：

```dart
// ✅ 好的做法：使用简单嵌套结构
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  data: {
    'user': {
      'name': 'John',
      'age': 30,
      'hobbies': ['reading', 'gaming'],
    },
  },
));

// ❌ 不好的做法：使用不可序列化的对象
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  data: {
    'user': myUserObject,  // 自定义对象可能无法正确序列化
  },
));
```

### 问题 6：Android 广播限制

**症状：** Android 8.0+ 应用无法接收隐式广播。

**说明：** Android 8.0+ 对隐式广播有限制。

**解决方案：**

1. **使用显式广播（指定包名）**
   ```dart
   await sendBroadcast(BroadcastMessage(
     name: 'com.example.action',
     androidPackage: 'com.example.target.app',  // 指定目标应用
   ));
   ```

2. **注册时设置 exported**
   ```dart
   final receiver = BroadcastReceiver(
     names: ['com.example.action'],
     isExported: true,  // 允许其他应用发送
   );
   ```

### 问题 7：iOS 对象过滤不工作

**症状：** 设置了 `iosObject` 但仍然收到所有消息。

**解决方案：**

确保发送和接收都使用相同的对象标识符：

```dart
// 接收器
final receiver = BroadcastReceiver(
  names: ['com.example.action'],
  iosObject: 'exact-object-name',  // 必须完全匹配
);

// 发送器
await sendBroadcast(BroadcastMessage(
  name: 'com.example.action',
  iosObject: 'exact-object-name',  // 必须完全匹配
));
```

### 问题 8：接收器重复启动

**症状：** 收到重复的消息或抛出 "already started" 异常。

**解决方案：**

```dart
Future<void> safeStart(BroadcastReceiver receiver) async {
  if (!receiver.isListening) {
    try {
      await receiver.start();
    } catch (e) {
      print('启动失败: $e');
    }
  } else {
    print('接收器已在运行');
  }
}

// 使用
await safeStart(receiver);
```

### 调试技巧

#### 1. 添加详细日志

```dart
receiver.messages.listen((message) {
  print('=== 收到广播 ===');
  print('名称: ${message.name}');
  print('数据: ${message.data}');
  print('时间戳: ${message.timestamp}');
  print('Flags: ${message.flags}');
  print('Categories: ${message.categories}');
  print('iOS Object: ${message.iosObject}');
  print('Android Package: ${message.androidPackage}');
  print('================');
});
```

#### 2. 使用 Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

然后连接到你的应用以监控内存和网络。

#### 3. 检查原生日志

```bash
# Android
adb logcat | grep flutter_broadcasts

# iOS (使用 Xcode)
# 在 Xcode 中查看控制台输出
```

---

## 附录

### 常用 Android 系统广播

| 广播名称 | 说明 | 权限要求 |
|---------|------|----------|
| `android.intent.action.BATTERY_CHANGED` | 电池状态变化 | 无 |
| `android.intent.action.BOOT_COMPLETED` | 系统启动完成 | `RECEIVE_BOOT_COMPLETED` |
| `android.intent.action.CONNECTIVITY_CHANGE` | 网络状态变化 | 无 |
| `android.intent.action.PACKAGE_ADDED` | 安装新应用 | 无 |
| `android.intent.action.PACKAGE_REMOVED` | 卸载应用 | 无 |
| `android.intent.action.SCREEN_ON` | 屏幕打开 | 无 |
| `android.intent.action.SCREEN_OFF` | 屏幕关闭 | 无 |

### 常用 iOS 通知名称

| 通知名称 | 说明 |
|---------|------|
| `UIApplicationDidBecomeActiveNotification` | 应用进入前台 |
| `UIApplicationWillResignActiveNotification` | 应用即将进入后台 |
| `UIApplicationDidEnterBackgroundNotification` | 应用已进入后台 |
| `UIApplicationWillEnterForegroundNotification` | 应用即将进入前台 |
| `UIApplicationDidFinishLaunchingNotification` | 应用启动完成 |

### 版本要求

- Flutter: >= 1.20.0
- Dart: >= 2.12.0 < 4.0.0
- Android: API 16+ (推荐 API 21+)
- iOS: 9.0+

### 相关资源

- [Android BroadcastReceiver 文档](https://developer.android.com/reference/android/content/BroadcastReceiver)
- [iOS NotificationCenter 文档](https://developer.apple.com/documentation/foundation/notificationcenter)
- [Flutter 插件开发指南](https://flutter.dev/docs/development/packages-and-plugins/developing-packages)
- [GitHub 仓库](https://github.com/kevlatus/flutter_broadcasts)

---

## 总结

Flutter Broadcasts 提供了一个简单而强大的跨平台广播通信解决方案：

- **统一 API**：在 Android 和 iOS 上使用相同的接口
- **灵活性**：支持基本广播和平台特定功能
- **易用性**：基于 Stream 的异步消息处理
- **安全性**：支持接收器导出控制和类别过滤

遵循本指南的最佳实践，可以有效地在 Flutter 应用中实现跨平台广播通信。
