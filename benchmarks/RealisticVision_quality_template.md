# RealisticVision v5.1 Quality Benchmark

Date: _____  
Tester: _____  
Hardware: Mac Mini M2 (RAM: ___GB)  
macOS version: _____

## Model Info
- Name: RealisticVision v5.1 (finetuned SD1.5)
- Source: https://huggingface.co/SG161222/Realistic_Vision_V5.1_noVAE
- Core ML format: split_einsum (ANE compatible)
- Location: `models/RealisticVision_v51_split-einsum/`

## Performance Benchmarks

### Latency Tests (512×512)
| Steps | CFG | First Run (with compile) | Subsequent Runs (median of 5) |
|-------|-----|-------------------------|-------------------------------|
| 20    | 7   | ___s                    | ___s                          |
| 30    | 8   | ___s                    | ___s                          |
| 40    | 10  | ___s                    | ___s                          |
| 50    | 12  | ___s                    | ___s                          |

**Notes:**
- First run includes ANE compile time (~1-2 min)
- Memory usage peak: ___MB

### Recommended Settings (Performance vs Quality)
- Fast preview: steps=20, CFG=7 (~___s)
- Production: steps=40, CFG=10 (~___s) ✓
- High quality: steps=50, CFG=12 (~___s)

## Quality Assessment

### Test Prompts (10 samples)
Evaluate với scale 1-5:
- 1 = Poor (nhiều lỗi, không match prompt)
- 3 = Acceptable (match prompt, chất lượng trung bình)
- 5 = Excellent (match prompt hoàn toàn, detail sắc nét)

#### Prompt 1: Portrait
**Prompt:** "portrait of a young woman with long brown hair, blue eyes, natural lighting, photorealistic, detailed skin texture, bokeh background"

**Negative:** "blurry, low quality, distorted, cartoon, anime"

**Settings:** steps=40, CFG=10, seed=42

**Score (1-5):** ___  
**Notes:** _______________________________

**Image saved as:** `benchmarks/images/realisticvision_portrait_1.png`

---

#### Prompt 2: Landscape
**Prompt:** "mountain landscape at sunset, dramatic clouds, lake reflection, vibrant colors, professional photography, 8k uhd"

**Negative:** "blurry, low quality, oversaturated, cartoon"

**Settings:** steps=40, CFG=10, seed=123

**Score (1-5):** ___  
**Notes:** _______________________________

---

#### Prompt 3: Complex Scene
**Prompt:** "modern coffee shop interior, wooden tables, hanging plants, large windows with city view, warm lighting, people sitting and talking, realistic, detailed"

**Negative:** "blurry, distorted, low quality, malformed objects"

**Settings:** steps=50, CFG=12, seed=456

**Score (1-5):** ___  
**Notes:** _______________________________

---

#### Prompt 4: Product Shot
**Prompt:** "luxury wristwatch on marble table, dramatic lighting, reflections, macro photography, sharp focus, high detail"

**Negative:** "blurry, low quality, distorted, cartoon"

**Settings:** steps=40, CFG=10, seed=789

**Score (1-5):** ___  
**Notes:** _______________________________

---

#### Prompt 5: Animal
**Prompt:** "majestic lion portrait, golden hour lighting, detailed fur texture, photorealistic, national geographic style"

**Negative:** "blurry, cartoon, anime, low quality, distorted"

**Settings:** steps=40, CFG=10, seed=101

**Score (1-5):** ___  
**Notes:** _______________________________

---

#### Prompt 6-10: [Add more test cases]
_Fill in with additional diverse prompts testing different scenarios_

### Quality Metrics Summary

**Average Prompt Adherence Score:** ___/5.0  
Target: ≥ 4.0

**Visual Quality Assessment:**
- Sharpness (edges clear, no blur): ___/5
- Coherence (no artifacts, deformed objects): ___/5
- Color/Lighting (natural, not oversaturated): ___/5
- Detail preservation: ___/5

**Overall Quality Rating:** ___/5  
Target: ≥ 4.0

## Comparison: Base SD1.5 vs RealisticVision

Run same prompts với base SD1.5 model để so sánh:

| Aspect | Base SD1.5 | RealisticVision v5.1 | Improvement |
|--------|------------|----------------------|-------------|
| Realism | ___/5 | ___/5 | +___ |
| Detail | ___/5 | ___/5 | +___ |
| Prompt adherence | ___/5 | ___/5 | +___ |
| Color accuracy | ___/5 | ___/5 | +___ |

**Conclusion:** RealisticVision có improve rõ rệt? (Yes/No): ___

## Issues & Observations

### Problems Encountered:
- [ ] OOM errors
- [ ] Artifacts in specific scenarios
- [ ] Slow compile time
- [ ] Other: _______________________________

### Strengths:
- _______________________________
- _______________________________

### Weaknesses:
- _______________________________
- _______________________________

## Recommendations

**Proceed to Phase 2?** (Yes/No): ___

**Suggested improvements:**
- _______________________________
- _______________________________

**Next steps:**
- [ ] Test với ControlNet integration
- [ ] Test upscaling pipeline
- [ ] Document optimal parameters trong backend config

---

**Sign-off:**  
Approved by: _____  
Date: _____
