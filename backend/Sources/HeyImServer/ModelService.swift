import Foundation
import CoreML
import StableDiffusion

/// Service to manage Stable Diffusion pipeline (Fast Mode only)
actor ModelService {
    static let shared = ModelService()
    
    // Single pipeline - RealisticVision v5.1 only
    private var pipeline: StableDiffusionPipeline?
    
    private var isLoading = false
    private var isGenerating = false
    
    private init() {}
    
    /// Load RealisticVision model
    func loadModel() async throws {
        // Check if already loaded
        if pipeline != nil {
            print("✅ RealisticVision already loaded")
            return
        }
        
        // Prevent concurrent loading
        guard !isLoading else {
            throw ModelServiceError.alreadyLoading
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let modelPath = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
        let resourceURL = URL(fileURLWithPath: modelPath)
        
        print("🔄 Loading RealisticVision v5.1 from: \(modelPath)")
        
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            
            print("  Initializing pipeline...")
            if #available(macOS 14.0, *) {
                let loadedPipeline = try StableDiffusionPipeline(
                    resourcesAt: resourceURL,
                    controlNet: [],
                    configuration: config,
                    disableSafety: true,
                    reduceMemory: false
                )
                self.pipeline = loadedPipeline
                print("✅ RealisticVision v5.1 loaded successfully (ANE optimized)")
                
            } else {
                throw ModelServiceError.loadFailed("macOS 14+ required")
            }
            
        } catch {
            print("❌ Failed to load pipeline: \(error)")
            throw ModelServiceError.loadFailed(error.localizedDescription)
        }
    }
    
    /// Load models (alias for compatibility)
    func loadModels() async throws {
        try await loadModel()
    }
    
    /// Get model status
    func getStatus() -> ModelStatus {
        if pipeline != nil {
            return .loaded
        } else if isLoading {
            return .loading
        } else {
            return .notLoaded
        }
    }
    
    /// Check if models are loaded
    func areModelsLoaded() -> Bool {
        return pipeline != nil
    }
    
    /// Check if currently generating
    func isCurrentlyGenerating() -> Bool {
        return isGenerating
    }
    
    /// Generate image from text prompt (with optional img2img)
    func generateImage(
        prompt: String,
        negativePrompt: String = "",
        steps: Int = 30,
        guidanceScale: Float = 7.5,
        seed: UInt32? = nil,
        inputImage: CGImage? = nil,
        strength: Float? = nil
    ) async throws -> CGImage {
        print("🎬 Starting generation...")
        
        // Load model if not already loaded
        try await loadModel()
        
        guard !isGenerating else {
            print("   ❌ Already generating!")
            throw ModelServiceError.generationFailed("Already generating")
        }
        
        guard let pipeline = pipeline else {
            throw ModelServiceError.generationFailed("Model not loaded")
        }
        
        isGenerating = true
        defer { 
            isGenerating = false
            print("   ✓ Generation flag cleared")
        }
        
        print("   Prompt: \(prompt)")
        print("   Negative: \(negativePrompt)")
        print("   Steps: \(steps), CFG: \(guidanceScale)")
        
        do {
            let actualSeed = seed ?? UInt32.random(in: 0...UInt32.max)
            
            var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)
            pipelineConfig.negativePrompt = negativePrompt
            pipelineConfig.imageCount = 1
            pipelineConfig.stepCount = steps
            pipelineConfig.seed = actualSeed
            pipelineConfig.guidanceScale = Float(guidanceScale)
            pipelineConfig.disableSafety = true
            
            // Image-to-Image configuration
            if let inputImg = inputImage {
                print("   🖼️  Using img2img mode")
                print("   Input image size: \(inputImg.width)x\(inputImg.height)")
                
                // Resize image to 512x512 for Stable Diffusion
                guard let resizedImg = ModelService.resizeImage(inputImg) else {
                    throw ModelServiceError.generationFailed("Failed to resize input image")
                }
                print("   Resized to: \(resizedImg.width)x\(resizedImg.height)")
                
                pipelineConfig.startingImage = resizedImg
                pipelineConfig.strength = strength ?? 0.75
                
                // Use PNDM scheduler for better img2img quality (preserves structure better)
                pipelineConfig.schedulerType = .pndmScheduler
                
                // Boost CFG slightly for img2img to maintain subject identity
                if pipelineConfig.guidanceScale < 9.0 {
                    pipelineConfig.guidanceScale = min(pipelineConfig.guidanceScale + 1.5, 10.0)
                    print("   CFG boosted to: \(pipelineConfig.guidanceScale) for img2img")
                }
                
                print("   Strength: \(pipelineConfig.strength)")
                print("   Scheduler: PNDM (optimized for img2img)")
            } else {
                // Use DPM++ for text-to-image (faster)
                pipelineConfig.schedulerType = .dpmSolverMultistepScheduler
            }
            
            print("   Calling pipeline.generateImages()...")
            
            let images = try pipeline.generateImages(
                configuration: pipelineConfig,
                progressHandler: { progress in
                    if progress.stepCount > 0 && progress.step % 5 == 0 {
                        print("   Step \(progress.step)/\(progress.stepCount)")
                    }
                    return true
                }
            )
            
            guard let firstImage = images.first, let image = firstImage else {
                print("   ❌ No image generated")
                throw ModelServiceError.generationFailed("No image generated")
            }
            
            print("✅ Generation completed!")
            return image
            
        } catch {
            print("❌ Generation error: \(error)")
            throw ModelServiceError.generationFailed("Generation failed: \(error.localizedDescription)")
        }
    }
}

