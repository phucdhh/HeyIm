# Implementation Plan: Apple StableDiffusion Framework

## Switch from Manual to Apple's Framework

### Step 1: Add Package Dependency

Update `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/apple/ml-stable-diffusion", branch: "main"),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0")
],
targets: [
    .executableTarget(
        name: "HeyImServer",
        dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "StableDiffusion", package: "ml-stable-diffusion")
        ]
    )
]
```

### Step 2: Simplify ModelService

```swift
import StableDiffusion

actor ModelService {
    private var pipeline: StableDiffusionPipeline?
    
    func loadModels() async throws {
        let resourcePath = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
        let resourceURL = URL(fileURLWithPath: resourcePath)
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        
        self.pipeline = try StableDiffusionPipeline(
            resourcesAt: resourceURL,
            configuration: .init(modelConfiguration: config)
        )
    }
    
    func generateImage(
        prompt: String,
        negativePrompt: String = "",
        steps: Int = 30,
        guidanceScale: Float = 7.5,
        seed: UInt32? = nil
    ) async throws -> CGImage {
        guard let pipeline = pipeline else {
            throw ModelServiceError.notLoaded
        }
        
        let config = StableDiffusionPipeline.Configuration(
            prompt: prompt,
            negativePrompt: negativePrompt,
            stepCount: steps,
            seed: seed ?? UInt32.random(in: 0...UInt32.max),
            guidanceScale: guidanceScale
        )
        
        let images = try pipeline.generateImages(configuration: config)
        guard let image = images.first else {
            throw ModelServiceError.noImageGenerated
        }
        
        return image
    }
}
```

### Step 3: Remove Custom Files

Can delete:
- `Tokenizer.swift`
- `StableDiffusionPipeline.swift`  

Keep:
- `ModelService.swift` (simplified)
- `Models.swift`
- `main.swift`

### Benefits

1. **Proven Implementation**: Apple's code is production-tested
2. **Better Error Handling**: Proper Swift error types
3. **Optimized**: Performance tuned for Apple Silicon
4. **Less Code**: ~500 lines → ~50 lines
5. **Maintainable**: Framework updates benefit us

### Risks

1. **Model Format**: Need to verify our models work with Apple's loader
2. **Dependencies**: Larger dependency tree
3. **Less Control**: Can't customize pipeline easily

### Decision

Given debugging difficulties and time constraints, **recommend switching to Apple's framework** for Phase 2 completion. Can always revert to custom implementation in Phase 3 if needed.
