# Viking 记忆系统 (Viking Memory System)

[English](#english) | [中文](#中文)

---

## 📌 兼容性声明 | Compatibility Statement

> **⚠️ 注意 | Notice**: 本项目针对 **OpenClaw** 框架设计开发，已在以下环境中测试通过：
> 
> 本项目针对 **OpenClaw** 设计。其他 Agent 框架（如 LangChain Agent、AutoGPT 等）需要自行适配核心 Hook 机制。
> 
> This project is designed for **OpenClaw** framework. Other Agent frameworks (e.g., LangChain Agent, AutoGPT) need to adapt the core Hook mechanism independently.

**已测试的 Agent 列表 | Tested Agents:**
- ✅ OpenClaw Native Agents (maojingli, maoxiami, maogongtou, maozhuli)
- ⚠️ 其他框架需自行适配

---

## 中文 (Chinese)

### 项目介绍

Viking 记忆系统是一个模拟人类记忆层级衰减机制的智能记忆管理系统。它通过模拟人脑记忆的自然遗忘曲线，实现记忆的自动压缩、归档和检索，类似于人类记忆从短期记忆到长期记忆的转化过程。

#### 核心特性

- **记忆生命周期管理**：自动将记忆从完整细节压缩为轮廓、关键词、极简标签，最后归档保留
- **重要性加权**：支持手动标记重要记忆（永不遗忘）和自动权重计算
- **搜索触发回忆**：归档的记忆可通过关键词搜索触发 LLM 恢复完整细节
- **OpenClaw 无缝集成**：通过 Hook 机制在会话开始/结束时自动加载/保存记忆
- **可配置压缩策略**：灵活配置压缩触发天数和保留策略

### 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                      Viking 记忆系统架构                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   用户交互   │───▶│  OpenClaw    │───▶│  Hook 加载器 │      │
│  │  (会话开始)  │    │   Framework  │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                    │             │
│                                                    ▼             │
│                                          ┌──────────────┐       │
│                                          │  sv_autoload │       │
│                                          │     .sh      │       │
│                                          └──────────────┘       │
│                                                    │             │
│                                                    ▼             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   向量存储   │◀───│  Viking 核心  │◀───│  记忆存储    │      │
│  │  (可选)      │    │   引擎        │    │  (~/.openclaw│      │
│  └──────────────┘    └──────────────┘    │  /viking-*)  │      │
│                                          └──────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 安装步骤

#### 前置要求

- **操作系统**: Linux (Ubuntu 20.04+), macOS, 或 Windows WSL2
- **OpenClaw**: v0.3.0+
- **Shell**: Bash 4.0+
- **Python**: 3.8+ (用于 hook_loader.py)
- **依赖工具**: curl, jq, yq (可选)

#### 安装方式

```bash
# 1. 克隆项目
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. 运行安装脚本
chmod +x install.sh
./install.sh

# 3. 初始化 Viking 工作空间
mkdir -p ~/.openclaw/viking-{agent_name}
```

详细安装说明请参考 [INSTALL.md](./INSTALL.md)

### 快速开始

```bash
# 设置环境变量
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# 写入记忆
sv_write viking://agent/memories/daily/2026-03-14.md "# 今日工作..."

# 搜索记忆
sv_find "项目"

# 自动加载记忆
sv_autoload.sh
```

详细使用说明请参考 [USAGE.md](./USAGE.md)

### 配置说明

主要配置文件位于 `scripts/viking.config`:

```yaml
# Viking 记忆系统配置
memory:
  default_retention: 90
  auto_compress: true
  compress_at: [1, 8, 30, 90]
  archive_searchable: true
  low_weight_threshold: 0.5

llm:
  model: glm-4-flash
  temperature: 0.3

hooks:
  on_session_start: true
  on_session_end: false
```

### OpenClaw 集成

Viking 系统通过 OpenClaw 的 Hook 机制实现无缝集成：

1. **会话开始时自动加载记忆**：通过 `on_session_start` Hook
2. **会话结束时自动保存**：通过 `on_session_end` Hook (可选)
3. **配置位置**: `~/.openclaw/config/agent-hooks.yaml`

详细 OpenClaw 改动说明请参考 [docs/openclaw-modifications.md](./docs/openclaw-modifications.md)

### 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

### 许可证

MIT License - 查看 [LICENSE](./LICENSE) 文件了解详情。

### 相关文档

- [安装指南](./INSTALL.md) - 详细安装步骤
- [使用说明](./USAGE.md) - 完整功能使用指南
- [架构设计](./ARCHITECTURE.md) - 系统架构详解
- [Viking 设计文档](./docs/viking-design.md) - 核心设计理念
- [嵌入指南](./docs/embedding-guide.md) - 如何嵌入到其他系统
- [部署指南](./docs/deployment.md) - 生产环境部署
- [OpenClaw 改动说明](./docs/openclaw-modifications.md) - 核心代码改动

---

## English

### Project Introduction

Viking Memory System is an intelligent memory management system that simulates human memory's hierarchical decay mechanism. By mimicking the natural forgetting curve of human brain memory, it achieves automatic memory compression, archiving, and retrieval - similar to how human memory transforms from short-term to long-term memory.

#### Core Features

- **Memory Lifecycle Management**: Automatically compresses memories from full details → contours → keywords → minimal tags → archive
- **Importance Weighting**: Supports manual marking of important memories (never forget) and automatic weight calculation
- **Search-Triggered Recall**: Archived memories can trigger LLM to restore full details through keyword search
- **Seamless OpenClaw Integration**: Automatically loads/saves memories through Hook mechanism at session start/end
- **Configurable Compression Strategy**: Flexible configuration of compression trigger days and retention policies

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Viking Memory System Architecture             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  User Input  │───▶│  OpenClaw    │───▶│ Hook Loader  │      │
│  │(Session Start)│   │  Framework  │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                    │             │
│                                                    ▼             │
│                                          ┌──────────────┐       │
│                                          │ sv_autoload  │       │
│                                          │    .sh       │       │
│                                          └──────────────┘       │
│                                                    │             │
│                                                    ▼             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │Vector Store  │◀───│ Viking Core  │◀───│Memory Storage│      │
│  │  (Optional)  │    │    Engine    │    │(~/.openclaw/ │      │
│  └──────────────┘    └──────────────┘    │ viking-*)    │      │
│                                          └──────────────┘      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Installation

#### Prerequisites

- **Operating System**: Linux (Ubuntu 20.04+), macOS, or Windows WSL2
- **OpenClaw**: v0.3.0+
- **Shell**: Bash 4.0+
- **Python**: 3.8+ (for hook_loader.py)
- **Dependencies**: curl, jq, yq (optional)

#### Installation Steps

```bash
# 1. Clone the project
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. Run installation script
chmod +x install.sh
./install.sh

# 3. Initialize Viking workspace
mkdir -p ~/.openclaw/viking-{agent_name}
```

For detailed installation instructions, see [INSTALL-en.md](./INSTALL-en.md)

### Quick Start

```bash
# Set environment variable
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# Write memory
sv_write viking://agent/memories/daily/2026-03-14.md "# Today's work..."

# Search memory
sv_find "project"

# Auto-load memories
sv_autoload.sh
```

For detailed usage instructions, see [USAGE-en.md](./USAGE-en.md)

### Configuration

Main configuration file at `scripts/viking.config`:

```yaml
# Viking Memory System Configuration
memory:
  default_retention: 90
  auto_compress: true
  compress_at: [1, 8, 30, 90]
  archive_searchable: true
  low_weight_threshold: 0.5

llm:
  model: glm-4-flash
  temperature: 0.3

hooks:
  on_session_start: true
  on_session_end: false
```

### OpenClaw Integration

Viking integrates seamlessly through OpenClaw's Hook mechanism:

1. **Auto-load memories at session start**: Via `on_session_start` Hook
2. **Auto-save at session end**: Via `on_session_end` Hook (optional)
3. **Config location**: `~/.openclaw/config/agent-hooks.yaml`

For detailed OpenClaw modifications, see [docs/openclaw-modifications.md](./docs/openclaw-modifications.md)

### Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### License

MIT License - See [LICENSE](./LICENSE) file for details.

### Related Documentation

- [Installation Guide](./INSTALL-en.md) - Detailed installation steps
- [Usage Guide](./USAGE-en.md) - Complete usage instructions
- [Architecture Design](./ARCHITECTURE-en.md) - System architecture details
- [Viking Design Document](./docs/viking-design-en.md) - Core design concepts
- [Embedding Guide](./docs/embedding-guide-en.md) - How to embed in other systems
- [Deployment Guide](./docs/deployment-en.md) - Production deployment
- [OpenClaw Modifications](./docs/openclaw-modifications.md) - Core code modifications

---

*文档版本: v2.0 | 更新日期: 2026-03-14 | 添加中英文双语支持*
