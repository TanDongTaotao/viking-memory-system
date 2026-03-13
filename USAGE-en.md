# Viking Memory System Usage Guide

This document provides detailed usage instructions for all Viking Memory System features.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Commands](#core-commands)
3. [Writing Memory](#writing-memory)
4. [Reading Memory](#reading-memory)
5. [Searching Memory](#searching-memory)
6. [Memory Compression](#memory-compression)
7. [Weight Management](#weight-management)
8. [Auto-Load](#auto-load)
9. [Advanced Features](#advanced-features)
10. [Best Practices](#best-practices)

---

## Quick Start

### Environment Setup

```bash
# Set workspace (separate for each Agent)
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# Set LLM service (optional)
export OLLAMA_HOST=http://192.168.5.110:11434

# Persist in .bashrc
echo 'export SV_WORKSPACE=~/.openclaw/viking-maojingli' >> ~/.bashrc
```

### First Use

```bash
# 1. Create memory directory
mkdir -p $SV_WORKSPACE/agent/memories/daily

# 2. Write first memory
sv_write viking://agent/memories/daily/2026-03-14.md "# Startup Log

Today started using Viking Memory System.
Goal: Implement intelligent memory management."

# 3. Search memories
sv_find "Viking"

# 4. List memories
sv_list
```

---

## Core Commands

### Command Overview

| Command | Function | Example |
|---------|----------|---------|
| `sv_write` | Write memory | `sv_write path "content"` |
| `sv_read` | Read memory | `sv_read mem_id` |
| `sv_find` | Search memory | `sv_find "keyword"` |
| `sv_list` | List memories | `sv_list [--layer L0]` |
| `sv_compress` | Compress memory | `sv_compress --dry-run` |
| `sv_autoload` | Auto-load | `sv_autoload.sh` |
| `sv_save` | Save memory | `sv_save.sh` |
| `sv_weight` | Calculate weight | `sv_weight mem_id` |

---

## Writing Memory

### Basic Write

```bash
# Method 1: Command line write
sv_write viking://agent/memories/daily/2026-03-14.md "# Today's Work

## Tasks Completed
- Completed project A development
- Code review

## Todo
- Prepare weekly report"
```

### Write with Metadata

```bash
# Write with importance flag
sv_write viking://agent/memories/daily/2026-03-14.md \
  --importance high \
  --important \
  --tags "work,projectA" <<'EOF'
# Important Meeting Notes

Decision: Start new project B
Participants: John, Jane
EOF
```

### Script-based Write

```bash
# Using sv_save.sh script
./scripts/sv_save.sh --title "Meeting Notes" --content "..." --importance high
```

---

## Reading Memory

### Basic Read

```bash
# Read single memory
sv_read viking://agent/memories/daily/2026-03-14.md

# Read with weight refresh
sv_read viking://agent/memories/daily/2026-03-14.md --refresh
```

### Programmatic Read

```bash
# Using sv_recall.sh script
./scripts/sv_recall.sh --id mem_20260314_001
```

---

## Searching Memory

### Simple Search

```bash
# Search keyword
sv_find "project"

# Search multiple words (AND)
sv_find "project AND development"

# Search tag
sv_find "#work"
```

### Advanced Search

```bash
# Search by layer
sv_find --layer L0      # Full details
sv_find --layer L1     # Contour
sv_find --layer L2     # Keywords

# Search by importance
sv_find --importance high

# Search by date range
sv_find --date-from 2026-01-01 --date-to 2026-03-14

# Search archived memories (trigger recall)
sv_find --archived "keyword"
```

### Search-Triggered Recall

When searching archived memories, the system automatically triggers LLM recovery:

```bash
# Search archived memory
sv_find --archived "2025-project"

# Example output:
# [Recall Triggered]
# Found archived memory: Project X (2025-06)
# ---
# [LLM Recovery]
# Recovered memory from keywords "projectX, 2025-06":
# In June 2025, Project X was initiated,
# Core team members include...
```

---

## Memory Compression

### Automatic Compression

Viking automatically compresses memories over time:

| Layer | Time | Content |
|-------|------|---------|
| L0 | 0-1 day | Full details |
| L1 | 2-7 days | Core contour |
| L2 | 8-30 days | Keywords |
| L3 | 30-90 days | Minimal tags |
| L4 | 90+ days | Archive (searchable) |

### Manual Compression

```bash
# Preview compression (dry run)
./scripts/sv_compress.sh --dry-run

# Execute compression
./scripts/sv_compress.sh

# Compress specific memory
./scripts/sv_compress.sh --id mem_20260314_001

# Force compression (ignore important flag)
./scripts/sv_compress.sh --force
```

### Compression Configuration

Configure in `viking.config`:

```yaml
memory:
  auto_compress: true
  compress_at: [1, 8, 30, 90]  # Days
  low_weight_threshold: 0.5   # Weight threshold
```

---

## Weight Management

### Weight Calculation

Formula: `W = importance_factor × (1 / (days+1)^0.3) × (access_count+1)`

```bash
# View memory weight
./scripts/sv_weight.sh mem_20260314_001

# Example output:
# Memory: 2026-03-14.md
# Importance: high (factor: 3.0)
# Days since last access: 2
# Access count: 5
# Weight: 3.0 × 1/(2+1)^0.3 × 6 = 14.2
# Layer: L0 (weight >= 10)
```

### Importance Factors

| importance | factor | Description |
|------------|--------|-------------|
| high | 3.0 | Core memory |
| medium | 1.5 | Normal importance |
| low | 0.5 | Minor information |
| important=true | 999 | Never forget |

### Manual Adjustment

```bash
# Mark as important (never forget)
sv_important mem_20260314_001 --set

# Remove important flag
sv_important mem_20260314_001 --unset

# Set retention period
sv_retention mem_20260314_001 --days 365
```

---

## Auto-Load

### Hook Auto-Load

Auto-load at session start via OpenClaw Hook:

```bash
# Manual trigger
./scripts/sv_autoload.sh

# Specify number of memories
./scripts/sv_autoload.sh --limit 10

# Specify layers
./scripts/sv_autoload.sh --layer L0,L1
```

### Loaded Content

- Recent N memories
- Important-flagged memories
- Todo tasks
- Hot memories (high weight)

### Loading Output Format

```
=== Viking Memory Load ===
Workspace: ~/.openclaw/viking-maojingli
Loaded: 5

--- Memory 1: 2026-03-14 Today's Work ---
[Importance: high] [Weight: 14.2] [Layer: L0]

# Today's Work

## Tasks Completed
- Completed project A development
...

--- Memory 2: 2026-03-13 Project Progress ---
...
```

---

## Advanced Features

### Memory Merge

```bash
# Merge multiple memories
./scripts/sv_merge.sh --ids mem001,mem002

# Merge date range
./scripts/sv_merge.sh --date-from 2026-01-01 --date-to 2026-03-14
```

### Memory Cleanup

```bash
# List low-weight memories
./scripts/sv_cleanup.sh --list

# Clean archived memories
./scripts/sv_cleanup.sh --archive --dry-run

# Force cleanup
./scripts/sv_cleanup.sh --force
```

### Token Limit Management

```bash
# Check current token usage
./scripts/sv_token_limit.sh --check

# Estimate compression savings
./scripts/sv_token_limit.sh --estimate
```

### Batch Operations

```bash
# Batch set importance
for f in memories/*.md; do
  sv_important "$f" --importance high
done

# Batch export
tar -czf memories-backup.tar.gz agent/memories/
```

---

## Best Practices

### 1. Memory Naming Convention

```
# Recommended format
agent/memories/daily/YYYY-MM-DD.md
agent/memories/long-term/project-name.md
agent/memories/meetings/YYYY-MM-project.md

# Examples
agent/memories/daily/2026-03-14.md
agent/memories/long-term/viking-design.md
```

### 2. Importance Marking

- **high**: Key decisions, important people, core projects
- **medium**: Normal tasks, daily meetings
- **low**: Temporary information, forgettable content

### 3. Regular Maintenance

```bash
# Weekly compression
0 2 * * 0 ~/.openclaw/viking/scripts/sv_compress.sh

# Monthly cleanup
0 3 * 1 ~/.openclaw/viking/scripts/sv_cleanup.sh
```

### 4. Team Collaboration

```bash
# Use global shared space
export SV_WORKSPACE=~/.openclaw/viking-global

# Write team task
sv_write viking://shared/tasks/project-x.md "# Project X Tasks"
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No search results | Keyword mismatch | Use broader keywords |
| Compression failed | LLM service unavailable | Check OLLAMA_HOST |
| Load timeout | Too many memories | Reduce --limit |
| Permission error | Insufficient directory permissions | chmod -R 700 |

### Debug Mode

```bash
# Enable debug output
export DEBUG=1
sv_find "keyword"

# View detailed logs
tail -f ~/.openclaw/logs/viking.log
```

---

## Related Documentation

- [Installation Guide](./INSTALL-en.md)
- [Architecture Design](./ARCHITECTURE-en.md)
- [Viking Design Document](./docs/viking-design-en.md)
- [Deployment Guide](./docs/deployment-en.md)

---

*Document Version: v2.0 | Updated: 2026-03-14*
