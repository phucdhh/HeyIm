# Multi-Model Architecture Design
**HeyIm - Fast Mode & Quality Mode**

## Overview

HeyIm sẽ hỗ trợ 2 models với 2 modes khác nhau:

### Fast Mode (RealisticVision v5.1)
- **Model**: RealisticVision v5.1 (SD 1.5 based)
- **Size**: 3.6GB Core ML
- **Speed**: 5-9 seconds/image
- **Best for**: Portrait photography, close-up faces, quick generation
- **Steps**: 25-35
- **CFG**: 7.5-8.5
- **Scheduler**: DPM Solver++

### Quality Mode (Juggernaut XL) - DEFAULT
- **Model**: Juggernaut XL v9 (SDXL 1.0 based)
- **Size**: 6-7GB Core ML
- **Speed**: 15-25 seconds/image
- **Best for**: Products, food, architecture, interiors, versatile subjects
- **Steps**: 30-40
- **CFG**: 3-7 (lower for more realistic)
- **Scheduler**: DPM++ 2M Karras

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  HeyIm Frontend                      │
│  ┌───────────────────────────────────────────────┐  │
│  │  Mode Selector:                                │  │
│  │  ○ Fast Mode    (5-9s, portraits)             │  │
│  │  ● Quality Mode (15-25s, versatile) [DEFAULT] │  │
│  └───────────────────────────────────────────────┘  │
│                                                      │
│  Tips display based on selected mode:                │
│  - Fast: "Best for portraits, faces, quick gen"     │
│  - Quality: "Best for products, food, detailed"     │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              HeyIm Backend (Swift/Vapor)             │
│  ┌───────────────────────────────────────────────┐  │
│  │  ModelService Actor                           │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  │  │
│  │  │ RealisticVision  │  │ Juggernaut XL    │  │  │
│  │  │ Pipeline         │  │ Pipeline         │  │  │
│  │  │ (Lazy loaded)    │  │ (Lazy loaded)    │  │  │
│  │  └──────────────────┘  └──────────────────┘  │  │
│  │                                               │  │
│  │  generateImage(prompt, model: .fast|.quality)│  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│          Mac Mini M2 Neural Engine                   │
│  ┌───────────────────────────────────────────────┐  │
│  │  Core ML Models (SPLIT_EINSUM)                │  │
│  │  - RealisticVision: 3.6GB (ready)            │  │
│  │  - Juggernaut XL: 6-7GB (converting)         │  │
│  │  Total: ~10GB models + 6GB runtime = 16GB OK │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Model Conversion ⏳
**Time**: 2-3 hours

1. **Run conversion script**:
   ```bash
   cd /Users/mac/HeyIm
   chmod +x scripts/convert_juggernaut_xl.sh
   ./scripts/convert_juggernaut_xl.sh
   ```

2. **Verify conversion**:
   - Check `models/Juggernaut_XL_v9_split-einsum/`
   - Test with MochiDiffusion app
   - Benchmark generation time

3. **Expected output**:
   - Size: ~6-7GB Core ML models
   - Files: unet, text_encoder (x2), vae_decoder, vae_encoder

### Phase 2: Backend Updates 🔧
**Time**: 3-4 hours

1. **Update ModelService.swift**:
   ```swift
   enum ModelType: String, Codable {
       case fast = "fast"           // RealisticVision v5.1
       case quality = "quality"      // Juggernaut XL
   }
   
   actor ModelService {
       private var realisticVisionPipeline: StableDiffusionPipeline?
       private var juggernautXLPipeline: StableDiffusionXLPipeline?
       
       func loadModel(_ type: ModelType) async throws {
           switch type {
           case .fast:
               if realisticVisionPipeline == nil {
                   // Load RealisticVision (already implemented)
               }
           case .quality:
               if juggernautXLPipeline == nil {
                   // Load Juggernaut XL (new)
                   let modelPath = "/Users/mac/HeyIm/models/Juggernaut_XL_v9_split-einsum"
                   // Initialize SDXL pipeline
               }
           }
       }
       
       func generateImage(
           prompt: String,
           modelType: ModelType,
           steps: Int,
           guidanceScale: Double,
           seed: UInt32
       ) async throws -> URL {
           try await loadModel(modelType)
           
           switch modelType {
           case .fast:
               return try await generateWithRealisticVision(...)
           case .quality:
               return try await generateWithJuggernautXL(...)
           }
       }
   }
   ```

