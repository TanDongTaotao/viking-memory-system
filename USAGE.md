# Viking 记忆系统 - 使用手册

## 基本概念

### 记忆目录结构

```
viking-{agent}/
├── agent/
│   ├── memories/
│   │   ├── config.md      # 核心配置 (人设、职责)
│   │   ├── daily/          # 每日工作日志
│   │   ├── hot/            # 热数据 (7天内)
│   │   └── long-term.md   # 长期记忆
│   └── instructions/       # 系统指令
├── user/
│   ├── preferences/        # 用户偏好
│   └── habits/            # 习惯
└── resources/             # 资源/文档
```

### 五层衰减机制

| 层级 | 名称 | 时间范围 | 权重 |
|------|------|----------|------|
| L1 | 核心 | 永久 | 1.0 |
| L2 | 热数据 | 0-7天 | 0.8 |
| L3 | 温数据 | 7-30天 | 0.5 |
| L4 | 冷数据 | 30-90天 | 0.2 |
| L5 | 冻结 | 90天+ | 0.1 |

## 常用命令

### 1. 自动加载记忆

```bash
# 会话开始时自动运行
./scripts/sv_autoload.sh
```

输出示例:
```
## Viking 记忆加载
> Agent: maojingli
> Workspace: /home/xlous/.openclaw/viking-maojingli

### 核心配置
# 猫经理配置
职责: 任务分配、整合汇报
...

### 最近工作日志
--- 2026-03-13.md ---
# 今日工作
...
```

### 2. 保存记忆

```bash
# 会话结束时运行
./scripts/sv_save.sh
```

### 3. 搜索记忆

```bash
# 关键词搜索
./scripts/sv_recall.sh "团队协作"
```

### 4. 权重计算

```bash
# 计算记忆权重
./scripts/sv_weight.sh

# 指定文件
./scripts/sv_weight.sh ~/.openclaw/viking-agent/agent/memories/config.md
```

### 5. 压缩归档

```bash
# 压缩90天+记忆
./scripts/sv_compress.sh
```

### 6. 实时监听

```bash
# 后台运行监听
./scripts/sv_memory_watcher.sh &
```

## 敏感信息过滤

系统自动过滤敏感信息:

```python
from sensitive_filter import filter_sensitive

text = "我的密码是 123456，请不要告诉别人"
cleaned = filter_sensitive(text)
print(cleaned)  # 输出: 我的密码是 [FILTERED]，请不要告诉别人
```

## 向量化搜索

### 生成向量

```bash
python scripts/viking-embed.py embed "Viking 记忆系统"
```

### 语义搜索

```bash
python scripts/viking-embed.py search "团队协作"
```

## 高级配置

### 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `SV_WORKSPACE` | Viking 根目录 | `~/.openclaw/viking-$AGENT_NAME` |
| `AGENT_NAME` | Agent 名称 | `maojingli` |
| `EMBEDDING_MODEL` | 向量模型 | `paraphrase-multilingual-MiniLM-L12-v2` |

### 钩子配置

编辑 `config/agent-hooks.yaml`:

```yaml
on_session_start:
  - script: sv_autoload.sh
    env:
      AGENT_NAME: "{agent_name}"

on_session_end:
  - script: sv_save.sh

on_message:
  - script: sv_memory_watcher.sh
```

## 故障排除

### 记忆加载为空
- 检查 `SV_WORKSPACE` 路径
- 确认 `agent/memories/config.md` 存在

### 搜索无结果
- 确认记忆文件格式为 `.md`
- 检查文件权限

### 向量化失败
- 确认已安装 `sentence-transformers`
- 检查网络连接 (首次下载模型)
