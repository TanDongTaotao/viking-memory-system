# Viking Memory System Embedding Guide

This document describes how to embed the Viking Memory System into other systems and applications.

## Table of Contents

1. [Overview](#overview)
2. [Embedding Methods](#embedding-methods)
3. [Python API](#python-api)
4. [Command Line Integration](#command-line-integration)
5. [Webhook Integration](#webhook-integration)
6. [HTTP API](#http-api)
7. [Example Projects](#example-projects)

---

## Overview

Viking Memory System supports multiple embedding methods to suit different use cases:

- **Python Module**: Direct import and use
- **Command Line**: Shell script invocation
- **Webhook**: HTTP callback triggers
- **HTTP API**: RESTful interface

---

## Embedding Methods

### Selection Guide

| Scenario | Recommended | Description |
|----------|-------------|-------------|
| Python App | Python API | Most flexible, full control |
| Script/Automation | Command Line | Simple and easy |
| Web Service | HTTP API | Remote call support |
| External Trigger | Webhook | Event-driven |

---

## Python API

### Basic Usage

```python
import sys
sys.path.insert(0, '/path/to/viking/scripts')

from viking_core import VikingMemory

# Initialize
viking = VikingMemory(
    workspace="~/.openclaw/viking-test",
    llm_service="ollama",
    llm_model="glm-4-flash"
)

# Write memory
viking.write(
    title="Test Memory",
    content="This is test content",
    importance="high"
)

# Read memory
memory = viking.read("mem_20260314_001")

# Search memories
results = viking.search("test")

# Compress
viking.compress()
```

### Complete API Reference

```python
class VikingMemory:
    """Viking Memory System Python API"""
    
    def __init__(
        self,
        workspace: str,
        llm_service: str = "ollama",
        llm_model: str = "glm-4-flash",
        llm_host: str = "http://localhost:11434"
    ):
        """Initialize Viking Memory System
        
        Args:
            workspace: Workspace path
            llm_service: LLM service type (ollama/openai/anthropic)
            llm_model: LLM model name
            llm_host: LLM service address
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
        """Write memory
        
        Returns:
            Memory ID
        """
        pass
    
    def read(
        self,
        memory_id: str,
        refresh_weight: bool = True
    ) -> dict:
        """Read memory
        
        Returns:
            Dictionary with content and metadata
        """
        pass
    
    def search(
        self,
        query: str,
        layer: str = None,
        importance: str = None,
        limit: int = 10
    ) -> List[dict]:
        """Search memories
        
        Returns:
            List of memories
        """
        pass
    
    def list(
        self,
        layer: str = None,
        importance: str = None,
        limit: int = 100
    ) -> List[dict]:
        """List memories
        
        Returns:
            List of memories
        """
        pass
    
    def compress(
        self,
        memory_id: str = None,
        dry_run: bool = False
    ) -> dict:
        """Compress memory
        
        Args:
            memory_id: Specific memory ID, empty for all
            dry_run: Preview only, don't execute
        
        Returns:
            Compression result
        """
        pass
    
    def get_weight(self, memory_id: str) -> float:
        """Get memory weight"""
        pass
    
    def set_importance(
        self,
        memory_id: str,
        importance: str,
        important: bool = None
    ):
        """Set importance"""
        pass
    
    def recall(self, query: str) -> dict:
        """Recall search (includes LLM recovery)
        
        Returns:
            Original memory + LLM recovered content
        """
        pass
```

### Async Usage

```python
import asyncio
from viking_core import AsyncVikingMemory

async def main():
    viking = AsyncVikingMemory(workspace="~/.openclaw/viking-test")
    
    # Async write
    memory_id = await viking.write(
        title="Async Test",
        content="Async content"
    )
    
    # Async search
    results = await viking.search("test")

asyncio.run(main())
```

---

## Command Line Integration

### Basic Commands

```bash
# Write
viking-write --title "Title" --content "Content" --importance high

# Read
viking-read mem_20260314_001

# Search
viking-search "keyword"

# Compress
viking-compress --dry-run

# List
viking-list --layer L0 --limit 10
```

### Shell Script Integration

```bash
#!/bin/bash
# viking-integration.sh

VIKING_HOME="/path/to/viking"
WORKSPACE="$HOME/.openclaw/viking-test"

# Write memory
write_memory() {
    local title="$1"
    local content="$2"
    
    $VIKING_HOME/scripts/sv_save.sh \
        --title "$title" \
        --content "$content" \
        --workspace "$WORKSPACE"
}

# Search memory
search_memory() {
    local query="$1"
    
    $VIKING_HOME/scripts/sv_recall.sh \
        --query "$query" \
        --workspace "$WORKSPACE"
}

# Usage
write_memory "Auto Task" "Memory created from script"
search_memory "Auto Task"
```

### Environment Variables

```bash
# Basic config
export VIKING_WORKSPACE="$HOME/.openclaw/viking-test"
export VIKING_LLM_HOST="http://192.168.5.110:11434"
export VIKING_LLM_MODEL="glm-4-flash"

# Optional config
export VIKING_LOG_LEVEL="debug"
export VIKING_CACHE_DIR="/tmp/viking-cache"
```

---

## Webhook Integration

### Configure Webhook

```yaml
# viking-webhook.yaml
webhooks:
  # Write trigger
  on_write:
    url: "https://your-server.com/webhook/write"
    method: POST
    headers:
      Authorization: "Bearer xxx"
    body:
      memory_id: "{memory_id}"
      title: "{title}"
      importance: "{importance}"
  
  # Search trigger
  on_search:
    url: "https://your-server.com/webhook/search"
    method: POST
    body:
      query: "{query}"
      results_count: "{results_count}"
```

### Receive Webhook

```python
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/webhook/write', methods=['POST'])
def handle_write():
    data = request.json
    print(f"New memory written: {data['memory_id']}")
    # Handle new memory
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

### Start API Service

```bash
# Start service
python -m viking_api --host 0.0.0.0 --port 8080

# Or use Docker
docker run -p 8080:8080 viking-memory-api
```

### API Endpoints

#### Write Memory

```bash
POST /api/v1/memories
Content-Type: application/json

{
    "title": "Test Memory",
    "content": "This is test content",
    "importance": "high",
    "tags": ["test", "example"]
}
```

Response:
```json
{
    "status": "success",
    "memory_id": "mem_20260314_001",
    "created": "2026-03-14T10:30:00Z"
}
```

#### Read Memory

```bash
GET /api/v1/memories/{memory_id}
```

Response:
```json
{
    "memory_id": "mem_20260314_001",
    "title": "Test Memory",
    "content": "This is test content",
    "importance": "high",
    "layer": "L0",
    "weight": 12.5,
    "created": "2026-03-14T10:30:00Z",
    "last_access": "2026-03-14T14:22:00Z"
}
```

#### Search Memory

```bash
POST /api/v1/search
Content-Type: application/json

{
    "query": "test",
    "layer": "L0,L1",
    "limit": 10
}
```

#### Recall Search

```bash
POST /api/v1/recall
Content-Type: application/json

{
    "query": "2025 project",
    "include_archived": true
}
```

---

## Example Projects

### Example 1: Slack Bot Integration

```python
from slack_sdk import WebClient
from viking_core import VikingMemory

slack = WebClient(token="xoxb-...")
viking = VikingMemory(workspace="~/.openclaw/viking-test")

def handle_slack_message(event):
    text = event['text']
    channel = event['channel']
    
    # Search related memories
    results = viking.search(text)
    
    if results:
        # Reply with memory content
        slack.chat_postMessage(
            channel=channel,
            text=f"Found memory: {results[0]['title']}\n{results[0]['content']}"
        )
```

### Example 2: GitHub Actions

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

### Example 3: Cron Scheduled Task

```bash
# /etc/cron.d/viking-maintenance
# Compress daily at 2 AM
0 2 * * * root /path/to/viking/scripts/sv_compress.sh >> /var/log/viking.log 2>&1

# Cleanup weekly at 3 AM Sunday
0 3 * * 0 root /path/to/viking/scripts/sv_cleanup.sh >> /var/log/viking.log 2>&1
```

---

## Related Documentation

- [Architecture Design](./ARCHITECTURE-en.md)
- [Deployment Guide](./deployment-en.md)
- [OpenClaw Modifications](./openclaw-modifications.md)

---

*Document Version: v2.0 | Updated: 2026-03-14*
