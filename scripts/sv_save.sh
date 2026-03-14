#!/bin/bash
# Viking 记忆保存脚本
# 用于 on_session_end 钩子

AGENT_NAME="${AGENT_NAME:-{agent}}"
SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-$AGENT_NAME}"

echo "保存会话记忆到 Viking..."

# 检查 sv_write 命令是否存在
if ! command -v sv_write &> /dev/null; then
    echo "警告: sv_write 命令不存在，使用 memory-pipeline 替代"
    
    # 尝试使用 memory-pipeline
    if command -v memory-pipeline &> /dev/null; then
        memory-pipeline save --agent "$AGENT_NAME" --tag "session-end"
    fi
else
    # 生成今日日志
    TODAY=$(date +%Y-%m-%d)
    CONTENT="# 会话结束 - $TODAY

时间: $(date)
会话ID: ${OPENCLAW_SESSION_ID:-unknown}

## 今日完成事项

(待补充)

## 明日待办

(待补充)
"
    echo "$CONTENT" | sv_write "viking://agent/memories/daily/$TODAY.md"
fi

echo "会话记忆已保存"
