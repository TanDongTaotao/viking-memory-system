# Viking 记忆系统安装指南

本文档详细介绍 Viking 记忆系统的安装步骤和配置方法。

## 目录

1. [前置要求](#前置要求)
2. [安装方式](#安装方式)
3. [配置 OpenClaw Hooks](#配置-openclaw-hooks)
4. [初始化工作空间](#初始化工作空间)
5. [验证安装](#验证安装)
6. [常见问题](#常见问题)

---

## 前置要求

### 操作系统

- **Linux**: Ubuntu 20.04+, Debian 11+, CentOS 8+
- **macOS**: 11.0 (Big Sur) 或更高版本
- **Windows**: WSL2 (Ubuntu 20.04+)

### 软件依赖

| 依赖 | 版本要求 | 说明 |
|------|----------|------|
| OpenClaw | v0.3.0+ | Agent 运行框架 |
| Bash | 4.0+ | Shell 脚本环境 |
| Python | 3.8+ | Hook 加载器运行环境 |
| curl | 任意版本 | HTTP 请求工具 |
| jq | 1.6+ | JSON 处理工具 (可选) |
| yq | 4.0+ | YAML 处理工具 (可选) |

### LLM 服务

Viking 系统需要 LLM 服务进行记忆压缩和恢复：

- **本地部署**: Ollama (推荐)
- **云端 API**: OpenAI, Anthropic, 智谱 GLM 等

---

## 安装方式

### 方式一：克隆安装 (推荐)

```bash
# 1. 克隆项目
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. 运行安装脚本
chmod +x install.sh
./install.sh

# 3. 验证安装
./scripts/sv_autoload.sh --help
```

### 方式二：手动安装

```bash
# 1. 创建安装目录
mkdir -p ~/.openclaw/viking
cd ~/.openclaw/viking

# 2. 克隆项目或复制文件
git clone https://github.com/Xlous/viking-memory-system.git .

# 3. 添加到 PATH (可选)
echo 'export PATH="$HOME/.openclaw/viking/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. 复制 Hook 配置
mkdir -p ~/.openclaw/config
cp scripts/agent-hooks.yaml ~/.openclaw/config/
```

### 方式三：Docker 部署

```bash
# 构建镜像
docker build -t viking-memory:latest .

# 运行容器
docker run -d \
  -v ~/.openclaw:/home/xlous/.openclaw \
  -v ~/viking-data:/data \
  viking-memory:latest
```

---

## 配置 OpenClaw Hooks

### 1. 创建 Hook 配置文件

创建或编辑 `~/.openclaw/config/agent-hooks.yaml`:

```yaml
# OpenClaw Agent Hooks 配置
hooks:
  on_session_start:
    - name: "Viking 记忆加载"
      command: "/home/xlous/.openclaw/viking/scripts/sv_autoload.sh"
      enabled: true
      timeout: 30
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-{agent}"
        OLLAMA_HOST: "http://192.168.5.110:11434"
        
  on_session_end:
    - name: "Viking 记忆保存"
      command: "/home/xlous/.openclaw/viking/scripts/sv_save.sh"
      enabled: false
      timeout: 30
```

### 2. 配置参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| command | Hook 脚本路径 | `/home/xlous/.openclaw/viking/scripts/sv_autoload.sh` |
| enabled | 是否启用 | `true` / `false` |
| timeout | 超时时间(秒) | `30` |
| env.SV_WORKSPACE | Viking 工作空间路径 | `/home/xlous/.openclaw/viking-{agent}` |
| env.OLLAMA_HOST | LLM 服务地址 | `http://192.168.5.110:11434` |

### 3. 为不同 Agent 配置

为每个 Agent 创建独立的工作空间：

```bash
# 猫经理的工作空间
mkdir -p ~/.openclaw/viking-maojingli/agent/memories/daily

# 猫小咪的工作空间  
mkdir -p ~/.openclaw/viking-maoxiami/agent/memories/daily

# 猫工头的工作空间
mkdir -p ~/.openclaw/viking-maogongtou/agent/memories/daily
```

---

## 初始化工作空间

### 1. 创建目录结构

```bash
# 主目录
mkdir -p ~/.openclaw/viking-{agent}

# 子目录
cd ~/.openclaw/viking-{agent}
mkdir -p agent/memories/{daily,long-term}
mkdir -p agent/instructions
mkdir -p user/{preferences,habits}
mkdir -p resources
```

### 2. 初始化配置文件

创建 `~/.openclaw/viking-{agent}/config.md`:

```markdown
---
name: "{agent_name}"
role: "AI Agent"
created: "2026-03-14"
---

# Agent 配置

## 人设
- 名称: {agent_name}
- 角色: AI 助手

## 职责
- 协助用户完成任务
- 管理记忆和上下文

## 团队成员
- 猫经理 (maojingli)
- 猫小咪 (maoxiami)
- 猫工头 (maogongtou)
- 猫助理 (maozhuli)
```

### 3. 设置权限

```bash
# 设置目录权限
chmod -R 700 ~/.openclaw/viking-{agent}

# 设置脚本权限
chmod +x ~/.openclaw/viking/scripts/*.sh
```

---

## 验证安装

### 1. 检查脚本可执行性

```bash
# 列出脚本
ls -la ~/.openclaw/viking/scripts/*.sh

# 测试脚本
~/.openclaw/viking/scripts/sv_autoload.sh --help
```

### 2. 测试 Hook 加载器

```bash
# 测试 Python Hook 加载器
python3 ~/.openclaw/viking/scripts/hook_loader.py --help

# 测试配置加载
python3 -c "
import yaml
with open('~/.openclaw/config/agent-hooks.yaml') as f:
    config = yaml.safe_load(f)
    print('Hooks loaded:', len(config.get('hooks', {})))
"
```

### 3. 创建测试记忆

```bash
# 设置环境变量
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# 创建测试记忆
echo "# 测试记忆
这是 Viking 系统的测试记忆。
创建时间: $(date)" > ~/.openclaw/viking-maojingli/agent/memories/daily/test.md

# 验证
ls -la ~/.openclaw/viking-maojingli/agent/memories/daily/
```

---

## 常见问题

### Q1: Hook 没有触发怎么办？

1. 检查 `agent-hooks.yaml` 语法是否正确
2. 确认脚本路径是否正确
3. 查看日志: `tail -f ~/.openclaw/logs/hooks.log`

### Q2: LLM 服务连接失败？

1. 确认 Ollama 服务正在运行: `curl http://192.168.5.110:11434/api/tags`
2. 检查环境变量 `OLLAMA_HOST` 配置
3. 确认模型已下载: `ollama list`

### Q3: 记忆没有自动压缩？

1. 检查 `viking.config` 中 `auto_compress` 是否为 `true`
2. 确认 `compress_at` 配置了正确的天数
3. 手动运行压缩: `./scripts/sv_compress.sh`

### Q4: 如何迁移现有记忆？

```bash
# 导出旧记忆
cp -r ~/.old-viking/* ~/.openclaw/viking-{agent}/

# 更新元数据
./scripts/sv_merge.sh
```

---

## 下一步

- 阅读 [使用说明](./USAGE.md) 了解完整功能
- 阅读 [架构设计](./ARCHITECTURE.md) 了解系统架构
- 配置 [OpenClaw 改动说明](./docs/openclaw-modifications.md) 了解核心代码

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
