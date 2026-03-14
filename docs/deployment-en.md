# Viking Memory System Deployment Guide

This document provides detailed deployment solutions for the Viking Memory System in different environments.

## Table of Contents

1. [Deployment Architecture](#deployment-architecture)
2. [Development Deployment](#development-deployment)
3. [Production Deployment](#production-deployment)
4. [Docker Deployment](#docker-deployment)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Monitoring and Operations](#monitoring-and-operations)
7. [Security Configuration](#security-configuration)
8. [Backup and Recovery](#backup-and-recovery)

---

## Deployment Architecture

### Single Machine Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                 Single Machine Deployment                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌─────────────┐                                          │
│   │  User/Agent  │                                          │
│   └──────┬──────┘                                          │
│          │                                                  │
│          ▼                                                  │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                  OpenClaw / Application              │  │
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
│   │              Local File System (Storage)             │  │
│   │         ~/.openclaw/viking-{agent}                  │  │
│   └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              LLM Service (Ollama/API)                 │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Distributed Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                  Distributed Deployment                    │
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
│   │ Viking API  │        │ Viking API  │  (Multi-instance)  │
│   │   Node 1    │        │   Node N    │                   │
│   └──────┬──────┘        └──────┬──────┘                   │
│          │                      │                           │
│          └──────────┬───────────┘                           │
│                     │                                        │
│                     ▼                                        │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              Distributed Storage (S3/MinIO)          │  │
│   └─────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              LLM Cluster (Ollama/K8s)                 │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Development Deployment

### Quick Start

```bash
# 1. Clone project
git clone https://github.com/Xlous/viking-memory-system.git
cd viking-memory-system

# 2. Run installation script
chmod +x install.sh
./install.sh

# 3. Initialize workspace
mkdir -p ~/.openclaw/viking-dev

# 4. Verify installation
./scripts/sv_autoload.sh --help
```

### Development Configuration

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
  auto_compress: false  # Disable in dev
  compress_at: [1, 7, 30, 90]
```

---

## Production Deployment

### System Requirements

| Config | Minimum | Recommended |
|--------|---------|-------------|
| CPU | 2 cores | 4 cores+ |
| Memory | 4 GB | 8 GB+ |
| Disk | 20 GB | 100 GB+ |
| OS | Ubuntu 20.04+ | Ubuntu 22.04 LTS |

### Installation Steps

```bash
# 1. Create dedicated user
sudo useradd -r -s /bin/false viking

# 2. Install dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip curl jq

# 3. Deploy Viking
sudo mkdir -p /opt/viking
sudo git clone https://github.com/Xlous/viking-memory-system.git /opt/viking
sudo chown -R viking:viking /opt/viking

# 4. Configure systemd service
sudo cp viking.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable viking
sudo systemctl start viking
```

### Production Configuration

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

## Docker Deployment

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Copy application
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create non-root user
RUN useradd -m viking && chown -R viking:viking /app
USER viking

# Expose port
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

### Build and Run

```bash
# Build image
docker build -t viking-memory:latest .

# Run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## Kubernetes Deployment

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

### Deploy

```bash
# Deploy
kubectl apply -f k8s/

# Check status
kubectl get pods -l app=viking-memory
kubectl get svc viking-service

# Scale
kubectl scale deployment viking-memory --replicas=5
```

---

## Monitoring and Operations

### Logging Configuration

```yaml
# Logging config
logging:
  level: info
  file: /var/log/viking/viking.log
  max_size: 100MB
  max_backups: 10
  
  # Structured logging
  format: json
  
  # Log fields
  fields:
    service: viking-memory
    version: 2.0.0
```

### Monitoring Metrics

```python
# prometheus_metrics.py
from prometheus_client import Counter, Histogram, Gauge

# Request metrics
requests_total = Counter('viking_requests_total', 'Total requests')
request_duration = Histogram('viking_request_duration_seconds')

# Memory metrics
memories_count = Gauge('viking_memories_count', 'Total memories')
memories_by_layer = Gauge('viking_memories_by_layer', 'Memories by layer', ['layer'])
compression_total = Counter('viking_compression_total', 'Total compressions')

# LLM metrics
llm_requests_total = Counter('viking_llm_requests_total')
llm_request_duration = Histogram('viking_llm_request_duration_seconds')
```

### Health Checks

```bash
# Health check endpoint
curl http://localhost:8080/health
# {"status": "healthy", "version": "2.0.0"}

# Readiness check
curl http://localhost:8080/ready
# {"status": "ready", "llm_connected": true}
```

### Alert Rules

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

## Security Configuration

### API Keys

```yaml
# Security config
security:
  # API key authentication
  api_keys:
    - key: "sk-prod-xxxxx"
      name: "production"
      rate_limit: 1000
    - key: "sk-dev-xxxxx"
      name: "development"
      rate_limit: 100
  
  # JWT config (optional)
  jwt:
    enabled: false
    secret: "${JWT_SECRET}"
    expiry: 3600
```

### Permission Control

```bash
# File permissions
chmod 700 /opt/viking/scripts/*.sh
chmod 600 /opt/viking/config.yaml
chown -R viking:viking /opt/viking
```

### Network Security

```yaml
# Network policy
network:
  # Only allow internal network
  allowed_cidrs:
    - 10.0.0.0/8
    - 172.16.0.0/12
    
  # TLS config
  tls:
    enabled: true
    cert_path: /etc/ssl/certs/viking.crt
    key_path: /etc/ssl/private/viking.key
```

---

## Backup and Recovery

### Automated Backup

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/viking"
DATE=$(date +%Y%m%d)

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup memory data
tar -czf $BACKUP_DIR/viking-$DATE.tar.gz \
    --exclude='*.log' \
    --exclude='.index' \
    /data/viking

# Backup config
cp /opt/viking/config.yaml $BACKUP_DIR/config-$DATE.yaml

# Keep 30 days
find $BACKUP_DIR -name "viking-*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "config-*.yaml" -mtime +30 -delete

echo "Backup completed: $DATE"
```

### Restore

```bash
#!/bin/bash
# restore.sh

BACKUP_FILE=$1
TARGET_DIR="/data/viking"

# Stop service
systemctl stop viking

# Restore data
tar -xzf $BACKUP_FILE -C /

# Fix permissions
chown -R viking:viking $TARGET_DIR

# Start service
systemctl start viking

echo "Restore completed"
```

### Cron Backup Task

```bash
# /etc/cron.d/viking-backup
# Backup daily at 3 AM
0 3 * * * root /opt/viking/scripts/backup.sh >> /var/log/viking-backup.log 2>&1
```

---

## Related Documentation

- [Installation Guide](../INSTALL-en.md)
- [Usage Guide](../USAGE-en.md)
- [Architecture Design](../ARCHITECTURE-en.md)
- [OpenClaw Modifications](./openclaw-modifications.md)

---

*Document Version: v2.0 | Updated: 2026-03-14*
