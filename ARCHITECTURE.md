# Viking 记忆系统架构设计

本文档详细介绍 Viking 记忆系统的整体架构设计和核心组件。

## 目录

1. [系统概述](#系统概述)
2. [整体架构](#整体架构)
3. [核心组件](#核心组件)
4. [数据流设计](#数据流设计)
5. [存储结构](#存储结构)
6. [集成方案](#集成方案)
7. [扩展设计](#扩展设计)

---

## 系统概述

### 设计目标

Viking 记忆系统的核心目标是**模拟人类记忆的层级衰减机制**，实现智能记忆管理：

1. **记忆生命周期管理** - 自动从完整细节压缩到归档保留
2. **重要性加权** - 基于访问和时间自动计算权重
3. **搜索触发回忆** - 归档记忆可通过关键词搜索恢复
4. **无缝框架集成** - 通过 Hook 机制与 OpenClaw 集成

### 核心特性

| 特性 | 说明 |
|------|------|
| 层级衰减 | L0→L1→L2→L3→L4 自动压缩 |
| 权重计算 | importance × time_decay × access_boost |
| 归档回忆 | L4 归档 + LLM 关键词恢复 |
| OpenClaw Hook | 会话开始/结束自动触发 |

---

## 整体架构

### 架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Viking 记忆系统架构                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        用户层 (User Layer)                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  CLI 命令   │  │ OpenClaw    │  │  Web UI     │            │   │
│  │  │ (sv_* 命令) │  │   Agent     │  │  (可选)     │            │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      接口层 (API Layer)                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  sv_write   │  │  sv_find    │  │  sv_read    │            │   │
│  │  │  写入接口   │  │  搜索接口    │  │  读取接口   │            │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    核心引擎 (Core Engine)                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  记忆存储   │  │  权重计算   │  │  压缩引擎   │            │   │
│  │  │  Manager    │  │  Weighter   │  │  Compressor │            │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  搜索索引   │  │  回忆恢复   │  │  Hook 加载  │            │   │
│  │  │  Searcher   │  │  Recall     │  │  Loader     │            │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      存储层 (Storage Layer)                       │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐   │   │
│  │  │  文件系统       │  │  向量存储       │  │  配置存储     │   │   │
│  │  │  (Markdown)    │  │  (可选-Chroma)  │  │  (YAML)       │   │   │
│  │  └─────────────────┘  └─────────────────┘  └────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        外部集成 (External Integration)                   │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────────┐  │
│  │   OpenClaw      │  │    LLM 服务     │  │    其他 Agent 框架    │  │
│  │   Framework     │  │   (Ollama)      │  │   (需适配)            │  │
│  └─────────────────┘  └─────────────────┘  └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 核心组件

### 1. 记忆存储管理器 (MemoryManager)

**职责**: 负责记忆的 CRUD 操作

```python
class MemoryManager:
    """记忆存储管理器"""
    
    def write(self, path: str, content: str, metadata: dict) -> bool
    def read(self, path: str) -> dict  # 返回 content + metadata
    def delete(self, path: str) -> bool
    def list(self, filters: dict) -> list  # 支持层级/重要性过滤
    def update_metadata(self, path: str, metadata: dict) -> bool
```

### 2. 权重计算器 (Weighter)

**职责**: 计算和更新记忆权重

```python
class Weighter:
    """记忆权重计算器"""
    
    # 权重公式: W = importance_factor × (1/(days+1)^0.3) × (access_count+1)
    
    def calculate(self, memory: dict) -> float
    def refresh_on_access(self, memory_id: str) -> dict  # 访问时刷新
    def get_layer(self, weight: float) -> str  # 权重→层级映射
```

### 3. 压缩引擎 (Compressor)

**职责**: 负责记忆层级压缩

```python
class Compressor:
    """记忆压缩引擎"""
    
    TRIGGERS = {
        1:  'compress_to_contour',   # L0 → L1
        7:  'compress_to_keywords',  # L1 → L2
        30: 'compress_to_tags',      # L2 → L3
        90: 'mark_for_archive',      # L3 → L4
    }
    
    def check_and_compress(self, memory: dict) -> dict
    def compress_to_contour(self, memory: dict) -> dict   # LLM 生成轮廓
    def compress_to_keywords(self, memory: dict) -> dict  # LLM 提取关键词
    def compress_to_tags(self, memory: dict) -> dict       # LLM 提取标签
    def mark_for_archive(self, memory: dict) -> dict      # L4 归档
```

### 4. 搜索引擎 (Searcher)

**职责**: 记忆搜索和过滤

```python
class Searcher:
    """记忆搜索引擎"""
    
    def search(self, query: str, filters: dict) -> list
    def search_by_layer(self, layer: str) -> list  # 按层级搜索
    def search_archived(self, query: str) -> list  # 搜索归档触发回忆
    def fuzzy_match(self, keyword: str) -> list    # 模糊匹配
```

### 5. 回忆恢复器 (Recall)

**职责**: 归档记忆的 LLM 恢复

```python
class Recall:
    """记忆回忆恢复器"""
    
    def recall(self, archived_memory: dict, query: str) -> str
    # 使用 LLM 根据关键词恢复完整记忆
```

### 6. Hook 加载器 (HookLoader)

**职责**: OpenClaw Hook 机制集成

```python
class HookLoader:
    """OpenClaw Hook 加载器"""
    
    def load_config(self, config_path: str) -> dict
    def execute_hook(self, hook_name: str, context: str) -> str
    def on_session_start(self) -> str  # 会话开始触发
    def on_session_end(self) -> str     # 会话结束触发
```

---

## 数据流设计

### 写入数据流

```
用户输入 (sv_write)
       │
       ▼
┌──────────────────┐
│  验证 & 解析     │
│  输入处理         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  生成元数据      │
│  - id            │
│  - created       │
│  - importance   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  保存到文件系统  │
│  Markdown 格式   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  更新索引        │
│  (可选: 向量)    │
└────────┬─────────┘
         │
         ▼
    [完成]
```

### 读取数据流

```
用户请求 (sv_read/sv_find)
       │
       ▼
┌──────────────────┐
│  查询索引        │
│  匹配记忆        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  检查层级        │
│  是归档(L4)?     │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ 是      │ 否
    ▼         ▼
┌────────┐ ┌──────────────────┐
│ 触发   │ │ 直接返回内容     │
│ 回忆   │ │ 更新访问计数     │
└────┬───┘ └────────┬─────────┘
     │              │
     ▼              ▼
┌──────────────┐ ┌──────────────────┐
│ LLM 恢复     │ │ 刷新权重         │
│ 关键词→内容  │ │ access_count++   │
└──────┬──────┘ └────────┬─────────┘
       │                 │
       └────────┬────────┘
                ▼
           [返回用户]
```

### 压缩数据流

```
定时任务 (每日 cron)
       │
       ▼
┌──────────────────┐
│  扫描所有记忆    │
│  检查天数        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  遍历记忆       │
│  for each mem   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ 达到压缩条件?  │
    └────┬────┘
         │
    ┌────┴────┐
    │ 是      │ 否 → 下一条
    ▼         ▼
┌────────┐
│ 调用LLM │
│ 生成压缩│
│ 内容    │
└────┬───┘
     │
     ▼
┌──────────────────┐
│  更新记忆层级   │
│  content_Lx     │
└────────┬─────────┘
         │
         ▼
    [继续下一条]
```

---

## 存储结构

### 目录结构

```
~/.openclaw/viking-{agent}/
├── config.yaml                 # Viking 配置
├── agent/
│   ├── memories/
│   │   ├── daily/             # 每日记忆
│   │   │   └── YYYY-MM-DD.md
│   │   ├── long-term/         # 长期记忆
│   │   └── meetings/         # 会议记忆
│   ├── instructions/         # 系统指令
│   └── config.md             # Agent 配置
├── user/
│   ├── preferences/          # 用户偏好
│   └── habits/              # 习惯
├── resources/                # 资源文件
└── .index/                   # 搜索索引 (可选)
```

### 记忆文件格式 (Markdown + Frontmatter)

```markdown
---
id: mem_20260314_001
title: "2026-03-14 今日工作"
importance: high
important: false
tags: [工作, 项目A]
created: 2026-03-14T10:30:00Z
last_access: 2026-03-14T14:22:00Z
access_count: 5
retention: 90
current_layer: L0
level: 0
weight: 14.2
---

# 今日工作

## 任务完成
- 完成项目 A 的开发
- 代码审查

## 待办
- 准备周报

---

## 轮廓 (L1)

项目A开发完成，准备周报。

---

### 关键词 (L2)

项目A, 代码审查, 周报

---

### 标签 (L3)

#项目A #周报
```

---

## 集成方案

### OpenClaw 集成

```yaml
# ~/.openclaw/config/agent-hooks.yaml
hooks:
  on_session_start:
    - name: "Viking 记忆加载"
      command: "/path/to/sv_autoload.sh"
      enabled: true
      timeout: 30
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-{agent}"
        
  on_session_end:
    - name: "Viking 记忆保存"
      command: "/path/to/sv_save.sh"
      enabled: false
      timeout: 30
```

### LLM 服务集成

```python
# 支持多种 LLM 服务
LLM_SERVICES = {
    'ollama': {
        'base_url': 'http://192.168.5.110:11434',
        'model': 'glm-4-flash',
    },
    'openai': {
        'api_key': 'sk-xxx',
        'model': 'gpt-4',
    },
    'anthropic': {
        'api_key': 'sk-ant-xxx',
        'model': 'claude-3',
    },
}
```

---

## 扩展设计

### 向量搜索扩展

```
当前: 关键词匹配 (grep/find)
扩展: 向量相似度搜索 (Chroma)

方案:
1. 嵌入模型: sentence-transformers
2. 向量库: Chroma / Milvus
3. 索引更新: 写入时异步更新
```

### 多模态扩展

```
支持:
- 图片记忆 (OCR + 描述)
- 语音记忆 (ASR + 摘要)
- 文件记忆 (提取文本)
```

### 分布式扩展

```
当前: 单机文件存储
扩展: 分布式存储

方案:
1. S3/OSS 对象存储
2. Redis 缓存层
3. PostgreSQL 元数据
```

---

## 相关文档

- [Viking 设计文档](./docs/viking-design.md)
- [嵌入指南](./docs/embedding-guide.md)
- [部署指南](./docs/deployment.md)
- [OpenClaw 改动说明](./docs/openclaw-modifications.md)

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