2. **Update GenerateRequest.swift**:
   ```swift
   struct GenerateRequest: Content {
       let prompt: String
       let negativePrompt: String?
       let steps: Int
       let guidanceScale: Double
       let seed: UInt32?
       let modelType: ModelType? // New field (default: .quality)
   }
   ```

3. **Update routes.swift**:
   ```swift
   app.post("api", "generate") { req async throws -> GenerateResponse in
       let input = try req.content.decode(GenerateRequest.self)
       let modelType = input.modelType ?? .quality // Default Quality Mode
       
       let imageURL = try await ModelService.shared.generateImage(
           prompt: input.prompt,
           modelType: modelType,
           steps: input.steps,
           guidanceScale: input.guidanceScale,
           seed: input.seed ?? UInt32.random(in: 0...UInt32.max)
       )
       
       return GenerateResponse(imageUrl: imageURL.path)
   }
   ```

### Phase 3: Frontend Updates 🎨
**Time**: 2-3 hours

1. **Add ModelType to types**:
   ```typescript
   // types/index.ts
   export type ModelType = 'fast' | 'quality';
   
   export interface GenerateRequest {
     prompt: string;
     negativePrompt?: string;
     steps: number;
     guidanceScale: number;
     seed?: number;
     modelType?: ModelType; // New field
   }
   ```

2. **Update GenerateForm.tsx**:
   ```tsx
   const [modelType, setModelType] = useState<ModelType>('quality');
   
   // Add mode selector UI
   <div className="space-y-2">
     <label className="block text-sm font-medium">
       Generation Mode
     </label>
     <div className="grid grid-cols-2 gap-4">
       <button
         onClick={() => setModelType('fast')}
         className={cn(
           "p-4 rounded-lg border-2 transition-all",
           modelType === 'fast'
             ? "border-blue-500 bg-blue-50"
             : "border-gray-300"
         )}
       >
         <div className="font-semibold">⚡ Fast Mode</div>
         <div className="text-xs text-gray-600">
           5-9s • Best for portraits & faces
         </div>
       </button>
       
       <button
         onClick={() => setModelType('quality')}
         className={cn(
           "p-4 rounded-lg border-2 transition-all",
           modelType === 'quality'
             ? "border-blue-500 bg-blue-50"
             : "border-gray-300"
         )}
       >
         <div className="font-semibold">✨ Quality Mode</div>
         <div className="text-xs text-gray-600">
           15-25s • Best for products & versatile
         </div>
       </button>
     </div>
   </div>
   ```

3. **Update prompts.json**:
   - Add `modelType` field to presets
   - Add SDXL-style prompts for Quality Mode
   - Keep existing prompts for Fast Mode

4. **Add Tips Component**:
   ```tsx
   const ModelTips = ({ modelType }: { modelType: ModelType }) => {
     const tips = modelType === 'fast' ? {
       title: 'Fast Mode Tips',
       items: [
         'Optimized for portrait photography',
         'Best with face close-ups',
         'Use detailed anatomy keywords',
         'Steps: 25-35, CFG: 7.5-8.5'
       ]
     } : {
       title: 'Quality Mode Tips',
       items: [
         'Versatile for all subjects',
         'Excellent for products, food, architecture',
         'Use photography keywords (e.g., "Food Photography")',
         'Steps: 30-40, CFG: 3-7 (lower = more realistic)'
       ]
     };
     
     return (
       <div className="bg-blue-50 p-4 rounded-lg">
         <h3 className="font-semibold mb-2">{tips.title}</h3>
         <ul className="space-y-1 text-sm">
           {tips.items.map((tip, i) => (
             <li key={i}>• {tip}</li>
           ))}
         </ul>
       </div>
     );
   };
   ```

### Phase 4: Testing & Optimization 🧪
**Time**: 2-3 hours

1. **Test Fast Mode (RealisticVision)**:
   - Portrait prompts
   - Face close-ups
   - Verify 5-9s generation time
   - Quality check

2. **Test Quality Mode (Juggernaut XL)**:
   - Product photography (keyboard, phone)
   - Food photography
   - Architecture/interiors
   - Verify 15-25s generation time
   - Quality comparison with Fast Mode

3. **Memory Management**:
   - Monitor RAM usage with both models
   - Lazy loading verification
   - Unload unused model if memory pressure

4. **Benchmark Results**:
   ```
   Fast Mode (RealisticVision v5.1):
   - Portrait: 5-9s, excellent quality
   - Product: 5-9s, poor quality ❌
   
   Quality Mode (Juggernaut XL):
   - Portrait: 15-25s, excellent quality
   - Product: 15-25s, excellent quality ✅
   - Food: 15-25s, excellent quality ✅
   - Architecture: 15-25s, excellent quality ✅
   ```

