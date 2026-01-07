#!/bin/bash
# Server management script

BACKEND_DIR="/Users/mac/HeyIm/backend"
LOG_FILE="$BACKEND_DIR/server.log"
PID_FILE="$BACKEND_DIR/server.pid"

cd "$BACKEND_DIR" || exit 1

# Kill existing server
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    kill -9 "$OLD_PID" 2>/dev/null
    rm "$PID_FILE"
fi

# Kill by name just in case
pkill -9 HeyImServer 2>/dev/null

# Clear log
> "$LOG_FILE"

echo "Starting server..."
.build/debug/HeyImServer > "$LOG_FILE" 2>&1 &
NEW_PID=$!
echo $NEW_PID > "$PID_FILE"

sleep 2

if ps -p $NEW_PID > /dev/null; then
    echo "✓ Server started (PID: $NEW_PID)"
    echo "Log: tail -f $LOG_FILE"
else
    echo "❌ Server failed to start"
    exit 1
fi
