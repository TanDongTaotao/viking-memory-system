# Viking 记忆系统

> AI Agent 长期记忆管理系统 | Five-Tier Decay Mechanism

Viking 是一个专为 AI Agent 设计的长期记忆系统，支持多 Agent 共享记忆、语义搜索和智能衰减。

## 特性

- 🧠 **长期记忆**: 持久化存储 Agent 工作经验和上下文
- 🔍 **语义搜索**: 基于向量嵌入的相似度搜索
- 📊 **五层衰减**: 智能热数据管理，自动归档冷数据
- 🔄 **多端同步**: 支持 Agent 间共享记忆
- 🛡️ **隐私保护**: 内置敏感信息过滤

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/your-org/viking-memory.git
cd viking-memory

# 查看安装指南
cat INSTALL.md

# 查看使用手册
cat USAGE.md
```

## 项目结构

```
viking-memory/
├── scripts/          # 核心脚本
│   ├── sv_autoload.sh      # 记忆自动加载
│   ├── sv_save.sh          # 记忆保存
│   ├── sv_recall.sh        # 记忆搜索
│   ├── sv_weight.sh        # 权重计算
│   ├── sv_compress.sh      # 记忆压缩
│   ├── sv_memory_watcher.sh # 实时监听
│   ├── viking-embed.py     # 向量化模块
│   └── sensitive_filter.py # 敏感过滤
├── config/           # 配置文件
│   ├── agent-hooks.yaml    # 钩子配置
│   └── hook_loader.py     # 钩子加载器
└── docs/             # 文档
    ├── viking-design.md       # 系统设计
    ├── embedding-guide.md     # 向量化指南
    └── deployment.md          # 部署教程
```

## 核心脚本

| 脚本 | 功能 |
|------|------|
| `sv_autoload.sh` | 会话开始时自动加载记忆 |
| `sv_save.sh` | 会话结束时保存记忆 |
| `sv_recall.sh` | 关键词搜索记忆 |
| `sv_weight.sh` | 计算记忆权重 |
| `sv_compress.sh` | 压缩/归档冷数据 |

## 文档

- [安装指南](INSTALL.md)
- [使用手册](USAGE.md)
- [架构设计](ARCHITECTURE.md)
- [系统设计详解](docs/viking-design.md)
- [向量化搜索配置](docs/embedding-guide.md)
- [部署教程](docs/deployment.md)

## 许可证

MIT License
