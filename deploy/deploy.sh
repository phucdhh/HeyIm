#!/bin/bash
# HeyIm Deployment Script
# Deploys backend and frontend as launchd daemons

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 HeyIm Deployment Script"
echo "=========================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root for launchd operations
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should NOT be run as root${NC}"
   echo "Run without sudo, script will ask for password when needed"
   exit 1
fi

echo -e "${YELLOW}Step 1: Pre-deployment checks${NC}"
echo "----------------------------------------"

# Check if builds exist
if [ ! -f "$PROJECT_ROOT/backend/.build/release/HeyImServer" ]; then
    echo -e "${RED}✗ Backend release build not found${NC}"
    echo "Run: cd $PROJECT_ROOT/backend && swift build -c release"
    exit 1
fi
echo -e "${GREEN}✓ Backend release build found${NC}"

if [ ! -d "$PROJECT_ROOT/frontend/.next" ]; then
    echo -e "${RED}✗ Frontend build not found${NC}"
    echo "Run: cd $PROJECT_ROOT/frontend && npm run build"
    exit 1
fi
echo -e "${GREEN}✓ Frontend build found${NC}"

# Check if models exist
if [ ! -d "$PROJECT_ROOT/models/RealisticVision_v51_split-einsum" ]; then
    echo -e "${RED}✗ Models not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Models found${NC}"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"
echo -e "${GREEN}✓ Logs directory ready${NC}"

echo ""
echo -e "${YELLOW}Step 2: Stop existing dev servers${NC}"
echo "----------------------------------------"

# Kill existing dev servers
pkill -f "HeyImServer" 2>/dev/null || true
pkill -f "next dev" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Stopped existing servers${NC}"

echo ""
echo -e "${YELLOW}Step 3: Install launchd daemons${NC}"
echo "----------------------------------------"

# Copy plist files to LaunchDaemons
echo "Installing backend daemon..."
sudo cp "$SCRIPT_DIR/com.heyim.backend.plist" /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.heyim.backend.plist
sudo chmod 644 /Library/LaunchDaemons/com.heyim.backend.plist
echo -e "${GREEN}✓ Backend daemon installed${NC}"

echo "Installing frontend daemon..."
sudo cp "$SCRIPT_DIR/com.heyim.frontend.plist" /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.heyim.frontend.plist
sudo chmod 644 /Library/LaunchDaemons/com.heyim.frontend.plist
echo -e "${GREEN}✓ Frontend daemon installed${NC}"

echo ""
echo -e "${YELLOW}Step 4: Start services${NC}"
echo "----------------------------------------"

echo "Starting backend..."
sudo launchctl load /Library/LaunchDaemons/com.heyim.backend.plist
sleep 3

# Check if backend started
if pgrep -f "HeyImServer" > /dev/null; then
    echo -e "${GREEN}✓ Backend started (PID: $(pgrep -f HeyImServer))${NC}"
else
    echo -e "${RED}✗ Backend failed to start${NC}"
    echo "Check logs: tail -50 $PROJECT_ROOT/logs/backend-error.log"
    exit 1
fi

echo "Starting frontend..."
sudo launchctl load /Library/LaunchDaemons/com.heyim.frontend.plist
sleep 5

# Check if frontend started
if pgrep -f "next start" > /dev/null; then
    echo -e "${GREEN}✓ Frontend started (PID: $(pgrep -f 'next start'))${NC}"
else
    echo -e "${RED}✗ Frontend failed to start${NC}"
    echo "Check logs: tail -50 $PROJECT_ROOT/logs/frontend-error.log"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 5: Verification${NC}"
echo "----------------------------------------"

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 5

# Test backend health
echo -n "Testing backend (http://localhost:5858/health)... "
if curl -s -f http://localhost:5858/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Backend not responding on port 5858"
fi

# Test frontend
echo -n "Testing frontend (http://localhost:3000)... "
if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    echo "Frontend not responding on port 3000"
fi

echo ""
echo -e "${YELLOW}Step 6: Cloudflare Tunnel Configuration${NC}"
echo "----------------------------------------"
echo ""
echo -e "${YELLOW}Next steps to configure Cloudflare Tunnel:${NC}"
echo ""
echo "1. Backup current config:"
echo "   cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.backup"
echo ""
echo "2. Add this entry to ~/.cloudflared/config.yml ingress section:"
echo "   (before the catch-all '- service: http_status:404' line)"
echo ""
echo "  # HeyIm AI Image Generation"
echo "  - hostname: heyim.truyenthong.edu.vn"
echo "    service: http://127.0.0.1:3000"
echo "    originRequest:"
echo "      noTLSVerify: false"
echo "      connectTimeout: 120s"
echo "      http2Origin: true"
echo "      keepAliveTimeout: 90s"
echo "      keepAliveConnections: 100"
echo ""
echo "3. Create DNS record:"
echo "   cloudflared tunnel route dns aithink heyim.truyenthong.edu.vn"
echo ""
echo "4. Restart cloudflared:"
echo "   sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist"
echo "   sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist"
echo ""
echo "5. Test access:"
echo "   curl https://heyim.truyenthong.edu.vn"
echo ""

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Services Status:"
echo "  Backend:  http://localhost:5858"
echo "  Frontend: http://localhost:3000"
echo "  Public:   https://heyim.truyenthong.edu.vn (after tunnel config)"
echo ""
echo "Logs:"
echo "  Backend:  tail -f $PROJECT_ROOT/logs/backend.log"
echo "  Frontend: tail -f $PROJECT_ROOT/logs/frontend.log"
echo ""
echo "Management Commands:"
echo "  Stop all:    $SCRIPT_DIR/stop.sh"
echo "  Restart all: $SCRIPT_DIR/restart.sh"
echo "  Status:      $SCRIPT_DIR/status.sh"
echo ""
