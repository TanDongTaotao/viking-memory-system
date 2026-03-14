#!/bin/bash
#
# memory-tier-cron.sh
# 每天自动执行所有 Agent 和全局记忆的降级
# 由 cron 每天凌晨 3 点调用
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/memory-tier-downgrade-$(date +%Y%m%d).log"

echo "=== 记忆层级降级 Cron ==="
echo "时间: $(date)"
echo ""

# Agent 列表
AGENTS="maojingli maoxiami maogongtou maozhuli global"

for agent in $AGENTS; do
    echo ">>> 处理: $agent"
    
    if [ "$agent" = "global" ]; then
        export SV_WORKSPACE="$HOME/.openclaw/viking-global"
    else
        export SV_WORKSPACE="$HOME/.openclaw/viking-$agent"
    fi
    
    # 执行降级
    "$SCRIPT_DIR/memory-tier-downgrade.sh" "$agent" || echo "  ⚠️ $agent 处理完成"
    
    echo ""
done

echo "=== 全部完成 ==="
