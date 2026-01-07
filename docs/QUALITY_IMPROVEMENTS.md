# HeyIm Quality Improvement Plan

## Current Status (Jan 2026)

### Model Setup
- **Model**: RealisticVision v5.1 (SG161222/Realistic_Vision_V5.1_noVAE)
- **Conversion**: SPLIT_EINSUM attention for Neural Engine
- **Compute**: CPU + Neural Engine
- **Resolution**: 512x512

### Generation Parameters
- **Scheduler**: PNDM (legacy, medium quality)
- **Steps**: 30-50 (good)
- **CFG Scale**: 7.5-9.0 (good)
- **Safety Checker**: Enabled (may reduce quality)

### Issues Reported
1. ❌ Images not matching prompt descriptions accurately
2. ❌ Body structure errors (anatomy issues)
3. ❌ Scene composition problems
4. ⚠️ Quality gap vs stablediffusionweb.com

---

## Improvement Tiers

### 🎯 Tier 1: Immediate Fixes (No Reconversion Needed)

#### A. Switch to Better Scheduler
**Current**: PNDM Scheduler (old, basic)
**Recommended**: DPM Solver++ or Euler Ancestral

**Available options in Apple's StableDiffusion:**
- `.pndmScheduler` (current - legacy)
- `.dpmSolverMultistepScheduler` (⭐ best quality/speed balance)
- `.eulerAncestralDiscreteScheduler` (⭐ high quality, creative)
- `.eulerDiscreteScheduler` (stable)

**Action**: Update `ModelService.swift` to use DPM Solver++

**Expected improvement**: 15-25% quality boost, better prompt adherence

---

#### B. Optimize CFG Guidance Scale
**Current**: 7.5-9.0 (good range)
**Recommended**: 
- Portraits: 8.0-9.5
- Landscapes: 7.0-8.5
- Complex scenes: 9.0-11.0

**Action**: Add dynamic CFG based on prompt type

**Expected improvement**: Better prompt following, fewer artifacts

---

#### C. Enhance Default Negative Prompts
**Current**: Basic negative prompt
**Recommended**: Comprehensive negative prompt template

```
ugly, deformed, disfigured, poor details, bad anatomy, 
lowres, low quality, blurry, distorted face, duplicate, 
mutated, extra limbs, bad proportions,
(worst quality:1.4), (low quality:1.4), 
(bad hands:1.2), (missing fingers:1.2), (extra fingers:1.2),
(bad anatomy:1.2), (anatomical nonsense:1.2),
text, watermark, signature, logo, username, artist name
```

**Action**: Update quality presets with better negatives

**Expected improvement**: Fewer anatomy errors, cleaner images

---

#### D. Increase Generation Steps for Premium
**Current**: Premium preset = 50 steps
**Recommended**: 60-75 steps for maximum quality

**Action**: Add "Ultra" preset with 70 steps

**Expected improvement**: Finer details, better coherence

---

### 🔧 Tier 2: Model Upgrade (Requires Reconversion - 2-3 hours)

#### A. Upgrade to RealisticVision v6.0
**Current**: v5.1 (Jan 2023)
**Latest**: v6.0 B1 (improved anatomy, better prompts)

**Benefits**:
- Better human anatomy
- Improved prompt understanding
- Less artifacts
- Better lighting/colors

**Model**: `SG161222/RealVisXL_V4.0` or `SG161222/Realistic_Vision_V6.0_B1_noVAE`

**Conversion command**:
```bash
cd ~/Documents/MochiDiffusion/conversion

# Download v6.0
wget https://huggingface.co/SG161222/Realistic_Vision_V6.0_B1_noVAE/resolve/main/Realistic_Vision_V6.0_noVAE_B1_fp16.safetensors -O RealisticVision_v60.safetensors

# Convert to diffusers
uv run python convert_original_stable_diffusion_to_diffusers.py \
  --checkpoint_path RealisticVision_v60.safetensors \
  --from_safetensors \
  --device cpu \
  --extract_ema \
  --dump_path RealisticVision_v60_diffusers

# Convert to Core ML (SPLIT_EINSUM for ANE)
uv run python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-vae-decoder \
  --convert-vae-encoder \
  --convert-unet \
  --convert-text-encoder \
  --model-version RealisticVision_v60_diffusers \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  -o /Users/mac/HeyIm/models/RealisticVision_v60_split-einsum
```

