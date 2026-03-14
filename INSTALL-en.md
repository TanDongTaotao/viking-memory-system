# Viking Memory System Installation Guide

This document provides detailed installation steps and configuration methods for the Viking Memory System.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation Methods](#installation-methods)
3. [Configure OpenClaw Hooks](#configure-openclaw-hooks)
4. [Initialize Workspace](#initialize-workspace)
5. [Verify Installation](#verify-installation)
6. [FAQ](#faq)

---

## Prerequisites

### Operating Systems

- **Linux**: Ubuntu 20.04+, Debian 11+, CentOS 8+
- **macOS**: 11.0 (Big Sur) or higher
- **Windows**: WSL2 (Ubuntu 20.04+)

### Software Dependencies

| Dependency | Version | Description |
|------------|---------|-------------|
| OpenClaw | v0.3.0+ | Agent runtime framework |
| Bash | 4.0+ | Shell script environment |
| Python | 3.8+ | Hook loader runtime |
| curl | Any | HTTP request tool |
| jq | 1.6+ | JSON processing tool (optional) |
| yq | 4.0+ | YAML processing tool (optional) |

### LLM Service

Viking system requires LLM service for memory compression and recall:

- **Local Deployment**: Ollama (recommended)
- **Cloud API**: OpenAI, Anthropic, Zhipu GLM, etc.

---

## Installation Methods

### Method 1: Clone Installation (Recommended)

```bash
# 1. Clone the project
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. Run installation script
chmod +x install.sh
./install.sh

# 3. Verify installation
./scripts/sv_autoload.sh --help
```

### Method 2: Manual Installation

```bash
# 1. Create installation directory
mkdir -p ~/.openclaw/viking
cd ~/.openclaw/viking

# 2. Clone project or copy files
git clone https://github.com/Xlous/viking-memory-system.git .

# 3. Add to PATH (optional)
echo 'export PATH="$HOME/.openclaw/viking/scripts:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 4. Copy Hook configuration
mkdir -p ~/.openclaw/config
cp scripts/agent-hooks.yaml ~/.openclaw/config/
```

### Method 3: Docker Deployment

```bash
# Build image
docker build -t viking-memory:latest .

# Run container
docker run -d \
  -v ~/.openclaw:/home/xlous/.openclaw \
  -v ~/viking-data:/data \
  viking-memory:latest
```

---

## Configure OpenClaw Hooks

### 1. Create Hook Configuration File

Create or edit `~/.openclaw/config/agent-hooks.yaml`:

```yaml
# OpenClaw Agent Hooks Configuration
hooks:
  on_session_start:
    - name: "Viking Memory Loader"
      command: "/home/xlous/.openclaw/viking/scripts/sv_autoload.sh"
      enabled: true
      timeout: 30
      env:
        SV_WORKSPACE: "/home/xlous/.openclaw/viking-{agent}"
        OLLAMA_HOST: "http://192.168.5.110:11434"
        
  on_session_end:
    - name: "Viking Memory Saver"
      command: "/home/xlous/.openclaw/viking/scripts/sv_save.sh"
      enabled: false
      timeout: 30
```

### 2. Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| command | Hook script path | `/home/xlous/.openclaw/viking/scripts/sv_autoload.sh` |
| enabled | Enable/disable | `true` / `false` |
| timeout | Timeout in seconds | `30` |
| env.SV_WORKSPACE | Viking workspace path | `/home/xlous/.openclaw/viking-{agent}` |
| env.OLLAMA_HOST | LLM service address | `http://192.168.5.110:11434` |

### 3. Configure for Different Agents

Create separate workspaces for each Agent:

```bash
# Cat Manager's workspace
mkdir -p ~/.openclaw/viking-maojingli/agent/memories/daily

# Cat Xiaomi's workspace  
mkdir -p ~/.openclaw/viking-maoxiami/agent/memories/daily

# Cat Foreman's workspace
mkdir -p ~/.openclaw/viking-maogongtou/agent/memories/daily
```

---

## Initialize Workspace

### 1. Create Directory Structure

```bash
# Main directory
mkdir -p ~/.openclaw/viking-{agent}

# Subdirectories
cd ~/.openclaw/viking-{agent}
mkdir -p agent/memories/{daily,long-term}
mkdir -p agent/instructions
mkdir -p user/{preferences,habits}
mkdir -p resources
```

### 2. Initialize Configuration File

Create `~/.openclaw/viking-{agent}/config.md`:

```markdown
---
name: "{agent_name}"
role: "AI Agent"
created: "2026-03-14"
---

# Agent Configuration

## Persona
- Name: {agent_name}
- Role: AI Assistant

## Responsibilities
- Assist users with tasks
- Manage memory and context

## Team Members
- Cat Manager (maojingli)
- Cat Xiaomi (maoxiami)
- Cat Foreman (maogongtou)
- Cat Assistant (maozhuli)
```

### 3. Set Permissions

```bash
# Set directory permissions
chmod -R 700 ~/.openclaw/viking-{agent}

# Set script permissions
chmod +x ~/.openclaw/viking/scripts/*.sh
```

---

## Verify Installation

### 1. Check Script Executability

```bash
# List scripts
ls -la ~/.openclaw/viking/scripts/*.sh

# Test script
~/.openclaw/viking/scripts/sv_autoload.sh --help
```

### 2. Test Hook Loader

```bash
# Test Python Hook loader
python3 ~/.openclaw/viking/scripts/hook_loader.py --help

# Test configuration loading
python3 -c "
import yaml
with open('~/.openclaw/config/agent-hooks.yaml') as f:
    config = yaml.safe_load(f)
    print('Hooks loaded:', len(config.get('hooks', {})))
"
```

### 3. Create Test Memory

```bash
# Set environment variable
export SV_WORKSPACE=~/.openclaw/viking-maojingli

# Create test memory
echo "# Test Memory
This is a test memory for Viking system.
Created: $(date)" > ~/.openclaw/viking-maojingli/agent/memories/daily/test.md

# Verify
ls -la ~/.openclaw/viking-maojingli/agent/memories/daily/
```

---

## FAQ

### Q1: Hook not triggering?

1. Check `agent-hooks.yaml` syntax is correct
2. Verify script path is correct
3. Check logs: `tail -f ~/.openclaw/logs/hooks.log`

### Q2: LLM service connection failed?

1. Confirm Ollama is running: `curl http://192.168.5.110:11434/api/tags`
2. Check `OLLAMA_HOST` environment variable
3. Confirm model is downloaded: `ollama list`

### Q3: Memory not auto-compressing?

1. Check if `auto_compress` is `true` in `viking.config`
2. Verify `compress_at` has correct days configured
3. Run compression manually: `./scripts/sv_compress.sh`

### Q4: How to migrate existing memories?

```bash
# Export old memories
cp -r ~/.old-viking/* ~/.openclaw/viking-{agent}/

# Update metadata
./scripts/sv_merge.sh
```

---

## Next Steps

- Read [Usage Guide](./USAGE-en.md) for complete features
- Read [Architecture Design](./ARCHITECTURE-en.md) for system architecture
- Configure [OpenClaw Modifications](./docs/openclaw-modifications.md) for core code changes

---

*Document Version: v2.0 | Updated: 2026-03-14*
