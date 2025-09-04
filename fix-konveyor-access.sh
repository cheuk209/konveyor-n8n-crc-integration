#!/bin/bash

echo "🔧 Fixing Konveyor Access"
echo "========================"

CRC_IP="192.168.126.11"
KONVEYOR_HOST="tackle-konveyor-tackle.apps-crc.testing"

echo "CRC Internal IP: $CRC_IP"
echo "Konveyor Route: $KONVEYOR_HOST"
echo ""

# Option 1: Add to /etc/hosts (requires sudo)
echo "Option 1: Fix DNS by adding to /etc/hosts"
echo "Run this command:"
echo "echo '$CRC_IP $KONVEYOR_HOST' | sudo tee -a /etc/hosts"
echo ""

# Option 2: Start port forwarding
echo "Option 2: Using port forwarding (RECOMMENDED)"
echo "Starting port forward..."

# Kill any existing port forwards
pkill -f "port-forward.*tackle-ui" 2>/dev/null

# Start fresh port forward
oc port-forward -n konveyor-tackle svc/tackle-ui 8081:8080 > /tmp/konveyor-pf.log 2>&1 &
PF_PID=$!

sleep 3

# Test if it's working
if curl -s http://localhost:8081 > /dev/null; then
    echo "✅ Port forwarding active!"
    echo "🌐 Access Konveyor at: http://localhost:8081"
    echo "👤 Login: admin / Passw0rd!"
    echo ""
    echo "Port forward process: $PF_PID"
    echo "To stop: kill $PF_PID"
else
    echo "❌ Port forwarding failed"
    echo "Check logs: tail /tmp/konveyor-pf.log"
fi

echo ""
echo "Option 3: Direct IP access (if DNS works)"
echo "Try: https://$CRC_IP (may need certificate bypass)"
echo ""

# Check service status
echo "📊 Service Status:"
oc get pods -n konveyor-tackle -l app.kubernetes.io/name=tackle-ui --no-headers | head -1