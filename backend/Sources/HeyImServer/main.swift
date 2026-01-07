import Vapor
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)

do {
    try await configure(app)
    try await app.execute()
} catch {
    app.logger.report(error: error)
    try? await app.asyncShutdown()
    throw error
}

func configure(_ app: Application) async throws {
    // Configure server
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 5858
    
    // Increase request body size limit for image uploads (10MB)
    app.routes.defaultMaxBodySize = "10mb"
    
    // Configure CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors)
    
    // Configure routes
    try routes(app)
    
    app.logger.info("🚀 HeyIm Server starting on port 5858")
}

func routes(_ app: Application) throws {
    // Health check
    app.get("health") { req async -> String in
        return "OK"
    }
    
    // API routes
    let api = app.grouped("api")
    
    // Info endpoint
    api.get("info") { req async throws -> [String: String] in
        return [
            "name": "HeyIm AI Image Generation",
            "version": "0.1.0",
            "status": "ready",
            "model_path": "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
        ]
    }
    
    // Status endpoint
    api.get("status") { req async throws -> StatusResponse in
        let modelService = ModelService.shared
        let status = await modelService.getStatus()
        let isGen = await modelService.isCurrentlyGenerating()
        
        return StatusResponse(
            modelStatus: status.rawValue,
            queueSize: 0,
            isGenerating: isGen
        )
    }
    
    // Load models endpoint
    api.post("load") { req async throws -> [String: String] in
        let modelService = ModelService.shared
        try await modelService.loadModels()
        
        return [
            "success": "true",
            "message": "Models loaded successfully"
        ]
    }
    
    // Generate endpoint (Fast Mode only - RealisticVision)
    api.post("generate") { req async throws -> GenerateResponse in
        let generateReq = try req.content.decode(GenerateRequest.self)
        try generateReq.validate()
        
        let modelService = ModelService.shared
        
        // Ensure model is loaded
        try await modelService.loadModel()
        
        let prompt = generateReq.prompt
        
        // Enhanced negative prompt for img2img to preserve face structure
        let defaultNegative = generateReq.inputImage != nil 
            ? "ugly, deformed, disfigured, bad anatomy, malformed face, bad face, distorted face, mutation, mutated, extra limbs, missing limbs, floating limbs, disconnected limbs, long neck, low quality, blurry"
            : "ugly, blurry, low quality, distorted, deformed"
        
        let negativePrompt = generateReq.negativePrompt ?? defaultNegative
        let steps = generateReq.steps ?? 30
        let cfgScale = generateReq.cfgScale ?? 8.0
        let seed = generateReq.seed ?? UInt32.random(in: 0...UInt32.max)
        
        // Handle img2img parameters
        let inputImage: CGImage? 
        let strength: Float?
        
        if let base64Image = generateReq.inputImage {
            inputImage = ModelService.base64ToCGImage(base64Image)
            strength = generateReq.strength ?? 0.75
            if inputImage == nil {
                return GenerateResponse(
                    success: false,
                    imageBase64: nil,
                    error: "Failed to decode input image",
                    metadata: nil
                )
            }
        } else {
            inputImage = nil
            strength = nil
        }
        
        let startTime = Date()
        
        do {
            let image = try await modelService.generateImage(
                prompt: prompt,
                negativePrompt: negativePrompt,
                steps: steps,
                guidanceScale: Float(cfgScale),
                seed: seed,
                inputImage: inputImage,
                strength: strength
            )
            
            let generationTime = Date().timeIntervalSince(startTime)
            
            // Convert CGImage to PNG base64
            let imageData = try cgImageToPNGData(image)
            let base64 = imageData.base64EncodedString()
            
            let metadata = GenerationMetadata(
                prompt: prompt,
                negativePrompt: negativePrompt,
                steps: steps,
                cfgScale: cfgScale,
                seed: seed,
                generationTime: generationTime,
                modelType: "fast",  // Always Fast Mode (RealisticVision)
                hasInputImage: inputImage != nil,
                strength: strength
            )
            
            return GenerateResponse(
                success: true,
                imageBase64: base64,
                error: nil,
                metadata: metadata
            )
            
        } catch {
            return GenerateResponse(
                success: false,
                imageBase64: nil,
                error: error.localizedDescription,
                metadata: nil
            )
        }
    }
    
    app.logger.info("✓ Routes configured")
}

// Helper function to convert CGImage to PNG data
func cgImageToPNGData(_ image: CGImage) throws -> Data {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data as CFMutableData,
        UTType.png.identifier as CFString,
        1,
        nil as CFDictionary?
    ) else {
        throw Abort(.internalServerError, reason: "Failed to create image destination")
    }
    
    CGImageDestinationAddImage(destination, image, nil as CFDictionary?)
    
    guard CGImageDestinationFinalize(destination) else {
        throw Abort(.internalServerError, reason: "Failed to finalize image")
    }
    
    return data as Data
}
