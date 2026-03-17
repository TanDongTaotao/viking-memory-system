# Viking 记忆系统

适用于 OpenClaw AI Agents 的轻量级、纯文本上下文管理系统。

## 核心思想

1. **五级记忆层级**：L0 → L1 → L2 → L3 → L4，按时间自动降级
2. **重要记忆保护**：手动标记的重要记忆不降级
3. **自动保存**：会话结束自动保存 + 凌晨定时处理
4. **向量搜索**：语义检索 + 关键词混合搜索
5. **跨 Agent 共享**：全局记忆供所有 Agent 访问

## 记忆层级

| 层级 | 目录 | 时间范围 | 内容 |
|------|------|---------|------|
| L0 | hot/ | 0-1天 | 100% 完整细节 |
| L1 | warm/ | 2-7天 | 70% 核心轮廓 |
| L2 | cold/ | 8-30天 | 30% 关键词 |
| L3 | archive/ | 30-90天 | 10% 标签 |
| L4 | archive/ | 90天+ | 仅标题 |
| 重要 | important/ | 永久 | 不降级 |

## 目录结构

```
viking-{agent}/
├── agent/memories/
│   ├── hot/          # L0: 0-1天（完整细节）
│   ├── warm/         # L1: 2-7天（核心轮廓）
│   ├── cold/         # L2: 8-30天（关键词）
│   ├── archive/       # L3: 30-90天（标签）
│   ├── important/    # 重要记忆（不降级）
│   └── config/       # 配置
├── user/
│   └── preferences/  # 用户偏好
└── shared/           # 跨 Agent 共享
    └── tasks/        # 任务记录
```

## 安装

```bash
# 克隆仓库
git clone https://github.com/TanDongTaotao/viking-memory-system.git

# 添加到 PATH
export PATH="$HOME/viking-memory-system/memory-pipeline:$HOME/viking-memory-system/simple-viking:$PATH"
```

## 使用方式

### 保存记忆
```bash
# 存储到 hot (L0)
memory-pipeline mp_store --content "内容" --title "标题"

# 写入全局记忆
memory-pipeline mp_global "任务完成：xxx"
```

### 搜索记忆
```bash
# 混合搜索（向量 + 关键词）
memory-pipeline mp_search "关键词"

# 或使用 simple-viking
sv hybrid "关键词"
```

### 自动加载
```bash
# 会话开始时加载
memory-pipeline mp_autoload

# 或
sv autoload maojingli
```

## 定时任务（Cron）

每天凌晨 3 点自动执行：

1. **智能提取**：从昨日会话中提取摘要
2. **降级处理**：L0→L1→L2→L3→L4
3. **向量索引**：构建语义搜索索引

```bash
# crontab -e
0 3 * * * ~/viking-memory-system/memory-pipeline/memory-tier-cron.sh
```

## 脚本说明

### memory-pipeline/
| 脚本 | 功能 |
|------|------|
| `memory-pipeline` | CLI 主入口 |
| `memory-auto-save.sh` | 会话结束自动保存 |
| `memory-tier-cron.sh` | 定时任务入口 |
| `memory-tier-downgrade.sh` | 记忆降级处理 |
| `memory-extract-summary.sh` | LLM 智能摘要 |

### simple-viking/
| 脚本 | 功能 |
|------|------|
| `sv` | 向量搜索 CLI |
| `sv_autoload.sh` | 自动加载上下文 |
| `lib.sh` | 基础库 |
| `find.sh` | 检索 |
| `read.sh` | 读取 |
| `write.sh` | 写入 |

## Bug 修复记录

1. ✅ tier 格式不识别 → 添加 `tier: L0` 支持
2. ✅ L0→L1 文件丢失 → 修复删除逻辑
3. ✅ global 错误生成记忆 → 跳过自动保存
4. ✅ 自动保存误判重要 → 简化判断逻辑

---

基于 OpenViking 思想设计
