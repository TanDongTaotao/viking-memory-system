# 向量化搜索配置指南

## 概述

Viking 通过向量嵌入实现语义搜索，使 Agent 能理解记忆的语义而不仅仅是关键词匹配。

## 安装依赖

```bash
pip install sentence-transformers numpy torch
```

## 支持的模型

### 推荐模型

| 模型 | 语言 | 向量维度 | 特点 |
|------|------|----------|------|
| paraphrase-multilingual-MiniLM-L12-v2 | 多语言 | 384 | 轻量、快速 |
| paraphrase-multilingual-mpnet-base-v2 | 多语言 | 768 | 精度更高 |
| text2vec-base-chinese | 中文 | 768 | 中文优化 |

### 选择建议

- 中文内容: 使用 `text2vec-base-chinese`
- 多语言内容: 使用 `paraphrase-multilingual-MiniLM-L12-v2`
- 高精度需求: 使用 `paraphrase-multilingual-mpnet-base-v2`

## 使用方法

### 1. 生成向量

```bash
python scripts/viking-embed.py embed "Viking 记忆系统架构设计"
```

输出:
```
✅ 已生成向量 (hash: a1b2c3d4e5f6)
向量维度: 384
```

### 2. 语义搜索

```bash
python scripts/viking-embed.py search "团队协作"
```

### 3. Python API

```python
from viking_embed import get_embedding

# 生成向量
text = "Viking 是 AI Agent 记忆系统"
vector = get_embedding(text)
print(f"向量维度: {len(vector)}")

# 保存向量
import json
import hashlib
from pathlib import Path

text_hash = hashlib.md5(text.encode()).hexdigest()
vector_store = Path.home() / ".openclaw" / "viking" / "vectors"
vector_store.mkdir(parents=True, exist_ok=True)

with open(vector_store / f"{text_hash}.json", "w") as f:
    json.dump({"text": text, "embedding": vector}, f)
```

## 相似度计算

```python
import numpy as np

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

# 计算两条记忆的相似度
mem1 = get_embedding("团队会议讨论项目进度")
mem2 = get_embedding("项目组每日站会")

similarity = cosine_similarity(mem1, mem2)
print(f"相似度: {similarity:.4f}")
```

## 性能优化

### 批量处理

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")

# 批量生成向量
texts = [
    "记忆1...",
    "记忆2...",
    "记忆3...",
]
embeddings = model.encode(texts)
```

### 向量索引

对于大规模数据，考虑使用:
- FAISS (Facebook)
- Annoy (Spotify)
- Milvus

## 配置环境变量

```bash
# 默认模型
export EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2

# 向量存储路径
export VECTOR_STORE=~/.openclaw/viking/vectors
```

## 常见问题

### Q: 首次加载模型很慢
A: 模型约 500MB，首次使用会自动下载。建议提前下载:
```python
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2")
```

### Q: 内存占用高
A: 可选用更小的模型:
```python
model = SentenceTransformer("all-MiniLM-L6-v2")  # 只需 200MB
```

### Q: 中文效果不好
A: 使用中文专用模型:
```python
model = SentenceTransformer("text2vec-base-chinese")
```
