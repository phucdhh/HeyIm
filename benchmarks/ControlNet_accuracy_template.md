# ControlNet Accuracy Benchmark Template

Date: _____  
Tester: _____  
Hardware: Mac Mini M2 (RAM: ___GB)

## ControlNet Model Info
- Type: _______ (Canny / OpenPose / Depth / Tile)
- Core ML format: split_einsum
- Location: `models/ControlNet_____CoreML/`

## Setup
- Base model used: RealisticVision v5.1
- Settings: steps=40, CFG=10

## Test Cases

### Test 1: Structural Accuracy
**Reference Image:** `benchmarks/images/controlnet_ref_1.png`  
**Type:** _______ (e.g., Canny edge map)

**Prompt:** "modern architecture building, glass facade, blue sky"

**Expected:** Output should follow the structure/edges from reference image

**Result:**
- Output saved as: `benchmarks/images/controlnet_output_1.png`
- Structural match: ___% (visual estimate)
- Score (1-5): ___
- Notes: _______________________________

---

### Test 2: Pose Control (OpenPose)
**Reference Image:** `benchmarks/images/pose_ref_1.png`  
**Type:** OpenPose skeleton

**Prompt:** "professional dancer, studio lighting, elegant pose"

**Expected:** Output person should match pose from reference

**Result:**
- Output saved as: `benchmarks/images/pose_output_1.png`
- Pose accuracy: ___% (visual estimate)
- Score (1-5): ___
- Notes: _______________________________

---

### Test 3: [Add more tests based on ControlNet type]

## Summary

**Average Accuracy Score:** ___/5.0  
Target: ≥ 4.0 (80% structural match)

**ControlNet adds value?** (Yes/No): ___

**Latency overhead:** +___s compared to base generation

**Recommendation:** Proceed to integrate in backend? ___

---

**Notes:**
- ControlNet particularly useful for: _______________________________
- Limitations observed: _______________________________
