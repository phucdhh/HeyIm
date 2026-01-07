#!/bin/bash
# Check status of HeyIm services

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📊 HeyIm Services Status"
echo "========================"
echo ""

# Check backend
echo -n "Backend (port 5858): "
if pgrep -f "HeyImServer" > /dev/null; then
    PID=$(pgrep -f "HeyImServer")
    echo -e "${GREEN}✓ Running (PID: $PID)${NC}"
    
    # Test health endpoint
    if curl -s -f http://localhost:5858/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Health check OK${NC}"
    else
        echo -e "  ${RED}✗ Health check FAILED${NC}"
    fi
else
    echo -e "${RED}✗ Not running${NC}"
fi

echo ""

# Check frontend
echo -n "Frontend (port 3000): "
if pgrep -f "next start" > /dev/null; then
    PID=$(pgrep -f "next start")
    echo -e "${GREEN}✓ Running (PID: $PID)${NC}"
    
    # Test frontend
    if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ HTTP check OK${NC}"
    else
        echo -e "  ${RED}✗ HTTP check FAILED${NC}"
    fi
else
    echo -e "${RED}✗ Not running${NC}"
fi

echo ""
echo "LaunchD Status:"
echo "---------------"
sudo launchctl list | grep "heyim" || echo "No HeyIm services in launchctl"

echo ""
echo "Recent Logs:"
echo "------------"
echo "Backend (last 5 lines):"
tail -5 /Users/mac/HeyIm/logs/backend.log 2>/dev/null || echo "No logs yet"

echo ""
echo "Frontend (last 5 lines):"
tail -5 /Users/mac/HeyIm/logs/frontend.log 2>/dev/null || echo "No logs yet"

echo ""
echo "System Resources:"
echo "-----------------"
echo "Memory usage:"
ps aux | grep -E "(HeyImServer|next start)" | grep -v grep | awk '{print $11 ": " $4"% MEM, " $3"% CPU"}'

echo ""
echo "Disk space:"
df -h /Users/mac/HeyIm | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'

echo ""
