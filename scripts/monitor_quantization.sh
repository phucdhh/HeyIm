#!/bin/bash

echo "=== Monitoring 8-bit Quantization Conversion ==="
echo "Target: 4.8GB → ~1.2GB (for ANE compatibility)"
echo "Started: $(date)"
echo ""

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       SDXL UNet 8-bit Quantization for ANE                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "⏰ Time: $(date +'%H:%M:%S')"
    echo ""
    
    # Check process
    if ps aux | grep "torch2coreml.*quantize" | grep -v grep > /dev/null; then
        echo "✅ Status: CONVERTING"
        ps aux | grep "torch2coreml.*quantize" | grep -v grep | head -1 | awk '{
            cpu = $3
            mem_gb = $6/1024/1024
            printf "   CPU: %.1f%% | Memory: %.1fGB\n", cpu, mem_gb
        }'
    else
        echo "❌ Status: STOPPED or COMPLETED"
        echo ""
        echo "Checking output..."
        if [ -d "/Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit" ]; then
            echo "✅ Output directory exists!"
            du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit 2>/dev/null
        fi
        break
    fi
    
    echo ""
    
    # Disk space
    echo "💾 Disk Space:"
    df -h / | tail -1 | awk '{printf "   Available: %s / %s (%s used)\n", $4, $2, $5}'
    
    echo ""
    
    # Output directory
    echo "📁 Output:"
    if [ -d "/Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit" ]; then
        size=$(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit 2>/dev/null | awk '{print $1}')
        files=$(find /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "   Size: $size | Files: $files"
        
        # Check for UNet
        if ls /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit/*unet*.mlpackage 2>/dev/null | grep -q .; then
            echo "   📦 UNet package found!"
            unet_size=$(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit/*unet*.mlpackage 2>/dev/null | awk '{print $1}')
            echo "      Size: $unet_size (target: ~1.2GB)"
        fi
    else
        echo "   Not created yet"
    fi
    
    echo ""
    
    # Log tail
    echo "📝 Latest Log:"
    if [ -f "/tmp/quantize8bit.log" ]; then
        tail -3 /tmp/quantize8bit.log 2>/dev/null | sed 's/^/   /'
    else
        echo "   Log not found"
    fi
    
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "Updates every 30s | Press Ctrl+C to stop monitoring"
    
    sleep 30
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    CONVERSION COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Final output:"
ls -lh /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit/ 2>/dev/null
echo ""
echo "UNet size comparison:"
echo "  Before: $(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_split-einsum/Unet.mlmodelc 2>/dev/null | awk '{print $1}')"
echo "  After:  $(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit/*unet*.mlpackage 2>/dev/null | awk '{print $1}')"
echo ""
echo "Check log: tail -100 /tmp/quantize8bit.log"