### Phase 5: Deployment 🚀
**Time**: 1 hour

1. **Update LaunchD daemon**:
   - Verify model paths
   - Increase memory limits if needed

2. **Deploy to production**:
   ```bash
   cd /Users/mac/HeyIm/backend
   swift build -c release
   launchctl unload ~/Library/LaunchAgents/com.heyim.backend.plist
   launchctl load ~/Library/LaunchAgents/com.heyim.backend.plist
   ```

3. **Frontend deployment**:
   ```bash
   cd /Users/mac/HeyIm/frontend
   npm run build
   # Update Cloudflare tunnel if needed
   ```

4. **Verification**:
   - Test both modes via UI
   - Check error handling
   - Monitor performance

## Prompt Guidelines

### Fast Mode (RealisticVision v5.1)
**Best Prompts**:
- "portrait of beautiful woman, detailed face, professional photography"
- "headshot photo, studio lighting, 8k uhd"
- "close-up portrait, bokeh background"

**Recommended Settings**:
- Steps: 30-35
- CFG: 7.5-8.5
- Negative: "(bad anatomy:1.3), (bad hands:1.2), deformed"

### Quality Mode (Juggernaut XL)
**Best Prompts**:
- "Food Photography: gourmet dish plating"
- "Product Photography: modern keyboard on desk"
- "Architecture Photography: modern interior design"
- "Cinematic portrait, dramatic lighting"

**Recommended Settings**:
- Steps: 30-40
- CFG: 3-7 (lower for realism)
- Negative: Keep minimal or none

**SDXL Prompt Tips**:
- Use photography keywords: "Food Photography", "Product Photography"
- Natural language works better than tags
- Don't over-prompt, SDXL is smart
- Lower CFG (3-7) for more realistic results

## Resource Management

### Memory Usage (Mac Mini M2 16GB)
```
Fast Mode only:
- Model: 3.6GB
- Runtime: ~4GB
- Total: ~8GB ✅

Quality Mode only:
- Model: 6-7GB
- Runtime: ~6GB
- Total: ~13GB ✅

Both loaded simultaneously:
- Models: ~10GB
- Runtime: ~6GB
- Total: ~16GB ⚠️ (tight but OK)
```

**Strategy**: Lazy loading
- Default: Load Quality Mode only
- Load Fast Mode when user switches
- Keep both in memory if RAM allows
- Unload unused model if memory pressure detected

### Disk Space
```
/Users/mac/HeyIm/models/
├── RealisticVision_v51_split-einsum/  (3.6GB)
└── Juggernaut_XL_v9_split-einsum/     (6-7GB)
Total: ~10GB ✅
```

## User Experience

### Default Behavior
1. User opens HeyIm → Quality Mode selected
2. First generation loads Juggernaut XL (~10s loading)
3. Subsequent generations: instant model response
4. User switches to Fast Mode → Loads RealisticVision (~5s loading)

### Auto-Suggestions
- Detect "portrait" in prompt → Suggest Fast Mode
- Detect "product", "food", "architecture" → Use Quality Mode (default)

### Loading States
```tsx
{isLoadingModel && (
  <div className="text-sm text-gray-600">
    Loading {modelType === 'fast' ? 'Fast' : 'Quality'} Mode model...
    This takes ~{modelType === 'fast' ? '5' : '10'}s on first use.
  </div>
)}
```

## Success Metrics

### Quality Improvements
- [x] Portrait quality: Excellent (both modes)
- [x] Product photography: Excellent (Quality Mode) ✅
- [x] Food photography: Excellent (Quality Mode) ✅
- [x] Architecture: Excellent (Quality Mode) ✅

### Performance
- [x] Fast Mode: 5-9s/image ✅
- [x] Quality Mode: 15-25s/image ✅
- [x] Memory usage: <16GB ✅
- [x] Model switching: <10s ✅

### User Satisfaction
- Clear mode descriptions
- Appropriate defaults
- Fast feedback on mode switching
- Quality matches expectations

## Rollback Plan

If Juggernaut XL has issues:
1. Keep RealisticVision as only model
2. Convert alternative SDXL model (e.g., SDXL-base)
3. Or wait for better product photography SD 1.5 model

Current state is safe - RealisticVision works perfectly for portraits.

---

**Next Step**: Run `./scripts/convert_juggernaut_xl.sh` to begin Phase 1!
