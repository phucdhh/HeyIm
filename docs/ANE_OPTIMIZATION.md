# ANE Optimization for SDXL Models

**Date**: January 7, 2026  
**Issue**: Juggernaut XL (SDXL) running on CPU instead of ANE, causing slow generation

## Problem Analysis

### Fast Mode (RealisticVision) - ✅ Working
- Model: Stable Diffusion 1.5 (3.6GB total)
- UNet size: ~1.2GB
- **ANE Usage**: ✅ Active
- **Generation Time**: 5-9 seconds

### Quality Mode (Juggernaut XL) - ⚠️ Slow
- Model: Stable Diffusion XL (6.6GB total)  
- UNet size: **4.8GB** (TOO LARGE for ANE)
- **ANE Usage**: ❌ 0% (falls back to CPU)
- **Generation Time**: >2 minutes (stuck)

## Root Cause

Apple Neural Engine has memory limitations:
- **ANE can handle**: ~2GB per model chunk
- **SDXL UNet**: 4.8GB monolithic model
- **Result**: Framework falls back to CPU

## Solutions

### Solution 1: UNet Chunking (IN PROGRESS) ✅
Split UNet into smaller chunks that fit in ANE memory:

```bash
python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-unet \
  --chunk-unet \
  --compute-unit CPU_AND_NE \
  --attention-implementation SPLIT_EINSUM \
  --xl-version
```

**Expected Result**:
- UnetChunk1: ~2.4GB
- UnetChunk2: ~2.4GB  
- Both chunks run on ANE
- Generation time: 15-25s (similar to SD 1.5)

### Solution 2: Quantization
Reduce model precision to fit ANE:

```bash
--quantize-nbits 6  # or 8
```

**Trade-offs**:
- ✅ Smaller file size
- ✅ Fits in ANE
- ⚠️ Slight quality loss

### Solution 3: Use Pre-chunked Models
MochiDiffusion community often provides pre-chunked SDXL models optimized for ANE.

## Implementation Status

### Current (10:50 AM)
- ✅ Identified root cause (UNet too large)
- ✅ Started UNet chunking conversion
- ⏳ Conversion in progress (~15-20 min)
- ⏳ Testing with Mochi Diffusion app

### Next Steps (After Chunking Complete)
1. Replace monolithic UNet with chunked versions
2. Update backend to use UnetChunk1 + UnetChunk2
3. Test generation speed with ANE
4. Verify ANE usage in Activity Monitor
5. Deploy if successful

## Technical Details

### Model Structure Comparison

**SD 1.5 (Fast Mode)**:
```
models/RealisticVision_v51_split-einsum/
├── TextEncoder.mlmodelc (235MB) ✅ ANE
├── Unet.mlmodelc (1.2GB) ✅ ANE
├── VAEDecoder.mlmodelc (189MB) ✅ ANE
└── VAEEncoder.mlmodelc (130MB) ✅ ANE
```

**SDXL (Quality Mode - Current)**:
```
models/Juggernaut_XL_v9_split-einsum/
├── TextEncoder.mlmodelc (235MB) ✅ ANE
├── TextEncoder2.mlmodelc (1.3GB) ✅ ANE
├── Unet.mlmodelc (4.8GB) ❌ CPU (TOO LARGE)
├── VAEDecoder.mlmodelc (189MB) ✅ ANE
└── VAEEncoder.mlmodelc (130MB) ✅ ANE
```

**SDXL (Quality Mode - Target)**:
```
models/Juggernaut_XL_v9_chunked/
├── TextEncoder.mlmodelc (235MB) ✅ ANE
├── TextEncoder2.mlmodelc (1.3GB) ✅ ANE
├── UnetChunk1.mlmodelc (~2.4GB) ✅ ANE
├── UnetChunk2.mlmodelc (~2.4GB) ✅ ANE
├── VAEDecoder.mlmodelc (189MB) ✅ ANE
└── VAEEncoder.mlmodelc (130MB) ✅ ANE
```

## Verification Commands

### Check ANE Usage
```bash
# In Activity Monitor or:
sudo powermetrics --samplers gpu_power -i1000 -n1 | grep -i "ane\|neural"
```

### Check Model Compute Units
```python
import coremltools as ct
model = ct.models.MLModel('path/to/model.mlmodelc')
print(f'Compute units: {model.compute_unit}')
```

### Monitor Generation
```bash
# Check which process uses ANE
ps aux | grep -i "heyim\|mochi"
```

## Expected Performance

| Mode | Model | Size | ANE | Time |
|------|-------|------|-----|------|
| Fast | RealisticVision | 3.6GB | ✅ | 5-9s |
| Quality (Before) | Juggernaut XL | 6.6GB | ❌ | >120s |
| Quality (After) | Juggernaut XL Chunked | 6.6GB | ✅ | 15-25s |

## References

- Apple ML Stable Diffusion: https://github.com/apple/ml-stable-diffusion
- Core ML ANE Optimization: https://developer.apple.com/documentation/coreml
- SPLIT_EINSUM attention for ANE: Splits attention operations for ANE compatibility
