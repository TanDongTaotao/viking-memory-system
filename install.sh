#!/bin/bash
#
# Viking Memory System 安装脚本
# 
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Viking Memory System 安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检测操作系统
OS="$(uname -s)"
case "$OS" in
    Linux*)     OS="linux";;
    Darwin*)    OS="macos";;
    *)          echo -e "${RED}不支持的操作系统: $OS${NC}"; exit 1;;
esac

echo -e "${YELLOW}[1/6] 检查前置条件...${NC}"

# 检查 Bash 版本
BASH_VERSION=${BASH_VERSION:-$BASH_VERSION_MAJOR.$BASH_VERSION_MINOR}
if [ -z "$BASH_VERSION" ]; then
    BASH_VERSION=$(bash --version | head -1 | grep -oP '\d+\.\d+')
fi

echo "  - 操作系统: $OS"
echo "  - Bash 版本: $BASH_VERSION"

# 检查 Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
    echo "  - Python: $PYTHON_VERSION"
else
    echo -e "${RED}  ✗ Python3 未安装${NC}"
    exit 1
fi

# 检查必要工具
MISSING_TOOLS=""
for tool in curl jq; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
        echo -e "${RED}  ✗ $tool 未安装${NC}"
    else
        echo -e "${GREEN}  ✓ $tool${NC}"
    fi
done

# 可选工具
if command -v yq &> /dev/null; then
    echo -e "${GREEN}  ✓ yq (可选)${NC}"
fi

if [ -n "$MISSING_TOOLS" ]; then
    echo -e "${YELLOW}  请安装缺失的工具后重试${NC}"
    exit 1
fi

echo -e "${YELLOW}[2/6] 创建目录结构...${NC}"

# 创建 OpenClaw 目录
OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

# 创建 Viking 工作空间
VIKING_DIR="$OPENCLAW_DIR/viking-global"
mkdir -p "$VIKING_DIR"/{agent/{memories/{hot,warm,cold,archive},resources},user/{preferences,habits},shared/{tasks,resources}}

# 创建默认 Agent 工作空间
for agent in maojingli maoxiami maogongtou maozhuli; do
    AGENT_DIR="$OPENCLAW_DIR/viking-$agent"
    mkdir -p "$AGENT_DIR"/{agent/{memories/{hot,warm,cold,archive},resources},user/{preferences,habits}}
    echo -e "${GREEN}  ✓ $agent 工作空间${NC}"
done

echo -e "${YELLOW}[3/6] 配置环境变量...${NC}"

# 添加到 .bashrc
VIKING_EXPORT="
# Viking Memory System
export SV_WORKSPACE=\"\$HOME/.openclaw/viking-maojingli\"
export PATH=\"\$HOME/.openclaw/skills/simple-viking/scripts:\$PATH\"
"

if ! grep -q "Viking Memory System" "$HOME/.bashrc" 2>/dev/null; then
    echo "$VIKING_EXPORT" >> "$HOME/.bashrc"
    echo -e "${GREEN}  ✓ 已添加到 .bashrc${NC}"
else
    echo -e "${YELLOW}  - 环境变量已配置${NC}"
fi

echo -e "${YELLOW}[4/6] 安装 skill...${NC}"

# 创建 skill 目录
SKILL_DIR="$OPENCLAW_DIR/skills/memory-pipeline"
mkdir -p "$SKILL_DIR/scripts"
mkdir -p "$SKILL_DIR/references"

# 复制脚本
cp -r scripts/* "$SKILL_DIR/scripts/"
cp SKILL.md "$SKILL_DIR/"

# 复制文档
cp -r docs "$SKILL_DIR/"
cp -r config "$SKILL_DIR/"

echo -e "${GREEN}  ✓ Skill 安装完成${NC}"

echo -e "${YELLOW}[5/6] 配置 OpenClaw Hooks...${NC}"

# 复制 agent-hooks.yaml
if [ -f "agent-hooks.yaml" ]; then
    mkdir -p "$OPENCLAW_DIR/config"
    cp agent-hooks.yaml "$OPENCLAW_DIR/config/"
    echo -e "${GREEN}  ✓ Hook 配置已安装${NC}"
fi

echo -e "${YELLOW}[6/6] 验证安装...${NC}"

# 验证
if [ -f "$SKILL_DIR/scripts/memory-pipeline" ]; then
    echo -e "${GREEN}  ✓ memory-pipeline CLI${NC}"
fi

if [ -f "$SKILL_DIR/scripts/memory-tools.sh" ]; then
    echo -e "${GREEN}  ✓ memory-tools.sh${NC}"
fi

if [ -f "$OPENCLAW_DIR/config/agent-hooks.yaml" ]; then
    echo -e "${GREEN}  ✓ Hook 配置${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "下一步:"
echo "  1. 重启终端或运行: source ~/.bashrc"
echo "  2. 设置 Agent: export SV_WORKSPACE=\"\$HOME/.openclaw/viking-maojingli\""
echo "  3. 测试: mp_autoload"
echo ""
echo "文档: 请查看 INSTALL.md 和 USAGE.md"
