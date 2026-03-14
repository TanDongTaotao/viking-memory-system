#!/bin/bash
# Viking 向量化搜索脚本
# 调用本地 Ollama embedding 模型进行语义搜索

# 从脚本名称提取 Agent 名称（备用）
AGENT_NAME="${AGENT_NAME:-$(basename "$0" | cut -d'-' -f2)}"

OLLAMA_HOST="http://192.168.5.110:11434"
EMBED_MODEL="nomic-embed-text:latest"

# 搜索函数
viking_semantic_search() {
    local query="$1"
    local top_k="${2:-5}"
    
    # 获取查询的 embedding
    local embedding=$(curl -s -X POST "$OLLAMA_HOST/api/embeddings" \
        -d "{\"model\": \"$EMBED_MODEL\", \"prompt\": \"$query\"}" \
        | jq -r '.embedding')
    
    if [ "$embedding" = "null" ] || [ -z "$embedding" ]; then
        echo "Error: Failed to get embedding"
        return 1
    fi
    
    # TODO: 这里需要结合 Viking 的文件索引做相似度匹配
    # 暂时用简单的关键词搜索作为 fallback
    echo "Query: $query"
    echo "Embedding dimension: $(echo $embedding | tr ' ' '\n' | wc -l)"
    echo "Top-k: $top_k"
    echo ""
    echo "提示: 向量搜索需要配合 Viking 索引使用"
    echo "当前返回关键词搜索结果:"
    
    # 临时用 sv_find 作为 fallback
    if command -v sv_find &> /dev/null; then
        sv_find "$query" --limit $top_k
    else
        echo "Viking CLI 未安装，请先安装 simple-viking"
    fi
}

# 主入口
case "$1" in
    search)
        viking_semantic_search "$2" "$3"
        ;;
    embed)
        # 直接返回文本的 embedding
        curl -s -X POST "$OLLAMA_HOST/api/embeddings" \
            -d "{\"model\": \"$EMBED_MODEL\", \"prompt\": \"$2\"}" \
            | jq '.embedding'
        ;;
    test)
        # 测试连接
        curl -s "$OLLAMA_HOST/api/tags" | jq '.models[].name'
        ;;
    *)
        echo "用法:"
        echo "  $0 search <查询内容> [top-k]"
        echo "  $0 embed <文本>"
        echo "  $0 test"
        ;;
esac
