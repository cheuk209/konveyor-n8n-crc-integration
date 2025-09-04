#!/bin/bash

echo "🔧 Ultra-Minimal Setup for 12GB CRC"
echo "===================================="
echo ""
echo "This script configures absolute minimum resources for all components."
echo "Performance will be limited but all services should run."
echo ""

# 1. Delete PostgreSQL StatefulSet and use SQLite for N8N
echo "🗑️  Removing PostgreSQL to save memory (N8N will use SQLite)..."
oc delete statefulset postgres-statefulset -n n8n --ignore-not-found=true
oc delete pvc postgres-storage-postgres-statefulset-0 -n n8n --ignore-not-found=true
oc delete service postgres-service -n n8n --ignore-not-found=true

# 2. Patch N8N to use SQLite with minimal resources
echo "📝 Configuring N8N to use SQLite..."
oc patch deployment n8n-deployment -n n8n --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/env", "value": [
    {"name": "DB_TYPE", "value": "sqlite"},
    {"name": "N8N_BASIC_AUTH_ACTIVE", "value": "true"},
    {"name": "N8N_BASIC_AUTH_USER", "value": "admin"},
    {"name": "N8N_BASIC_AUTH_PASSWORD", "value": "password"},
    {"name": "N8N_HOST", "value": "n8n.n8n.svc.cluster.local"},
    {"name": "WEBHOOK_URL", "value": "https://n8n-n8n.apps-crc.testing/"}
  ]},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "200m", "memory": "256Mi"},
    "requests": {"cpu": "25m", "memory": "128Mi"}
  }}
]'

# 3. Ultra-minimal K8SMCP
echo "📉 Setting ultra-minimal K8SMCP resources..."
oc patch deployment k8smcp -n k8smcp --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "100m", "memory": "128Mi"},
    "requests": {"cpu": "25m", "memory": "64Mi"}
  }}
]'

# 4. Minimal Konveyor components
echo "📉 Setting minimal Konveyor resources..."

# Hub
oc patch deployment tackle-hub -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "200m", "memory": "384Mi"},
    "requests": {"cpu": "50m", "memory": "256Mi"}
  }}
]'

# UI
oc patch deployment tackle-ui -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "100m", "memory": "192Mi"},
    "requests": {"cpu": "25m", "memory": "96Mi"}
  }}
]'

# Operator
oc patch deployment tackle-operator -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "100m", "memory": "192Mi"},
    "requests": {"cpu": "25m", "memory": "96Mi"}
  }}
]'

# 5. Scale everything to 1
echo "🚀 Starting all services..."
oc scale deployment n8n-deployment -n n8n --replicas=1
oc scale deployment k8smcp -n k8smcp --replicas=1

echo "⏳ Waiting for pods to restart..."
sleep 30

# 6. Check status
echo ""
echo "📊 Current Status:"
echo "=================="
echo ""
echo "N8N Pods:"
oc get pods -n n8n
echo ""
echo "K8SMCP Pods:"
oc get pods -n k8smcp
echo ""
echo "Konveyor Pods:"
oc get pods -n konveyor-tackle
echo ""
echo "Node Resources:"
oc describe node crc | grep -A5 "Allocated resources"
echo ""
echo "✅ Ultra-minimal setup complete!"
echo ""
echo "📝 Configuration Summary:"
echo "  • N8N: 128Mi (using SQLite, no PostgreSQL)"
echo "  • K8SMCP: 64Mi"
echo "  • Konveyor Hub: 256Mi"
echo "  • Konveyor UI: 96Mi"
echo "  • Konveyor Operator: 96Mi"
echo "  • Total: ~640Mi (should easily fit in 12GB CRC)"
echo ""
echo "⚠️  Note: Performance will be limited with these settings."
echo "   Consider running components selectively if you experience issues."