# Viking 记忆系统 - 安装指南

## 环境要求

- Linux/macOS
- Bash 4.0+
- Python 3.8+ (可选，向量化功能需要)
- Git

## 安装步骤

### 1. 克隆仓库

```bash
git clone https://github.com/your-org/viking-memory.git
cd viking-memory
```

### 2. 创建符号链接

```bash
# 将脚本链接到 OpenClaw 脚本目录
ln -s $(pwd)/scripts/sv_autoload.sh ~/.openclaw/scripts/sv_autoload.sh
ln -s $(pwd)/scripts/sv_save.sh ~/.openclaw/scripts/sv_save.sh
ln -s $(pwd)/scripts/sv_recall.sh ~/.openclaw/scripts/sv_recall.sh
ln -s $(pwd)/scripts/sv_weight.sh ~/.openclaw/scripts/sv_weight.sh
ln -s $(pwd)/scripts/sv_compress.sh ~/.openclaw/scripts/sv_compress.sh
ln -s $(pwd)/scripts/sv_memory_watcher.sh ~/.openclaw/scripts/sv_memory_watcher.sh
```

### 3. 配置环境变量

在 `.bashrc` 或 `.zshrc` 中添加:

```bash
# Viking 记忆系统
export SV_WORKSPACE=~/.openclaw/viking-$AGENT_NAME

# 可选: 向量化配置
export EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2
```

### 4. 创建 Viking 目录结构

```bash
# 为每个 Agent 创建独立的 Viking 目录
mkdir -p ~/.openclaw/viking-{agent_name}/agent/memories/{config,daily,hot,long-term}
mkdir -p ~/.openclaw/viking-{agent_name}/user/{preferences,habits}
mkdir -p ~/.openclaw/viking-{agent_name}/resources
```

### 5. 配置钩子 (可选)

编辑 `~/.openclaw/config/agent-hooks.yaml`:

```yaml
on_session_start:
  - script: sv_autoload.sh

on_session_end:
  - script: sv_save.sh
```

## 向量化模块安装 (可选)

```bash
# 安装 Python 依赖
pip install sentence-transformers numpy

# 测试向量化
python scripts/viking-embed.py embed "测试文本"
```

## 验证安装

```bash
# 测试脚本
bash scripts/sv_autoload.sh

# 检查输出
echo $?
```

## 常见问题

### Q: 提示 "command not found"
A: 确保脚本有执行权限: `chmod +x scripts/*.sh`

### Q: 向量化模块导入失败
A: 确保已安装 sentence-transformers: `pip install sentence-transformers`

### Q: 记忆加载失败
A: 检查 SV_WORKSPACE 路径是否正确设置
