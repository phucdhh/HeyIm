#!/bin/bash
# Stop HeyIm services

set -e

echo "🛑 Stopping HeyIm services..."

# Stop backend
if sudo launchctl list | grep -q "com.heyim.backend"; then
    echo "Stopping backend..."
    sudo launchctl unload /Library/LaunchDaemons/com.heyim.backend.plist
    echo "✓ Backend stopped"
else
    echo "Backend not running"
fi

# Stop frontend
if sudo launchctl list | grep -q "com.heyim.frontend"; then
    echo "Stopping frontend..."
    sudo launchctl unload /Library/LaunchDaemons/com.heyim.frontend.plist
    echo "✓ Frontend stopped"
else
    echo "Frontend not running"
fi

# Kill any remaining processes
pkill -f "HeyImServer" 2>/dev/null || true
pkill -f "next start" 2>/dev/null || true

echo ""
echo "✓ All services stopped"
