# Viking 记忆系统使用指南

本文档详细介绍 Viking 记忆系统的所有功能和使用方法。

## 目录

1. [快速开始](#快速开始)
2. [核心命令](#核心命令)
3. [记忆写入](#记忆写入)
4. [记忆读取](#记忆读取)
5. [记忆搜索](#记忆搜索)
6. [记忆压缩](#记忆压缩)
7. [权重管理](#权重管理)
8. [自动加载](#自动加载)
9. [高级功能](#高级功能)
10. [最佳实践](#最佳实践)

---

## 快速开始

### 环境设置

```bash
# 设置工作空间 (每个 Agent 独立)
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# 设置 LLM 服务 (可选)
export OLLAMA_HOST=http://192.168.5.110:11434

# 添加到 .bashrc 持久化
echo 'export SV_WORKSPACE=~/.openclaw/viking-maojingli' >> ~/.bashrc
```

### 首次使用

```bash
# 1. 创建记忆目录
mkdir -p $SV_WORKSPACE/agent/memories/daily

# 2. 写入第一条记忆
sv_write viking://agent/memories/daily/2026-03-14.md "# 启动日志

今天开始使用 Viking 记忆系统。
目标：实现智能记忆管理。"

# 3. 搜索记忆
sv_find "Viking"

# 4. 查看记忆列表
sv_list
```

---

## 核心命令

### 命令概览

| 命令 | 功能 | 示例 |
|------|------|------|
| `sv_write` | 写入记忆 | `sv_write path "content"` |
| `sv_read` | 读取记忆 | `sv_read mem_id` |
| `sv_find` | 搜索记忆 | `sv_find "关键词"` |
| `sv_list` | 列出记忆 | `sv_list [--layer L0]` |
| `sv_compress` | 压缩记忆 | `sv_compress --dry-run` |
| `sv_autoload` | 自动加载 | `sv_autoload.sh` |
| `sv_save` | 保存记忆 | `sv_save.sh` |
| `sv_weight` | 计算权重 | `sv_weight mem_id` |

---

## 记忆写入

### 基本写入

```bash
# 方式1: 命令行写入
sv_write viking://agent/memories/daily/2026-03-14.md "# 今日工作

## 任务完成
- 完成项目 A 的开发
- 代码审查

## 待办
- 准备周报"
```

### 带元数据的写入

```bash
# 写入带 importance 标记的记忆
sv_write viking://agent/memories/daily/2026-03-14.md \
  --importance high \
  --important \
  --tags "工作,项目A" <<'EOF'
# 重要会议记录

决策：启动新项目 B
参与人员：张三、李四
EOF
```

### 脚本方式写入

```bash
# 使用 sv_save.sh 脚本
./scripts/sv_save.sh --title "会议记录" --content "内容..." --importance high
```

---

## 记忆读取

### 基本读取

```bash
# 读取单条记忆
sv_read viking://agent/memories/daily/2026-03-14.md

# 带刷新权重的读取
sv_read viking://agent/memories/daily/2026-03-14.md --refresh
```

### 程序化读取

```bash
# 使用 sv_recall.sh 脚本
./scripts/sv_recall.sh --id mem_20260314_001
```

---

## 记忆搜索

### 简单搜索

```bash
# 搜索关键词
sv_find "项目"

# 搜索多个词 (AND)
sv_find "项目 AND 开发"

# 搜索标签
sv_find "#工作"
```

### 高级搜索

```bash
# 按层级搜索
sv_find --layer L0      # 完整细节
sv_find --layer L1     # 轮廓
sv_find --layer L2     # 关键词

# 按重要性搜索
sv_find --importance high

# 按日期范围搜索
sv_find --date-from 2026-01-01 --date-to 2026-03-14

# 搜索归档记忆 (触发回忆)
sv_find --archived "关键词"
```

### 搜索触发回忆

当搜索归档记忆时，系统会自动触发 LLM 恢复：

```bash
# 搜索归档记忆
sv_find --archived "2025年的项目"

# 输出示例:
# [回忆触发]
# 找到归档记忆: 项目X (2025-06)
# ---
# [LLM 恢复]
# 根据关键词"项目X, 2025-06"恢复的记忆:
# 2025年6月启动了项目X，
# 核心团队成员包括...
```

---

## 记忆压缩

### 自动压缩

Viking 系统会自动按时间压缩记忆：

| 层级 | 时间 | 内容 |
|------|------|------|
| L0 | 0-1天 | 完整细节 |
| L1 | 2-7天 | 核心轮廓 |
| L2 | 8-30天 | 关键词 |
| L3 | 30-90天 | 极简标签 |
| L4 | 90天+ | 归档(搜索可回忆) |

### 手动压缩

```bash
# 预览压缩 (不实际执行)
./scripts/sv_compress.sh --dry-run

# 执行压缩
./scripts/sv_compress.sh

# 压缩特定记忆
./scripts/sv_compress.sh --id mem_20260314_001

# 强制压缩 (忽略 important 标记)
./scripts/sv_compress.sh --force
```

### 压缩配置

在 `viking.config` 中配置：

```yaml
memory:
  auto_compress: true
  compress_at: [1, 8, 30, 90]  # 天数
  low_weight_threshold: 0.5   # 权重阈值
```

---

## 权重管理

### 权重计算

权重公式: `W = importance_factor × (1 / (days+1)^0.3) × (access_count+1)`

```bash
# 查看记忆权重
./scripts/sv_weight.sh mem_20260314_001

# 输出示例:
# Memory: 2026-03-14.md
# Importance: high (factor: 3.0)
# Days since last access: 2
# Access count: 5
# Weight: 3.0 × 1/(2+1)^0.3 × 6 = 14.2
# Layer: L0 (weight >= 10)
```

### 重要性因子

| importance | factor | 说明 |
|------------|--------|------|
| high | 3.0 | 核心记忆 |
| medium | 1.5 | 一般重要 |
| low | 0.5 | 次要信息 |
| important=true | 999 | 永不遗忘 |

### 手动调整

```bash
# 标记重要 (永不遗忘)
sv_important mem_20260314_001 --set

# 取消重要标记
sv_important mem_20260314_001 --unset

# 设置保留期
sv_retention mem_20260314_001 --days 365
```

---

## 自动加载

### Hook 自动加载

通过 OpenClaw Hook 在会话开始时自动加载：

```bash
# 手动触发
./scripts/sv_autoload.sh

# 指定记忆数量
./scripts/sv_autoload.sh --limit 10

# 指定层级
./scripts/sv_autoload.sh --layer L0,L1
```

### 加载内容

- 最近 N 条记忆
- 标记为 important 的记忆
- 待办任务
- 热点记忆 (高权重)

### 加载输出格式

```
=== Viking 记忆加载 ===
工作空间: ~/.openclaw/viking-maojingli
加载数量: 5

--- 记忆 1: 2026-03-14 今日工作 ---
[重要性: high] [权重: 14.2] [层级: L0]

# 今日工作

## 任务完成
- 完成项目 A 的开发
...

--- 记忆 2: 2026-03-13 项目进度 ---
...
```

---

## 高级功能

### 记忆合并

```bash
# 合并多条记忆
./scripts/sv_merge.sh --ids mem001,mem002

# 合并指定日期范围
./scripts/sv_merge.sh --date-from 2026-01-01 --date-to 2026-03-14
```

### 记忆清理

```bash
# 列出低权重记忆
./scripts/sv_cleanup.sh --list

# 清理归档记忆
./scripts/sv_cleanup.sh --archive --dry-run

# 强制清理
./scripts/sv_cleanup.sh --force
```

### Token 限制管理

```bash
# 检查当前 token 使用
./scripts/sv_token_limit.sh --check

# 估算压缩后节省
./scripts/sv_token_limit.sh --estimate
```

### 批量操作

```bash
# 批量设置重要性
for f in memories/*.md; do
  sv_important "$f" --importance high
done

# 批量导出
tar -czf memories-backup.tar.gz agent/memories/
```

---

## 最佳实践

### 1. 记忆命名规范

```
# 推荐格式
agent/memories/daily/YYYY-MM-DD.md
agent/memories/long-term/project-name.md
agent/memories/meetings/YYYY-MM-project.md

# 示例
agent/memories/daily/2026-03-14.md
agent/memories/long-term/viking-design.md
```

### 2. 重要性标记

- **high**: 关键决策、重要人物、核心项目
- **medium**: 一般任务、日常会议
- **low**: 临时信息、可遗忘内容

### 3. 定期维护

```bash
# 每周执行压缩
0 2 * * 0 ~/.openclaw/viking/scripts/sv_compress.sh

# 每月执行清理
0 3 * 1 ~/.openclaw/viking/scripts/sv_cleanup.sh
```

### 4. 团队协作

```bash
# 使用全局共享空间
export SV_WORKSPACE=~/.openclaw/viking-global

# 写入团队任务
sv_write viking://shared/tasks/project-x.md "# 项目X任务"
```

---

## 故障排查

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 搜索无结果 | 关键词不匹配 | 使用更宽泛的关键词 |
| 压缩失败 | LLM 服务不可用 | 检查 OLLAMA_HOST |
| 加载超时 | 记忆太多 | 减少 --limit 数量 |
| 权限错误 | 目录权限不足 | chmod -R 700 |

### 调试模式

```bash
# 启用调试输出
export DEBUG=1
sv_find "关键词"

# 查看详细日志
tail -f ~/.openclaw/logs/viking.log
```

---

## 相关文档

- [安装指南](./INSTALL.md)
- [架构设计](./ARCHITECTURE.md)
- [Viking 设计文档](./docs/viking-design.md)
- [部署指南](./docs/deployment.md)

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
