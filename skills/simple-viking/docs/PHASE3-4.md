# Viking Phase 3 & 4 实现说明

## 概述

已实现 Viking 记忆系统的向量化搜索集成 (Phase 3) 和自动加载功能 (Phase 4)。

---

## Phase 3: 向量化搜索集成

### 功能

1. **语义搜索** - 使用 Ollama 的 `nomic-embed-text` 模型进行向量相似度匹配
2. **关键词搜索** - 传统的路径和内容匹配
3. **混合搜索** - 结合语义和关键词的混合检索

### 新增函数 (lib.sh)

| 函数 | 说明 |
|------|------|
| `sv_get_embedding()` | 调用 Ollama API 获取文本向量 |
| `sv_build_vector_index()` | 构建向量索引 |
| `sv_semantic_search()` | 语义搜索 |
| `sv_hybrid_search()` | 混合搜索 |

### 使用方式

```bash
# 设置工作空间
export SV_WORKSPACE=~/.openclaw/viking-maojingli
export OLLAMA_HOST=http://192.168.5.110:11434

# 构建向量索引 (首次使用)
sv build-index ~/.openclaw/viking-maojingli 50

# 语义搜索
sv semantic "今天做了什么" 5

# 混合搜索 (默认)
sv hybrid "任务" 5

# 关键词搜索 (使用原有功能)
sv_find "任务" --keyword
```

---

## Phase 4: 自动加载脚本

### sv_autoload.sh

会话开始时自动加载上下文，包括:

1. **核心配置** - `agent/memories/config/config.md` (始终加载)
2. **热点记忆** - `agent/memories/hot/` (7天内文件)
3. **近期记忆** - `agent/memories/warm/` (30天内文件)
4. **待办任务** - 搜索包含 TODO/待办 的文件
5. **全局上下文** - 董事长偏好、团队信息

### 使用方式

```bash
# 加载猫经理上下文
sv autoload maojingli

# 加载其他 Agent
sv autoload maoxiami
sv autoload maogongtou

# 或者直接调用脚本
~/.openclaw/skills/simple-viking/scripts/sv_autoload.sh maojingli
```

### 输出格式

脚本输出格式化的 Markdown，可直接注入到 system prompt:

```
=== Viking Auto-Load: maojingli ===

📋 加载配置...
--- CONFIG ---
[配置文件内容]

🔥 加载热点记忆 (7天内)...
--- 2026-03-10.md ---
[日记内容]
...
```

---

## 集成到 OpenClaw

### 方法 1: 在 system prompt 中调用

在 Agent 的 SOUL.md 或启动脚本中添加:

```bash
# 加载 Viking 上下文
VIKING_CONTEXT=$(sv autoload maojingli)
```

### 方法 2: 使用 memory-pipeline skill

确保使用统一的记忆存取接口。

---

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib.sh` | 添加了向量搜索函数 |
| `find.sh` | 支持 `--vector/--keyword/--hybrid` 选项 |
| `sv` | 向量化搜索命令行工具 |
| `sv_autoload.sh` | 自动加载脚本 |

---

## 依赖

- **Ollama** 运行在 `192.168.5.110:11434`
- 模型: `nomic-embed-text:latest`
- Python 3
- curl, ripgrep

---

## 测试

```bash
# 测试 Ollama 连接
sv test-ollama

# 测试向量索引构建
sv build-index ~/.openclaw/viking-maojingli 20

# 测试语义搜索
sv semantic "工作日志"

# 测试自动加载
sv autoload maojingli
```
