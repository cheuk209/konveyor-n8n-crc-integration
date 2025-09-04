#!/bin/bash

echo "🎯 Demo Mode Setup - Minimal Resources"
echo "======================================="
echo "Setting up just enough to demonstrate the workflow"
echo ""

# 1. Remove PostgreSQL - N8N works fine with SQLite for demos
echo "📦 Simplifying N8N (removing PostgreSQL)..."
oc scale statefulset postgres-statefulset -n n8n --replicas=0 2>/dev/null

# 2. Configure N8N for demo mode - tiny resources
echo "🔧 Configuring N8N for demo..."
oc patch deployment n8n-deployment -n n8n --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "200m", "memory": "256Mi"},
    "requests": {"cpu": "10m", "memory": "128Mi"}
  }}
]'

# 3. K8SMCP - minimal for demo
echo "🔧 Configuring K8SMCP for demo..."
oc patch deployment k8smcp -n k8smcp --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "limits": {"cpu": "100m", "memory": "128Mi"},
    "requests": {"cpu": "10m", "memory": "64Mi"}
  }}
]'

# 4. Konveyor - just enough to analyze and show reports
echo "🔧 Configuring Konveyor for demo..."
oc patch deployment tackle-hub -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "requests": {"cpu": "50m", "memory": "256Mi"},
    "limits": {"cpu": "500m", "memory": "512Mi"}
  }}
]'

oc patch deployment tackle-ui -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "requests": {"cpu": "10m", "memory": "64Mi"},
    "limits": {"cpu": "200m", "memory": "256Mi"}
  }}
]'

oc patch deployment tackle-operator -n konveyor-tackle --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {
    "requests": {"cpu": "10m", "memory": "64Mi"},
    "limits": {"cpu": "200m", "memory": "256Mi"}
  }}
]'

# 5. Start everything
echo "🚀 Starting all demo components..."
oc scale deployment n8n-deployment -n n8n --replicas=1
oc scale deployment k8smcp -n k8smcp --replicas=1

echo ""
echo "⏳ Waiting for pods to start (30 seconds)..."
sleep 30

# 6. Quick status check
echo ""
echo "📊 Demo Components Status:"
echo "=========================="
oc get pods -n n8n --no-headers | grep -v postgres
oc get pods -n k8smcp --no-headers
oc get pods -n konveyor-tackle --no-headers | grep -E "(hub|ui|operator)"

echo ""
echo "🌐 Access URLs:"
echo "=============="
echo "Konveyor: https://tackle-konveyor-tackle.apps-crc.testing"
echo "N8N:      https://n8n-n8n.apps-crc.testing" 
echo ""
echo "✅ Demo setup complete!"
echo ""
echo "Total memory: ~576Mi (Hub:256Mi + N8N:128Mi + K8SMCP:64Mi + UI:64Mi + Op:64Mi)"