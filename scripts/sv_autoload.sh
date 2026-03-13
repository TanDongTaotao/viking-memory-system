#!/bin/bash
#=============================================================================
# Viking 记忆自动加载脚本 (简化版)
#=============================================================================

set -e

AGENT_NAME="${AGENT_NAME:-${OPENCLAW_AGENT_NAME:-maojingli}}"
SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-${AGENT_NAME}}"

echo "## Viking 记忆加载"
echo "> Agent: ${AGENT_NAME}"
echo "> Workspace: ${SV_WORKSPACE}"
echo ""

# 检查 workspace
[ -d "$SV_WORKSPACE" ] || { echo "⚠️ Workspace 不存在"; exit 0; }

# 1. 核心配置 (限30行)
CONFIG_FILE="$SV_WORKSPACE/agent/memories/config/config.md"
if [ -f "$CONFIG_FILE" ]; then
    echo "### 核心配置"
    head -30 "$CONFIG_FILE"
    echo ""
fi

# 2. 最近7天日志 (限3个文件，每个20行)
HOT_DIR="$SV_WORKSPACE/agent/memories/hot"
if [ -d "$HOT_DIR" ]; then
    echo "### 最近工作日志"
    find "$HOT_DIR" -name "*.md" -mtime -7 2>/dev/null | sort -r | head -3 | while read f; do
        echo "--- $(basename "$f") ---"
        head -20 "$f"
        echo ""
    done
fi

# 3. 检查是否有待办任务
TASK_FILE="$SV_WORKSPACE/agent/memories/hot/TODO.md"
if [ -f "$TASK_FILE" ]; then
    echo "### 待办任务"
    head -15 "$TASK_FILE"
    echo ""
fi

echo "✅ 记忆加载完成"
