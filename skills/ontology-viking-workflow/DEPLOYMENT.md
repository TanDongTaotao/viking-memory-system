# Ontology-Viking 集成方案 - 部署完成 ✅

## 📋 方案概述

实现 **数据模式统一 → 语义存储 → 快速检索** 的完整流程：

1. **Ontology-Mapper**：将异构数据映射到标准本体
2. **Viking 记忆系统**：将映射结果持久化到文件系统，支持分层索引
3. **统一工作流**：一键执行完整管道

---

## 🚀 快速开始

### 对所有 Agent 已配置

✅ 所有 Agent 已链接 `ontology-viking-workflow` 技能  
✅ 所有 Agent 已初始化独立的 Viking 工作区  
✅ 全局本体配置已放置在 `~/.openclaw/viking-global/`

| Agent | Viking 工作区 |
|-------|--------------|
| maojingli | `~/.openclaw/viking-maojingli` |
| maogongtou | `~/.openclaw/viking-maogongtou` |
| maoxiami | `~/.openclaw/viking-maoxiami` |
| maozhuli | `~/.openclaw/viking-maozhuli` |

---

## 📦 已安装组件

| 组件 | 版本 | 位置 |
|------|------|------|
| ontology-mapper 技能 | 2.1.0 | `~/.openclaw/workspace/agents/*/skills/ontology-mapper` |
| ontology-viking-workflow 技能 | 1.0.0 | `~/.openclaw/workspace/skills/ontology-viking-workflow` |
| SimpleViking 工具集 | 0.1.0 | `~/.openclaw/skills/simple-viking` |

---

## 🔧 使用方式

### Agent 内部调用

Agent 可以通过 `exec` 工具调用 `ov_pipeline`：

```bash
exec(command="ov_pipeline --source data.json --schema ifc-source-schema.json --ontology ifc-ontology.json --name '项目名称' --tags 'BIM,IFC'")
```

### 手动测试

```bash
# 指定 Agent 的工作空间
export SV_WORKSPACE="$HOME/.openclaw/viking-maojingli"

# 执行完整管道
ov_pipeline \
  --source /path/to/source-data.json \
  --schema /path/to/source-schema.json \
  --ontology /path/to/target-ontology.json \
  --name "我的项目" \
  --tags "标签1,标签2"
```

---

## 📁 目录结构

```
~/.openclaw/
├── viking-global/                          # 全局共享资源
│   └── resources/
│       ├── ontologies/                    # 本体定义
│       │   ├── ifc-source-schema.json    # 源数据模式
│       │   └── ifc-ontology.json         # 目标本体
│       └── test-data/                     # 测试数据
│           └── building-elements.json
├── viking-{agent}/                        # 各 Agent 的独立存储
│   └── resources/
│       └── mapped/                        # 映射结果自动存入此处
│           ├── *.md
│           ├── *.json
│           ├── .abstract
│           └── .overview
└── skills/
    ├── ontology-viking-workflow/          # 集成技能
    │   ├── SKILL.md
    │   └── tools/
    │       ├── ov_map                    # 数据映射
    │       ├── ov_pipeline              # 完整管道
    │       └── ov_search                # Viking 检索
    └── simple-viking/                     # Viking 基础工具
        └── tools/
            ├── sv_write
            ├── sv_update_layers
            └── sv_find
```

---

## 🎯 工作流程

```mermaid
graph LR
    A[源数据 JSON] --> B(ov_map)
    B --> C[映射结果 JSON]
    C --> D(生成 Markdown 报告)
    D --> E(sv_write)
    E --> F[Viking 文件系统]
    F --> G(sv_update_layers)
    G --> H[分层索引 L0/L1]
    H --> I(sv_find 检索)
```

---

## 🛠️ 工具参考

### ov_pipeline（推荐）

完整一键管道。

**参数：**
- `--source <文件>`：源数据 JSON（必需）
- `--schema <文件>`：源数据模式 JSON Schema（必需）
- `--ontology <文件>`：目标本体定义（必需）
- `--name <文本>`：项目名称（必需）
- `--tags <列表>`：标签，逗号分隔（可选）
- `--output-dir <目录>`：输出目录（默认：`~/.openclaw/viking/resources/mapped/`）
- `--verbose`：详细输出

**输出：**
- Markdown 报告文件（`*.md`）
- 原始映射结果（`*.json`）
- 自动更新 Viking 索引（`.abstract`, `.overview`）

### ov_map

仅执行映射步骤。

**参数：**
- `--source <文件>`
- `--schema <文件>`
- `--ontology <文件>`
- `--output <文件>`

**输出：** 包含映射详情的 JSON 文件。

### ov_search

在 Viking 中搜索（封装 `sv_find`）。

**参数：**
- `<关键词>`
- `--workspace <路径>`：指定 Viking 工作区（默认当前 `$SV_WORKSPACE`）
- `--layer <l0|l1|l2>`：限制搜索层级

**示例：**
```bash
ov_search "IFC" --workspace viking-global
```

---

## 📝 配置示例

### 场景：导入建筑项目数据

**1. 准备源数据**（`project-abc.json`）：
```json
{
  "element_type": "Wall",
  "level": "Level 1",
  "material": "Concrete"
}
```

**2. 调用 pipeline**：
```bash
export SV_WORKSPACE="$HOME/.openclaw/viking-maojingli"
ov_pipeline \
  --source project-abc.json \
  --schema ifc-source-schema.json \
  --ontology ifc-ontology.json \
  --name "项目 ABC" \
  --tags "BIM,Wall"
```

**3. 验证**：
```bash
ov_search "项目 ABC"
```

---

## 🔄 跨 Agent 共享

使用 `viking-global` 工作区实现团队共享：

```bash
# 将公共本体放入全局
export SV_WORKSPACE="$HOME/.openclaw/viking-global"
sv_write viking://shared/ontologies/ifc-standard.md "# IFC 标准..."

# 各 Agent 可读取
export SV_WORKSPACE="$HOME/.openclaw/viking-maojingli"
sv_read viking://shared/ontologies/ifc-standard.md
```

---

## 🧪 已验证状态

- ✅ 所有 4 个 Agent 测试通过
- ✅ Ontology 映射能够识别标准概念（如 Wall → IfcWall）
- ✅ Viking 存储和索引更新正常
- ✅ 全局本体配置已就绪

---

## 📌 注意事项

1. **ontology-mapper 当前仅支持 IFC 等预定义本体**。如需要自定义本体，请扩展 `ontology-mapper-cli` 的 `_load_ontologies` 方法。

2. **Viking 检索基于关键词**，如需语义搜索，请考虑安装 `openviking` 技能（MCP 服务器 + embedding 支持）。

3. **SV_WORKSPACE 环境变量** 必须正确设置，默认为各 Agent 的 `~/.openclaw/viking-{agent}`。

4. **工具路径**：直接在 OpenClaw 中调用时不需要绝对路径；手动测试时使用工具的全路径（如 `~/.openclaw/skills/simple-viking/tools/sv_write`）。

---

## 🎉 完成！

现在所有 Agent 都可以使用这个方案处理数据了。同时社群笔记版 TOOLS.md 已同步更新，记录了这个集成方案。

**如有问题，请修改 `ontology-viking-workflow` 技能目录下的脚本。**
