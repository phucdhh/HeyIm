import Vapor

struct GenerateRequest: Content {
    let prompt: String
    let negativePrompt: String?
    let steps: Int?
    let cfgScale: Float?
    let seed: UInt32?
    let width: Int?
    let height: Int?
    let modelType: String?  // "fast" or "quality"
    
    // Image-to-Image fields
    let inputImage: String?  // base64 encoded input image
    let strength: Float?     // denoising strength (0.1 to 1.0)
    
    // Validation
    func validate() throws {
        guard !prompt.isEmpty else {
            throw Abort(.badRequest, reason: "Prompt cannot be empty")
        }
        
        if let steps = steps {
            guard steps >= 10 && steps <= 100 else {
                throw Abort(.badRequest, reason: "Steps must be between 10 and 100")
            }
        }
        
        if let cfg = cfgScale {
            guard cfg >= 1.0 && cfg <= 20.0 else {
                throw Abort(.badRequest, reason: "CFG scale must be between 1.0 and 20.0")
            }
        }
        
        if let strength = strength {
            guard strength >= 0.1 && strength <= 1.0 else {
                throw Abort(.badRequest, reason: "Strength must be between 0.1 and 1.0")
            }
        }
    }
}

struct GenerateResponse: Content {
    let success: Bool
    let imageBase64: String?
    let error: String?
    let metadata: GenerationMetadata?
}

struct GenerationMetadata: Content {
    let prompt: String
    let negativePrompt: String
    let steps: Int
    let cfgScale: Float
    let seed: UInt32
    let generationTime: Double
    let modelType: String  // Track which model was used
    
    // Image-to-Image metadata
    let hasInputImage: Bool
    let strength: Float?
}

struct StatusResponse: Content {
    let modelStatus: String
    let queueSize: Int
    let isGenerating: Bool
}
