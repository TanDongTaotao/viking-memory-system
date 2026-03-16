#!/bin/bash
#
# memory-extract-summary.sh
# 使用 LLM 智能提取会话摘要、任务和待办
#

set -e

AGENT_NAME="${1:-maojingli}"
SESSION_FILE="$2"
YESTERDAY="${3:-$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)}"

if [ -z "$SESSION_FILE" ] || [ ! -f "$SESSION_FILE" ]; then
    echo "用法: $0 <agent_name> <session_file> [yesterday_date]"
    exit 1
fi

# 提取会话内容（限制长度）
SESSION_CONTENT=$(cat "$SESSION_FILE" | head -c 15000)

# 构建提示词
read -r -d '' PROMPT << 'EOF'
请分析以下会话记录，提取关键信息并以结构化格式输出：

【会话内容】
{{SESSION_CONTENT}}

请提取以下内容：
1. **会话主题**：用一句话概括这次会话的核心内容
2. **关键决策**：列出本次会话中做出的所有决策（如有）
3. **待办任务**：列出所有未完成的任务，格式为 "- [ ] 任务描述"
4. **重要性评估**：判断本次会话的重要性（high/medium/low），考虑因素：是否涉及董事长guyxlous、是否紧急、是否是bug修复、是否是重要决策

请严格按照以下格式输出：

```
主题: <一句话主题>

决策:
- <决策1>
- <决策2>

待办:
- [ ] <任务1>
- [ ] <任务2>

重要性: <high/medium/low>
```
EOF

PROMPT=$(echo "$PROMPT" | sed "s|{{SESSION_CONTENT}}|$SESSION_CONTENT|g")

# 调用 OpenClaw Agent 使用 Step3.5Flash
OPENCLAW_BIN="${OPENCLAW_BIN:-/home/xlous/.npm-global/bin/openclaw}"

RESULT=$("$OPENCLAW_BIN" agent --local --agent maoxiami --message "$PROMPT" 2>/dev/null | head -100)

# 解析结果
SUMMARY=$(echo "$RESULT" | grep -A 100 "主题:" | head -50)
IMPORTANCE=$(echo "$SUMMARY" | grep "重要性:" | sed 's/.*重要性: *//' | tr -d ' ')
TODO_LIST=$(echo "$SUMMARY" | grep "^- \[ \]" | head -10)

# 输出结构化结果
echo "=== 智能会话摘要 ==="
echo "Agent: $AGENT_NAME"
echo "日期: $YESTERDAY"
echo "重要性: ${IMPORTANCE:-medium}"
echo ""
echo "--- 摘要 ---"
echo "$SUMMARY"
echo ""
echo "--- 待办任务 ---"
if [ -n "$TODO_LIST" ]; then
    echo "$TODO_LIST"
else
    echo "- [ ] 检查昨日任务完成情况"
    echo "- [ ] 继续推进进行中的项目"
fi
