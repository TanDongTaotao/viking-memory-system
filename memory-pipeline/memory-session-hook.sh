#!/bin/bash
#
# 会话钩子：会话结束时自动保存
# 需要在 OpenClaw 配置中调用
#

AGENT_NAME="${AGENT_NAME:-maojingli}"

# 获取最近的消息作为摘要
SESSION_SUMMARY="${1:-会话摘要}"

# 调用自动保存
~/.openclaw/skills/memory-pipeline/scripts/memory-auto-save.sh save \
    "$SESSION_SUMMARY" \
    "会话结束-$(date +%Y-%m-%d-%H:%M)"

echo "✅ 会话已保存"
