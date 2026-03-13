# Viking 部署教程

## 部署方式

### 1. 独立部署 (推荐)

适用于单台机器运行多个 Agent 的场景。

```bash
# 克隆仓库
git clone https://github.com/your-org/viking-memory.git

# 安装依赖
pip install -r requirements.txt

# 创建软链接
mkdir -p ~/.openclaw/scripts
ln -s $(pwd)/scripts/sv_*.sh ~/.openclaw/scripts/

# 初始化目录
mkdir -p ~/.openclaw/viking-{agent}/agent/memories
```

### 2. Docker 部署

```dockerfile
FROM python:3.10-slim

RUN apt-get update && apt-get install -y inotify-tools

WORKDIR /app
COPY . .

RUN chmod +x scripts/*.sh

CMD ["tail", "-f", "/dev/null"]
```

构建运行:
```bash
docker build -t viking-memory .
docker run -d -v ~/.openclaw:/root/.openclaw viking-memory
```

### 3. 集群部署

适用于多机器场景，需要:
- 共享存储 (NFS)
- 数据库 (PostgreSQL/MongoDB)
- 消息队列 (Redis)

## OpenClaw 集成

### 配置钩子

编辑 `~/.openclaw/config/agent-hooks.yaml`:

```yaml
on_session_start:
  - script: sv_autoload.sh
    env:
      SV_WORKSPACE: "~/.openclaw/viking-{agent}"

on_session_end:
  - script: sv_save.sh

# 可选: 定时任务
cron:
  - schedule: "0 3 * * *"  # 每天3点
    script: sv_compress.sh
```

### 加载钩子

Viking 使用 `hook_loader.py` 加载钩子配置:

```python
from hook_loader import load_hooks

hooks = load_hooks("~/.openclaw/config/agent-hooks.yaml")
```

## 目录权限

```bash
# 设置正确的权限
chmod 700 ~/.openclaw/viking-*
chmod 600 ~/.openclaw/viking-*/agent/memories/config.md
```

## 验证部署

### 1. 检查脚本

```bash
ls -la ~/.openclaw/scripts/sv_*.sh
```

### 2. 运行测试

```bash
# 测试加载
bash ~/.openclaw/scripts/sv_autoload.sh

# 测试保存
bash ~/.openclaw/scripts/sv_save.sh

# 测试搜索
bash ~/.openclaw/scripts/sv_recall.sh "测试"
```

### 3. 检查日志

```bash
tail -f /var/log/viking.log
```

## 监控

### 定时任务

```bash
# 每天凌晨压缩
0 3 * * * cd ~/viking-memory && ./scripts/sv_compress.sh >> ~/.openclaw/logs/viking.log 2>&1

# 每周权重更新
0 4 * * 0 cd ~/viking-memory && ./scripts/sv_weight.sh >> ~/.openclaw/logs/viking.log 2>&1
```

### 监控脚本

```bash
# 检查 Viking 服务状态
ps aux | grep sv_memory_watcher

# 检查磁盘使用
du -sh ~/.openclaw/viking-*
```

## 备份

```bash
# 备份 Viking 目录
tar -czvf viking-backup-$(date +%Y%m%d).tar.gz ~/.openclaw/viking-*/

# 恢复
tar -xzvf viking-backup-20260313.tar.gz -C ~/
```

## 升级

```bash
cd viking-memory
git pull

# 重新创建软链接
rm ~/.openclaw/scripts/sv_*.sh
ln -s $(pwd)/scripts/sv_*.sh ~/.openclaw/scripts/
```

## 故障恢复

### 记忆丢失

1. 检查 `.archive/` 目录
2. 解压备份: `gunzip .archive/*.gz`
3. 恢复文件到对应目录

### 权限问题

```bash
chown -R $(whoami):$(whoami) ~/.openclaw/viking-*
```
