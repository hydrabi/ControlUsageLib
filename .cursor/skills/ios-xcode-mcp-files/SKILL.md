---
name: ios-xcode-mcp-files
description: Creates, removes, moves, or renames Swift/asset files inside iOS Xcode projects via the user-xcode-tools MCP server so the navigator and targets stay consistent. Use when adding or deleting source files under an Xcode project/workspace, refactoring file locations in the project tree, or when the user mentions doing file operations in iOS with Xcode MCP xcode-tools.
disable-model-invocation: false
---

# iOS 工程文件：优先用 Xcode MCP（xcode-tools）

## 目标

在 **iOS / Xcode** 工程中**新增**或**删除**（含从工程移除）源代码与资源文件时，**不要使用**仅用工作区磁盘 API 写文件/删文件的方式替代完整流程——应优先通过 **MCP：`user-xcode-tools`**（XcodeWrite / XcodeRM / XcodeMV / XcodeMakeDir）操作，以避免「磁盘有文件但未加入工程 / target」或「工程引用残留」等问题。

## 何时必须走 xcode-tools

- 新建 `.swift`、资源 plist、Storyboard/XIB、Assets 等她需要出现在 **Xcode Navigator** 且参与 **编译/打包** 的文件。
- 从工程中**删除**文件或整组目录，并可能需要同时删除磁盘文件。
- 在工程目录树中**移动 / 复制 / 重命名**文件路径。

若在对话中无法用 MCP（例如未启用、Xcode 未打开），向用户说明限制；**不要随意**仅以编辑器写盘后假定工程已同步。

## 调用前检查（强制）

1. **先读工具描述 JSON**：在调用任何 MCP 工具前，从本机 MCP 描述目录读取对应工具的 schema（参数名、必填项、枚举值），再 `call_mcp_tool`。不要凭记忆拼参数。
2. **解析 `tabIdentifier`**：对需要 `tabIdentifier` 的工具，先调用 **XcodeListWindows**（无参数），在返回的窗口列表里选择 **`workspacePath` 与当前任务一致** 的那条，取其 `tabIdentifier`。**禁止**凭空猜测 tab id。

## 路径约定（与纯磁盘路径区分）

工具里的 `filePath` / `path` / `sourcePath` / `destinationPath` / `directoryPath` 使用的是 **工程导航器中相对 Xcode 组织结构的路径**（示例：`ControlUsageLib/UIControl/MyView.swift`），**不一定**等价于磁盘上的绝对路径。以工具返回的 `absolutePath`、`message` 为准。

## 常用操作映射

| 意图 | MCP 工具 | 要点 |
|------|----------|------|
| 新建或覆盖文件并加入工程 | **XcodeWrite** | 必须提供 `tabIdentifier`、`filePath`、`content`；会自动加入工程结构 |
| 仅确保存在分组/目录 | **XcodeMakeDir** | `directoryPath` + `tabIdentifier` |
| 从工程移除并可删磁盘 | **XcodeRM** | `path` + `tabIdentifier`；目录配合 `recursive`；`deleteFiles` 默认为真时会把底层文件移至废纸篓 |
| 移动/改名/复制 | **XcodeMV** | `sourcePath`、`destinationPath`、`tabIdentifier`；按需指定 `operation`（move/copy） |

## Swift 源代码补充约定

编写 `content` 时遵循工程既有风格（import、文件头、`final class`/`struct` 等）。按用户规则为**功能性注释**留白：新业务代码需简要说明用途；若为占位骨架，需在注释中标明占位意图，便于后续替换。

## 校验

工具返回 `"success": true` 后，如有必要可再用 **XcodeRead** 或 Xcode 本地构建确认文件已入库且可被编译；未完成同步时不要声称「已在工程中可用」。

## 不适用场景

以下情况可直接用磁盘/仓库工具：**不**需要出现在 Xcode target 内的脚本、`README`、`docs`、临时数据、或未纳入 `.xcodeproj` 的纯文档类文件——但若用户明确要求「也要出现在 Navigator / 工程里」，仍应走 xcode-tools。
