# Phase 1 Quick Start Guide

Hướng dẫn nhanh để hoàn thành Phase 1: Convert models & Benchmark.

## Overview
Phase 1 mục tiêu:
- ✓ Convert RealisticVision v5.1 (finetuned SD1.5) sang Core ML
- ✓ Convert ít nhất 2 ControlNet models (Canny + OpenPose recommended)
- ✓ Run performance và quality benchmarks
- ✓ Document kết quả và approve để tiếp Phase 2

**Thời gian ước tính:** 2-3 ngày (bao gồm conversion time + testing)

## Step-by-Step

### 1. Environment Setup (1-2 giờ)
Đọc và làm theo [ENV.md](../ENV.md):
```bash
# Checklist nhanh
xcode-select --install
brew install uv git-lfs
git clone https://github.com/MochiDiffusion/MochiDiffusion.git ~/MochiDiffusion
cd ~/MochiDiffusion/conversion && uv venv && ./download-script.sh
```

✓ Hoàn thành khi: tất cả items trong ENV.md checklist pass

---

### 2. Convert RealisticVision (~30-40 phút)
```bash
cd ~/HeyIm
chmod +x scripts/convert_realisticvision.sh
./scripts/convert_realisticvision.sh
```

**Trong lúc chờ:** đọc thêm về [quality benchmarking](../benchmarks/README.md)

✓ Hoàn thành khi: `models/RealisticVision_v51_split-einsum/` chứa `.mlmodelc` files

---

### 3. Download ControlNet Models (15 phút)
Recommended: tải pre-converted từ coreml-community thay vì convert:

```bash
cd ~/HeyIm

# Clone ControlNet repo
git lfs install
git clone https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML /tmp/controlnet

# Copy Canny model
mkdir -p models/ControlNet_Canny_CoreML
cp -r /tmp/controlnet/CN/canny/* models/ControlNet_Canny_CoreML/

# Copy OpenPose model
mkdir -p models/ControlNet_OpenPose_CoreML
cp -r /tmp/controlnet/CN/openpose/* models/ControlNet_OpenPose_CoreML/
```

✓ Hoàn thành khi: cả 2 ControlNet models đều có `.mlmodelc` files

---

### 4. Verify Models (10 phút)
Test models với MochiDiffusion app:

```bash
# Launch MochiDiffusion
open ~/MochiDiffusion/build/Release/MochiDiffusion.app
# (hoặc tải từ GitHub releases nếu chưa build)
```

In MochiDiffusion:
1. Settings → Models folder → browse to `~/HeyIm/models`
2. Select "RealisticVision_v51_split-einsum"
3. Generate test image với prompt: "portrait of a person, photorealistic"
4. Observe: latency, memory usage, quality

✓ Pass nếu: image generates successfully, không crash/OOM

---

### 5. Run Performance Benchmarks (30-60 phút)
```bash
# Copy template
cp benchmarks/RealisticVision_quality_template.md benchmarks/RealisticVision_quality_results.md

# Create images folder
mkdir -p benchmarks/images
```

Test với MochiDiffusion hoặc backend prototype:
- Run prompts từ template với các settings khác nhau (steps=20/40/50, CFG=7/10/12)
- Ghi latency vào table
- Save generated images vào `benchmarks/images/`
- Rate quality (1-5) cho mỗi prompt

✓ Hoàn thành khi: template đã điền đầy đủ metrics

---

### 6. Run Quality Assessment (1-2 giờ)
Fill out quality scores in `RealisticVision_quality_results.md`:
- Test all 10 prompts (diverse scenarios)
- Rate: prompt adherence, sharpness, coherence, colors
- Compare với base SD1.5 nếu có (optional nhưng recommended)
- Calculate average scores

**Target to pass Phase 1:**
- Average quality score ≥ 4.0/5.0
- No major artifacts or issues
- Latency acceptable (≤ 20s cho steps=40)

---

### 7. Test ControlNet (30 phút)
```bash
cp benchmarks/ControlNet_accuracy_template.md benchmarks/ControlNet_Canny_results.md
```

Test ControlNet integration:
1. Prepare reference images (edge maps hoặc pose skeletons)
2. Generate với ControlNet enabled
3. Visual comparison: output structure match reference?
4. Document accuracy score

✓ Pass nếu: ≥ 80% structural accuracy, no major distortions

---

### 8. Review & Approve (~30 phút)
Review tất cả benchmark results:
```bash
cat benchmarks/RealisticVision_quality_results.md
cat benchmarks/ControlNet_Canny_results.md
```

**Decision criteria:**
- [ ] RealisticVision average quality ≥ 4.0/5.0
- [ ] ControlNet accuracy ≥ 80%
- [ ] Performance acceptable (latency ≤ 20s for production settings)
- [ ] No critical issues (OOM, crashes, major artifacts)

If ALL pass → **Approve Phase 1, proceed to Phase 2** ✓

If any fail → iterate:
- Try different model versions
- Adjust parameters
- Investigate issues

---

## Deliverables Checklist

Phase 1 complete khi có:
- [ ] `models/RealisticVision_v51_split-einsum/` với `.mlmodelc` files
- [ ] `models/ControlNet_Canny_CoreML/` và `models/ControlNet_OpenPose_CoreML/`
- [ ] `benchmarks/RealisticVision_quality_results.md` (filled out)
- [ ] `benchmarks/ControlNet_Canny_results.md` (filled out)
- [ ] `benchmarks/images/` với test images
- [ ] Phase 1 approval sign-off trong benchmark docs

---

## Troubleshooting Quick Reference

| Issue | Quick Fix |
|-------|-----------|
| "killed" during conversion | Close other apps, use `nice -n 10`, or reboot |
| Cannot find coremlcompiler | Xcode Settings → Locations → re-select CLT |
| Model không load được | Check `.mlmodelc` structure, verify với `ls -R` |
| Quality scores thấp | Try steps=50, CFG=12; check negative prompts |
| ControlNet không work | Verify reference image format (grayscale for Canny) |

---

## Next Steps After Phase 1

Khi Phase 1 approved:
1. Update [PLANNING.md](../PLANNING.md) với actual benchmark results
2. Proceed to Phase 2: Backend development
3. Create backend skeleton với model loader stubs
4. Tôi sẽ hỗ trợ setup Swift/Vapor backend structure

---

**Questions?** Check:
- [ENV.md](../ENV.md) — environment setup
- [scripts/README.md](../scripts/README.md) — conversion scripts
- [benchmarks/README.md](../benchmarks/README.md) — benchmarking approach
- [PLANNING.md](../PLANNING.md) — full project plan
