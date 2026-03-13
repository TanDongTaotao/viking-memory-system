# Ontology-Viking 工作流技能

统一使用 ontology-mapper 转换数据模式，然后存入 Viking 记忆系统。

## 核心能力

1. **数据模式映射**：使用 ontology-mapper 将各种数据源转换为标准本体
2. **持久化存储**：将映射结果保存到 Viking 文件系统
3. **自动索引**：更新 Viking 分层索引（L0/L1/L2）
4. **语义检索**：通过 Viking 快速查找已映射的数据

## 工具列表

| 工具 | 描述 |
|------|------|
| `ov_map` | 执行 ontology-mapper 映射，输出到指定位置 |
| `ov_store` | 将映射结果存入 Viking |
| `ov_pipeline` | 一键执行完整流程：映射 → 存储 → 索引 |
| `ov_search` | 在 Viking 中检索已映射的数据 |

## 快速开始

### 完整流程示例

```bash
# 假设用户需要导入一个新的建筑项目数据
# 1. 执行完整管道
ov_pipeline \
  --source /data/project-x.json \
  --schema ~/.openclaw/viking/resources/ontologies/building-schema.json \
  --ontology ~/.openclaw/viking/resources/ontologies/building-ontology.json \
  --name "项目X" \
  --tags "建筑,IFC"

# 2. 验证存储成功
ov_search "项目X"
```

### 单独使用各步骤

```bash
# 步骤 1: 仅映射
ov_map \
  --source source.json \
  --schema schema.json \
  --ontology ontology.json \
  --output /tmp/mapped.json

# 步骤 2: 存储到 Viking
ov_store /tmp/mapped.json "resources/mapped/project-x.md" --title "项目X"

# 步骤 3: 更新索引（通常自动）
sv_update_layers viking://resources/mapped/
```

## 配置

首次使用前，需要准备本体定义：

```bash
# 1. 创建本体目录
mkdir -p ~/.openclaw/viking/resources/ontologies

# 2. 定义数据源模式（JSON Schema）
cat > ~/.openclaw/viking/resources/ontologies/building-schema.json << 'EOF'
{
  "type": "object",
  "properties": {
    "project_id": {"type": "string"},
    "building_name": {"type": "string"},
    "floors": {"type": "number"},
    "area": {"type": "number"}
  }
}
EOF

# 3. 定义目标本体（可以是自定义或标准本体如 IFC 简化版）
cat > ~/.openclaw/viking/resources/ontologies/building-ontology.json << 'EOF'
{
  "Building": {
    "identifier": "string",
    "name": "string",
    "storeyCount": "number",
    "grossArea": "number"
  }
}
EOF

# 4. 可选：定义映射规则文件
cat > ~/.openclaw/viking/resources/ontologies/building-rules.md << 'EOF'
# 映射规则

- project_id → Building.identifier
- building_name → Building.name
- floors → Building.storeyCount
- area → Building.grossArea
EOF
```

## 工具详解

### ov_map

执行 ontology-mapper 进行数据转换。

**参数：**
- `--source <path>`：源数据文件（JSON/XML/CSV）
- `--schema <path>`：源数据模式（JSON Schema）
- `--ontology <path>`：目标本体定义
- `--rules <path>`：映射规则文件（可选）
- `--output <path>`：输出文件路径

**示例：**
```bash
ov_map \
  --source ~/data/bim-model.json \
  --schema ~/.openclaw/viking/resources/ontologies/ifc-schema.json \
  --ontology ~/.openclaw/viking/resources/ontologies/ifc-ontology.json \
  --output ~/.openclaw/viking/tmp/mapped.json
```

### ov_store

将映射后的数据存入 Viking 系统。

**参数：**
- `input_file`：映射结果文件路径
- `viking_uri`：Viking URI（如 `resources/mapped/project-x.md`）
- `--title <text>`：文档标题（可选，会自动添加到内容）
- `--tags <list>`：标签列表，逗号分隔

**示例：**
```bash
ov_store /tmp/mapped.json "resources/mapped/ifc-project.md" \
  --title "IFC 项目数据" \
  --tags "BIM,IFC,建筑"
```

此工具会：
1. 读取 JSON 文件
2. 格式化为 Markdown
3. 调用 `sv_write` 写入 Viking
4. 更新父目录的 `.abstract` 和 `.overview`

### ov_pipeline

一键执行完整流程。

