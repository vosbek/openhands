# OpenHands: Comprehensive Setup & Configuration Guide

## Executive Summary

This guide provides an exhaustive walkthrough for deploying OpenHands in various environments, from local development to enterprise production deployments. It covers all supported deployment methods, security configurations, performance optimizations, and troubleshooting procedures.

## Table of Contents

1. [Prerequisites & System Requirements](#prerequisites--system-requirements)
2. [Deployment Options Overview](#deployment-options-overview)
3. [Local Development Setup](#local-development-setup)
4. [Docker/Podman Deployment](#dockerpodman-deployment)
5. [AWS Bedrock Integration](#aws-bedrock-integration)
6. [Enterprise Kubernetes Deployment](#enterprise-kubernetes-deployment)
7. [Security Hardening](#security-hardening)
8. [Performance Optimization](#performance-optimization)
9. [Monitoring & Logging](#monitoring--logging)
10. [Troubleshooting & Common Issues](#troubleshooting--common-issues)
11. [Maintenance & Updates](#maintenance--updates)

---

## Prerequisites & System Requirements

### Hardware Requirements

| Component | Minimum | Recommended | Enterprise |
|-----------|---------|-------------|------------|
| CPU | 4 cores | 8 cores | 16+ cores |
| RAM | 8GB | 16GB | 32GB+ |
| Storage | 50GB | 100GB | 500GB+ |
| Network | 100Mbps | 1Gbps | 10Gbps+ |

### Software Prerequisites

#### Core Dependencies
- **Container Runtime**: Docker 20.10+ or Podman 4.0+
- **Python**: 3.9+ (for development/debugging)
- **Node.js**: 18+ (for UI development)
- **Git**: 2.30+ (for repository management)

#### Operating System Support
- **Linux**: Ubuntu 20.04+, RHEL 8+, CentOS 8+, Amazon Linux 2
- **macOS**: 12.0+ (Monterey)
- **Windows**: Windows 10/11 with WSL2

#### Cloud Platform Requirements
- **AWS**: Account with Bedrock access, EC2, VPC, IAM permissions
- **Azure**: Container instances, OpenAI service access
- **GCP**: Compute Engine, Vertex AI access

### Network Requirements

#### Inbound Ports
- **3000**: OpenHands UI (configurable)
- **8080**: Sample application port
- **22**: SSH access (enterprise deployments)

#### Outbound Connectivity
- **443**: HTTPS for LLM API calls
- **80**: HTTP for package downloads
- **22**: Git repository access
- **Docker Registry**: Container image pulls

---

## Deployment Options Overview

### 1. Local Development (Quickstart)
**Use Case**: Individual developers, testing, learning
**Complexity**: Low
**Security**: Minimal
**Scalability**: Single user

### 2. Docker/Podman Standalone
**Use Case**: Small teams, isolated environments
**Complexity**: Medium
**Security**: Moderate
**Scalability**: Limited

### 3. AWS Bedrock Integration
**Use Case**: Enterprise security, compliance
**Complexity**: High
**Security**: High
**Scalability**: High

### 4. Kubernetes Deployment
**Use Case**: Production, multi-tenant, high availability
**Complexity**: Very High
**Security**: Maximum
**Scalability**: Unlimited

---

## Local Development Setup

### Quick Start (5 minutes)

```bash
# Clone the repository
git clone https://github.com/All-Hands-AI/OpenHands.git
cd OpenHands

# Start with Docker Compose
docker-compose up -d

# Access the UI
open http://localhost:3000
```

### Development Environment Setup

#### 1. Environment Configuration

```bash
# Create environment file
cat > .env << EOF
# Core Configuration
SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik
LOG_ALL_EVENTS=true
DEBUG=true

# LLM Configuration (OpenAI Example)
LLM_MODEL=gpt-4-turbo
LLM_API_KEY=your-openai-api-key
LLM_BASE_URL=https://api.openai.com/v1

# Security
SECURE_MODE=false
SANDBOX_TIMEOUT=300

# Performance
MAX_CONCURRENT_TASKS=1
MEMORY_LIMIT=4g
CPU_LIMIT=2
EOF
```

#### 2. Development Tools Setup

```bash
# Install development dependencies
pip install -r requirements-dev.txt
npm install

# Setup pre-commit hooks
pre-commit install

# Run development server
python -m openhands.server.listen --port 3000
```

### IDE Integration

#### VS Code Configuration

```json
{
  "python.defaultInterpreterPath": "./venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "docker.defaultRegistryPath": "docker.all-hands.dev",
  "extensions.recommendations": [
    "ms-python.python",
    "ms-vscode.vscode-typescript-next",
    "ms-azuretools.vscode-docker"
  ]
}
```

---

## Docker/Podman Deployment

### Standard Docker Deployment

#### 1. Docker Compose Configuration

```yaml
# docker-compose.yml
version: '3.8'
services:
  openhands:
    image: docker.all-hands.dev/all-hands-ai/openhands:0.48
    container_name: openhands-app
    ports:
      - "3000:3000"
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik
      - LOG_ALL_EVENTS=true
      - LLM_MODEL=${LLM_MODEL}
      - LLM_API_KEY=${LLM_API_KEY}
      - LLM_BASE_URL=${LLM_BASE_URL}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./workspace:/workspace
      - ./logs:/app/logs
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - openhands
```

#### 2. Nginx Configuration

```nginx
events {
    worker_connections 1024;
}

http {
    upstream openhands {
        server openhands:3000;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        location / {
            proxy_pass http://openhands;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

### Podman Deployment (Enterprise)

#### 1. Rootless Podman Setup

```bash
# Install Podman (RHEL/CentOS)
sudo dnf install -y podman podman-compose

# Configure rootless mode
echo "$USER:10000:65536" | sudo tee -a /etc/subuid
echo "$USER:10000:65536" | sudo tee -a /etc/subgid

# Enable user namespaces
echo "user.max_user_namespaces=28633" | sudo tee -a /etc/sysctl.d/userns.conf
sudo sysctl -p /etc/sysctl.d/userns.conf

# Setup Podman socket
systemctl --user enable podman.socket
systemctl --user start podman.socket
```

#### 2. Secure Podman Configuration

```bash
# Create secure podman configuration
mkdir -p ~/.config/containers

cat > ~/.config/containers/policy.json << EOF
{
    "default": [
        {
            "type": "reject"
        }
    ],
    "transports": {
        "docker": {
            "docker.all-hands.dev": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8"
                }
            ]
        }
    }
}
EOF

# Create containers.conf
cat > ~/.config/containers/containers.conf << EOF
[containers]
default_capabilities = [
    "CHOWN",
    "DAC_OVERRIDE",
    "FOWNER",
    "FSETID",
    "KILL",
    "NET_BIND_SERVICE",
    "SETFCAP",
    "SETGID",
    "SETPCAP",
    "SETUID",
    "SYS_CHROOT"
]

[engine]
runtime = "crun"
infra_image = "registry.access.redhat.com/ubi8/pause:latest"

[network]
default_network = "podman"
network_cmd_path = "/usr/bin/netavark"
EOF
```

#### 3. Production Podman Command

```bash
#!/bin/bash
# deploy-openhands.sh

set -euo pipefail

# Configuration
IMAGE="docker.all-hands.dev/all-hands-ai/openhands:0.48"
CONTAINER_NAME="openhands-production"
PORT="3000"
WORKSPACE_DIR="/opt/openhands/workspace"
LOGS_DIR="/opt/openhands/logs"

# Create directories
sudo mkdir -p "$WORKSPACE_DIR" "$LOGS_DIR"
sudo chown -R "$USER:$USER" "$WORKSPACE_DIR" "$LOGS_DIR"

# Stop existing container
podman stop "$CONTAINER_NAME" 2>/dev/null || true
podman rm "$CONTAINER_NAME" 2>/dev/null || true

# Deploy new container
podman run -d \
  --name "$CONTAINER_NAME" \
  --restart=unless-stopped \
  --security-opt seccomp=seccomp.json \
  --security-opt apparmor=openhands \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --read-only \
  --tmpfs /tmp:noexec,nosuid,size=1g \
  --tmpfs /var/tmp:noexec,nosuid,size=1g \
  -p "$PORT:3000" \
  -v "$WORKSPACE_DIR:/workspace:rw" \
  -v "$LOGS_DIR:/app/logs:rw" \
  -v /run/podman/podman.sock:/var/run/docker.sock:ro \
  --env-file .env \
  "$IMAGE"

echo "OpenHands deployed successfully!"
echo "Access: http://localhost:$PORT"
podman logs -f "$CONTAINER_NAME"
```

---

## AWS Bedrock Integration

### Enhanced Bedrock Setup

#### 1. Advanced IAM Configuration

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BedrockModelAccess",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream"
            ],
            "Resource": [
                "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
                "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0",
                "arn:aws:bedrock:us-east-1::foundation-model/cohere.command-r-plus-v1:0"
            ]
        },
        {
            "Sid": "BedrockModelInfo",
            "Effect": "Allow",
            "Action": [
                "bedrock:GetFoundationModel",
                "bedrock:ListFoundationModels"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchLogs",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:us-east-1:*:log-group:/aws/bedrock/openhands*"
        }
    ]
}
```

#### 2. VPC Endpoint Configuration

```bash
# Create VPC endpoint for Bedrock
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-12345678 \
  --service-name com.amazonaws.us-east-1.bedrock-runtime \
  --route-table-ids rtb-12345678 \
  --policy-document file://bedrock-endpoint-policy.json

# Endpoint policy
cat > bedrock-endpoint-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalTag/Project": "OpenHands"
                }
            }
        }
    ]
}
EOF
```

#### 3. Multi-Model Configuration

```bash
# Enhanced environment configuration
cat > .env.bedrock << EOF
# Primary Model Configuration
LLM_MODEL=anthropic.claude-3-sonnet-20240229-v1:0
LLM_BASE_URL=https://bedrock-runtime.us-east-1.amazonaws.com
LLM_API_KEY=bedrock

# Fallback Model Configuration
LLM_FALLBACK_MODEL=anthropic.claude-3-haiku-20240307-v1:0
LLM_FALLBACK_ENABLED=true

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...

# Cost Control
LLM_MAX_TOKENS=4000
LLM_TIMEOUT=30
LLM_RATE_LIMIT=10

# Monitoring
CLOUDWATCH_LOG_GROUP=/aws/bedrock/openhands
CLOUDWATCH_ENABLED=true
METRICS_ENABLED=true
EOF
```

### Cost Optimization

#### 1. Token Usage Monitoring

```python
# token_monitor.py
import boto3
import json
from datetime import datetime, timedelta

class BedrockCostMonitor:
    def __init__(self, region='us-east-1'):
        self.bedrock = boto3.client('bedrock-runtime', region_name=region)
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
    
    def log_usage(self, model_id, input_tokens, output_tokens, cost):
        """Log token usage to CloudWatch"""
        self.cloudwatch.put_metric_data(
            Namespace='OpenHands/Bedrock',
            MetricData=[
                {
                    'MetricName': 'InputTokens',
                    'Value': input_tokens,
                    'Unit': 'Count',
                    'Dimensions': [{'Name': 'Model', 'Value': model_id}]
                },
                {
                    'MetricName': 'OutputTokens',
                    'Value': output_tokens,
                    'Unit': 'Count',
                    'Dimensions': [{'Name': 'Model', 'Value': model_id}]
                },
                {
                    'MetricName': 'Cost',
                    'Value': cost,
                    'Unit': 'None',
                    'Dimensions': [{'Name': 'Model', 'Value': model_id}]
                }
            ]
        )
    
    def check_daily_budget(self, budget_limit=100.0):
        """Check if daily budget is exceeded"""
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=1)
        
        response = self.cloudwatch.get_metric_statistics(
            Namespace='OpenHands/Bedrock',
            MetricName='Cost',
            StartTime=start_time,
            EndTime=end_time,
            Period=86400,
            Statistics=['Sum']
        )
        
        if response['Datapoints']:
            daily_cost = response['Datapoints'][0]['Sum']
            return daily_cost > budget_limit, daily_cost
        return False, 0.0
```

---

## Enterprise Kubernetes Deployment

### 1. Kubernetes Manifests

#### Namespace and RBAC

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openhands
  labels:
    name: openhands
    security: restricted
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: openhands-sa
  namespace: openhands
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/OpenHandsRole
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: openhands-role
  namespace: openhands
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: openhands-binding
  namespace: openhands
subjects:
- kind: ServiceAccount
  name: openhands-sa
  namespace: openhands
roleRef:
  kind: Role
  name: openhands-role
  apiGroup: rbac.authorization.k8s.io
```

#### ConfigMap and Secrets

```yaml
# config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openhands-config
  namespace: openhands
data:
  SANDBOX_RUNTIME_CONTAINER_IMAGE: "docker.all-hands.dev/all-hands-ai/runtime:0.48-nikolaik"
  LOG_ALL_EVENTS: "true"
  LLM_MODEL: "anthropic.claude-3-sonnet-20240229-v1:0"
  LLM_BASE_URL: "https://bedrock-runtime.us-east-1.amazonaws.com"
  AWS_REGION: "us-east-1"
  MAX_CONCURRENT_TASKS: "5"
  MEMORY_LIMIT: "8g"
  CPU_LIMIT: "4"
  SECURE_MODE: "true"
  SANDBOX_TIMEOUT: "600"
---
apiVersion: v1
kind: Secret
metadata:
  name: openhands-secrets
  namespace: openhands
type: Opaque
data:
  LLM_API_KEY: YmVkcm9jaw==  # base64 encoded "bedrock"
  # AWS credentials handled by IRSA
```

#### Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openhands
  namespace: openhands
  labels:
    app: openhands
spec:
  replicas: 3
  selector:
    matchLabels:
      app: openhands
  template:
    metadata:
      labels:
        app: openhands
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: openhands-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: openhands
        image: docker.all-hands.dev/all-hands-ai/openhands:0.48
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        - containerPort: 8080
          name: metrics
        envFrom:
        - configMapRef:
            name: openhands-config
        - secretRef:
            name: openhands-secrets
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "8Gi"
            cpu: "4000m"
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: logs
          mountPath: /app/logs
        - name: tmp
          mountPath: /tmp
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: workspace
        persistentVolumeClaim:
          claimName: openhands-workspace-pvc
      - name: logs
        persistentVolumeClaim:
          claimName: openhands-logs-pvc
      - name: tmp
        emptyDir:
          sizeLimit: 1Gi
      nodeSelector:
        kubernetes.io/os: linux
        node-type: compute
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "openhands"
        effect: "NoSchedule"
```

#### Service and Ingress

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: openhands-service
  namespace: openhands
  labels:
    app: openhands
spec:
  selector:
    app: openhands
  ports:
  - port: 80
    targetPort: 3000
    name: http
  - port: 8080
    targetPort: 8080
    name: metrics
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openhands-ingress
  namespace: openhands
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - openhands.your-domain.com
    secretName: openhands-tls
  rules:
  - host: openhands.your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: openhands-service
            port:
              number: 80
```

### 2. Horizontal Pod Autoscaler

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: openhands-hpa
  namespace: openhands
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: openhands
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

---

## Security Hardening

### 1. Container Security

#### Seccomp Profile

```json
{
    "defaultAction": "SCMP_ACT_ERRNO",
    "archMap": [
        {
            "architecture": "SCMP_ARCH_X86_64",
            "subArchitectures": [
                "SCMP_ARCH_X86",
                "SCMP_ARCH_X32"
            ]
        }
    ],
    "syscalls": [
        {
            "names": [
                "accept",
                "accept4",
                "access",
                "arch_prctl",
                "bind",
                "brk",
                "chdir",
                "chmod",
                "chown",
                "close",
                "connect",
                "dup",
                "dup2",
                "execve",
                "exit",
                "exit_group",
                "fchmod",
                "fchown",
                "fcntl",
                "fork",
                "fstat",
                "fsync",
                "getdents",
                "getegid",
                "geteuid",
                "getgid",
                "getpid",
                "getppid",
                "getuid",
                "listen",
                "lseek",
                "lstat",
                "mkdir",
                "mmap",
                "mprotect",
                "munmap",
                "open",
                "openat",
                "pipe",
                "pipe2",
                "read",
                "readlink",
                "rename",
                "rmdir",
                "rt_sigaction",
                "rt_sigprocmask",
                "rt_sigreturn",
                "select",
                "socket",
                "stat",
                "symlink",
                "unlink",
                "wait4",
                "write"
            ],
            "action": "SCMP_ACT_ALLOW"
        }
    ]
}
```

#### AppArmor Profile

```bash
# /etc/apparmor.d/openhands
#include <tunables/global>

profile openhands flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>
  #include <abstractions/ssl_certs>

  capability dac_override,
  capability setuid,
  capability setgid,
  capability net_bind_service,

  network inet tcp,
  network inet udp,
  network inet6 tcp,
  network inet6 udp,

  /app/** r,
  /workspace/** rw,
  /tmp/** rw,
  /var/tmp/** rw,
  /usr/bin/** ix,
  /usr/local/bin/** ix,

  # Deny dangerous operations
  deny /etc/passwd w,
  deny /etc/shadow rw,
  deny /proc/sys/kernel/** rw,
  deny /sys/** rw,
  deny mount,
  deny umount,
  deny ptrace,
  deny signal,

  # Python specific
  /usr/bin/python3* ix,
  /usr/lib/python3*/** r,
  /usr/local/lib/python3*/** r,

  # Node.js specific
  /usr/bin/node ix,
  /usr/lib/node_modules/** r,
}
```

### 2. Network Security

#### Network Policies

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: openhands-netpol
  namespace: openhands
spec:
  podSelector:
    matchLabels:
      app: openhands
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    - podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 3000
    - protocol: TCP
      port: 8080
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

### 3. Secrets Management

#### External Secrets Operator

```yaml
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: openhands
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        secretRef:
          accessKeyIDSecretRef:
            name: aws-credentials
            key: access-key-id
          secretAccessKeySecretRef:
            name: aws-credentials
            key: secret-access-key
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: openhands-secrets
  namespace: openhands
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: openhands-secrets
    creationPolicy: Owner
  data:
  - secretKey: LLM_API_KEY
    remoteRef:
      key: openhands/llm-api-key
  - secretKey: AWS_ACCESS_KEY_ID
    remoteRef:
      key: openhands/aws-access-key-id
  - secretKey: AWS_SECRET_ACCESS_KEY
    remoteRef:
      key: openhands/aws-secret-access-key
```

---

## Performance Optimization

### 1. Resource Tuning

#### JVM Tuning (if applicable)

```bash
# jvm-opts.conf
-Xms2g
-Xmx8g
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=8
-XX:ConcGCThreads=2
-XX:+UseStringDeduplication
-XX:+OptimizeStringConcat
-XX:+UseCompressedOops
-XX:+UseCompressedClassPointers
-Djava.awt.headless=true
-Dfile.encoding=UTF-8
-Duser.timezone=UTC
```

#### Python Optimization

```bash
# python-opts.sh
export PYTHONUNBUFFERED=1
export PYTHONHASHSEED=0
export PYTHONOPTIMIZE=2
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH=/app:/app/src
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=131072
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_TOP_PAD_=131072
export MALLOC_MMAP_MAX_=65536
```

### 2. Caching Strategy

#### Redis Configuration

```yaml
# redis-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
  namespace: openhands
data:
  redis.conf: |
    maxmemory 2gb
    maxmemory-policy allkeys-lru
    timeout 300
    tcp-keepalive 60
    save 900 1
    save 300 10
    save 60 10000
    stop-writes-on-bgsave-error yes
    rdbcompression yes
    rdbchecksum yes
    dbfilename dump.rdb
    dir /data
    appendonly yes
    appendfsync everysec
    no-appendfsync-on-rewrite no
    auto-aof-rewrite-percentage 100
    auto-aof-rewrite-min-size 64mb
```

### 3. Database Optimization

#### PostgreSQL Configuration

```sql
-- postgresql.conf optimizations
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 32MB
maintenance_work_mem = 512MB
max_connections = 100
random_page_cost = 1.1
effective_io_concurrency = 200
max_worker_processes = 8
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 512MB
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
```

---

## Monitoring & Logging

### 1. Prometheus Configuration

```yaml
# prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
    - /etc/prometheus/rules/*.yml
    
    scrape_configs:
    - job_name: 'openhands'
      static_configs:
      - targets: ['openhands-service.openhands.svc.cluster.local:8080']
      metrics_path: /metrics
      scrape_interval: 30s
      honor_labels: true
      
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - openhands
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

### 2. Grafana Dashboard

```json
{
  "dashboard": {
    "title": "OpenHands Operations Dashboard",
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(openhands_requests_total[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(openhands_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(openhands_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      },
      {
        "title": "Active Tasks",
        "type": "singlestat",
        "targets": [
          {
            "expr": "openhands_active_tasks",
            "legendFormat": "Active Tasks"
          }
        ]
      },
      {
        "title": "LLM Token Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(openhands_llm_tokens_total[5m])",
            "legendFormat": "{{type}}"
          }
        ]
      },
      {
        "title": "Container Resource Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{pod=~\"openhands-.*\"}[5m])",
            "legendFormat": "CPU Usage"
          },
          {
            "expr": "container_memory_usage_bytes{pod=~\"openhands-.*\"}",
            "legendFormat": "Memory Usage"
          }
        ]
      }
    ]
  }
}
```

### 3. Structured Logging

```python
# logging_config.py
import logging
import json
from datetime import datetime

class StructuredFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
            'thread': record.thread,
            'process': record.process
        }
        
        # Add extra fields
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
        if hasattr(record, 'task_id'):
            log_entry['task_id'] = record.task_id
        if hasattr(record, 'session_id'):
            log_entry['session_id'] = record.session_id
        
        # Add exception info if present
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/app/logs/openhands.log')
    ]
)

# Apply structured formatter
for handler in logging.root.handlers:
    handler.setFormatter(StructuredFormatter())
```

---

## Troubleshooting & Common Issues

### 1. Container Issues

#### Problem: Container fails to start

**Symptoms:**
- Container exits immediately
- "Permission denied" errors
- "No such file or directory" errors

**Diagnosis:**
```bash
# Check container logs
docker logs openhands-app

# Check image contents
docker run -it --rm --entrypoint=/bin/sh docker.all-hands.dev/all-hands-ai/openhands:0.48

# Check permissions
docker exec -it openhands-app ls -la /app
```

**Solutions:**
1. **Permission Issues:**
   ```bash
   # Fix ownership
   sudo chown -R 1000:1000 /path/to/workspace
   
   # Update container user
   docker run --user 1000:1000 ...
   ```

2. **Missing Dependencies:**
   ```bash
   # Rebuild with dependencies
   docker build --no-cache -t openhands-custom .
   ```

3. **Environment Variables:**
   ```bash
   # Validate environment
   docker run --rm openhands-app env | grep -E "(LLM|AWS)"
   ```

#### Problem: High memory usage

**Diagnosis:**
```bash
# Monitor memory usage
docker stats openhands-app

# Check memory breakdown
docker exec openhands-app cat /proc/meminfo

# Analyze heap dumps (if Java)
docker exec openhands-app jmap -dump:format=b,file=/tmp/heap.hprof 1
```

**Solutions:**
1. **Increase memory limits:**
   ```bash
   docker run --memory=8g --memory-swap=16g ...
   ```

2. **Optimize garbage collection:**
   ```bash
   # Add JVM flags
   -XX:+UseG1GC -XX:MaxGCPauseMillis=200
   ```

3. **Monitor for memory leaks:**
   ```bash
   # Enable memory profiling
   export PYTHONMALLOC=debug
   ```

### 2. LLM Integration Issues

#### Problem: Bedrock authentication failures

**Symptoms:**
- "AccessDeniedException" errors
- "UnauthorizedOperation" errors
- "TokenRefreshRequired" errors

**Diagnosis:**
```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Bedrock access
aws bedrock list-foundation-models --region us-east-1

# Test specific model
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-sonnet-20240229-v1:0 \
  --body '{"prompt":"Hello","max_tokens_to_sample":10}' \
  --region us-east-1 \
  response.json
```

**Solutions:**
1. **IAM Policy Issues:**
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "bedrock:InvokeModel",
                   "bedrock:GetFoundationModel"
               ],
               "Resource": "*"
           }
       ]
   }
   ```

2. **Region Mismatch:**
   ```bash
   # Ensure consistent region
   export AWS_DEFAULT_REGION=us-east-1
   export AWS_REGION=us-east-1
   ```

3. **Model Access:**
   ```bash
   # Request model access in Bedrock console
   aws bedrock put-model-invocation-logging-configuration \
     --logging-config '{"cloudWatchConfig":{"logGroupName":"/aws/bedrock/modelinvocations","roleArn":"arn:aws:iam::ACCOUNT:role/service-role/BedrockCloudWatchLogsRole"}}'
   ```

#### Problem: High latency or timeouts

**Diagnosis:**
```bash
# Test network connectivity
curl -w "@curl-format.txt" -o /dev/null -s "https://bedrock-runtime.us-east-1.amazonaws.com"

# Check DNS resolution
nslookup bedrock-runtime.us-east-1.amazonaws.com

# Monitor response times
watch -n 1 'curl -w "%{time_total}\n" -o /dev/null -s "https://bedrock-runtime.us-east-1.amazonaws.com"'
```

**Solutions:**
1. **Increase timeouts:**
   ```bash
   export LLM_TIMEOUT=60
   export HTTP_TIMEOUT=120
   ```

2. **Use VPC endpoint:**
   ```bash
   # Configure VPC endpoint
   export LLM_BASE_URL="https://vpce-12345678-abcdef01.bedrock-runtime.us-east-1.vpce.amazonaws.com"
   ```

3. **Implement retry logic:**
   ```python
   import time
   import random
   
   def exponential_backoff(attempt):
       return min(300, (2 ** attempt) + random.uniform(0, 1))
   
   for attempt in range(5):
       try:
           response = bedrock_client.invoke_model(**params)
           break
       except Exception as e:
           if attempt < 4:
               time.sleep(exponential_backoff(attempt))
           else:
               raise
   ```

### 3. Network and Connectivity Issues

#### Problem: Cannot access OpenHands UI

**Diagnosis:**
```bash
# Check container status
docker ps -a | grep openhands

# Check port binding
netstat -tulpn | grep 3000

# Test local connectivity
curl -v http://localhost:3000

# Check firewall rules
sudo ufw status
sudo iptables -L
```

**Solutions:**
1. **Port conflicts:**
   ```bash
   # Find process using port
   sudo lsof -i :3000
   
   # Use different port
   docker run -p 3001:3000 ...
   ```

2. **Firewall issues:**
   ```bash
   # Allow port through firewall
   sudo ufw allow 3000
   
   # Or disable firewall temporarily
   sudo ufw disable
   ```

3. **Network configuration:**
   ```bash
   # Check Docker network
   docker network ls
   docker network inspect bridge
   
   # Create custom network
   docker network create openhands-net
   docker run --network openhands-net ...
   ```

### 4. Performance Issues

#### Problem: Slow response times

**Diagnosis:**
```bash
# Monitor system resources
top -p $(pgrep -f openhands)
iostat -x 1
vmstat 1

# Check disk I/O
sudo iotop

# Monitor network
sudo nethogs
```

**Solutions:**
1. **Resource constraints:**
   ```bash
   # Increase container resources
   docker run --cpus=4 --memory=8g ...
   
   # Use faster storage
   docker run -v /fast/ssd:/workspace ...
   ```

2. **Database optimization:**
   ```sql
   -- Analyze query performance
   EXPLAIN ANALYZE SELECT * FROM tasks WHERE status = 'running';
   
   -- Add indexes
   CREATE INDEX idx_tasks_status ON tasks(status);
   CREATE INDEX idx_tasks_created_at ON tasks(created_at);
   ```

3. **Caching:**
   ```bash
   # Enable Redis caching
   docker run -d --name redis redis:alpine
   docker run --link redis:redis -e REDIS_URL=redis://redis:6379 ...
   ```

---

## Maintenance & Updates

### 1. Update Procedures

#### Rolling Updates

```bash
#!/bin/bash
# rolling-update.sh

set -euo pipefail

OLD_VERSION="0.47"
NEW_VERSION="0.48"
CONTAINER_NAME="openhands-app"
IMAGE_NAME="docker.all-hands.dev/all-hands-ai/openhands"

echo "Starting rolling update from $OLD_VERSION to $NEW_VERSION"

# Pull new image
echo "Pulling new image..."
docker pull "$IMAGE_NAME:$NEW_VERSION"

# Health check function
health_check() {
    local container_name=$1
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
            echo "Health check passed for $container_name"
            return 0
        fi
        echo "Health check failed, attempt $((attempt + 1))/$max_attempts"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "Health check failed for $container_name after $max_attempts attempts"
    return 1
}

# Backup current state
echo "Creating backup..."
docker exec "$CONTAINER_NAME" tar -czf /backup/openhands-backup-$(date +%Y%m%d-%H%M%S).tar.gz /workspace /app/logs

# Start new container
echo "Starting new container..."
docker run -d \
  --name "${CONTAINER_NAME}-new" \
  --env-file .env \
  -p 3001:3000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/workspace:/workspace \
  "$IMAGE_NAME:$NEW_VERSION"

# Wait for new container to be healthy
echo "Waiting for new container to be healthy..."
if health_check "${CONTAINER_NAME}-new"; then
    echo "New container is healthy, switching traffic..."
    
    # Update port mapping
    docker stop "$CONTAINER_NAME"
    docker run -d \
      --name "${CONTAINER_NAME}-temp" \
      --env-file .env \
      -p 3000:3000 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $(pwd)/workspace:/workspace \
      "$IMAGE_NAME:$NEW_VERSION"
    
    # Final health check
    if health_check "${CONTAINER_NAME}-temp"; then
        echo "Update successful, cleaning up..."
        docker rm "$CONTAINER_NAME"
        docker stop "${CONTAINER_NAME}-new"
        docker rm "${CONTAINER_NAME}-new"
        docker rename "${CONTAINER_NAME}-temp" "$CONTAINER_NAME"
        echo "Rolling update completed successfully"
    else
        echo "Final health check failed, rolling back..."
        docker stop "${CONTAINER_NAME}-temp"
        docker rm "${CONTAINER_NAME}-temp"
        docker start "$CONTAINER_NAME"
        docker stop "${CONTAINER_NAME}-new"
        docker rm "${CONTAINER_NAME}-new"
        echo "Rollback completed"
        exit 1
    fi
else
    echo "New container failed health check, rolling back..."
    docker stop "${CONTAINER_NAME}-new"
    docker rm "${CONTAINER_NAME}-new"
    echo "Rollback completed"
    exit 1
fi
```

#### Kubernetes Rolling Updates

```yaml
# update-strategy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openhands
  namespace: openhands
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: openhands
        image: docker.all-hands.dev/all-hands-ai/openhands:0.48
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
```

### 2. Backup and Recovery

#### Database Backup

```bash
#!/bin/bash
# backup-database.sh

set -euo pipefail

DATABASE_URL="postgresql://user:pass@localhost:5432/openhands"
BACKUP_DIR="/backup/database"
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename
BACKUP_FILE="$BACKUP_DIR/openhands-$(date +%Y%m%d-%H%M%S).sql"

# Create backup
echo "Creating database backup..."
pg_dump "$DATABASE_URL" > "$BACKUP_FILE"

# Compress backup
gzip "$BACKUP_FILE"

# Remove old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Verify backup
echo "Verifying backup..."
gunzip -t "$BACKUP_FILE.gz"

echo "Backup completed successfully: $BACKUP_FILE.gz"
```

#### Workspace Backup

```bash
#!/bin/bash
# backup-workspace.sh

set -euo pipefail

WORKSPACE_DIR="/workspace"
BACKUP_DIR="/backup/workspace"
RETENTION_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename
BACKUP_FILE="$BACKUP_DIR/workspace-$(date +%Y%m%d-%H%M%S).tar.gz"

# Create backup
echo "Creating workspace backup..."
tar -czf "$BACKUP_FILE" -C "$WORKSPACE_DIR" .

# Remove old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed successfully: $BACKUP_FILE"
```

### 3. Health Checks and Monitoring

#### Custom Health Check Script

```bash
#!/bin/bash
# health-check.sh

set -euo pipefail

HEALTH_URL="http://localhost:3000/health"
MAX_RESPONSE_TIME=5
ALERT_EMAIL="admin@company.com"

# Function to send alert
send_alert() {
    local message="$1"
    echo "$message" | mail -s "OpenHands Health Alert" "$ALERT_EMAIL"
    echo "$(date): $message" >> /var/log/openhands-health.log
}

# Check HTTP response
if ! response=$(curl -s -w "%{http_code}:%{time_total}" "$HEALTH_URL" --max-time $MAX_RESPONSE_TIME); then
    send_alert "OpenHands health check failed: Unable to connect to $HEALTH_URL"
    exit 1
fi

# Parse response
http_code=$(echo "$response" | cut -d: -f1)
response_time=$(echo "$response" | cut -d: -f2)

# Check HTTP status
if [ "$http_code" != "200" ]; then
    send_alert "OpenHands health check failed: HTTP $http_code"
    exit 1
fi

# Check response time
if (( $(echo "$response_time > $MAX_RESPONSE_TIME" | bc -l) )); then
    send_alert "OpenHands health check warning: Response time ${response_time}s exceeds threshold ${MAX_RESPONSE_TIME}s"
fi

# Check container resources
if command -v docker &> /dev/null; then
    container_id=$(docker ps -q -f name=openhands-app)
    if [ -n "$container_id" ]; then
        memory_usage=$(docker stats --no-stream --format "table {{.MemUsage}}" "$container_id" | tail -n 1 | cut -d/ -f1)
        cpu_usage=$(docker stats --no-stream --format "table {{.CPUPerc}}" "$container_id" | tail -n 1 | sed 's/%//')
        
        # Check memory usage (assuming 8GB limit)
        if (( $(echo "$memory_usage" | sed 's/[^0-9.]//g') > 7.0 )); then
            send_alert "OpenHands high memory usage: ${memory_usage}"
        fi
        
        # Check CPU usage
        if (( $(echo "$cpu_usage > 90" | bc -l) )); then
            send_alert "OpenHands high CPU usage: ${cpu_usage}%"
        fi
    fi
fi

echo "$(date): OpenHands health check passed"
```

#### Automated Recovery

```bash
#!/bin/bash
# auto-recovery.sh

set -euo pipefail

CONTAINER_NAME="openhands-app"
MAX_RESTART_ATTEMPTS=3
RESTART_DELAY=60

# Function to restart container
restart_container() {
    echo "$(date): Restarting OpenHands container..."
    docker restart "$CONTAINER_NAME"
    sleep $RESTART_DELAY
}

# Function to check if container is running
is_container_running() {
    docker ps -q -f name="$CONTAINER_NAME" | grep -q .
}

# Function to check if service is healthy
is_service_healthy() {
    curl -f -s http://localhost:3000/health > /dev/null 2>&1
}

# Main recovery logic
restart_count=0

while [ $restart_count -lt $MAX_RESTART_ATTEMPTS ]; do
    if is_container_running && is_service_healthy; then
        echo "$(date): OpenHands is healthy"
        exit 0
    fi
    
    echo "$(date): OpenHands is unhealthy, attempting recovery (attempt $((restart_count + 1))/$MAX_RESTART_ATTEMPTS)"
    
    if ! is_container_running; then
        echo "$(date): Container is not running, starting it..."
        docker start "$CONTAINER_NAME"
    else
        restart_container
    fi
    
    restart_count=$((restart_count + 1))
    
    # Wait before checking again
    sleep $RESTART_DELAY
done

echo "$(date): Failed to recover OpenHands after $MAX_RESTART_ATTEMPTS attempts"
exit 1
```

---

## Conclusion

This comprehensive setup guide provides enterprise-grade deployment options for OpenHands, covering everything from local development to production Kubernetes deployments. The guide emphasizes security, scalability, and operational excellence while providing practical troubleshooting procedures and maintenance workflows.

### Key Takeaways:

1. **Security First**: Always implement proper sandboxing, network policies, and access controls
2. **Scalability**: Use Kubernetes for production deployments with proper resource management
3. **Monitoring**: Implement comprehensive monitoring and alerting for operational visibility
4. **Maintenance**: Regular updates, backups, and health checks are essential
5. **Documentation**: Keep deployment procedures and configurations well-documented

For additional support and community resources, refer to the OpenHands GitHub repository and official documentation.
