#!/bin/bash

echo "🌐 Fixing CRC Networking Access"
echo "==============================="

REAL_CRC_IP="192.168.126.11"
echo "Real CRC IP: $REAL_CRC_IP"
echo "CRC command returns: $(crc ip)"
echo ""

echo "Adding correct hosts entries..."
echo "You'll be prompted for your Mac admin password."
echo ""

# Add all the necessary CRC routes to hosts file
sudo sh -c "cat >> /etc/hosts << EOF

# CRC Routes - Added $(date)
$REAL_CRC_IP api.crc.testing
$REAL_CRC_IP oauth-openshift.apps-crc.testing
$REAL_CRC_IP console-openshift-console.apps-crc.testing
$REAL_CRC_IP tackle-konveyor-tackle.apps-crc.testing
$REAL_CRC_IP n8n-n8n.apps-crc.testing
$REAL_CRC_IP k8smcp-k8smcp.apps-crc.testing
EOF"

echo "✅ Hosts entries added!"
echo ""
echo "🌐 Now you can access:"
echo "• Konveyor: https://tackle-konveyor-tackle.apps-crc.testing"
echo "• N8N: https://n8n-n8n.apps-crc.testing"
echo "• Console: https://console-openshift-console.apps-crc.testing"
echo ""
echo "🔑 Konveyor Login: admin / Passw0rd!"
echo "🔑 Console Login: kubeadmin / M6VgT-QgQTI-tXMBf-ydpzn"
echo ""

# Test access
echo "🧪 Testing access..."
if curl -k -s -o /dev/null -w "%{http_code}" https://console-openshift-console.apps-crc.testing | grep -q "200\|302"; then
    echo "✅ Console accessible"
else
    echo "❌ Console not accessible"
fi

if curl -k -s -o /dev/null -w "%{http_code}" https://tackle-konveyor-tackle.apps-crc.testing | grep -q "200\|302"; then
    echo "✅ Konveyor accessible"
else
    echo "❌ Konveyor not accessible (UI pod may be down)"
fi