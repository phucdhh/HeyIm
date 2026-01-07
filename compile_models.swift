#!/usr/bin/env swift

import Foundation
import CoreML

let modelsDir = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"

let models = [
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder.mlpackage",
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_unet.mlpackage",
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_decoder.mlpackage",
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_encoder.mlpackage"
]

let outputNames = [
    "TextEncoder.mlmodelc",
    "Unet.mlmodelc",
    "VAEDecoder.mlmodelc",
    "VAEEncoder.mlmodelc"
]

print("🔨 Compiling Core ML models...")

for (model, output) in zip(models, outputNames) {
    let modelURL = URL(fileURLWithPath: "\(modelsDir)/\(model)")
    let outputURL = URL(fileURLWithPath: "\(modelsDir)/\(output)")
    
    print("Compiling \(model)...")
    
    do {
        // Compile the model
        let compiledURL = try MLModel.compileModel(at: modelURL)
        
        // Remove existing output if it exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Move compiled model to final location
        try FileManager.default.moveItem(at: compiledURL, to: outputURL)
        
        print("✅ Created \(output)")
    } catch {
        print("❌ Failed to compile \(model): \(error)")
    }
}

print("✅ All models compiled!")
