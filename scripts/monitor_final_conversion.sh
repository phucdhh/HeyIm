#!/bin/bash

echo "=== Monitoring Chunked UNet Conversion ==="
echo "Started: $(date)"
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    clear
    echo "=== Conversion Status at $(date +%H:%M:%S) ==="
    echo ""
    
    # Check process
    if ps aux | grep "python.*torch2coreml.*chunk-unet" | grep -v grep > /dev/null; then
        echo "✅ Process: RUNNING"
        ps aux | grep "python.*torch2coreml.*chunk-unet" | grep -v grep | awk '{printf "   CPU: %.1f%% | Memory: %s\n", $3, $6}'
    else
        echo "❌ Process: STOPPED"
        break
    fi
    
    echo ""
    
    # Check disk space
    echo "💾 Disk Space:"
    df -h / | tail -1 | awk '{printf "   Available: %s / %s (Used: %s)\n", $4, $2, $5}'
    
    echo ""
    
    # Check output files
    echo "📁 Output Files:"
    if [ -d "/Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked" ]; then
        file_count=$(find /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked -type f 2>/dev/null | wc -l | tr -d ' ')
        dir_size=$(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked 2>/dev/null | awk '{print $1}')
        echo "   Files: $file_count | Size: $dir_size"
        
        # List mlpackage directories
        if ls /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/*.mlpackage 2>/dev/null | grep -q .; then
            echo "   📦 MLPackages found:"
            for pkg in /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/*.mlpackage; do
                pkg_name=$(basename "$pkg")
                pkg_size=$(du -sh "$pkg" 2>/dev/null | awk '{print $1}')
                echo "      - $pkg_name ($pkg_size)"
            done
        fi
    else
        echo "   Directory not created yet"
    fi
    
    echo ""
    
    # Check log tail
    echo "📝 Latest Log (last 5 lines):"
    tail -5 /tmp/chunk_final.log 2>/dev/null | sed 's/^/   /'
    
    echo ""
    echo "---"
    echo "Next update in 30 seconds..."
    
    sleep 30
done

echo ""
echo "=== Conversion Complete or Stopped ==="
echo "Check final output:"
echo "  ls -lh /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/"
echo "  tail -50 /tmp/chunk_final.log"
