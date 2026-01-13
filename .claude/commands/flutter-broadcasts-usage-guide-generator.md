---
description: flutter-broadcasts-usage-guide-generator
---
```mermaid
flowchart TD
    analyze_project[analyze-project]
    generate_guide[generate-guide]
    format_output[format-output]
    start_node_default([开始])
    end_node_default([结束])

    start_node_default --> analyze_project
    analyze_project --> generate_guide
    generate_guide --> format_output
    format_output --> end_node_default
```

## 工作流执行指南

按照上方的Mermaid流程图执行工作流。每种节点类型的执行方法如下所述。

### 各节点类型的执行方法

- **矩形节点**：使用Task工具执行子代理
- **菱形节点（AskUserQuestion:...）**：使用AskUserQuestion工具提示用户并根据其响应进行分支
- **菱形节点（Branch/Switch:...）**：根据先前处理的结果自动分支（参见详细信息部分）
- **矩形节点（Prompt节点）**：执行下面详细信息部分中描述的提示
