#!/bin/bash
#=============================================================================
# Viking 记忆搜索脚本
#=============================================================================
# 功能: 基于关键词搜索 Viking 记忆
# 使用: sv_recall.sh "搜索关键词"

set -e

KEYWORD="${1:-}"
SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-$AGENT_NAME}"

if [ -z "$KEYWORD" ]; then
    echo "用法: sv_recall.sh \"搜索关键词\""
    exit 1
fi

echo "## Viking 记忆搜索"
echo "> 关键词: ${KEYWORD}"
echo ""

# 检查 workspace
[ -d "$SV_WORKSPACE" ] || { echo "⚠️ Workspace 不存在"; exit 1; }

# 使用 grep 搜索所有 markdown 文件
echo "### 搜索结果"
grep -rn "$KEYWORD" "$SV_WORKSPACE" --include="*.md" 2>/dev/null | head -20 || echo "未找到相关记忆"

echo ""
echo "✅ 搜索完成"
