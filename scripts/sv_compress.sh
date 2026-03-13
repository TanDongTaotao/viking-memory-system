#!/bin/bash
#=============================================================================
# Viking 记忆压缩脚本
#=============================================================================
# 功能: 压缩/归档长时间未访问的记忆
# 使用: sv_compress.sh

set -e

SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-$AGENT_NAME}"
ARCHIVE_DIR="$SV_WORKSPACE/.archive"

echo "## Viking 记忆压缩"
echo "> Workspace: ${SV_WORKSPACE}"
echo ""

# 创建归档目录
mkdir -p "$ARCHIVE_DIR"

# 压缩90天+未访问的记忆
find "$SV_WORKSPACE" -name "*.md" -mtime +90 -type f 2>/dev/null | while read f; do
    echo "压缩: $f"
    gzip -c "$f" > "$ARCHIVE_DIR/$(basename "$f").gz"
    rm "$f"
done

echo ""
echo "✅ 记忆压缩完成 (90天+已归档)"
