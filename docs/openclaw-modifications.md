# OpenClaw 核心代码改动说明

本文档详细介绍 Viking 记忆系统对 OpenClaw 核心代码的改动和扩展。

## 目录

1. [概述](#概述)
2. [改动文件清单](#改动文件清单)
3. [hook_loader.py 增强](#hook_loaderpy-增强)
4. [agent-hooks.yaml 配置格式](#agent-hooksyaml-配置格式)
5. [openclaw-wrapper.sh 包装脚本](#openclaw-wrappersh-包装脚本)
6. [集成验证](#集成验证)
7. [兼容性说明](#兼容性说明)

---

## 概述

Viking 记忆系统通过以下方式与 OpenClaw 集成：

1. **Hook 加载器增强** (`hook_loader.py`): 扩展原生 Hook 机制，支持更丰富的配置
2. **配置文件更新** (`agent-hooks.yaml`): 使用新的 YAML 配置格式
3. **包装脚本方案** (`openclaw-wrapper.sh`): 提供更灵活的调用方式

> **注意**: 这些改动是 **Viking 系统专用** 的增强，非 OpenClaw 官方功能。

---

## 改动文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| `hook_loader.py` | 增强 | 扩展 Hook 加载器，支持超时、环境变量等 |
| `agent-hooks.yaml` | 新增 | Hook 配置文件 |
| `openclaw-wrapper.sh` | 新增 | 包装脚本方案 |
| `scripts/sv_autoload.sh` | 新增 | 记忆自动加载脚本 |
| `scripts/sv_save.sh` | 新增 | 记忆保存脚本 |

---

## hook_loader.py 增强

### 原始版本 vs Viking 增强版

#### 原始版本功能
- 加载 YAML 配置
- 执行 Hook 脚本
- 基本超时控制

#### Viking 增强功能

```python
# 新增功能
class HooksManager:
    """Viking 增强版 Hook 加载器"""
    
    # 1. 环境变量支持
    def _execute_hook(self, hook: HookConfig, context_data: Optional[str] = None) -> Optional[str]:
        """执行单个 Hook，支持环境变量注入"""
        # 合并环境变量
        env = os.environ.copy()
        env.update(hook.get("env", {}))
        
        # 设置工作目录 (新增)
        cwd = hook.get("cwd", "/tmp")
        
        # 执行子进程
        process = subprocess.Popen(
            full_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            cwd=cwd,  # 新增: 工作目录支持
            text=True,
        )
        ...
    
    # 2. 超时增强 (新增)
    def _execute_hook(self, hook: HookConfig, ...):
        timeout = hook.get("timeout", 30)
        
        # 支持 soft_timeout 和 hard_timeout
        soft_timeout = hook.get("soft_timeout", timeout * 0.8)
        hard_timeout = hook.get("timeout", timeout)
        
        # 先发送 SIGTERM，超时再 SIGKILL
        try:
            stdout, stderr = process.communicate(input=context_data, timeout=soft_timeout)
        except subprocess.TimeoutExpired:
            # 软超时处理：发送警告，继续等待
            logger.warning(f"Hook approaching timeout: {hook.get('name')}")
            try:
                stdout, stderr = process.communicate(input=context_data, timeout=hard_timeout - soft_timeout)
            except subprocess.TimeoutExpired:
                # 硬超时：强制终止
                os.killpg(os.getpgid(process.pid), signal.SIGKILL)
    
    # 3. 输出截断保护 (新增)
    MAX_STDOUT_SIZE = 2048  # 2KB 限制
    
    def _execute_hook(self, hook, context_data):
        stdout, stderr = process.communicate(input=context_data, timeout=timeout)
        
        # 截断过长输出
        if len(stdout) > self.MAX_STDOUT_SIZE:
            stdout = stdout[:self.MAX_STDOUT_SIZE] + f"\n... [truncated {len(stdout) - self.MAX_STDOUT_SIZE} bytes]"
        
        return stdout
    
    # 4. 错误重试机制 (新增)
    def execute_with_retry(self, hook: HookConfig, context_data: Optional[str] = None) -> Optional[str]:
        """带重试的执行"""
        max_retries = hook.get("max_retries", 0)
        retry_delay = hook.get("retry_delay", 5)
        
        for attempt in range(max_retries + 1):
            try:
                return self._execute_hook(hook, context_data)
            except Exception as e:
                if attempt < max_retries:
                    logger.warning(f"Hook failed, retrying in {retry_delay}s: {e}")
                    time.sleep(retry_delay)
                else:
                    raise
```

### 配置示例

```python
# 增强配置
hook = {
    "name": "Viking Memory Loader",
    "command": "/path/to/sv_autoload.sh",
    "enabled": True,
    "timeout": 30,
    "soft_timeout": 20,       # 新增
    "max_retries": 3,         # 新增
    "retry_delay": 5,          # 新增
    "cwd": "/home/xlous",     # 新增
    "env": {
        "SV_WORKSPACE": "/home/xlous/.openclaw/viking-maojingli",
        "OLLAMA_HOST": "http://192.168.5.110:11434"
    }
}
```

---

## agent-hooks.yaml 配置格式

### 配置结构

```yaml
# OpenClaw Agent Hooks 配置
# 官方 Feature Request: https://github.com/openclaw/openclaw/issues/44661

hooks:
  on_session_start:
    - name: "Hook 名称"
      command: "/path/to/script.sh"
      enabled: true|false
      timeout: 30              # 超时秒数
      soft_timeout: 20        # 软超时秒数 (可选)
      max_retries: 0         # 重试次数 (可选)
      retry_delay: 5          # 重试间隔秒数 (可选)
      cwd: "/working/dir"     # 工作目录 (可选)
      args: []                # 脚本参数 (可选)
      env:                   # 环境变量 (可选)
        KEY: "value"
        
  on_session_end:
    - name: "Hook 名称"
      command: "/path/to/script.sh"
      enabled: false
      timeout: 30
      
  on_message:               # 新增: 消息触发
    - name: "消息处理 Hook"
      command: "/path/to/handler.sh"
      enabled: false
      trigger: "keyword"    # 触发关键词
```

### Viking 实际配置

```yaml
# ~/.openclaw/config/agent-hooks.yaml

hooks:
  on_session_start:
    - name: "Viking 记忆加载"
      command: "/home/xlous/.openclaw/scripts/sv_autoload.sh"
      enabled: true
      timeout: 30
      soft_timeout: 20
      max_retries: 2
      retry_delay: 3
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-maojingli"
        OLLAMA_HOST: "http://192.168.5.110:11434"
        
  on_session_end:
    - name: "Viking 记忆保存"
      command: "/home/xlous/.openclaw/scripts/sv_save.sh"
      enabled: false
      timeout: 30
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-maojingli"
```

---

## openclaw-wrapper.sh 包装脚本

### 脚本功能

`openclaw-wrapper.sh` 是一个包装脚本，提供以下功能：

1. **环境初始化**: 设置必要的工作环境变量
2. **Hook 触发**: 调用 OpenClaw 的 Hook 机制
3. **错误处理**: 优雅的错误处理和日志记录
4. **状态检查**: 检查 OpenClaw 和 LLM 服务状态

### 脚本内容

```bash
#!/bin/bash
# openclaw-wrapper.sh - OpenClaw 包装脚本
# 用法: openclaw-wrapper.sh [command] [options]

set -euo pipefail

# 配置
VIKING_DIR="${VIKING_DIR:-$HOME/.openclaw}"
CONFIG_DIR="${VIKING_DIR}/config"
LOG_DIR="${VIKING_DIR}/logs"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 检查依赖
check_dependencies() {
    local deps=("curl" "jq" "python3")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Missing dependency: $dep"
            exit 1
        fi
    done
}

# 检查 OpenClaw 状态
check_openclaw() {
    if ! pgrep -f "openclaw" > /dev/null; then
        log_warn "OpenClaw not running"
        return 1
    fi
    return 0
}

# 检查 LLM 服务
check_llm() {
    local host="${OLLAMA_HOST:-http://localhost:11434}"
    if ! curl -s "$host/api/tags" > /dev/null 2>&1; then
        log_warn "LLM service not available at $host"
        return 1
    fi
    return 0
}

# 执行 Hook
execute_hook() {
    local hook_name="$1"
    local hook_config="$CONFIG_DIR/agent-hooks.yaml"
    
    if [[ ! -f "$hook_config" ]]; then
        log_error "Hook config not found: $hook_config"
        return 1
    fi
    
    log_info "Executing hook: $hook_name"
    
    # 使用 Python Hook 加载器执行
    python3 "$VIKING_DIR/scripts/hook_loader.py" \
        --hook "$hook_name" \
        --config "$hook_config"
}

# 主命令
main() {
    local command="${1:-}"
    
    check_dependencies
    
    case "$command" in
        "status")
            check_openclaw && log_info "OpenClaw: Running" || log_error "OpenClaw: Not running"
            check_llm && log_info "LLM: Available" || log_warn "LLM: Not available"
            ;;
        "hook")
            execute_hook "${2:-}"
            ;;
        "check")
            check_dependencies
            check_openclaw
            check_llm
            log_info "All checks passed"
            ;;
        *)
            echo "Usage: $0 {status|hook|check} [args]"
            exit 1
            ;;
    esac
}

main "$@"
```

### 使用方法

```bash
# 检查状态
./openclaw-wrapper.sh status

# 执行 Hook
./openclaw-wrapper.sh hook on_session_start

# 完整检查
./openclaw-wrapper.sh check
```

---

## 集成验证

### 1. 验证 Hook 加载器

```bash
# 测试 Python Hook 加载器
python3 ~/.openclaw/scripts/hook_loader.py --help

# 测试配置加载
python3 -c "
import yaml
with open('~/.openclaw/config/agent-hooks.yaml') as f:
    config = yaml.safe_load(f)
    print('Hooks:', list(config.get('hooks', {}).keys()))
"
```

### 2. 验证脚本执行

```bash
# 测试自动加载脚本
~/.openclaw/scripts/sv_autoload.sh --help

# 手动触发
~/.openclaw/scripts/sv_autoload.sh
```

### 3. 验证集成

```bash
# 启动 OpenClaw
openclaw gateway start

# 检查 Hook 日志
tail -f ~/.openclaw/logs/hooks.log
```

---

## 兼容性说明

### OpenClaw 版本要求

| Viking 版本 | OpenClaw 最低版本 |
|-------------|-------------------|
| v2.0 | v0.3.0 |
| v1.x | v0.2.0 |

### 已测试的 Agent 列表

✅ **完全兼容**:
- maojingli (猫经理)
- maoxiami (猫小咪)
- maogongtou (猫工头)
- maozhuli (猫助理)

⚠️ **需适配**:
- 其他 OpenClaw Agent (需测试)

❌ **不支持**:
- 非 OpenClaw 框架 (如 LangChain Agent, AutoGPT 等)

### 回滚方案

如果 Viking 集成出现问题：

```bash
# 1. 禁用 Hook
# 编辑 ~/.openclaw/config/agent-hooks.yaml
enabled: false

# 2. 恢复原始 hook_loader.py
# 从备份恢复或重新安装 OpenClaw

# 3. 清理环境变量
unset SV_WORKSPACE
unset OLLAMA_HOST
```

---

## 相关文档

- [安装指南](../INSTALL.md)
- [使用说明](../USAGE.md)
- [架构设计](../ARCHITECTURE.md)
- [Viking 设计文档](./viking-design.md)

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
