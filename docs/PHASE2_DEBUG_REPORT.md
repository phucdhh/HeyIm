# Phase 2 Progress Report - Generation Debugging

## Current Status (2026-01-01 20:30)

### ✅ Working Components
- **Backend Infrastructure**: Swift/Vapor server builds and runs
- **Model Loading**: All 3 models load successfully (~40s)
  - UNet: 1.6GB
  - TextEncoder: 235MB  
  - VAEDecoder: 95MB
- **API Endpoints**: `/health`, `/api/info`, `/api/status`, `/api/load` all functional
- **Model Compilation**: CoreML compilation working (tested text encoder successfully)
- **Text Encoder Test**: Standalone test confirms text encoder works perfectly

### ❌ Current Issue
**Generation fails with ModelServiceError**
- Error: `ModelServiceError error 1` (generationFailed)
- No detailed logs showing actual cause
- Pipeline object created successfully
- Error happens when calling `pipeline.generate()`

### 🔍 Debug Findings
1. **Server logs show**:
   - "✓ Pipeline ready" - pipeline created successfully
   - "/api/generate" request received
   - NO "🎬 Starting generation..." message - error before entering generateImage body
   
2. **Standalone test shows**:
   - Text encoder compiles and runs inference successfully
   - Output shape correct: `[1, 77, 768]`

3. **Possible causes**:
   - Error in pipeline.generate() not being caught/logged properly
   - Task.detached may be swallowing errors/logs
   - Model input/output names or shapes mismatch
   - Memory issue during diffusion loop

### 📝 Implementation Details

**Files Created**:
- `Tokenizer.swift` - CLIP tokenizer with basic vocab
- `StableDiffusionPipeline.swift` - Full SD pipeline implementation
  - Text encoding
  - Latent initialization  
  - Diffusion loop with CFG
  - VAE decoding
  - EulerDiscreteScheduler
- `ModelService.swift` - Actor-based model management
- `Models.swift` - Request/Response structures
- `main.swift` - Vapor routes and server config

**Key Design Decisions**:
- Used `Task.detached` to avoid blocking actor
- Manual pipeline implementation instead of Apple's framework
- Compile models on-demand (cached in /tmp)

### 🐛 Known Issues
1. **Terminal corruption** - zsh terminals getting stuck/corrupted
2. **Logging not appearing** - print statements in pipeline not showing
3. **Error details missing** - ModelServiceError doesn't include underlying error

### 💡 Next Steps

**Option A: Debug Current Implementation**
1. Add file-based logging instead of print()
2. Test UNet and VAE decoder in isolation
3. Check model input/output names match expectations
4. Add error boundaries around each pipeline step

**Option B: Use Apple's Framework**
Replace manual pipeline with Apple's `StableDiffusion` framework:
```swift
import StableDiffusion

let pipeline = try StableDiffusionPipeline(
    resourcesAt: modelPath,
    configuration: .init(
        computeUnits: .cpuAndNeuralEngine
    )
)
```

Pros: Battle-tested, proper error handling, optimized
Cons: Need to restructure model loading

**Option C: Simplify Test Case**
Create minimal reproducible test:
1. Load models
2. Run one UNet prediction
3. Verify output
4. Build up from there

### 🎯 Recommendation
**Try Option B** - Use Apple's StableDiffusion framework. The manual implementation is complex and error-prone. Apple's framework:
- Handles all edge cases
- Proper memory management
- Known to work with our model format
- Better error messages

Implementation would require:
1. Add StableDiffusion package dependency
2. Restructure model loading to use Apple's format
3. Replace pipeline with Apple's implementation
4. Test generation

Estimated time: 30-60 minutes vs many hours of debugging.
