#!/bin/bash

echo "🔧 Increasing CRC Memory Configuration"
echo "======================================="
echo ""
echo "Your current CRC is configured with 12GB RAM, but we need at least 16GB to run:"
echo "  • Konveyor (analysis platform)"
echo "  • N8N (workflow automation)"
echo "  • K8SMCP (Kubernetes MCP server)"
echo "  • System pods"
echo ""
echo "To increase CRC memory, you need to:"
echo ""
echo "1. Stop CRC:"
echo "   crc stop"
echo ""
echo "2. Increase memory to 16GB (recommended) or 20GB (comfortable):"
echo "   crc config set memory 16384  # for 16GB"
echo "   # or"
echo "   crc config set memory 20480  # for 20GB"
echo ""
echo "3. Start CRC again:"
echo "   crc start"
echo ""
echo "4. After restart, run the optimization script:"
echo "   ./optimize-all-resources.sh"
echo ""
echo "⚠️  IMPORTANT: Make sure your Mac has enough RAM!"
echo "   - For 16GB CRC: Your Mac should have at least 24GB total RAM"
echo "   - For 20GB CRC: Your Mac should have at least 32GB total RAM"
echo ""
echo "Current system memory:"
sysctl -n hw.memsize | awk '{print "Total Mac RAM: " $1/1024/1024/1024 " GB"}'
echo ""
read -p "Press Enter to continue with increasing CRC memory, or Ctrl+C to cancel..."

echo ""
echo "Stopping CRC..."
crc stop

echo ""
echo "Setting memory to 16GB..."
crc config set memory 16384

echo ""
echo "Starting CRC with new memory configuration..."
crc start

echo ""
echo "✅ CRC restarted with increased memory!"
echo ""
echo "Now run: ./optimize-all-resources.sh"