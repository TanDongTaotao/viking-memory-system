# Viking 记忆系统修复与优化 (2026-03-14)

## 修复内容

### 1. Agent Hooks 配置修复
- **文件**: `~/.openclaw/config/agent-hooks.yaml`
- **问题**: 钩子配置缺少 `AGENT_NAME` 环境变量，导致脚本总是加载错误的记忆
- **修复**: 为所有 Agent (maojingli, maoxiami, maogongtou, maozhuli) 添加了 `AGENT_NAME` 环境变量

### 2. 各 Agent SOUL.md 启动规则
- **文件**: `~/.openclaw/workspace/agents/{agent}/SOUL.md`
- **问题**: Agent 收到任务时不会自动加载记忆
- **修复**: 添加了启动规则
```yaml
## 启动规则
- 每次收到任务时，**必须先**执行 `exec` 工具运行命令：
  `~/.openclaw/skills/memory-pipeline/scripts/memory-pipeline mp_autoload`
- 等待命令执行完成后再开始处理任务
```

### 3. Skill 链接修复
- **问题**: memory-pipeline 和 simple-viking skill 没有链接到所有 Agent
- **修复**: 为 mamumu 添加了 skill 链接

### 4. viking-embed.sh 脚本修复
- **文件**: `~/.openclaw/scripts/viking-embed.sh`
- **问题**: shebang 前面有错误语句 `AGENT_NAME=$(basename "$0" | cut -d'-' -f1)`
- **修复**: 移除错误语句，修正脚本格式
- **依赖**: 安装了 jq 命令 (`sudo apt-get install -y jq`)

### 5. simple-viking 向量搜索修复
- **文件**: `~/.openclaw/skills/simple-viking/scripts/lib.sh`, `sv`
- **问题**: 
  - Python 脚本中 top_k 变量未正确传递
  - 默认 SV_WORKSPACE 环境变量未设置
- **修复**:
  - 修正 Python 代码中 top_k 变量传递
  - 在 sv 脚本中添加默认 `SV_WORKSPACE` 设置

### 6. OpenClaw 源码修改 (未完全生效)
- **文件**: `~/.npm-global/lib/node_modules/openclaw/dist/auth-profiles-iXW75sRj.js`
- **目的**: 让 sessions_spawn 创建的子会话也触发 on_session_start 钩子
- **修改**: 在 spawnSubagentDirect 函数中添加钩子触发代码
- **状态**: 代码已添加但未生效（可能是缓存或其他原因）

## 测试结果

### 记忆加载
- ✅ 新建对话: 触发钩子加载记忆
- ⚠️ sessions_spawn 子会话: 暂未生效（需要进一步排查）

### 向量库
- ✅ 构建索引: `sv build-index`
- ✅ 语义搜索: `sv semantic "关键词"`
- 示例输出:
```
0.7219 viking://agent/memories/hot/today.md
0.6530 viking://agent/memories/hot/test-20260314012520.md
0.6401 viking://agent/memories/hot/test-vector.md
```

## 相关文件路径

- 钩子配置: `~/.openclaw/config/agent-hooks.yaml`
- Viking 脚本: `~/.openclaw/scripts/`
- Simple-viking: `~/.openclaw/skills/simple-viking/`
- Agent 配置: `~/.openclaw/workspace/agents/`
- Viking 记忆: `~/.openclaw/viking-{agent}/`