enum ModelStatus: String, Codable {
    case notLoaded = "not_loaded"
    case loading = "loading"
    case loaded = "loaded"
}

enum ModelServiceError: Error {
    case alreadyLoading
    case loadFailed(String)
    case generationFailed(String)
    case noImagesGenerated
}

// MARK: - Helper Functions
extension ModelService {
    /// Convert base64 string to CGImage
    static func base64ToCGImage(_ base64String: String) -> CGImage? {
        guard let data = Data(base64Encoded: base64String) else {
            print("❌ Failed to decode base64 string")
            return nil
        }
        
        guard let dataProvider = CGDataProvider(data: data as CFData) else {
            print("❌ Failed to create data provider")
            return nil
        }
        
        // Try different image formats
        if let image = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
            return image
        }
        
        if let image = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) {
            return image
        }
        
        // Fallback: use ImageIO
        guard let imageSource = CGImageSourceCreateWithDataProvider(dataProvider, nil) else {
            print("❌ Failed to create image source")
            return nil
        }
        
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }
    
    /// Resize CGImage to 512x512 for Stable Diffusion (preserving aspect ratio with padding)
    static func resizeImage(_ image: CGImage, to size: CGSize = CGSize(width: 512, height: 512)) -> CGImage? {
        let targetWidth = Int(size.width)
        let targetHeight = Int(size.height)
        let bitsPerComponent = 8
        let bytesPerRow = targetWidth * 4
        
        // Calculate aspect fit dimensions
        let sourceWidth = CGFloat(image.width)
        let sourceHeight = CGFloat(image.height)
        let sourceAspect = sourceWidth / sourceHeight
        let targetAspect = size.width / size.height
        
        var drawWidth: CGFloat
        var drawHeight: CGFloat
        
        if sourceAspect > targetAspect {
            // Image is wider - fit to width
            drawWidth = size.width
            drawHeight = size.width / sourceAspect
        } else {
            // Image is taller - fit to height
            drawHeight = size.height
            drawWidth = size.height * sourceAspect
        }
        
        // Center the image
        let x = (size.width - drawWidth) / 2
        let y = (size.height - drawHeight) / 2
        
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("❌ Failed to create CGContext for resize")
            return nil
        }
        
        // Fill with white background (better for portrait photos)
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        // Draw image centered with aspect fit
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: x, y: y, width: drawWidth, height: drawHeight))
        
        return context.makeImage()
    }
}
