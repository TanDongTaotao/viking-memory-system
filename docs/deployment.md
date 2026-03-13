# Viking 记忆系统部署指南

本文档详细介绍 Viking 记忆系统在不同环境下的部署方案。

## 目录

1. [部署架构](#部署架构)
2. [开发环境部署](#开发环境部署)
3. [生产环境部署](#生产环境部署)
4. [Docker 部署](#docker-部署)
5. [Kubernetes 部署](#kubernetes-部署)
6. [监控与运维](#监控与运维)
7. [安全配置](#安全配置)
8. [备份与恢复](#备份与恢复)

---

## 部署架构

### 单机部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                      单机部署架构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐                                          │
│   │   用户/Agent │                                          │
│   └──────┬──────┘                                          │
│          │                                                  │
│          ▼                                                  │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                  OpenClaw / 应用                     │  │
│   └──────────────────────┬──────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │               Viking Scripts / API                    │  │
│   │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │  │
│   │  │sv_write│ │sv_find │ │compress│ │ autoload│       │  │
│   │  └────┬───┘ └────┬───┘ └───┬────┘ └───┬─────┘       │  │
│   └───────┼──────────┼─────────┼──────────┼──────────────┘  │
│           │          │         │          │                  │
│           ▼          ▼         ▼          ▼                  │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              本地文件系统 (存储)                       │  │
│   │         ~/.openclaw/viking-{agent}                  │  │
│   └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              LLM 服务 (Ollama/API)                    │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 分布式部署架构

```
┌─────────────────────────────────────────────────────────────┐
│                     分布式部署架构                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐                     │
│   │ Agent 1 │  │ Agent 2 │  │ Agent 3 │  ...                │
│   └────┬────┘  └────┬────┘  └────┬────┘                     │
│        │            │            │                          │
│        └────────────┼────────────┘                          │
│                     │                                        │
│                     ▼                                        │
│          ┌──────────────────────┐                           │
│          │   Load Balancer      │                           │
│          └──────────┬───────────┘                           │
│                     │                                        │
│          ┌──────────┴───────────┐                           │
│          │                      │                           │
│          ▼                      ▼                           │
│   ┌─────────────┐        ┌─────────────┐                   │
│   │ Viking API  │        │ Viking API  │  (多实例)          │
│   │   Node 1    │        │   Node N    │                   │
│   └──────┬──────┘        └──────┬──────┘                   │
│          │                      │                           │
│          └──────────┬───────────┘                           │
│                     │                                        │
│                     ▼                                        │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              分布式存储 (S3/MinIO)                    │  │
│   └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              LLM 集群 (Ollama/K8s)                    │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 开发环境部署

### 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. 运行安装脚本
chmod +x install.sh
./install.sh

# 3. 初始化工作空间
mkdir -p ~/.openclaw/viking-dev

# 4. 验证安装
./scripts/sv_autoload.sh --help
```

### 开发配置

```yaml
# ~/.openclaw/viking-dev/config.yaml
development:
  workspace: ~/.openclaw/viking-dev
  log_level: debug
  
llm:
  service: ollama
  model: glm-4-flash
  host: http://localhost:11434

memory:
  auto_compress: false  # 开发环境关闭自动压缩
  compress_at: [1, 7, 30, 90]
```

---

## 生产环境部署

### 系统要求

| 配置 | 最低 | 推荐 |
|------|------|------|
| CPU | 2 核 | 4 核+ |
| 内存 | 4 GB | 8 GB+ |
| 磁盘 | 20 GB | 100 GB+ |
| 系统 | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

### 安装步骤

```bash
# 1. 创建专用用户
sudo useradd -r -s /bin/false viking

# 2. 安装依赖
sudo apt-get update
sudo apt-get install -y python3 python3-pip curl jq

# 3. 部署 Viking
sudo mkdir -p /opt/viking
sudo git clone https://github.com/Xlous/viking-memory-system.git /opt/viking
sudo chown -R viking:viking /opt/viking

# 4. 配置 systemd 服务
sudo cp viking.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable viking
sudo systemctl start viking
```

### 生产配置

```yaml
# /opt/viking/config.yaml
production:
  workspace: /data/viking
  log_level: info
  log_file: /var/log/viking/viking.log

llm:
  service: ollama
  model: glm-4-flash
  host: http://192.168.5.110:11434
  timeout: 60
  retry: 3

memory:
  auto_compress: true
  compress_at: [1, 8, 30, 90]
  low_weight_threshold: 0.5
  max_memory_size: 10000

api:
  host: 0.0.0.0
  port: 8080
  workers: 4
  timeout: 300

security:
  api_key_required: true
  rate_limit: 100
```

---

## Docker 部署

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# 安装依赖
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 复制应用
COPY . .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建非root用户
RUN useradd -m viking && chown -R viking:viking /app
USER viking

# 暴露端口
EXPOSE 8080

CMD ["python", "-m", "viking_api"]
```

### Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  viking:
    image: viking-memory:latest
    container_name: viking-memory
    ports:
      - "8080:8080"
    volumes:
      - viking-data:/data
      - ./config.yaml:/app/config.yaml
    environment:
      - VIKING_WORKSPACE=/data/viking
      - VIKING_LLM_HOST=http://ollama:11434
    depends_on:
      - ollama
    restart: unless-stopped

  ollama:
    image: ollama/ollama:latest
    container_name: viking-ollama
    volumes:
      - ollama-data:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped

volumes:
  viking-data:
  ollama-data:
```

### 构建和运行

```bash
# 构建镜像
docker build -t viking-memory:latest .

# 运行
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止
docker-compose down
```

---

## Kubernetes 部署

### Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: viking-memory
  labels:
    app: viking-memory
spec:
  replicas: 3
  selector:
    matchLabels:
      app: viking-memory
  template:
    metadata:
      labels:
        app: viking-memory
    spec:
      containers:
      - name: viking
        image: viking-memory:latest
        ports:
        - containerPort: 8080
        env:
        - name: VIKING_WORKSPACE
          value: /data/viking
        - name: VIKING_LLM_HOST
          value: "http://ollama-service:11434"
        volumeMounts:
        - name: viking-data
          mountPath: /data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: viking-data
        persistentVolumeClaim:
          claimName: viking-pvc
```

### Service

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: viking-service
spec:
  selector:
    app: viking-memory
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

### PVC

```yaml
# k8s/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: viking-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

### 部署

```bash
# 部署
kubectl apply -f k8s/

# 查看状态
kubectl get pods -l app=viking-memory
kubectl get svc viking-service

# 扩展
kubectl scale deployment viking-memory --replicas=5
```

---

## 监控与运维

### 日志配置

```yaml
# 日志配置
logging:
  level: info
  file: /var/log/viking/viking.log
  max_size: 100MB
  max_backups: 10
  
  # 结构化日志
  format: json
  
  # 日志字段
  fields:
    service: viking-memory
    version: 2.0.0
```

### 监控指标

```python
# prometheus_metrics.py
from prometheus_client import Counter, Histogram, Gauge

# 请求指标
requests_total = Counter('viking_requests_total', 'Total requests')
request_duration = Histogram('viking_request_duration_seconds')

# 记忆指标
memories_count = Gauge('viking_memories_count', 'Total memories')
memories_by_layer = Gauge('viking_memories_by_layer', 'Memories by layer', ['layer'])
compression_total = Counter('viking_compression_total', 'Total compressions')

# LLM 指标
llm_requests_total = Counter('viking_llm_requests_total')
llm_request_duration = Histogram('viking_llm_request_duration_seconds')
```

### 健康检查

```bash
# 健康检查端点
curl http://localhost:8080/health
# {"status": "healthy", "version": "2.0.0"}

# 就绪检查
curl http://localhost:8080/ready
# {"status": "ready", "llm_connected": true}
```

### 告警规则

```yaml
# prometheus/alert-rules.yaml
groups:
- name: viking
  rules:
  - alert: HighErrorRate
    expr: rate(viking_requests_errors_total[5m]) > 0.1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate"
      
  - alert: LLMUnavailable
    expr: viking_llm_available == 0
    for: 1m
    labels:
      severity: high
    annotations:
      summary: "LLM service unavailable"
```

---

## 安全配置

### API 密钥

```yaml
# 安全配置
security:
  # API 密钥认证
  api_keys:
    - key: "sk-prod-xxxxx"
      name: "production"
      rate_limit: 1000
    - key: "sk-dev-xxxxx"
      name: "development"
      rate_limit: 100
  
  # JWT 配置 (可选)
  jwt:
    enabled: false
    secret: "${JWT_SECRET}"
    expiry: 3600
```

### 权限控制

```bash
# 文件权限
chmod 700 /opt/viking/scripts/*.sh
chmod 600 /opt/viking/config.yaml
chown -R viking:viking /opt/viking
```

### 网络安全

```yaml
# 网络策略
network:
  # 只允许内网访问
  allowed_cidrs:
    - 10.0.0.0/8
    - 172.16.0.0/12
    
  # TLS 配置
  tls:
    enabled: true
    cert_path: /etc/ssl/certs/viking.crt
    key_path: /etc/ssl/private/viking.key
```

---

## 备份与恢复

### 自动备份

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/viking"
DATE=$(date +%Y%m%d)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份记忆数据
tar -czf $BACKUP_DIR/viking-$DATE.tar.gz \
    --exclude='*.log' \
    --exclude='.index' \
    /data/viking

# 备份配置
cp /opt/viking/config.yaml $BACKUP_DIR/config-$DATE.yaml

# 保留 30 天
find $BACKUP_DIR -name "viking-*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "config-*.yaml" -mtime +30 -delete

echo "Backup completed: $DATE"
```

### 恢复

```bash
#!/bin/bash
# restore.sh

BACKUP_FILE=$1
TARGET_DIR="/data/viking"

# 停止服务
systemctl stop viking

# 恢复数据
tar -xzf $BACKUP_FILE -C /

# 修复权限
chown -R viking:viking $TARGET_DIR

# 启动服务
systemctl start viking

echo "Restore completed"
```

### Cron 备份任务

```bash
# /etc/cron.d/viking-backup
# 每天凌晨3点备份
0 3 * * * root /opt/viking/scripts/backup.sh >> /var/log/viking-backup.log 2>&1
```

---

## 相关文档

- [安装指南](../INSTALL.md)
- [使用说明](../USAGE.md)
- [架构设计](../ARCHITECTURE.md)
- [OpenClaw 改动说明](./openclaw-modifications.md)

---

*文档版本: v2.0 | 更新日期: 2026-03-14*
