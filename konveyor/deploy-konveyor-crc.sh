#!/bin/bash

# Deploy Konveyor on CRC
# This script deploys Konveyor operator and creates a minimal Tackle instance optimized for CRC

set -e

echo "🚀 Deploying Konveyor on CRC..."

# Check if CRC is running
if ! crc status | grep -q "OpenShift.*Running"; then
    echo "❌ CRC is not running. Please start CRC first: crc start"
    exit 1
fi

# Set OpenShift context
eval $(crc oc-env)

# Check if logged in
if ! oc whoami &>/dev/null; then
    echo "❌ Not logged in to OpenShift. Please login first: oc login -u kubeadmin"
    exit 1
fi

echo "✅ Connected to CRC cluster"

# Clean up any existing Konveyor deployment
echo "🧹 Cleaning up any existing Konveyor deployment..."
oc delete namespace konveyor-tackle --ignore-not-found=true --wait=false
oc delete catalogsource konveyor -n openshift-marketplace --ignore-not-found=true

# Wait for namespace deletion
echo "⏳ Waiting for namespace cleanup..."
while oc get namespace konveyor-tackle &>/dev/null; do
    sleep 5
done

# Deploy base resources (namespace, catalog, operator)
echo "📦 Installing Konveyor operator..."
oc apply -k base/

# Wait for operator to be ready
echo "⏳ Waiting for operator catalog to be ready..."
sleep 30

# Check if catalog pod is running
while ! oc get pods -n openshift-marketplace | grep konveyor | grep -q Running; do
    echo "Waiting for catalog pod..."
    sleep 10
done

echo "✅ Catalog source is ready"

# Wait for operator to be installed
echo "⏳ Waiting for operator installation..."
sleep 60

# Check operator status
if oc get csv -n konveyor-tackle | grep -q konveyor; then
    echo "✅ Konveyor operator installed successfully"
else
    echo "⚠️  Operator not yet ready, waiting..."
    sleep 30
fi

# Deploy Tackle CR with CRC optimizations
echo "🔧 Creating Tackle instance with CRC optimizations..."
oc apply -f overlays/crc/tackle-cr.yaml

# Wait for deployment
echo "⏳ Waiting for Tackle deployment (this may take several minutes)..."
sleep 30

# Monitor deployment progress
echo "📊 Deployment status:"
oc get pods -n konveyor-tackle -w &
WATCH_PID=$!

# Wait for user to see progress then continue
sleep 60
kill $WATCH_PID 2>/dev/null || true

# Get route information
echo ""
echo "🎉 Konveyor deployment initiated!"
echo ""
echo "📌 Access Information:"
echo "-------------------"

# Wait for route to be created
sleep 30
ROUTE=$(oc get route -n konveyor-tackle tackle --no-headers -o custom-columns=HOST:.spec.host 2>/dev/null || echo "Route not yet available")

if [ "$ROUTE" != "Route not yet available" ]; then
    echo "🌐 Konveyor UI: https://$ROUTE"
    echo "👤 Default credentials: admin / Passw0rd!"
else
    echo "⚠️  Route not yet created. Check later with:"
    echo "   oc get route -n konveyor-tackle"
fi

echo ""
echo "📋 Check deployment status:"
echo "   oc get pods -n konveyor-tackle"
echo "   oc get tackle -n konveyor-tackle"
echo ""
echo "🔍 View logs:"
echo "   oc logs -n konveyor-tackle -l app.kubernetes.io/name=tackle-operator"
echo ""
echo "✅ Deployment script completed!"