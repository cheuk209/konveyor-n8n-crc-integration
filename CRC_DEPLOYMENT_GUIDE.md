# 🚀 OpenShift CRC Deployment Guide

## Overview
This guide provides comprehensive instructions for deploying the Konveyor N8N Integration project on Red Hat OpenShift CRC (CodeReady Containers) in a secure, production-ready manner.

## Architecture Components

### 1. MCP Server (Model Context Protocol)
- Exposes Kubernetes API via MCP for AI agents
- Runs with ServiceAccount-based authentication
- Secured with OpenShift Security Context Constraints

### 2. N8N Workflow Automation
- Provides workflow automation with AI capabilities
- Integrated with PostgreSQL for persistence
- Protected with authentication and encryption

### 3. PostgreSQL Database
- Stateful storage for N8N workflows
- Runs as non-root with security constraints
- Persistent volume for data retention

## Prerequisites

### System Requirements
- **RAM**: Minimum 16GB (CRC requires 9GB)
- **CPU**: 4+ cores
- **Storage**: 35GB+ free space
- **OS**: macOS, Linux, or Windows with WSL2

### Software Requirements
```bash
# Install CRC
crc setup
crc start --cpus 4 --memory 12288

# Install OpenShift CLI
# macOS
brew install openshift-cli

# Linux
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar xvf openshift-client-linux.tar.gz
sudo mv oc kubectl /usr/local/bin/
```

## Quick Start

### 1. Prepare Secrets
```bash
# Copy template
cp .env.secrets.template .env.secrets

# Edit with your credentials
nano .env.secrets
```

### 2. Run Deployment
```bash
# Make script executable
chmod +x deploy-secure-crc.sh

# Deploy everything
./deploy-secure-crc.sh
```

### 3. Access Applications
After deployment, you'll receive URLs like:
- MCP Server: `https://k8smcp-k8smcp.apps-crc.testing`
- N8N UI: `https://n8n-n8n.apps-crc.testing`

## Detailed Deployment Steps

### Step 1: CRC Configuration
```bash
# Start CRC with adequate resources
crc start --cpus 4 --memory 12288 --disk-size 50

# Get credentials
crc console --credentials

# Setup environment
eval $(crc oc-env)
```

### Step 2: Manual Secret Creation
```bash
# Source your secrets
source .env.secrets

# Create namespaces
oc create namespace k8smcp
oc create namespace n8n

# Create image pull secret (if using private registry)
oc create secret docker-registry quay-io-dkcapgemini \
  --docker-server=quay.io \
  --docker-username="$QUAY_USERNAME" \
  --docker-password="$QUAY_PASSWORD" \
  -n k8smcp

# Create PostgreSQL secrets
oc create secret generic postgres-secrets \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_DB="$POSTGRES_DB" \
  -n n8n

# Create N8N secrets
oc create secret generic n8n-secrets \
  --from-literal=DB_POSTGRESDB_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=N8N_BASIC_AUTH_USER="$N8N_BASIC_AUTH_USER" \
  --from-literal=N8N_BASIC_AUTH_PASSWORD="$N8N_BASIC_AUTH_PASSWORD" \
  --from-literal=N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
  -n n8n
```

### Step 3: Deploy MCP Server
```bash
cd agentic/mcp/k8s
oc apply -k . --kustomize kustomization-crc.yaml

# Grant security permissions
oc adm policy add-scc-to-user anyuid -z k8smcp -n k8smcp

# Verify deployment
oc get pods -n k8smcp
oc logs -f -n k8smcp -l app=mcpk8s
```

### Step 4: Deploy N8N with PostgreSQL
```bash
cd ../../n8n/k8s
oc apply -k . --kustomize kustomization-crc.yaml

# Grant security permissions
oc adm policy add-scc-to-user anyuid -z n8n -n n8n
oc adm policy add-scc-to-user anyuid -z postgres -n n8n

# Verify deployment
oc get pods -n n8n
oc logs -f -n n8n -l app=n8n
```

## Security Configuration

### OpenShift Security Context Constraints (SCC)

#### MCP Server SCC
- **Location**: `agentic/mcp/k8s/k8smcp-scc.yaml`
- Runs as non-root user
- No privilege escalation
- Restricted capabilities

#### N8N SCC
- **Location**: `agentic/n8n/k8s/n8n-scc.yaml`
- Enforces non-root execution
- Drops all unnecessary capabilities
- Restricted volume types

### Network Security

#### Routes Configuration
- TLS termination at edge
- Automatic HTTPS redirect
- Cluster-internal communication over HTTP