**Expected improvement**: 30-40% quality boost

---

#### B. Alternative: Try Community Models

**High-quality alternatives**:
1. **DreamShaper v8** - Great for artistic/creative
2. **AbsoluteReality v1.8.1** - Excellent realism
3. **epiCRealism** - Best for photorealism
4. **CyberRealistic v4.0** - Sharp, detailed

**Best pick for portraits**: AbsoluteReality or CyberRealistic

---

### 🚀 Tier 3: Advanced Optimizations (Optional)

#### A. Resolution Upgrade (512 → 768)
**Warning**: 
- 2.25x more computation
- Requires model reconversion with `--latent-w 96 --latent-h 96`
- Generation time: 12s → 25-30s

**Only do this if**:
- Neural Engine has capacity
- Users willing to wait longer
- Need print-quality outputs

---

#### B. Multi-model LoRA Support
Add specialized LoRA models for:
- Better hands
- Better faces
- Style-specific improvements

**Complexity**: High (requires LoRA conversion to Core ML)

---

#### C. Upscaling Pipeline
Add Real-ESRGAN post-processing:
- Generate at 512x512
- Upscale to 1024x1024 or 2048x2048
- Enhances details without slow generation

---

## Implementation Priority

### Week 1: Quick Wins
1. ✅ Switch to DPM Solver++ scheduler
2. ✅ Enhance negative prompts
3. ✅ Add Ultra quality preset (70 steps)
4. ✅ Dynamic CFG based on prompt

**Expected result**: 15-25% quality improvement

### Week 2: Model Upgrade
1. Convert RealisticVision v6.0
2. A/B test v5.1 vs v6.0
3. Update production if better

**Expected result**: Additional 30-40% improvement

### Month 2: Advanced (Optional)
1. Test alternative models
2. Evaluate resolution upgrade feasibility
3. Explore upscaling pipeline

---

## Quality Metrics

### Test Prompts
```
1. "professional portrait of a beautiful woman, detailed face, high quality, photorealistic, 8k uhd, studio lighting"

2. "full body photo of a woman in elegant dress, natural pose, detailed hands and fingers, photorealistic"

3. "modern office interior, large windows, natural lighting, architectural photography, high detail"
```

### Success Criteria
- ✅ Correct anatomy (hands, face, body proportions)
- ✅ Prompt adherence (95%+ elements present)
- ✅ No obvious artifacts (extra fingers, distorted features)
- ✅ Professional quality suitable for real use

---

## Comparison with stablediffusionweb.com

### Their Advantages
1. Likely using SDXL (larger, better model)
2. GPU servers (more compute power)
3. Multiple model options
4. Advanced schedulers (DPM++ 2M Karras)
5. Higher resolution options

### Our Competitive Edge
1. **Privacy**: On-device generation
2. **Speed**: Neural Engine optimization
3. **Cost**: No API fees
4. **Offline**: Works without internet

### Realistic Expectations
- We won't match SDXL quality (10x larger model)
- We CAN match SD 1.5 quality with optimizations
- Our niche: Fast, private, local generation

---

## Next Steps

1. **Implement Tier 1 improvements** (today)
2. **Test with user prompts** (validate improvements)
3. **Decide on v6.0 upgrade** (based on feedback)
4. **Document results** (before/after comparisons)

---

**Estimated timeline**: 
- Tier 1: 2-4 hours
- Tier 2: 3-4 hours (if approved)
- Total improvement: 40-60% quality boost
