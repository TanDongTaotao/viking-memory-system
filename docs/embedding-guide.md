# Viking 记忆系统嵌入指南

本文档介绍如何将 Viking 记忆系统嵌入到其他系统和应用程序中。

## 目录

1. [概述](#概述)
2. [嵌入式方式](#嵌入式方式)
3. [Python API](#python-api)
4. [命令行集成](#命令行集成)
5. [Webhook 集成](#webhook-集成)
6. [HTTP API](#http-api)
7. [示例项目](#示例项目)

---

## 概述

Viking 记忆系统支持多种嵌入方式，以适应不同的使用场景：

- **Python 模块**: 直接导入使用
- **命令行工具**: 通过 Shell 调用
- **Webhook**: HTTP 回调触发
- **HTTP API**: RESTful 接口

---

## 嵌入式方式

### 方式选择指南

| 场景 | 推荐方式 | 说明 |
|------|----------|------|
| Python 应用 | Python API | 最灵活，完全控制 |
| 脚本/自动化 | 命令行 | 简单易用 |
| Web 服务 | HTTP API | 支持远程调用 |
| 外部触发 | Webhook | 事件驱动 |

---

## Python API

### 基础用法

```python
import sys
sys.path.insert(0, '/path/to/viking/scripts')

from viking_core import VikingMemory

# 初始化
viking = VikingMemory(
    workspace="~/.openclaw/viking-test",
    llm_service="ollama",
    llm_model="glm-4-flash"
)

# 写入记忆
viking.write(
    title="测试记忆",
    content="这是测试内容",
    importance="high"
)

# 读取记忆
memory = viking.read("mem_20260314_001")

# 搜索记忆
results = viking.search("测试")

# 压缩
viking.compress()
```

### 完整 API 参考

```python
class VikingMemory:
    """Viking 记忆系统 Python API"""
    
    def __init__(
        self,
        workspace: str,
        llm_service: str = "ollama",
        llm_model: str = "glm-4-flash",
        llm_host: str = "http://localhost:11434"
    ):
        """初始化 Viking 记忆系统
        
        Args:
            workspace: 工作空间路径
            llm_service: LLM 服务类型 (ollama/openai/anthropic)
            llm_model: LLM 模型名称
            llm_host: LLM 服务地址
        """
        pass
    
    def write(
        self,
        title: str,
        content: str,
        importance: str = "medium",
        important: bool = False,
        tags: List[str] = None,
        retention: int = 90
    ) -> str:
        """写入记忆
        
        Returns:
            记忆 ID
        """
        pass
    
    def read(
        self,
        memory_id: str,
        refresh_weight: bool = True
    ) -> dict:
        """读取记忆
        
        Returns:
            包含 content, metadata 的字典
        """
        pass
    
    def search(
        self,
        query: str,
        layer: str = None,
        importance: str = None,
        limit: int = 10
    ) -> List[dict]:
        """搜索记忆
        
        Returns:
            记忆列表
        """
        pass
    
    def list(
        self,
        layer: str = None,
        importance: str = None,
        limit: int = 100
    ) -> List[dict]:
        """列出记忆
        
        Returns:
            记忆列表
        """
        pass
    
    def compress(
        self,
        memory_id: str = None,
        dry_run: bool = False
    ) -> dict:
        """压缩记忆
        
        Args:
            memory_id: 指定记忆 ID，为空则压缩所有
            dry_run: 仅预览不执行
        
        Returns:
            压缩结果
        """
        pass
    
    def get_weight(self, memory_id: str) -> float:
        """获取记忆权重"""
        pass
    
    def set_importance(
        self,
        memory_id: str,
        importance: str,
        important: bool = None
    ):
        """设置重要性"""
        pass
    
    def recall(self, query: str) -> dict:
        """回忆搜索（包含 LLM 恢复）
        
        Returns:
            包含原始记忆 + LLM 恢复内容
        """
        pass
```

### 异步用法

```python
import asyncio
from viking_core import AsyncVikingMemory

async def main():
    viking = AsyncVikingMemory(workspace="~/.openclaw/viking-test")
    
    # 异步写入
    memory_id = await viking.write(
        title="异步测试",
        content="异步写入的内容"
    )
    
    # 异步搜索
    results = await viking.search("测试")

asyncio.run(main())
```

---

## 命令行集成

### 基本命令

```bash
# 写入
viking-write --title "标题" --content "内容" --importance high

# 读取
viking-read mem_20260314_001

# 搜索
viking-search "关键词"

# 压缩
viking-compress --dry-run

# 列出
viking-list --layer L0 --limit 10
```

### Shell 脚本集成

```bash
#!/bin/bash
# viking-integration.sh

VIKING_HOME="/path/to/viking"
WORKSPACE="$HOME/.openclaw/viking-test"

# 写入记忆
write_memory() {
    local title="$1"
    local content="$2"
    
    $VIKING_HOME/scripts/sv_save.sh \
        --title "$title" \
        --content "$content" \
        --workspace "$WORKSPACE"
}

# 搜索记忆
search_memory() {
    local query="$1"
    
    $VIKING_HOME/scripts/sv_recall.sh \
        --query "$query" \
        --workspace "$WORKSPACE"
}

# 使用示例
write_memory "自动任务" "从脚本自动创建的記憶"
search_memory "自动任务"
```

### 环境变量配置

```bash
# 基础配置
export VIKING_WORKSPACE="$HOME/.openclaw/viking-test"
export VIKING_LLM_HOST="http://192.168.5.110:11434"
export VIKING_LLM_MODEL="glm-4-flash"

# 可选配置
export VIKING_LOG_LEVEL="debug"
export VIKING_CACHE_DIR="/tmp/viking-cache"
```

---

## Webhook 集成

### 配置 Webhook

```yaml
# viking-webhook.yaml
webhooks:
  # 写入触发
  on_write:
    url: "https://your-server.com/webhook/write"
    method: POST
    headers:
      Authorization: "Bearer xxx"
    body:
      memory_id: "{memory_id}"
      title: "{title}"
      importance: "{importance}"
  
  # 搜索触发
  on_search:
    url: "https://your-server.com/webhook/search"
    method: POST
    body:
      query: "{query}"
      results_count: "{results_count}"
```

### 接收 Webhook

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/webhook/write', methods=['POST'])
def handle_write():
    data = request.json
    print(f"New memory written: {data['memory_id']}")
    # 处理新记忆
    return jsonify({"status": "ok"})

@app.route('/webhook/search', methods=['POST'])
def handle_search():
    data = request.json
    print(f"Search query: {data['query']}")
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    app.run(port=5000)
```

---

## HTTP API

### 启动 API 服务

```bash
# 启动服务
python -m viking_api --host 0.0.0.0 --port 8080

# 或使用 Docker
docker run -p 8080:8080 viking-memory-api
```

### API 端点

#### 写入记忆

```bash
POST /api/v1/memories
Content-Type: application/json

{
    "title": "测试记忆",
    "content": "这是测试内容",
    "importance": "high",
    "tags": ["测试", "示例"]
}
```

响应:
```json
{
    "status": "success",
    "memory_id": "mem_20260314_001",
    "created": "2026-03-14T10:30:00Z"
}
```

#### 读取记忆

```bash
GET /api/v1/memories/{memory_id}
```

响应:
```json
{
    "memory_id": "mem_20260314_001",
    "title": "测试记忆",
    "content": "这是测试内容",
    "importance": "high",
    "layer": "L0",
    "weight": 12.5,
    "created": "2026-03-14T10:30:00Z",
    "last_access": "2026-03-14T14:22:00Z"
}
```

#### 搜索记忆

```bash
POST /api/v1/search
Content-Type: application/json

{
    "query": "测试",
    "layer": "L0,L1",
    "limit": 10
}
```

#### 回忆搜索

```bash
POST /api/v1/recall
Content-Type: application/json

{
    "query": "2025年的项目",
    "include_archived": true
}
```

---

## 示例项目

### 示例 1: Slack Bot 集成

```python
from slack_sdk import WebClient
from viking_core import VikingMemory

slack = WebClient(token="xoxb-...")
viking = VikingMemory(workspace="~/.openclaw/viking-test")

def handle_slack_message(event):
    text = event['text']
    channel = event['channel']
    
    # 搜索相关记忆
    results = viking.search(text)
    
    if results:
        # 回复记忆内容
        slack.chat_postMessage(
            channel=channel,
            text=f"找到相关记忆: {results[0]['title']}\n{results[0]['content']}"
        )
```

### 示例 2: GitHub Actions

```yaml
# .github/workflows/viking.yml
name: Viking Memory

on:
  issues:
    types: [opened]

jobs:
  record:
    runs-on: ubuntu-latest
    steps:
      - name: Record Issue
        run: |
          curl -X POST http://localhost:8080/api/v1/memories \
            -H "Content-Type: application/json" \
            -d '{
              "title": "GitHub Issue: ${{ github.event.issue.number }}",
              "content": "${{ github.event.issue.body }}",
              "importance": "high"
            }'
```

### 示例 3: Cron 定时任务

```bash
# /etc/cron.d/viking-maintenance
# 每天凌晨2点执行压缩
0 2 * * * root /path/to/viking/scripts/sv_compress.sh >> /var/log/viking.log 2>&1

# 每周日凌晨3点执行清理
0 3 * * 0 root /path/to/viking/scripts/sv_cleanup.sh >> /var/log/viking.log 2>&1
```

---

## 相关文档

- [架构设计](./ARCHITECTURE.md)
- [部署指南](./deployment.md)
- [OpenClaw 改动说明](./openclaw-modifications.md)

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
