#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Secure Deployment to OpenShift CRC${NC}"
echo "=================================="

# Check if .env.secrets exists
if [ ! -f .env.secrets ]; then
    echo -e "${YELLOW}⚠️  Creating .env.secrets template file...${NC}"
    cat > .env.secrets <<'EOF'
# Container Registry Credentials
export QUAY_USERNAME="your-quay-username"
export QUAY_PASSWORD="your-quay-password"

# PostgreSQL Database
export POSTGRES_USER="n8n"
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"
export POSTGRES_DB="n8n"

# N8N Credentials
export N8N_BASIC_AUTH_USER="admin"
export N8N_BASIC_AUTH_PASSWORD="$(openssl rand -base64 16)"
export N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)"

# OpenAI API (for N8N workflow)
export OPENAI_API_KEY="your-openai-api-key"
EOF
    echo -e "${RED}Please edit .env.secrets with your actual credentials before running this script again.${NC}"
    exit 1
fi

# Load secrets
source .env.secrets

# Check CRC status
echo -e "${YELLOW}🔍 Checking CRC status...${NC}"
if ! crc status | grep -q "Running"; then
    echo -e "${RED}❌ CRC is not running. Starting CRC...${NC}"
    crc start
    sleep 10
fi

# Setup oc environment
eval $(crc oc-env)

# Login as kubeadmin
echo -e "${YELLOW}🔐 Logging into CRC...${NC}"
KUBEADMIN_PASS=$(crc console --credentials | grep kubeadmin | awk '{print $NF}')
oc login -u kubeadmin -p "${KUBEADMIN_PASS}" https://api.crc.testing:6443 --insecure-skip-tls-verify=true

# Create namespaces
echo -e "${GREEN}📦 Creating namespaces...${NC}"
oc create namespace k8smcp --dry-run=client -o yaml | oc apply -f -
oc create namespace n8n --dry-run=client -o yaml | oc apply -f -

# Create image pull secrets if using private registry
if [ "$QUAY_USERNAME" != "your-quay-username" ]; then
    echo -e "${GREEN}🔑 Creating image pull secrets...${NC}"
    
    oc create secret docker-registry quay-io-dkcapgemini \
      --docker-server=quay.io \
      --docker-username="$QUAY_USERNAME" \
      --docker-password="$QUAY_PASSWORD" \
      --namespace=k8smcp --dry-run=client -o yaml | oc apply -f -
    
    oc create secret docker-registry quay-io-dkcapgemini \
      --docker-server=quay.io \
      --docker-username="$QUAY_USERNAME" \
      --docker-password="$QUAY_PASSWORD" \
      --namespace=n8n --dry-run=client -o yaml | oc apply -f -
else
    echo -e "${YELLOW}⚠️  Skipping image pull secret creation (using public images)${NC}"
fi

# Create database secrets
echo -e "${GREEN}🔐 Creating database secrets...${NC}"
oc create secret generic postgres-secrets \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=POSTGRES_DB="$POSTGRES_DB" \
  --from-literal=POSTGRES_NON_ROOT_DB="$POSTGRES_DB" \
  --namespace=n8n --dry-run=client -o yaml | oc apply -f -

# Create N8N application secrets
echo -e "${GREEN}🔐 Creating N8N application secrets...${NC}"
oc create secret generic n8n-secrets \
  --from-literal=DB_TYPE="postgresdb" \
  --from-literal=DB_POSTGRESDB_HOST="postgres-statefulset" \
  --from-literal=DB_POSTGRESDB_PORT="5432" \
  --from-literal=DB_POSTGRESDB_DATABASE="$POSTGRES_DB" \
  --from-literal=DB_POSTGRESDB_USER="$POSTGRES_USER" \
  --from-literal=DB_POSTGRESDB_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=N8N_BASIC_AUTH_USER="$N8N_BASIC_AUTH_USER" \
  --from-literal=N8N_BASIC_AUTH_PASSWORD="$N8N_BASIC_AUTH_PASSWORD" \
  --from-literal=N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
  --namespace=n8n --dry-run=client -o yaml | oc apply -f -

# Deploy MCP Server
echo -e "${GREEN}📦 Deploying MCP Server...${NC}"
cd agentic/mcp/k8s

# Apply kustomization for CRC
if [ -f kustomization-crc.yaml ]; then
    oc apply -k . --kustomize kustomization-crc.yaml
