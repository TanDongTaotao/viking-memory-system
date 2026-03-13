#!/bin/bash
# Viking 内存监听器 - 实时同步 hot/ 目录的新文件
# 用法：在会话启动时后台运行此脚本

set -e

# 确保本地 bin/lib 在 PATH/LD_LIBRARY_PATH 中
export PATH="$HOME/.local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"

# 配置
SV_WORKSPACE="${SV_WORKSPACE:-$HOME/.openclaw/viking-default}"

# 支持两种模式：
# 1. 标准模式：监听 $SV_WORKSPACE/agent/memories/hot
# 2. 全局模式：通过 WATCH_DIR_OVERRIDE 指定目录（用于 viking-global）
if [ -n "$WATCH_DIR_OVERRIDE" ]; then
    WATCH_DIR="$WATCH_DIR_OVERRIDE"
else
    WATCH_DIR="$SV_WORKSPACE/agent/memories/hot"
fi

LOADED_TRACKER="/tmp/viking_loaded_$(echo "$WATCH_DIR" | md5sum | cut -d' ' -f1).list"
LOG_FILE="/tmp/viking_watcher_$(echo "$WATCH_DIR" | md5sum | cut -d' ' -f1).log"

# 初始化
mkdir -p "$WATCH_DIR"
touch "$LOADED_TRACKER"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Viking 监听器启动" >> "$LOG_FILE"
echo "监控目录: $WATCH_DIR" >> "$LOG_FILE"
echo "已加载记录: $LOADED_TRACKER" >> "$LOG_FILE"

# 检查 inotifywait 是否可用
if command -v inotifywait &> /dev/null; then
    echo "[$(date)] 使用 inotify (Linux)" >> "$LOG_FILE"
    
    # 监听文件关闭写入事件（确保文件写入完成）
    inotifywait -m -e close_write --format "%w%f" "$WATCH_DIR" 2>/dev/null | while read new_file; do
        # 过滤条件
        if [[ ! "$new_file" == *.md ]]; then
            continue
        fi
        
        # 检查是否已加载过
        if grep -q "^$new_file$" "$LOADED_TRACKER" 2>/dev/null; then
            echo "[$(date)] 跳过已加载: $(basename "$new_file")" >> "$LOG_FILE"
            continue
        fi
        
        # 加载新记忆
        echo "" >> /dev/stdout
        echo "=== 🔄 检测到新记忆: $(basename "$new_file") ===" >> /dev/stdout
        echo "时间: $(date '+%H:%M:%S')" >> /dev/stdout
        
        # 输出文件内容（限制长度，避免超token）
        # 优先读取 L0 完整部分，若无则读取全部
        if grep -q "^# L0 " "$new_file" 2>/dev/null; then
            # 提取 L0 部分
            sed -n '/^# L0 /,/^##/p' "$new_file" | head -c 2000 >> /dev/stdout
        else
            # 直接输出前2000字符
            head -c 2000 "$new_file" >> /dev/stdout
        fi
        
        echo "" >> /dev/stdout
        echo "=== 加载完成 ===" >> /dev/stdout
        
        # 记录已加载
        echo "$new_file" >> "$LOADED_TRACKER"
        
        echo "[$(date)] 已加载: $(basename "$new_file")" >> "$LOG_FILE"
    done
    
else
    echo "[$(date)] inotifywait 未安装，使用轮询模式" >> "$LOG_FILE"
    
    # 轮询模式（兼容 macOS 等）
    LAST_CHECK=$(date +%s)
    
    while true; do
        sleep 10  # 10秒轮询一次
        
        # 查找最近10秒内修改的 .md 文件
        CURRENT_TIME=$(date +%s)
        
        # 使用临时文件列表避免管道子shell问题
        FIND_RESULT=$(mktemp)
        find "$WATCH_DIR" -name "*.md" -type f 2>/dev/null > "$FIND_RESULT"
        
        while IFS= read -r new_file; do
            [ -n "$new_file" ] || continue
            FILE_MTIME=$(stat -c %Y "$new_file" 2>/dev/null || echo 0)
            if [ $FILE_MTIME -gt $LAST_CHECK ]; then
                # 检查是否已加载
                if grep -q "^$new_file$" "$LOADED_TRACKER" 2>/dev/null; then
                    continue
                fi
                
                echo "" >> /dev/stdout
                echo "=== 🔄 检测到新记忆: $(basename "$new_file") ===" >> /dev/stdout
                echo "时间: $(date '+%H:%M:%S')" >> /dev/stdout
                
                if grep -q "^# L0 " "$new_file" 2>/dev/null; then
                    sed -n '/^# L0 /,/^##/p' "$new_file" | head -c 2000 >> /dev/stdout
                else
                    head -c 2000 "$new_file" >> /dev/stdout
                fi
                
                echo "" >> /dev/stdout
                echo "=== 加载完成 ===" >> /dev/stdout
                
                echo "$new_file" >> "$LOADED_TRACKER"
                echo "[$(date)] 已加载: $(basename "$new_file")" >> "$LOG_FILE"
            fi
        done < "$FIND_RESULT"
        rm -f "$FIND_RESULT"
        
        LAST_CHECK=$CURRENT_TIME
    done
fi
