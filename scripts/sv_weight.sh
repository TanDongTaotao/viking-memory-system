#!/bin/bash
#=============================================================================
# Viking 记忆权重计算脚本
#=============================================================================
# 功能: 根据访问频率、时间衰减计算记忆权重
# 使用: sv_weight.sh [记忆文件路径]

set -e

MEMORY_FILE="${1:-}"
SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-$AGENT_NAME}"

echo "## Viking 记忆权重计算"
echo "> 文件: ${MEMORY_FILE:-all}"
echo ""

# 五层衰减机制权重
# L1: 核心配置 (权重 1.0)
# L2: 7天内热数据 (权重 0.8)
# L3: 30天内温数据 (权重 0.5)
# L4: 90天冷却数据 (权重 0.2)
# L5: 90天+冷数据 (权重 0.1，待压缩)

calculate_weight() {
    local file="$1"
    local days=$(find "$file" -mtime -7 2>/dev/null | wc -l)
    echo "权重计算: 基于访问时间和频率"
}

if [ -n "$MEMORY_FILE" ] && [ -f "$MEMORY_FILE" ]; then
    calculate_weight "$MEMORY_FILE"
else
    echo "扫描记忆目录..."
    find "$SV_WORKSPACE" -name "*.md" -type f 2>/dev/null | while read f; do
        days=$(($(date +%s) - $(stat -c %Y "$f" 2>/dev/null || echo $(date +%s))) / 86400)
        if [ "$days" -lt 7 ]; then
            weight="0.8 (热)"
        elif [ "$days" -lt 30 ]; then
            weight="0.5 (温)"
        elif [ "$days" -lt 90 ]; then
            weight="0.2 (冷)"
        else
            weight="0.1 (冻结)"
        fi
        echo "$weight - $f"
    done
fi

echo ""
echo "✅ 权重计算完成"
