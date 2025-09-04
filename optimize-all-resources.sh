#!/bin/bash

# Optimize all components for minimal CRC deployment
echo "🔧 Optimizing resource usage for CRC..."

# 1. Reduce N8N resources
echo "📉 Reducing N8N resources..."
oc patch deployment n8n-deployment -n n8n --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "250m", "memory": "384Mi"},
    "requests": {"cpu": "50m", "memory": "256Mi"}
  }}
]'

# 2. Add resources to K8SMCP
echo "📉 Setting K8SMCP resources..."
oc patch deployment k8smcp -n k8smcp --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "200m", "memory": "256Mi"},
    "requests": {"cpu": "50m", "memory": "128Mi"}
  }}
]'

# 3. Reduce PostgreSQL resources
echo "📉 Reducing PostgreSQL resources..."
oc patch statefulset postgres-statefulset -n n8n --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "200m", "memory": "256Mi"},
    "requests": {"cpu": "50m", "memory": "128Mi"}
  }}
]'

# 4. Force update Konveyor hub deployment
echo "📉 Patching Konveyor hub resources..."
oc patch deployment tackle-hub -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "384Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "512Mi"}
]'

# 5. Patch Konveyor UI
echo "📉 Patching Konveyor UI resources..."
oc patch deployment tackle-ui -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "128Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"}
]'

# 6. Patch Konveyor operator
echo "📉 Patching Konveyor operator resources..."
oc patch deployment tackle-operator -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/memory", "value": "128Mi"},
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/memory", "value": "256Mi"}
]'

echo "⏳ Waiting for pods to restart..."
sleep 10

# Start all services
echo "🚀 Starting all services..."
oc scale deployment n8n-deployment -n n8n --replicas=1
oc scale deployment k8smcp -n k8smcp --replicas=1

echo "📊 Checking pod status..."
sleep 20

echo ""
echo "=== N8N Status ==="
oc get pods -n n8n

echo ""
echo "=== K8SMCP Status ==="
oc get pods -n k8smcp

echo ""
echo "=== Konveyor Status ==="
oc get pods -n konveyor-tackle

echo ""
echo "=== Node Resource Usage ==="
oc describe node crc | grep -A5 "Allocated resources"

echo ""
echo "✅ Resource optimization complete!"
echo ""
echo "📝 Total expected memory usage:"
echo "  - Konveyor: ~768Mi (hub=384Mi, ui=128Mi, operator=128Mi, catalog=50Mi)"
echo "  - N8N: 256Mi + PostgreSQL: 128Mi"
echo "  - K8SMCP: 128Mi"
echo "  - Total: ~1.3Gi (should fit in CRC with 12GB)"