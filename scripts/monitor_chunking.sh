#!/bin/bash
# Monitor UNet chunking progress with disk space tracking

LOG_FILE="/tmp/chunk_retry.log"
OUTPUT_DIR="/Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked"

echo "🔍 UNet Chunking Monitor"
echo "========================"
echo "Started: $(date '+%H:%M:%S')"
echo "Log: $LOG_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

for i in {1..30}; do
    TIMESTAMP=$(date '+%H:%M:%S')
    
    # Check if process is running
    if ps aux | grep "torch2coreml" | grep -v grep > /dev/null; then
        STATUS="✅ Running"
    else
        STATUS="⚠️ Stopped"
    fi
    
    # Get last meaningful log line
    LAST_LINE=$(tail -5 "$LOG_FILE" 2>/dev/null | grep -E "INFO:|Converting|Loading|ERROR" | tail -1 | sed 's/^[^:]*://' | cut -c1-80)
    
    # Check output files
    if [ -d "$OUTPUT_DIR" ]; then
        FILE_COUNT=$(find "$OUTPUT_DIR" -name "*.mlpackage" 2>/dev/null | wc -l | tr -d ' ')
        DIR_SIZE=$(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)
    else
        FILE_COUNT="0"
        DIR_SIZE="0B"
    fi
    
    # Disk space
    AVAIL=$(df -h / | tail -1 | awk '{print $4}')
    
    echo "[$i/30] $TIMESTAMP | $STATUS | Files: $FILE_COUNT | Size: $DIR_SIZE | Free: $AVAIL"
    
    if [ "$STATUS" = "⚠️ Stopped" ]; then
        echo ""
        echo "Process stopped. Checking for completion..."
        if [ -f "$OUTPUT_DIR/UnetChunk1.mlpackage/Manifest.json" ] && \
           [ -f "$OUTPUT_DIR/UnetChunk2.mlpackage/Manifest.json" ]; then
            echo "✅ CHUNKING COMPLETE!"
            break
        else
            echo "❌ Process failed or incomplete. Check $LOG_FILE"
            tail -20 "$LOG_FILE" | grep -E "ERROR|Error|Failed|Traceback"
            break
        fi
    fi
    
    sleep 60  # Check every minute
done

echo ""
echo "Final status:"
ls -lh "$OUTPUT_DIR" 2>/dev/null || echo "Output directory not found"