**参数：**
- `--source <path>`
- `--schema <path>`
- `--ontology <path>`
- `--rules <path>`（可选）
- `--name <text>`：项目名称
- `--tags <list>`：标签
- `--output-dir <dir>`：输出目录（默认：`~/.openclaw/viking/resources/mapped/`）

**执行顺序：**
1. `ov_map` 生成映射结果
2. `ov_store` 存入 Viking
3. `sv_update_layers` 更新索引

**示例：**
```bash
ov_pipeline \
  --source ~/data/project.json \
  --schema ~/.openclaw/viking/resources/ontologies/building-schema.json \
  --ontology ~/.openclaw/viking/resources/ontologies/building-ontology.json \
  --name "中新大厦" \
  --tags "BIM,IFC,商业建筑"
```

### ov_search

在 Viking 中搜索已映射的数据。

**参数：**
- `keywords`：搜索关键词
- `--workspace <name>`：指定 Viking workspace（默认使用当前 Agent 的）
- `--layer <l0|l1|l2>`：指定搜索层级（默认全部）

**示例：**
```bash
# 搜索包含"大厦"的文档
ov_search "大厦"

# 只在 L1 索引中搜索（更快）
ov_search "BIM" --layer l1

# 指定 workspace（跨 Agent 共享）
ov_search "项目X" --workspace viking-global
```

## 在 OpenClaw Agent 中集成

### 自动发现

将本技能放入 Agent 的 `skills/` 目录后，OpenClaw 会自动加载其工具。

**目录结构：**
```
~/.openclaw/workspace/agents/maozhuli/skills/ontology-viking-workflow/
├── SKILL.md
├── tools/
│   ├── ov_map
│   ├── ov_store
│   ├── ov_pipeline
│   └── ov_search
└── scripts/
    └── mapper.sh（包装 ontology-mapper 调用）
```

### 工具调用方式

Agent 内部通过 `exec` 调用这些工具：

```bash
exec(command="ov_pipeline --source data.json --schema schema.json --ontology onto.json --name '项目A'")
```

或使用 `sessions_send` 让其他 Agent 执行：

```bash
sessions_send(
  sessionKey="...",
  message="请使用 ov_pipeline 导入项目数据..."
)
```

## 错误处理与调试

### 常见问题

1. **"ontology-mapper: command not found"**
   - 确保已安装 ontology-mapper 技能
   - 检查 PATH 是否包含技能工具目录

2. **Viking URI 格式错误**
   - URI 必须以 `viking://` 开头
   - 路径使用正斜杠，如 `viking://resources/mapped/file.md`

3. **索引未更新**
   - 手动运行：`sv_update_layers viking://resources/mapped/`
   - 检查 `~/.openclaw/viking/resources/mapped/.abstract` 文件

### 日志查看

```bash
# 查看 ov_pipeline 详细输出
ov_pipeline ... --verbose

# 查看 Viking 操作日志
tail -f ~/.openclaw/viking/logs/operations.log
```

## 扩展与定制

### 添加自定义本体

将新的本体定义放入 `~/.openclaw/viking/resources/ontologies/`，并更新映射脚本。

### 多数据源支持

扩展 `ov_map` 支持 CSV、XML、Excel 等格式，利用 ontology-mapper 的多格式能力。

### 批量导入

编写批量脚本：
```bash
for file in ~/data/projects/*.json; do
  name=$(basename "$file" .json)
  ov_pipeline \
    --source "$file" \
    --schema ~/.openclaw/viking/resources/ontologies/building-schema.json \
    --ontology ~/.openclaw/viking/resources/ontologies/building-ontology.json \
    --name "$name"
done
```

---

## 部署到所有 Agent

### 全局安装（推荐）

```bash
# 复制技能到全局 skills 目录
cp -r ~/.openclaw/workspace/agents/maozhuli/skills/ontology-viking-workflow \
  ~/.openclaw/workspace/skills/

# 为每个 Agent 创建符号链接
for agent in maojingli maogongtou maoxiami maozhuli; do
  ln -sf ~/.openclaw/workspace/skills/ontology-viking-workflow \
    ~/.openclaw/workspace/agents/$agent/skills/
done
```

### 验证

```bash
# 检查技能是否可见
openclaw skills list | grep ontology-viking

# 测试工具是否可用
export SV_WORKSPACE="$HOME/.openclaw/viking-maozhuli"
ov_map --help
```

---

**版本:** 1.0.0  
**依赖:** ontology-mapper (v2.1.0), simple-viking (v0.1.0)  
**作者:** 猫助理 (maozhuli)  
**许可证:** Apache-2.0
