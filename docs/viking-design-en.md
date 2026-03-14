# Viking Memory System Design Document

This document provides detailed information about the core design concepts, algorithms, and implementation details of the Viking Memory System.

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Memory Model](#memory-model)
3. [Forgetting Algorithm](#forgetting-algorithm)
4. [Compression Strategy](#compression-strategy)
5. [Recall Mechanism](#recall-mechanism)
6. [Technology Choices](#technology-choices)

---

## Design Philosophy

### Core Inspiration

The Viking Memory System is inspired by **how human memory works**:

> Human memory is not perfect storage - it naturally decays over time.
> 
> - Short-term memory (working memory): Can only hold 7±2 information chunks
> - Long-term memory: Transforms through rehearsal and reinforcement
> - Forgetting curve: Ebbinghaus curve shows exponential decay
> - Important memories: Emotionally charged or repeated information is harder to forget

### Design Goals

1. **Simulate Human Memory Layers** - Natural transition from full details to abstract tags
2. **Importance Awareness** - Important information gets higher weight, decays slower
3. **Recoverable Forgetting** - Archive is not deletion, search can trigger recall
4. **Automatic Management** - Automated compression and weight management

### Comparison with Traditional Solutions

| Solution | Pros | Cons |
|----------|------|------|
| Full Storage | Preserves all info | High token cost, hard to retrieve |
| Vector DB | Semantic search | High storage cost, can't compress |
| **Viking** | **Brain-like, smart compression** | **Higher implementation complexity** |

---

## Memory Model

### Memory Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Memory Lifecycle                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Full Details ──→ Contour Summary ──→ Keywords ──→ Tags ──→ Archive │
│    │             │               │          │           │         │
│   0 days       2 days        8 days     30 days     90+ days      │
│                                                                     │
│  [Full Content] [Core Contour] [Keywords] [Minimal Tags] [Searchable]│
│                                                                     │
│                    ▲ Search Triggered Recall ▲                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Layer Definition

| Layer | Time Range | Content Preserved | Clarity | Recallable |
|-------|------------|-------------------|---------|------------|
| L0-Original | 0-1 day | 100% full details | 100% | Auto |
| L1-Contour | 2-7 days | Core contour/summary | ~70% | Auto |
| L2-Keywords | 8-30 days | Key information | ~30% | Search trigger |
| L3-Tags | 30-90 days | Minimal tags | ~10% | Search trigger |
| L4-Archive | 90+ days | Archive (not deleted) | 0% | Searchable ✓ |

### Metadata Structure

```yaml
---
# Core fields
id: mem_20260314_001           # Unique identifier
title: "Project Kickoff Meeting"  # Memory title

# Importance management
importance: high|medium|low   # Importance level
important: true|false         # Never forget flag
tags: [project, meeting]      # Tags

# Time tracking
created: 2026-03-14T10:30:00Z
last_access: 2026-03-14T14:22:00Z

# Access statistics
access_count: 5
access_history:               # Last 5 accesses
  - 2026-03-14T14:22:00Z
  - 2026-03-14T11:15:00Z

# Retention policy
retention: forever|30|90|365
auto_archive: true

# Current layer
current_layer: L0
level: 0
weight: 14.2
---
```

---

## Forgetting Algorithm

### Weight Calculation Formula

```
Weight = Importance Factor × Time Decay Factor × Access Boost Factor

W = importance_factor × (1 / (days + 1)^0.3) × (access_count + 1)
```

### Importance Factors

| importance | importance_factor | Description |
|------------|-------------------|-------------|
| high | 3.0 | Core memory |
| medium | 1.5 | Normal importance |
| low | 0.5 | Minor information |
| important=true | 999 (max) | Never forget |

### Time Decay Curve

```
Weight Change (importance=medium, access_count=0)
│
14┤                                 *
12┤                              *
10┤                           *
 8┤                        *
 6┤                    *
 4┤                *
 2┤            *
 0┤__________*__________________________
   0    10    20    30    40    50    60 (days)
```

### Weight to Layer Mapping

| Weight Range | Suggested Layer | Action |
|--------------|----------------|--------|
| W >= 10 | L0 | Keep full content |
| 5 <= W < 10 | L1 | Keep core contour |
| 2 <= W < 5 | L2 | Keep keywords |
| 0.5 <= W < 2 | L3 | Keep minimal tags |
| W < 0.5 | L4 | Archive (searchable) |

### Weight Update Triggers

1. **On Access**: `access_count++`, `last_access = now()`
2. **On Write**: New memory default weight = importance_factor × 2
3. **Daily cron**: Batch check weights, trigger compression

---

## Compression Strategy

### Compression Triggers

```python
TRIGGERS = {
    1:  'compress_to_contour',    # 1 day → contour
    7:  'compress_to_keywords',  # 7 days → keywords (updated to 8)
    30: 'compress_to_tags',      # 30 days → tags
    90: 'mark_for_archive',      # 90 days → archive (not delete)
}
```

### LLM Compression Prompts

#### Contour Compression (L0 → L1)

```
## Task: Generate Memory Contour

Original Memory:
{{Full Content}}

Requirements:
1. Keep core contour and key points (max 150 characters)
2. Keep key people, dates, decisions
3. Simplify process description

Output Format:
## Contour
[Your contour]
```

#### Keyword Extraction (L1 → L2)

```
## Task: Extract Keywords

Contour Content:
{{Contour}}

Requirements:
1. Extract 8-15 core keywords
2. Use comma separation
3. Prioritize: people, projects, technology, dates, actions

Output Format:
### Keywords
keyword1, keyword2, keyword3, ...
```

#### Minimal Tags (L2 → L3)

```
## Task: Extract Minimal Tags

Keyword Content:
{{Keywords}}

Requirements:
1. Extract 3-5 most core tags
2. Use # prefix
3. Keep only most critical elements

Output Format:
### Tags
#tag1 #tag2 #tag3
```

---

## Recall Mechanism

### Search-Triggered Recall Flow

```
User searches "project kickoff"
    ↓
Retrieve L4 archived memories (match keywords/tags)
    ↓
Found: #project #kickoff #2026Q1
    ↓
┌─────────────────────────────────────┐
│  Trigger LLM "Recall" Recovery      │
│                                     │
│  Input: Keywords + Time Context     │
│  Output: Recover Full/Detailed Memory│
└─────────────────────────────────────┘
    ↓
Display to User
```

### LLM Recovery Prompt

```
## Task: Recover Memory from Archived Keywords

Archived Keywords: {{Keywords}}
Memory Creation Time: {{Created}}
Memory Title: {{Title}}

Requirements:
1. Based on provided keywords and time context
2. Recover as much full detail as possible
3. Reasonably infer context, people, decisions at the time
4. Mark which content is "inferred"

Output Format:
## Recovered Memory
[LLM recovered full content]

## Inference Notes
[Which content is LLM inferred]
```

### Recall Quality

| Existing Content | Recovery Quality |
|------------------|------------------|
| L2 Keywords | High (expandable) |
| L3 Tags | Medium (needs inference) |
| L4 Archive only | Low (full inference) |

---

## Technology Choices

### Storage Solutions

| Solution | Use Case | Pros | Cons |
|----------|----------|------|------|
| Markdown Files | Personal/Small team | Simple, readable, editable | Slow search |
| SQLite | Medium scale | Fast indexing, transactions | Extra learning |
| Vector DB (Chroma) | Semantic search | Similarity retrieval | Large storage |

### LLM Services

| Service | Model | Features |
|---------|-------|----------|
| Ollama | glm-4-flash | Local, free |
| OpenAI | gpt-4 | Best quality, expensive |
| Zhipu | glm-4 | Chinese optimized, China available |

### Performance Optimization

1. **Batch Compression**: Daily cron batch processing to avoid real-time latency
2. **Async Index**: Async vector index update on write
3. **Cache**: Hot memories cached in memory

---

## Future Plans

- [ ] Vector similarity search
- [ ] Multimodal memory (images, voice)
- [ ] Memory association graph
- [ ] Social memory sharing
- [ ] Memory export/import

---

*Document Version: v2.2 | Updated: 2026-03-14*
