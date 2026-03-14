#!/bin/bash
#
# memory-auto-save.sh
# 自动记忆保存机制
# 支持：会话结束自动保存、关键词触发保存
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

# 检查是否需要自动保存
should_auto_save() {
    local content="$1"
    
    # 检查关键词
    if echo "$content" | grep -qE "$AUTO_SAVE_KEYWORDS"; then
        return 0
    fi
    
    # 检查是否有待办完成
    if echo "$content" | grep -qE "^- \[x\]"; then
        return 0
    fi
    
    return 1
}

# 自动保存会话摘要
auto_save_session() {
    local summary="$1"
    local title="${2:-会话摘要}"
    
    if [ -z "$summary" ]; then
        echo -e "${YELLOW}摘要为空，跳过保存${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}检测到重要内容，自动保存记忆...${NC}"
    
    # 使用 mp_store 保存
    ~/.openclaw/skills/memory-pipeline/scripts/memory-pipeline mp_store \
        --content "$summary" \
        --title "$title" \
        --tags "自动保存,会话" \
        --tier L0
    
    return $?
}

# 监听模式：持续监控输入
monitor_mode() {
    echo -e "${GREEN}=== 自动保存监听模式 ===${NC}"
    echo "监听关键词: $AUTO_SAVE_KEYWORDS"
    echo "按 Ctrl+C 退出"
    echo ""
    
    local buffer=""
    
    while read -r line; do
        buffer+="$line"$'\n'
        
        # 检查是否触发保存
        if should_auto_save "$buffer"; then
            echo -e "${GREEN}检测到触发关键词: $line${NC}"
            
            # 提取关键内容（最近几行）
            local recent_lines
            recent_lines=$(echo "$buffer" | tail -10)
            
            # 保存
            auto_save_session "$recent_lines" "自动保存-$(date +%H:%M)"
            
            # 清空缓冲区
            buffer=""
        fi
    done
}

# 从对话中提取任务并保存
extract_and_save() {
    local conversation="$1"
    
    # 提取任务信息
    local title=""
    local content=""
    
    # 提取标题（第一行或包含任务的那行）
    title=$(echo "$conversation" | head -1 | head -c 50)
    
    # 提取关键信息
    content="$conversation"
    
    if should_auto_save "$content"; then
        auto_save_session "$content" "$title"
    fi
}

# 主入口
case "$1" in
    monitor)
        monitor_mode
        ;;
    save)
        auto_save_session "$2" "$3"
        ;;
    check)
        should_auto_save "$2" && echo "需要保存" || echo "不需要保存"
        ;;
    extract)
        extract_and_save "$2"
        ;;
    *)
        echo "用法:"
        echo "  $0 monitor           # 监听模式（从stdin读取）"
        echo "  $0 save <内容> [标题] # 手动保存"
        echo "  $0 check <内容>       # 检查是否需要保存"
        echo "  $0 extract <对话>     # 从对话提取并保存"
        ;;
esac
