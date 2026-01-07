#!/usr/bin/env swift

import Foundation
import CoreML

print("🔨 Pre-compiling Core ML models...")

let basePath = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
let models = [
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_unet",
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder",
    "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_decoder"
]

for modelName in models {
    let modelPath = "\(basePath)/\(modelName).mlpackage"
    let modelURL = URL(fileURLWithPath: modelPath)
    
    print("\n📦 Compiling: \(modelName)")
    print("   Source: \(modelPath)")
    
    do {
        let compiledURL = try MLModel.compileModel(at: modelURL)
        print("   ✓ Compiled to: \(compiledURL.path)")
        
        // Get size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: compiledURL.path),
           let size = attrs[.size] as? Int64 {
            let sizeMB = Double(size) / 1_000_000.0
            print("   ✓ Size: \(String(format: "%.1f", sizeMB)) MB")
        }
        
    } catch {
        print("   ❌ Failed: \(error)")
    }
}

print("\n✅ Compilation complete!")
