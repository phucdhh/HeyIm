#!/usr/bin/env swift

import Foundation
import CoreML

print("🧪 Testing CoreML model loading and inference...")

let basePath = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"

// Test 1: Compile and load text encoder
print("\n1️⃣ Testing Text Encoder...")
let textEncoderPath = "\(basePath)/Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder.mlpackage"
let textEncoderURL = URL(fileURLWithPath: textEncoderPath)

do {
    print("   Compiling...")
    let compiledURL = try MLModel.compileModel(at: textEncoderURL)
    print("   ✓ Compiled to: \(compiledURL.path)")
    
    print("   Loading model...")
    let config = MLModelConfiguration()
    config.computeUnits = .cpuAndNeuralEngine
    let model = try MLModel(contentsOf: compiledURL, configuration: config)
    print("   ✓ Model loaded")
    
    // Test inference
    print("   Testing inference...")
    let inputArray = try MLMultiArray(shape: [1, 77] as [NSNumber], dataType: .int32)
    for i in 0..<77 {
        inputArray[i] = NSNumber(value: i < 2 ? 49406 : 49407) // BOS and PAD tokens
    }
    
    let input = try MLDictionaryFeatureProvider(dictionary: ["input_ids": MLFeatureValue(multiArray: inputArray)])
    let output = try model.prediction(from: input)
    
    if let embedding = output.featureValue(for: "last_hidden_state")?.multiArrayValue {
        print("   ✓ Inference successful!")
        print("   Output shape: \(embedding.shape)")
    } else {
        print("   ❌ Could not get output")
    }
    
} catch {
    print("   ❌ Error: \(error)")
}

print("\n✅ Test complete")
