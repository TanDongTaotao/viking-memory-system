#!/bin/bash
#
# memory-auto-save.sh
# 自动记忆保存机制
# 支持：会话结束自动保存、关键词触发保存、去重
#

set -e

AGENT_NAME="${AGENT_NAME:-maojingli}"
SV_WORKSPACE="$HOME/.openclaw/viking-$AGENT_NAME"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 自动保存关键词
AUTO_SAVE_KEYWORDS="完成|解决|修复|创建|更新|修改|删除|提交|部署|测试|验证|确认|通过"

# 去重：根据标题检查是否已存在
is_duplicate() {
    local title="$1"
    local workspace="${2:-$SV_WORKSPACE}"
    
    # 标准化标题
    local norm_title
    norm_title=$(echo "$title" | tr -d '\n' | tr -s ' ')
    
    # 检查 hot 目录是否有相同标题
    if [ -d "$workspace/agent/memories/hot" ]; then
        for file in "$workspace/agent/memories/hot"/*.md; do
            [ -f "$file" ] || continue
            [[ "$(basename "$file")" == .* ]] && continue
            
            # 从文件名提取标题
            filename=$(basename "$file" .md | sed 's/^[0-9-]*_*[0-9]*_//')
            
            if echo "$filename" | grep -qF "$norm_title"; then
                echo "重复: $(basename "$file")"
                return 0
            fi
        done
    fi
    return 1
}

# 检查是否需要自动保存
should_auto_save() {
    local content="$1"
    echo "$content" | grep -qE "$AUTO_SAVE_KEYWORDS"
}

# 自动保存（带去重）
auto_save_session() {
    local summary="$1"
    local title="${2:-会话摘要}"
    
    [ -z "$summary" ] && return 1
    
    # 根据标题去重
    if is_duplicate "$title" "$SV_WORKSPACE"; then
        echo -e "${YELLOW}跳过（已有相同标题记忆）${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}保存记忆: $title${NC}"
    ~/.openclaw/skills/memory-pipeline/scripts/memory-pipeline mp_store \
        --content "$summary" --title "$title" --tags "自动保存" --tier L0
}

# 主入口
case "$1" in
    save)
        auto_save_session "$2" "$3"
        ;;
    check)
        should_auto_save "$2" && echo "需要保存" || echo "不需要保存"
        ;;
    dedup)
        # 简单去重检查
        workspace="${2:-$SV_WORKSPACE}"
        echo "=== 去重检查: $workspace ==="
        find "$workspace/agent/memories/hot" -name "*.md" -type f ! -name ".*" 2>/dev/null | \
            while read f; do
                echo "$(basename "$f"): $(head -c 30 "$f")"
            done | sort | uniq -d -w30
        ;;
    *)
        echo "用法: $0 save <内容> [标题] | check <内容> | dedup [workspace]"
        ;;
esac