else
    oc apply -k .
fi

# Grant SCC permissions for MCP
echo -e "${YELLOW}🔧 Configuring MCP Security Context...${NC}"
oc adm policy add-scc-to-user anyuid -z k8smcp -n k8smcp
oc adm policy add-scc-to-user k8smcp-scc -z k8smcp -n k8smcp 2>/dev/null || true

# Wait for MCP deployment
echo -e "${YELLOW}⏳ Waiting for MCP Server to be ready...${NC}"
oc wait --for=condition=available --timeout=300s deployment/k8smcp -n k8smcp || {
    echo -e "${RED}MCP deployment failed. Checking logs...${NC}"
    oc logs -n k8smcp -l app=mcpk8s --tail=50
}

# Deploy N8N with PostgreSQL
echo -e "${GREEN}📦 Deploying N8N with PostgreSQL...${NC}"
cd ../../n8n/k8s

# Apply kustomization for CRC
if [ -f kustomization-crc.yaml ]; then
    oc apply -k . --kustomize kustomization-crc.yaml
else
    oc apply -k .
fi

# Grant SCC permissions for N8N and PostgreSQL
echo -e "${YELLOW}🔧 Configuring N8N Security Context...${NC}"
oc adm policy add-scc-to-user anyuid -z n8n -n n8n
oc adm policy add-scc-to-user n8n-scc -z n8n -n n8n 2>/dev/null || true
oc adm policy add-scc-to-user anyuid -z postgres -n n8n
oc adm policy add-scc-to-user n8n-scc -z postgres -n n8n 2>/dev/null || true

# Wait for PostgreSQL
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
oc wait --for=condition=ready pod -l app=postgres -n n8n --timeout=300s || {
    echo -e "${RED}PostgreSQL deployment failed. Checking logs...${NC}"
    oc logs -n n8n -l app=postgres --tail=50
}

# Wait for N8N deployment
echo -e "${YELLOW}⏳ Waiting for N8N to be ready...${NC}"
oc wait --for=condition=available --timeout=300s deployment/n8n-deployment -n n8n || {
    echo -e "${RED}N8N deployment failed. Checking logs...${NC}"
    oc logs -n n8n -l app=n8n --tail=50
}

# Get routes
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo "=================================="
echo ""
echo -e "${GREEN}📍 Access URLs:${NC}"
MCP_ROUTE=$(oc get route k8smcp -n k8smcp -o jsonpath='{.spec.host}' 2>/dev/null)
N8N_ROUTE=$(oc get route n8n -n n8n -o jsonpath='{.spec.host}' 2>/dev/null)

if [ -n "$MCP_ROUTE" ]; then
    echo -e "MCP Server: ${GREEN}https://${MCP_ROUTE}${NC}"
else
    echo -e "${YELLOW}MCP Server: Route not found, checking service...${NC}"
    oc get svc -n k8smcp
fi

if [ -n "$N8N_ROUTE" ]; then
    echo -e "N8N UI: ${GREEN}https://${N8N_ROUTE}${NC}"
    echo ""
    echo -e "${YELLOW}🔐 N8N Login Credentials:${NC}"
    echo "Username: $N8N_BASIC_AUTH_USER"
    echo "Password: $N8N_BASIC_AUTH_PASSWORD"
else
    echo -e "${YELLOW}N8N UI: Route not found, checking service...${NC}"
    oc get svc -n n8n
fi

echo ""
echo -e "${GREEN}🔧 N8N Configuration Steps:${NC}"
echo "1. Access N8N at the URL above"
echo "2. Import the K8sMCP.json workflow"
echo "3. Update MCP endpoint in workflow to: http://k8smcp-internal.k8smcp.svc.cluster.local:8080/sse"
echo "4. Configure OpenAI API credentials in N8N"
echo ""
echo -e "${GREEN}📊 Check deployment status:${NC}"
echo "  oc get pods -n k8smcp"
echo "  oc get pods -n n8n"
echo ""
echo -e "${GREEN}📋 View logs:${NC}"
echo "  oc logs -f -n k8smcp -l app=mcpk8s"
echo "  oc logs -f -n n8n -l app=n8n"
echo ""
echo -e "${YELLOW}💡 Tip: If pods are failing, check security context:${NC}"
echo "  oc describe pod <pod-name> -n <namespace>"
echo "  oc get events -n <namespace>"