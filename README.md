
# Konveyor N8N Integration

Konveyor output to modernize tech stack → AI agent will take the output and action it.

## Project Overview

This project creates an AI-powered Kubernetes automation workflow using:
- **Konveyor**: Provides modernization analysis and recommendations
- **MCP Server**: Exposes Kubernetes API via Model Context Protocol
- **N8N**: Workflow automation with AI agent capabilities
- **OpenAI**: Powers the AI decision-making agent

The integration allows you to chat with an AI agent that can inspect, monitor, and manage Kubernetes resources through natural language.

## Quick Start Guide

### Prerequisites

- Kubernetes cluster or OpenShift CRC
- 16GB+ RAM (12GB for CRC)
- `kubectl` or `oc` CLI configured
- Container runtime (Podman or Docker)
- N8N workflow (`K8sMCP.json` included)

### 🚀 Quick Deployment

Choose your deployment method based on your system:

#### Option 1: OpenShift CRC (Recommended for local development)
```bash
# For any architecture (Mac M1, Intel, Linux):
crc config set memory 12288
crc start
eval $(crc oc-env)
cd agentic/mcp/k8s && cp kustomization-crc.yaml kustomization.yaml && oc apply -k . && cd ../../..
```

#### Option 2: Standard Kubernetes
```bash
# For ARM64 systems (Mac M1, ARM Linux):
cd agentic/mcp/k8s && cp kustomization-arm64.yaml kustomization.yaml && kubectl apply -k . && cd ../../..

# For AMD64/x86_64 systems:
kubectl apply -k agentic/mcp/k8s/
```

#### Option 3: Automated CRC Deployment
```bash
# Complete setup with secrets management
chmod +x deploy-secure-crc.sh
./deploy-secure-crc.sh
```

### 🎯 Access Applications
- **N8N UI**: `https://n8n-n8n.apps-crc.testing` (CRC) or your cluster's service IP
- **MCP Server**: `https://k8smcp-k8smcp.apps-crc.testing` (CRC)
- Import `K8sMCP.json` workflow into N8N
- Configure OpenAI credentials in N8N settings

### 💬 Start Chatting!
Once deployed, you can chat with your AI agent to manage Kubernetes resources using natural language.

## 📋 Deployment Reference

| System | Platform | Command | Notes |
|--------|----------|---------|-------|
| **Any** | CRC | `cd agentic/mcp/k8s && cp kustomization-crc.yaml kustomization.yaml && oc apply -k .` | Downloads correct binary via init container |
| **ARM64** | K8s | `cd agentic/mcp/k8s && cp kustomization-arm64.yaml kustomization.yaml && kubectl apply -k .` | ARM64 binary download |
| **AMD64** | K8s | `kubectl apply -k agentic/mcp/k8s/` | Private registry image (requires auth) |
| **Any** | CRC | `./deploy-secure-crc.sh` | Automated with secrets management |

For complete instructions, see [`CRC_DEPLOYMENT_GUIDE.md`](CRC_DEPLOYMENT_GUIDE.md)

---

## Architecture Components

### File Structure
```
agentic/
├── mcp/k8s/           # MCP Server Kubernetes manifests
│   ├── k8smcp-deployment-arm64.yaml     # ARM64 deployment (Mac M1)
│   ├── k8smcp-deployment-crc.yaml       # CRC/AMD64 deployment  
│   ├── k8smcp-deployment.yaml           # Standard K8s/AMD64
│   ├── k8smcp-service.yaml
│   ├── k8smcp-namespace.yaml
│   ├── kustomization.yaml              # Default (AMD64)
│   ├── kustomization-crc.yaml          # CRC-specific
│   └── kustomization-arm64.yaml        # ARM64-specific
└── n8n/k8s/          # N8N Kubernetes manifests
    ├── n8n-deployment.yaml
    ├── n8n-service.yaml
    ├── postgres/      # PostgreSQL for N8N persistence
    └── kustomization.yaml

K8sMCP.json           # Pre-configured N8N workflow
```

