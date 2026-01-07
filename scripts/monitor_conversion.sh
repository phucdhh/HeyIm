#!/bin/bash
# Monitor Core ML conversion progress every 5 minutes

LOG_FILE="/tmp/coreml_juggernaut.log"
OUTPUT_DIR="/Users/mac/HeyIm/models/Juggernaut_XL_v9_split-einsum"
MONITOR_LOG="/tmp/conversion_monitor.log"

echo "🔍 Core ML Conversion Monitor" > "$MONITOR_LOG"
echo "Started: $(date '+%H:%M:%S')" >> "$MONITOR_LOG"
echo "======================================" >> "$MONITOR_LOG"
echo "" >> "$MONITOR_LOG"

while true; do
    TIMESTAMP=$(date '+%H:%M:%S')
    
    # Check if process is still running
    if ps aux | grep "python.*torch2coreml" | grep -v grep > /dev/null; then
        echo "[$TIMESTAMP] ✅ Conversion process running" >> "$MONITOR_LOG"
        
        # Get last log line
        LAST_LINE=$(tail -1 "$LOG_FILE" 2>/dev/null | grep -o "INFO:.*" || echo "Converting...")
        echo "[$TIMESTAMP] Status: $LAST_LINE" >> "$MONITOR_LOG"
        
        # Count converted models
        MODEL_COUNT=$(ls -1 "$OUTPUT_DIR"/*.mlpackage 2>/dev/null | wc -l | tr -d ' ')
        echo "[$TIMESTAMP] Models completed: $MODEL_COUNT/4" >> "$MONITOR_LOG"
        
        # Show directory size
        DIR_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1 || echo "0")
        echo "[$TIMESTAMP] Output size: $DIR_SIZE" >> "$MONITOR_LOG"
        
        echo "" >> "$MONITOR_LOG"
        
        # Sleep 5 minutes
        sleep 300
    else
        echo "[$TIMESTAMP] ⚠️ Conversion process stopped" >> "$MONITOR_LOG"
        
        # Check if completed successfully
        if [ -f "$OUTPUT_DIR/vocab.json" ]; then
            echo "[$TIMESTAMP] ✅ CONVERSION COMPLETE!" >> "$MONITOR_LOG"
        else
            echo "[$TIMESTAMP] ❌ Conversion may have failed - check $LOG_FILE" >> "$MONITOR_LOG"
        fi
        
        break
    fi
done

echo "" >> "$MONITOR_LOG"
echo "Monitor stopped: $(date '+%H:%M:%S')" >> "$MONITOR_LOG"
