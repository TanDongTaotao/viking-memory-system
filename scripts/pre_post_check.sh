#!/bin/bash
#
# 发布前安全检查脚本 (Pre-Post Check)
# 用于社区发布前的敏感信息检查
#
# 退出码:
#   0 - 通过检查，可以发布
#   1 - 需人工确认后发布
#   2 - 拦截发布，风险过高
#

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER_SCRIPT="$SCRIPT_DIR/sensitive_filter.py"
LOG_FILE="$HOME/.openclaw/logs/security_audit.log"

# 颜色输出
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 日志函数
log_audit() {
    local action="$1"
    local status="$2"
    local details="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 写入日志
    echo "[$timestamp] [$action] [$status] $details" >> "$LOG_FILE"
}

# 显示帮助
show_help() {
    cat << EOF
用法: $(basename "$0") [选项] <文本内容>

选项:
    -f, --file <文件>     从文件读取内容
    -j, --json            JSON 格式输出结果
    -w, --whitelist <词>  添加白名单关键词 (可多次使用)
    -h, --help            显示帮助信息
    -y, --yes             自动确认并发布 (跳过确认提示)
    -v, --verbose         详细输出

示例:
    $(basename "$0") "这是一条测试消息"
    $(basename "$0") -f post_content.txt
    echo "消息内容" | $(basename "$0")
EOF
}

# 解析参数
JSON_OUTPUT=false
AUTO_YES=false
VERBOSE=false
WHITELIST=()
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            INPUT_FILE="$2"
            shift 2
            ;;
        -j|--json)
            JSON_OUTPUT=true
            shift
            ;;
        -w|--whitelist)
            WHITELIST+=("$2")
            shift 2
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            TEXT_CONTENT="$1"
            shift
            ;;
    esac
done

# 获取文本内容
if [[ -n "$INPUT_FILE" ]]; then
    if [[ -f "$INPUT_FILE" ]]; then
        CONTENT=$(cat "$INPUT_FILE")
    else
        echo -e "${RED}错误: 文件不存在: $INPUT_FILE${NC}" >&2
        exit 2
    fi
elif [[ -n "$TEXT_CONTENT" ]]; then
    CONTENT="$TEXT_CONTENT"
elif [[ ! -t 0 ]]; then
    # 从 stdin 读取
    CONTENT=$(cat)
else
    echo -e "${RED}错误: 请提供要检查的内容${NC}" >&2
    show_help
    exit 1
fi

# 检查过滤器脚本是否存在
if [[ ! -f "$FILTER_SCRIPT" ]]; then
    echo -e "${RED}错误: 敏感信息过滤器不存在: $FILTER_SCRIPT${NC}" >&2
    exit 2
fi

# 构建白名单参数
WHITELIST_ARGS=""
for item in "${WHITELIST[@]}"; do
    WHITELIST_ARGS="$WHITELIST_ARGS -w $item"
done

# 执行检查
if [[ "$VERBOSE" == "true" ]]; then
    echo "执行敏感信息检查..."
fi

# 调用 Python 过滤器 (使用 -j 参数获取 JSON 输出)
RESULT=$(python3 "$FILTER_SCRIPT" -j "$CONTENT" $WHITELIST_ARGS 2>&1) || {
    echo -e "${RED}错误: 过滤器执行失败${NC}" >&2
    log_audit "PRE_POST_CHECK" "ERROR" "过滤器执行失败"
    exit 2
}

# 解析结果
PASSED=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['passed'])")
RISK_LEVEL=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['risk_level'])")
NEED_REVIEW=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['need_review'])")
MATCH_COUNT=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['matches']))")

# 日志记录
log_audit "PRE_POST_CHECK" "COMPLETED" "risk_level=$RISK_LEVEL, matched=$MATCH_COUNT"

# 输出结果
if [[ "$JSON_OUTPUT" == "true" ]]; then
    echo "$RESULT"
fi

# 根据风险等级决定退出码
if [[ "$RISK_LEVEL" == "critical" ]]; then
    echo -e "${RED}✗ 拦截发布: 检测到高风险敏感信息${NC}"
    echo "风险等级: $RISK_LEVEL"
    echo "匹配数量: $MATCH_COUNT"
    echo ""
    echo "匹配详情:"
    echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  - [{m[\"type\"]}] {m[\"masked_value\"]}') for m in d['matches']]"
    log_audit "PRE_POST_CHECK" "BLOCKED" "critical risk detected"
    exit 2
    
elif [[ "$NEED_REVIEW" == "True" || "$RISK_LEVEL" == "high" ]]; then
    echo -e "${YELLOW}⚠ 需人工确认: 检测到敏感信息${NC}"
    echo "风险等级: $RISK_LEVEL"
    echo "匹配数量: $MATCH_COUNT"
    echo ""
    echo "匹配详情:"
    echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  - [{m[\"type\"]}] {m[\"masked_value\"]}') for m in d['matches']]"
    echo ""
    
    if [[ "$AUTO_YES" == "true" ]]; then
        echo "自动确认发布..."
        log_audit "PRE_POST_CHECK" "MANUAL_APPROVED" "auto-approved by user"
        exit 0
    fi
    
    read -p "确认发布? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_audit "PRE_POST_CHECK" "MANUAL_APPROVED" "user approved"
        exit 0
    else
        log_audit "PRE_POST_CHECK" "USER_REJECTED" "user rejected"
        exit 1
    fi
    
elif [[ "$MATCH_COUNT" -gt 0 ]]; then
    echo -e "${YELLOW}⚠ 低风险: 检测到少量敏感信息 (已自动过滤)${NC}"
    echo "风险等级: $RISK_LEVEL"
    echo "匹配数量: $MATCH_COUNT"
    echo ""
    echo "匹配详情:"
    echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  - [{m[\"type\"]}] {m[\"masked_value\"]}') for m in d['matches']]"
    log_audit "PRE_POST_CHECK" "AUTO_FILTERED" "low risk, auto-filtered"
    exit 0
    
else
    echo -e "${GREEN}✓ 通过检查: 未检测到敏感信息${NC}"
    log_audit "PRE_POST_CHECK" "PASSED" "no sensitive content detected"
    exit 0
fi
