# Viking 系统设计详解

## 设计理念

Viking 旨在解决 AI Agent 的长期记忆问题，通过五层时间衰减机制实现记忆的智能管理。

## 核心挑战

1. **上下文丢失**: 长对话后 Agent 忘记早期信息
2. **信息冗余**: 存储过多低价值记忆
3. **隐私风险**: 敏感信息意外泄露
4. **检索效率**: 大规模记忆的快速搜索

## 解决方案

### 1. 分层存储

```bash
viking-{agent}/
├── agent/memories/
│   ├── config.md      # L1: 核心配置 (永久)
│   ├── hot/           # L2: 热数据 (7天内)
│   ├── daily/         # L3: 温数据 (30天内)
│   └── long-term.md   # L4: 冷数据 (90天内)
└── .archive/         # L5: 冻结数据 (90天+)
```

### 2. 智能加载

会话开始时:
1. 加载 config.md (30行)
2. 加载 hot/ 下 3 个最新文件 (各 20 行)
3. 检查 TODO.md

### 3. 自动保存

会话结束时:
1. 生成当日工作日志
2. 更新 TODO 列表
3. 标记热数据

### 4. 敏感过滤

```python
FILTER_PATTERNS = [
    r'\d{11}',           # 手机号
    r'password[:\s=].*', # 密码
    r'api[_-]?key.*',    # API Key
]
```

### 5. 向量化搜索

- 文本 → 向量 (sentence-transformers)
- 相似度计算 (余弦相似度)
- Top-K 检索

## 实现细节

### 五层衰减算法

```python
def calculate_weight(file_path):
    days = (now - modified_time).days
    
    if days < 7:      return 0.8   # 热
    elif days < 30:  return 0.5   # 温
    elif days < 90:  return 0.2   # 冷
    else:            return 0.1   # 冻结
```

### 压缩触发条件

- 文件修改时间 > 90 天
- 访问频率 < 1次/月
- 文件大小 > 100KB

## 扩展场景

### 多 Agent 共享

```
~/.openclaw/viking-global/
├── team/members.md
├── shared/resources/
└── boss/preferences.md
```

### 跨会话记忆

通过 `SV_WORKSPACE` 环境变量指定不同的记忆目录。

## 参考资料

- [向量化搜索配置指南](embedding-guide.md)
- [部署教程](deployment.md)
