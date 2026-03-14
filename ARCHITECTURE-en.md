# Viking Memory System Architecture Design

This document provides a detailed overview of the Viking Memory System's overall architecture and core components.

## Table of Contents

1. [System Overview](#system-overview)
2. [Overall Architecture](#overall-architecture)
3. [Core Components](#core-components)
4. [Data Flow Design](#data-flow-design)
5. [Storage Structure](#storage-structure)
6. [Integration](#integration)
7. [Extension Design](#extension-design)

---

## System Overview

### Design Goals

The core goal of the Viking Memory System is to **simulate human memory's hierarchical decay mechanism** for intelligent memory management:

1. **Memory Lifecycle Management** - Auto-compress from full details to archive retention
2. **Importance Weighting** - Auto-calculate weight based on access and time
3. **Search-Triggered Recall** - Archived memories can be recovered via keyword search
4. **Seamless Framework Integration** - Integrate with OpenClaw via Hook mechanism

### Core Features

| Feature | Description |
|---------|-------------|
| Hierarchical Decay | L0→L1→L2→L3→L4 auto-compression |
| Weight Calculation | importance × time_decay × access_boost |
| Archive Recall | L4 archive + LLM keyword recovery |
| OpenClaw Hook | Auto-trigger at session start/end |

---

## Overall Architecture

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Viking Memory System Architecture                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        User Layer                               │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  CLI cmds   │  │  OpenClaw   │  │  Web UI     │            │   │
│  │  │ (sv_*)      │  │   Agent     │  │  (Optional) │            │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                       API Layer                                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  sv_write   │  │  sv_find    │  │  sv_read     │            │   │
│  │  │  Write API  │  │  Search API │  │  Read API    │            │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │   │
│  └─────────┼────────────────┼────────────────┼────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      Core Engine                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  Memory     │  │  Weight     │  │  Compress   │            │   │
│  │  │  Manager    │  │  Calculator │  │  Engine     │            │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │   │
│  │  │  Search    │  │  Recall     │  │  Hook       │            │   │
│  │  │  Engine    │  │  Recovery   │  │  Loader     │            │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│            │                │                │                          │
│            ▼                ▼                ▼                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     Storage Layer                                │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐   │   │
│  │  │  File System    │  │  Vector Store   │  │  Config Store  │   │   │
│  │  │  (Markdown)     │  │ (Optional-Chroma)│ │   (YAML)      │   │   │
│  │  └─────────────────┘  └─────────────────┘  └────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      External Integration                                │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────────┐  │
│  │   OpenClaw      │  │    LLM Service │  │   Other Agent Frameworks│  │
│  │   Framework     │  │   (Ollama)      │  │   (Need Adaptation)    │  │
│  └─────────────────┘  └─────────────────┘  └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

### 1. Memory Manager

**Responsibility**: CRUD operations for memories

```python
class MemoryManager:
    """Memory storage manager"""
    
    def write(self, path: str, content: str, metadata: dict) -> bool
    def read(self, path: str) -> dict  # Returns content + metadata
    def delete(self, path: str) -> bool
    def list(self, filters: dict) -> list  # Supports layer/importance filters
    def update_metadata(self, path: str, metadata: dict) -> bool
```

### 2. Weighter

**Responsibility**: Calculate and update memory weights

```python
class Weighter:
    """Memory weight calculator"""
    
    # Formula: W = importance_factor × (1/(days+1)^0.3) × (access_count+1)
    
    def calculate(self, memory: dict) -> float
    def refresh_on_access(self, memory_id: str) -> dict  # Refresh on access
    def get_layer(self, weight: float) -> str  # Weight→layer mapping
```

### 3. Compressor

**Responsibility**: Memory layer compression

```python
class Compressor:
    """Memory compression engine"""
    
    TRIGGERS = {
        1:  'compress_to_contour',   # L0 → L1
        7:  'compress_to_keywords',  # L1 → L2
        30: 'compress_to_tags',      # L2 → L3
        90: 'mark_for_archive',      # L3 → L4
    }
    
    def check_and_compress(self, memory: dict) -> dict
    def compress_to_contour(self, memory: dict) -> dict   # LLM generates contour
    def compress_to_keywords(self, memory: dict) -> dict  # LLM extracts keywords
    def compress_to_tags(self, memory: dict) -> dict       # LLM extracts tags
    def mark_for_archive(self, memory: dict) -> dict      # L4 archive
```

### 4. Searcher

**Responsibility**: Memory search and filtering

```python
class Searcher:
    """Memory search engine"""
    
    def search(self, query: str, filters: dict) -> list
    def search_by_layer(self, layer: str) -> list  # Search by layer
    def search_archived(self, query: str) -> list  # Search archive trigger recall
    def fuzzy_match(self, keyword: str) -> list    # Fuzzy matching
```

### 5. Recall

**Responsibility**: LLM recovery for archived memories

```python
class Recall:
    """Memory recall recoverer"""
    
    def recall(self, archived_memory: dict, query: str) -> str
    # Uses LLM to recover full memory from keywords
```

### 6. HookLoader

**Responsibility**: OpenClaw Hook mechanism integration

```python
class HookLoader:
    """OpenClaw Hook loader"""
    
    def load_config(self, config_path: str) -> dict
    def execute_hook(self, hook_name: str, context: str) -> str
    def on_session_start(self) -> str  # Session start trigger
    def on_session_end(self) -> str     # Session end trigger
```

---

## Data Flow Design

### Write Data Flow

```
User Input (sv_write)
       │
       ▼
┌──────────────────┐
│  Validate & Parse│
│  Input Processing│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Generate Metadata│
│  - id            │
│  - created       │
│  - importance   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Save to File    │
│  Markdown Format │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Update Index    │
│  (Optional: Vector)│
└────────┬─────────┘
         │
         ▼
    [Done]
```

### Read Data Flow

```
User Request (sv_read/sv_find)
       │
       ▼
┌──────────────────┐
│  Query Index    │
│  Match Memories │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Check Layer    │
│  Is Archive(L4)?│
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Yes     │ No
    ▼         ▼
┌────────┐ ┌──────────────────┐
│ Trigger│ │ Return Content  │
│ Recall │ │ Update Access   │
└────┬───┘ └────────┬─────────┘
     │              │
     ▼              ▼
┌──────────────┐ ┌──────────────────┐
│ LLM Recovery │ │ Refresh Weight  │
│ Keyword→Content│ │ access_count++  │
└──────┬───────┘ └────────┬─────────┘
       │                  │
       └────────┬─────────┘
                ▼
           [Return to User]
```

### Compression Data Flow

```
Scheduled Task (Daily cron)
       │
       ▼
┌──────────────────┐
│  Scan All Memories│
│  Check Days      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Iterate Memories│
│  for each mem   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Compression│
    │ Condition? │
    └────┬────┘
         │
    ┌────┴────┐
    │ Yes     │ No → Next
    ▼         ▼
┌────────┐
│ Call LLM │
│ Generate │
│ Compressed│
│ Content  │
└────┬─────┘
     │
     ▼
┌──────────────────┐
│  Update Layer   │
│  content_Lx     │
└────────┬─────────┘
         │
         ▼
    [Continue]
```

---

## Storage Structure

### Directory Structure

```
~/.openclaw/viking-{agent}/
├── config.yaml                 # Viking config
├── agent/
│   ├── memories/
│   │   ├── daily/             # Daily memories
│   │   │   └── YYYY-MM-DD.md
│   │   ├── long-term/         # Long-term memories
│   │   └── meetings/         # Meeting memories
│   ├── instructions/         # System instructions
│   └── config.md             # Agent config
├── user/
│   ├── preferences/          # User preferences
│   └── habits/               # Habits
├── resources/                # Resource files
└── .index/                   # Search index (optional)
```

### Memory File Format (Markdown + Frontmatter)

```markdown
---
id: mem_20260314_001
title: "2026-03-14 Today's Work"
importance: high
important: false
tags: [work, projectA]
created: 2026-03-14T10:30:00Z
last_access: 2026-03-14T14:22:00Z
access_count: 5
retention: 90
current_layer: L0
level: 0
weight: 14.2
---

# Today's Work

## Tasks Completed
- Completed project A development
- Code review

## Todo
- Prepare weekly report

---

## Contour (L1)

Project A completed, prepare weekly report.

---

### Keywords (L2)

ProjectA, CodeReview, WeeklyReport

---

### Tags (L3)

#ProjectA #WeeklyReport
```

---

## Integration

### OpenClaw Integration

```yaml
# ~/.openclaw/config/agent-hooks.yaml
hooks:
  on_session_start:
    - name: "Viking Memory Loader"
      command: "/path/to/sv_autoload.sh"
      enabled: true
      timeout: 30
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-{agent}"
        
  on_session_end:
    - name: "Viking Memory Saver"
      command: "/path/to/sv_save.sh"
      enabled: false
      timeout: 30
```

### LLM Service Integration

```python
# Support multiple LLM services
LLM_SERVICES = {
    'ollama': {
        'base_url': 'http://192.168.5.110:11434',
        'model': 'glm-4-flash',
    },
    'openai': {
        'api_key': 'sk-xxx',
        'model': 'gpt-4',
    },
    'anthropic': {
        'api_key': 'sk-ant-xxx',
        'model': 'claude-3',
    },
}
```

---

## Extension Design

### Vector Search Extension

```
Current: Keyword matching (grep/find)
Extension: Vector similarity search (Chroma)

Plan:
1. Embedding model: sentence-transformers
2. Vector DB: Chroma / Milvus
3. Index update: Async on write
```

### Multimodal Extension

```
Support:
- Image memory (OCR + description)
- Voice memory (ASR + summary)
- File memory (text extraction)
```

### Distributed Extension

```
Current: Single-machine file storage
Extension: Distributed storage

Plan:
1. S3/OSS object storage
2. Redis cache layer
3. PostgreSQL metadata
```

---

## Related Documentation

- [Viking Design Document](./docs/viking-design-en.md)
- [Embedding Guide](./docs/embedding-guide-en.md)
- [Deployment Guide](./docs/deployment-en.md)
- [OpenClaw Modifications](./docs/openclaw-modifications.md)

---

*Document Version: v2.0 | Updated: 2026-03-14*
