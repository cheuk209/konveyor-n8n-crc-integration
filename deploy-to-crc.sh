#!/bin/bash

set -e

echo "🚀 Deploying to OpenShift CRC..."

# Check CRC status
if ! crc status | grep -q "Running"; then
    echo "❌ CRC is not running. Please start with: crc start"
    exit 1
fi

# Setup oc environment
eval $(crc oc-env)

# Login as kubeadmin
echo "🔐 Logging into CRC..."
oc login -u kubeadmin -p $(crc console --credentials | grep kubeadmin | awk '{print $NF}') https://api.crc.testing:6443 --insecure-skip-tls-verify=true

# Deploy MCP Server
echo "📦 Deploying MCP Server..."
cd agentic/mcp/k8s
oc apply -k . --kustomize kustomization-crc.yaml || oc apply -f k8smcp-namespace.yaml && oc apply -k . --kustomize kustomization-crc.yaml

# Wait for MCP deployment
echo "⏳ Waiting for MCP Server to be ready..."
oc wait --for=condition=available --timeout=300s deployment/k8smcp -n k8smcp

# Deploy N8N with PostgreSQL
echo "📦 Deploying N8N..."
cd ../../n8n/k8s
oc apply -k . --kustomize kustomization-crc.yaml || oc apply -f n8n-namespace.yaml && oc apply -k . --kustomize kustomization-crc.yaml

# Wait for N8N deployment
echo "⏳ Waiting for N8N to be ready..."
oc wait --for=condition=available --timeout=300s deployment/n8n -n n8n

# Get routes
echo "✅ Deployment complete!"
echo ""
echo "📍 Access URLs:"
echo "MCP Server: https://$(oc get route k8smcp -n k8smcp -o jsonpath='{.spec.host}')"
echo "N8N UI: https://$(oc get route n8n -n n8n -o jsonpath='{.spec.host}')"
echo ""
echo "🔧 N8N Configuration:"
echo "- Import K8sMCP.json workflow"
echo "- Update MCP endpoint to: http://k8smcp-internal.k8smcp.svc.cluster.local:8080/sse"
echo "- Configure OpenAI API credentials"