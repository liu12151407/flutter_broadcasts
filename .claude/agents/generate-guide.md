---
name: generate-guide
description: 生成标准使用指南
model: sonnet
---
基于项目分析结果，生成一份完整的中文简体使用指南，包括：

1. **项目概述**
   - 项目简介和用途
   - 平台支持情况

2. **安装配置**
   - 依赖添加方法
   - 平台特定配置（如有）

3. **核心API说明**
   - BroadcastReceiver 类
   - sendBroadcast 函数
   - BroadcastMessage 类

4. **使用示例**
   - 基础广播接收
   - 发送广播
   - Android特定功能（categories、flags、exported）
   - iOS特定功能
   - 完整示例代码

5. **平台特性对照表**
   - Android vs iOS 功能对比

6. **最佳实践**
   - 资源管理（start/stop）
   - 错误处理
   - 性能考虑

7. **故障排查**
   - 常见问题和解决方案

确保指南结构清晰、示例完整、易于理解。