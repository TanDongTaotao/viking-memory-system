#!/usr/bin/env python3
"""
Viking 向量化模块
==================

功能: 将 Viking 记忆文本转换为向量嵌入，支持语义搜索

依赖:
    - sentence-transformers
    - numpy

使用示例:
    python viking-embed.py embed "Viking 记忆系统架构设计"
    python viking-embed.py search "团队协作" --top-k 5
"""

import sys
import json
import hashlib
from pathlib import Path

# 向量存储路径
VECTOR_STORE = Path.home() / ".openclaw" / "viking" / "vectors"
VECTOR_STORE.mkdir(parents=True, exist_ok=True)


def get_embedding(text: str, model: str = "paraphrase-multilingual-MiniLM-L12-v2") -> list:
    """
    获取文本的向量嵌入
    
    Args:
        text: 输入文本
        model: 模型名称 (默认多语言模型)
    
    Returns:
        向量列表
    """
    try:
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer(model)
        embedding = model.encode(text)
        return embedding.tolist()
    except ImportError:
        print("错误: 请安装 sentence-transformers")
        print("pip install sentence-transformers")
        sys.exit(1)


def embed_command(args):
    """嵌入命令"""
    if not args:
        print("用法: viking-embed.py embed <文本>")
        return
    
    text = " ".join(args)
    embedding = get_embedding(text)
    
    # 保存向量
    text_hash = hashlib.md5(text.encode()).hexdigest()
    vector_file = VECTOR_STORE / f"{text_hash}.json"
    
    with open(vector_file, "w") as f:
        json.dump({"text": text, "embedding": embedding}, f)
    
    print(f"✅ 已生成向量 (hash: {text_hash})")
    print(f"向量维度: {len(embedding)}")


def search_command(args):
    """搜索命令"""
    # 简化版搜索 (完整实现需向量相似度计算)
    query = " ".join(args) if args else ""
    if not query:
        print("用法: viking-embed.py search <关键词> [--top-k N]")
        return
    
    print(f"🔍 搜索: {query}")
    print("(需配置向量化模型和向量存储)")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    
    command = sys.argv[1]
    args = sys.argv[2:]
    
    if command == "embed":
        embed_command(args)
    elif command == "search":
        search_command(args)
    else:
        print(f"未知命令: {command}")
        print(__doc__)


if __name__ == "__main__":
    main()
