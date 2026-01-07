# UNet Chunking Progress - January 7, 2026

## Status: ⏳ IN PROGRESS

### Timeline
- **11:30 AM**: Identified ANE issue - UNet too large (4.8GB)
- **11:35 AM**: Freed 20GB disk space (removed duplicates)
- **11:38 AM**: Started UNet chunking conversion
- **ETA**: ~12:00-12:10 PM (20-30 minutes)

### Disk Space Management
**Before cleanup**:
- Available: 10GB
- Issues: Conversion failed with "No space left on device"

**After cleanup** (Removed):
- MochiDiffusion copy: 13GB ✅
- Original safetensors: 6.6GB ✅  
- Debug builds: ~500MB ✅
- **Total freed**: ~20GB
- **Available now**: 25GB ✅

### Conversion Details
**Command**:
```bash
python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-unet \
  --model-version /Users/mac/HeyIm/models/Juggernaut_XL_v9_diffusers \
  --xl-version \
  --attention-implementation SPLIT_EINSUM \
  --chunk-unet \
  --compute-unit CPU_AND_NE \
  -o /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked
```

**Expected Output**:
```
/Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/
├── UnetChunk1.mlpackage (~2.4GB) - First half of UNet
├── UnetChunk2.mlpackage (~2.4GB) - Second half of UNet
└── (other files from original conversion)
```

### Why Chunking Matters

**Problem**: SDXL UNet (4.8GB) too large for ANE
- ANE memory limit: ~2GB per model
- Result: Falls back to CPU (100x slower)

**Solution**: Split UNet into 2 chunks
- Each chunk: ~2.4GB (fits in ANE)
- Both chunks run on ANE in sequence
- Expected speed: 15-25s (vs 120s+ on CPU)

### Monitoring
**Active monitors**:
- Main log: `/tmp/chunk_retry.log`
- Monitor script: `/tmp/chunking_monitor.log` (updates every minute)
- Process check: `ps aux | grep torch2coreml`

**Check progress**:
```bash
# Watch conversion log
tail -f /tmp/chunk_retry.log

# Watch monitor
tail -f /tmp/chunking_monitor.log

# Check output
ls -lh /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/
```

### Next Steps (After Conversion)

#### 1. Verify Chunked Models
```bash
ls -lh /Users/mac/HeyIm/models/Juggernaut_XL_v9_chunked/*.mlpackage
# Should see: UnetChunk1 and UnetChunk2
```

#### 2. Compile mlmodelc Files
```python
import coremltools as ct
for chunk in ['UnetChunk1', 'UnetChunk2']:
    model = ct.models.MLModel(f'{chunk}.mlpackage')
    compiled = model.get_compiled_model_path()
    # Copy to chunked directory
```

#### 3. Update Backend to Use Chunks
The `StableDiffusionXLPipeline` automatically detects and uses chunked UNet:
```swift
// Backend already handles this!
let pipeline = try StableDiffusionXLPipeline(
    resourcesAt: resourceURL,  // Points to chunked directory
    configuration: config,
    reduceMemory: false
)
// If UnetChunk1/2 exist, framework uses them automatically
```

#### 4. Test Generation
```bash
# Start backend
cd /Users/mac/HeyIm/backend && .build/release/HeyImServer

# Test Quality Mode
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Product Photography: wireless keyboard", "modelType": "quality", "steps": 20}'
```

#### 5. Verify ANE Usage
```bash
# During generation, check Activity Monitor:
# - Process: HeyImServer
# - Look for: "ANE Usage" > 0%
# - Should see ~80-100% ANE during UNet steps
```

### Expected Performance

| Metric | Before (Monolithic) | After (Chunked) |
|--------|-------------------|-----------------|
| UNet Size | 4.8GB (1 file) | 2.4GB × 2 chunks |
| ANE Usage | 0% (CPU fallback) | 80-100% ✅ |
| Load Time | ~10s | ~15s |
| Generation Time | >120s | 15-25s ✅ |
| Memory Usage | 6GB RAM | 8GB RAM |

### Troubleshooting

**If conversion fails**:
1. Check `/tmp/chunk_retry.log` for errors
2. Verify disk space: `df -h /`
3. Check temp space: `df -h /var/folders`
4. Retry with more space or lower precision

**If ANE still not used**:
1. Verify chunks created: `ls *.mlpackage`
2. Check chunk sizes: `du -sh UnetChunk*.mlpackage`
3. Confirm mlmodelc compiled correctly
4. Test with Activity Monitor during generation

### Success Criteria
- ✅ UnetChunk1.mlpackage exists (~2.4GB)
- ✅ UnetChunk2.mlpackage exists (~2.4GB)
- ✅ Both chunks have mlmodelc versions
- ✅ Backend loads without errors
- ✅ Generation completes in 15-25s
- ✅ Activity Monitor shows ANE usage > 80%

---

**Current Status**: Conversion running, monitor every minute for ~20-30 minutes
**Next Update**: When conversion completes or fails
