#!/bin/bash
# Restart HeyIm services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Restarting HeyIm services..."
echo ""

# Stop services
"$SCRIPT_DIR/stop.sh"

echo ""
sleep 2

# Start services
echo "Starting backend..."
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
sleep 3

echo "Starting frontend..."
sudo launchctl load /Library/LaunchDaemons/com.heyim.frontend.plist
sleep 3

echo ""
echo "✓ Services restarted"
echo ""

# Show status
"$SCRIPT_DIR/status.sh"