### AI Workflow Components
- **Chat Trigger**: Receives user messages
- **AI Agent**: Processes requests using OpenAI GPT-4o-mini
- **Memory**: Maintains conversation context
- **MCP Client**: Connects to Kubernetes MCP server at `k8smcp.k8smcp:8080/sse`

---

## Manual Container Build (Alternative)

**Containerfile:**

```dockerfile
FROM alpine:3.22.1 AS downloader
ARG MCP_VERSION
RUN apk add --no-cache curl
RUN curl -L https://github.com/containers/kubernetes-mcp-server/releases/download/${MCP_VERSION}/kubernetes-mcp-server-linux-amd64 \
   -o /kubernetes-mcp-server && \
   chmod +x /kubernetes-mcp-server
FROM alpine:3.22.1
RUN mkdir /mcp
COPY --from=downloader /kubernetes-mcp-server /mcp/kubernetes-mcp-server
ENTRYPOINT ["./mcp/kubernetes-mcp-server", "--port", "8080", "--log-level", "4"]
```

### Build image

```bash
podman build --build-arg MCP_VERSION=v0.0.49 -t k8smcp:v1 .
```

### Create local volume

```bash
podman create volume kubeconfig
```

### Add kubeconfig

```bash
podman run --rm -v kubeconfig:/kubeconfig -v $HOME/.kube/config:/tmp/config:ro alpine sh -c "cp /tmp/config /kubeconfig/config"
```

### Run MCP locally

```bash
podman run -d --name k8smcp_test -p 8080:8080 -v kubeconfig:/root/.kube:ro localhost/k8smcp:v1
```

---

## Configure VS Code

1. Press `CTRL+SHIFT+P`
2. Select `MCP: Add server`
3. Add `http://localhost:8080/sse`
4. Register with Copilot
5. Use Copilot to connect to your cluster :)

---

## Run on AKS (Azure Kubernetes Service)

1. Create a configmap with the kube config in the k8s manifest folder for MCP:
   ```bash
   oc create configmap k8smcp-kubeconfig --from-file=config=config -n k8smcp -o yaml --dry-run > /home/dudu/CloudNativeandK8s/n8n/k8s/mcp/k8s/k8smcp-kubeconfig.yaml
   ```
2. Apply the k8s manifests:
   ```bash
   oc apply -k .
   ```

[GitHub - containers/kubernetes-mcp-server: Model Context Protocol (MCP) server for Kubernetes and OpenShift](https://github.com/containers/kubernetes-mcp-server)

---

## N8N

### Containerfile

```dockerfile
FROM docker.io/n8nio/n8n:latest
USER root
RUN npm install --prefix /home/node/.n8n n8n-nodes-mcp
USER node
```

### Build the image

```bash
podman build -t n8n
podman tag b9b6f439aa6d quay.io/dkcapgemini/n8nmcp:v1
podman push quay.io/dkcapgemini/n8nmcp:v1
```

### Deploy N8N into AKS

```bash
oc apply -k . # use the n8n/k8s folder to deploy n8n into AKS
```

After this, access N8N on your public service at: `http://IP/n8n`

---

## What You Can Do

Once deployed, your AI agent can help you with:

### Kubernetes Operations
- **Monitor**: Check pod status, events, logs
- **Inspect**: Describe resources, get metrics
- **Troubleshoot**: Analyze failures, debug issues
- **List**: View all resources by type/namespace

### Helm Operations  
- **Deploy**: Install new applications
- **Update**: Upgrade existing releases
- **Rollback**: Revert problematic deployments
- **Manage**: List, uninstall, view history

### Example Commands
- "Show me all failing pods in the default namespace"
- "Get logs for the nginx pod"
- "What helm releases are running?"
- "Install nginx using helm in the web namespace"

---

## Configuration Notes

- **OpenAI API**: Required for AI agent functionality
- **MCP Endpoint**: Pre-configured to `k8smcp.k8smcp:8080/sse`
- **Database**: PostgreSQL provides workflow persistence
- **RBAC**: MCP server includes cluster admin permissions
 
 