#!/bin/bash

echo "🔧 Stable Konveyor Access Setup"
echo "==============================="

# Get the current UI pod IP
UI_POD_IP=$(oc get pods -n konveyor-tackle -l app.kubernetes.io/name=tackle-ui -o jsonpath='{.items[0].status.podIP}' 2>/dev/null)
CRC_IP="192.168.126.11"

echo "UI Pod IP: $UI_POD_IP"
echo "CRC Node IP: $CRC_IP"
echo ""

if [ -n "$UI_POD_IP" ]; then
    echo "✅ Testing direct pod access..."
    if curl -s -o /dev/null -w "%{http_code}" http://$UI_POD_IP:8080 | grep -q "200\|302"; then
        echo "✅ Pod responding!"
        echo ""
        echo "🌐 WORKING ACCESS METHODS:"
        echo "=========================="
        echo ""
        echo "Method 1: Port Forward (Recommended)"
        echo "Command: oc port-forward -n konveyor-tackle pod/\$(oc get pods -n konveyor-tackle -l app.kubernetes.io/name=tackle-ui -o name | cut -d'/' -f2) 8081:8080"
        
        # Start reliable port forward
        POD_NAME=$(oc get pods -n konveyor-tackle -l app.kubernetes.io/name=tackle-ui -o name | cut -d'/' -f2)
        echo "Starting port forward to pod: $POD_NAME"
        
        # Kill existing
        pkill -f "port-forward.*$POD_NAME" 2>/dev/null
        
        # Start new port forward directly to pod
        oc port-forward -n konveyor-tackle pod/$POD_NAME 8081:8080 > /tmp/stable-pf.log 2>&1 &
        PF_PID=$!
        
        sleep 3
        if curl -s http://localhost:8081 > /dev/null; then
            echo "✅ Port forward working: http://localhost:8081"
            echo "Process ID: $PF_PID"
        else
            echo "❌ Port forward failed, trying NodePort..."
        fi
        
        echo ""
        echo "Method 2: NodePort Access"
        echo "URL: http://$CRC_IP:30080"
        echo ""
        
        echo "Method 3: Add to /etc/hosts (permanent fix)"
        echo "sudo sh -c 'echo \"$CRC_IP tackle-konveyor-tackle.apps-crc.testing\" >> /etc/hosts'"
        echo "Then use: https://tackle-konveyor-tackle.apps-crc.testing"
        
    else
        echo "❌ Pod not responding"
    fi
else
    echo "❌ No UI pod found"
fi

echo ""
echo "📊 Current Status:"
oc get pods -n konveyor-tackle -l app.kubernetes.io/name=tackle-ui --no-headers
echo ""
echo "🔑 Login credentials: admin / Passw0rd!"