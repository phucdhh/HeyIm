# Scripts for Model Conversion and Benchmarking

## Prerequisites
- macOS (recommended) — conversion targets Core ML and ANE.
- Python 3.10+, pip, virtualenv
- MochiDiffusion repo cloned: `~/MochiDiffusion`
- Complete environment setup from [ENV.md](../ENV.md)

## Available Scripts

### convert_realisticvision.sh
Automated pipeline to download and convert RealisticVision v5.1 (high-quality finetuned SD1.5) to Core ML.

**Usage:**
```bash
chmod +x scripts/convert_realisticvision.sh
./scripts/convert_realisticvision.sh
```

**What it does:**
1. Downloads RealisticVision v5.1 from Hugging Face (or uses existing file)
2. Converts safetensors → diffusers format
3. Converts diffusers → Core ML (SPLIT_EINSUM for ANE)
4. Outputs to: `models/RealisticVision_v51_split-einsum/`

**Time:** ~25-35 minutes total  
**Disk:** ~4GB for model files

---

### convert_controlnet.sh
Helper script for converting ControlNet models to Core ML.

**Usage:**
```bash
chmod +x scripts/convert_controlnet.sh
./scripts/convert_controlnet.sh canny      # For Canny edge detection
./scripts/convert_controlnet.sh openpose   # For pose control
./scripts/convert_controlnet.sh depth      # For depth map
./scripts/convert_controlnet.sh tile       # For tile upscaling
```

**Recommendation:** Download pre-converted models from coreml-community instead:
```bash
git lfs install
git clone https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML
cp -r ControlNet-Models-For-Core-ML/CN/canny models/ControlNet_Canny_CoreML/
cp -r ControlNet-Models-For-Core-ML/CN/openpose models/ControlNet_OpenPose_CoreML/
```

---

### convert_coreml.sh (legacy/general wrapper)
General-purpose wrapper that provides example commands. Use specific scripts above instead.

**Usage:**
```bash
./scripts/convert_coreml.sh --model runwayml/stable-diffusion-v1-5 --out Models/SD15_CoreML --method mochidiffusion
```

## After Conversion

1. **Verify models exist:**
```bash
ls -lh models/RealisticVision_v51_split-einsum/
# Should see: TextEncoder.mlmodelc, Unet.mlmodelc, VAEDecoder.mlmodelc, etc.
```

2. **Test with MochiDiffusion app:**
   - Open MochiDiffusion
   - Settings → Models folder → select `~/HeyIm/models`
   - Select RealisticVision model
   - Generate test image

3. **Run benchmarks:**
   - Copy `benchmarks/RealisticVision_quality_template.md` → `RealisticVision_quality_results.md`
   - Fill in performance and quality metrics
   - Save test images to `benchmarks/images/`

4. **Proceed to Phase 2** when quality benchmarks pass (≥4.0/5.0 scores)

## Troubleshooting

### "MochiDiffusion conversion directory not found"
**Fix:** Clone and setup MochiDiffusion first:
```bash
cd ~
git clone https://github.com/MochiDiffusion/MochiDiffusion.git
cd MochiDiffusion/conversion
uv venv
./download-script.sh
```

### "Killed" during conversion
**Fix:** Not enough RAM. Close other apps, or use:
```bash
nice -n 10 ./scripts/convert_realisticvision.sh
```

### "Cannot find .safetensors file"
**Fix:** Download manually:
```bash
cd ~/MochiDiffusion/conversion
wget https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors -O RealisticVision_v51.safetensors
```

## Notes
- Conversion scripts print recommended commands but do not attempt to install dependencies or download large weights automatically (to give you control).
- For reproducible conversion, follow MochiDiffusion's tested instructions.
- SPLIT_EINSUM models are compatible with Neural Engine (ANE) for best performance on Apple Silicon.
