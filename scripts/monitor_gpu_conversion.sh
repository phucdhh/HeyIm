#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   SDXL UNet GPU Conversion (8-bit Quantized for Hybrid ANE+GPU) ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Started: $(date)"
echo ""

while true; do
    clear
    echo "═══════════════════════════════════════════════════════════════════"
    echo "⏰ $(date +'%H:%M:%S') | GPU UNet Conversion Status"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check process
    if ps aux | grep "torch2coreml.*CPU_AND_GPU" | grep -v grep > /dev/null; then
        echo "✅ Status: CONVERTING (GPU)"
        ps aux | grep "torch2coreml.*CPU_AND_GPU" | grep -v grep | head -1 | awk '{
            cpu = $3
            mem_gb = $6/1024/1024
            printf "   CPU: %.1f%% | Memory: %.1fGB\n", cpu, mem_gb
        }'
    else
        echo "✅ Status: COMPLETED or STOPPED"
        break
    fi
    
    echo ""
    echo "💾 Disk:"
    df -h / | tail -1 | awk '{printf "   Available: %s / %s (%s used)\n", $4, $2, $5}'
    
    echo ""
    echo "📁 Output:"
    if [ -d "/Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid" ]; then
        size=$(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid 2>/dev/null | awk '{print $1}')
        files=$(find /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "   Size: $size | Files: $files"
        
        if ls /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid/*unet*.mlpackage 2>/dev/null | grep -q .; then
            unet=$(ls /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid/*unet*.mlpackage 2>/dev/null | head -1)
            unet_size=$(du -sh "$unet" 2>/dev/null | awk '{print $1}')
            echo "   📦 GPU UNet: $unet_size"
        fi
    else
        echo "   Not created yet"
    fi
    
    echo ""
    echo "📝 Log (last 3 lines):"
    tail -3 /tmp/gpu_unet_conversion.log 2>/dev/null | sed 's/^/   /'
    
    echo ""
    echo "───────────────────────────────────────────────────────────────────"
    echo "Next update in 30s | Press Ctrl+C to stop"
    
    sleep 30
done

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    CONVERSION COMPLETE!                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if [ -d "/Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid" ]; then
    echo "📊 Final Output:"
    ls -lh /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid/ 2>/dev/null | tail -n +2
    echo ""
    total=$(du -sh /Users/mac/HeyIm/models/Juggernaut_XL_v9_hybrid 2>/dev/null | awk '{print $1}')
    echo "Total size: $total"
    echo ""
    echo "🔄 Next steps:"
    echo "  1. Compile GPU UNet to mlmodelc"
    echo "  2. Copy ANE models (TextEncoder, VAE) from split-einsum"
    echo "  3. Update backend path"
    echo "  4. Test hybrid ANE+GPU performance"
fi

echo ""
echo "Check full log: tail -100 /tmp/gpu_unet_conversion.log"
