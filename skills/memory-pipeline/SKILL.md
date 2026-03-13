---
name: memory-pipeline
description: 统一记忆存取工作流。用于存储或检索长期记忆，确保数据经过 ontology 模式映射后存入 Viking 系统，保证数据规范化。适用于：(1) 重要数据存储 - 自动 ontology 映射 + Viking 存储；(2) 记忆检索 - 通过 Viking 语义搜索；(3) 批量导入 - 多个数据源统一处理。当需要存取长期记忆时使用此 skill。
---

# memory-pipeline

统一记忆存取工作流，确保数据规范化存储和检索。

## 核心能力

1. **规范化存储**：数据自动经过 ontology 模式映射后再存入 Viking
2. **语义检索**：通过 Viking 快速搜索已存储的记忆
3. **一键 pipeline**：存储+映射+索引自动化完成

## 使用场景

### 场景 1：存储重要记忆

当需要存储重要数据到长期记忆时，必须使用此 skill：

```python
# 错误的做法（直接写入）
sv_write("viking://agent/memories/hot/today.md", "# 任务...")

# 正确的做法（使用 memory-pipeline）
# 自动完成：ontology 映射 → Viking 存储 → 索引更新
# 按热度存储：hot/ 7天内, warm/ 7-30天, cold/ 30天+
```

### 场景 2：检索记忆

当需要从长期记忆中检索信息时：

```python
# 使用 memory-pipeline 检索
sv_find("董事长偏好")
# 或
sv_read("viking://agent/memories/config.md")
```

## 工作流程

```
存储流程：
┌─────────────┐    ┌──────────────┐    ┌────────────┐    ┌──────────┐
│ 输入数据     │ → │ Ontology 映射 │ → │ Viking 存储 │ → │ 索引更新 │
└─────────────┘    └──────────────┘    └────────────┘    └──────────┘

检索流程：
┌─────────────┐    ┌────────────┐
│ 搜索关键词   │ → │ Viking 查询 │
└─────────────┘    └────────────┘
```

## 快速使用

### 存储记忆

```bash
# 使用 pipeline 存储（推荐）
mp_store --content "任务完成情况：..." --title "2026-03-11 工作日志" --tags "工作,日报"

# 或使用 simple-viking 直接存储
# hot/ 7天内, warm/ 7-30天, cold/ 30天+
sv_write "viking://agent/memories/hot/2026-03-11.md" "# 今日工作..."
```

### 检索记忆

```bash
# 语义搜索
sv_find "猫经理 偏好"

# 读取指定记忆 (按热度层级)
sv_read "viking://agent/memories/config/config.md"
sv_read "viking://agent/memories/hot/today.md"

# 列出所有记忆
ls -la ~/.openclaw/viking-*/agent/memories/
```

## 工具

| 工具 | 描述 |
|------|------|
| `mp_store` | 一键存储：ontology 映射 + Viking 存储 |
| `mp_search` | 语义搜索已存储的记忆 |
| `sv_write` | Viking 原生写入 |
| `sv_find` | Viking 语义搜索 |
| `sv_read` | 读取指定记忆 |

## 配置

默认使用当前 Agent 的 Viking workspace：
- 猫经理：`~/.openclaw/viking-maojingli/`
- 猫小咪：`~/.openclaw/viking-maoxiami/`
- 猫工头：`~/.openclaw/viking-maogongtou/`
- 猫助理：`~/.openclaw/viking-maozhuli/`

全局共享：`~/.openclaw/viking-global/`

## 重要规则

> **强制要求**：所有重要数据存储必须使用 memory-pipeline，确保数据经过 ontology 映射规范化后再存入 Viking。

这样可以：
1. 保证数据格式统一
2. 便于跨 Agent 检索
3. 建立统一的知识图谱

---

*此 skill 封装了 ontology-viking-workflow 和 simple-viking，确保记忆存取流程规范化。*