#### Service Communication
- MCP internal endpoint: `http://k8smcp-internal.k8smcp.svc.cluster.local:8080`
- PostgreSQL: `postgres-statefulset.n8n.svc.cluster.local:5432`
- N8N: `n8n.n8n.svc.cluster.local:5678`

## N8N Workflow Configuration

### 1. Import Workflow
1. Access N8N UI at provided URL
2. Login with credentials from deployment output
3. Import `K8sMCP.json` or `update-n8n-workflow-crc.json`

### 2. Configure MCP Connection
Update the MCP Client node:
```json
{
  "url": "http://k8smcp-internal.k8smcp.svc.cluster.local:8080/sse",
  "method": "SSE"
}
```

### 3. Configure OpenAI
Add your OpenAI API key in N8N credentials:
1. Settings → Credentials → New
2. Select "OpenAI API"
3. Enter your API key

## Troubleshooting

### Common Issues

#### 1. Pods in CrashLoopBackOff
```bash
# Check pod details
oc describe pod <pod-name> -n <namespace>

# Check security context issues
oc get events -n <namespace> | grep -i security

# Fix permissions
oc adm policy add-scc-to-user anyuid -z <serviceaccount> -n <namespace>
```

#### 2. Route Not Accessible
```bash
# Check route status
oc get routes -n <namespace>

# Check CRC IP
crc ip

# Add to hosts file
echo "$(crc ip) k8smcp-k8smcp.apps-crc.testing n8n-n8n.apps-crc.testing" | sudo tee -a /etc/hosts
```

#### 3. Database Connection Issues
```bash
# Check PostgreSQL pod
oc logs -n n8n postgres-statefulset-0

# Verify secrets
oc get secrets -n n8n
oc describe secret postgres-secrets -n n8n
```

#### 4. Image Pull Errors
```bash
# For public images, remove imagePullSecrets from deployments
oc edit deployment k8smcp -n k8smcp
# Remove the imagePullSecrets section

# Or create proper pull secret
oc create secret docker-registry <secret-name> \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password>
```

### Debug Commands
```bash
# View all resources
oc get all -n k8smcp
oc get all -n n8n

# Check pod logs
oc logs -f <pod-name> -n <namespace>

# Execute into pod
oc exec -it <pod-name> -n <namespace> -- /bin/sh

# Check resource usage
oc top pods -n <namespace>

# View security context
oc get pod <pod-name> -n <namespace> -o yaml | grep -A 10 securityContext
```

## Production Considerations

### 1. Resource Limits
Update resource limits in deployment files:
```yaml
resources:
  limits:
    memory: "2Gi"
    cpu: "1000m"
  requests:
    memory: "512Mi"
    cpu: "250m"
```

### 2. Backup Strategy
```bash
# Backup PostgreSQL
oc exec -n n8n postgres-statefulset-0 -- pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup.sql

# Backup N8N workflows
oc cp n8n/<n8n-pod>:/home/node/.n8n ./n8n-backup
```

### 3. Monitoring
```bash
# Enable metrics
oc label namespace n8n openshift.io/cluster-monitoring="true"

# View metrics
oc get --raw /apis/metrics.k8s.io/v1beta1/namespaces/n8n/pods
```

### 4. High Availability
For production:
- Increase replica count
- Configure PostgreSQL replication
- Use external load balancer
- Implement backup/restore procedures

## Clean Up

### Remove Deployment
```bash
# Delete applications
oc delete namespace k8smcp
oc delete namespace n8n

# Remove SCCs
oc delete scc k8smcp-scc
oc delete scc n8n-scc

# Stop CRC
crc stop

# Delete CRC (optional)
crc delete
```

## Support and Resources

### Documentation
- [OpenShift CRC Documentation](https://crc.dev/crc/)
- [N8N Documentation](https://docs.n8n.io/)
- [MCP Server Documentation](https://github.com/containers/kubernetes-mcp-server)

### Logs Location
- MCP Server: `oc logs -n k8smcp -l app=mcpk8s`
- N8N: `oc logs -n n8n -l app=n8n`
- PostgreSQL: `oc logs -n n8n -l app=postgres`

### Getting Help
1. Check pod events: `oc describe pod <pod> -n <namespace>`
2. Review security context: `oc get pod <pod> -n <namespace> -o yaml`
3. Examine route status: `oc describe route <route> -n <namespace>`
4. Verify service endpoints: `oc get endpoints -n <namespace>`

## Version Information
- OpenShift CRC: 4.x
- PostgreSQL: 14-alpine
- N8N: Latest with MCP nodes
- MCP Server: 0.0.49

## License
This deployment guide is part of the Konveyor N8N Integration project.