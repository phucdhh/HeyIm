#!/usr/bin/env swift

import Foundation
import CoreML
import StableDiffusion
import UniformTypeIdentifiers

// Load model pipeline
let resourceURL = URL(fileURLWithPath: "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum")

print("Loading Stable Diffusion pipeline from: \(resourceURL.path)")

let config = MLModelConfiguration()
config.computeUnits = .cpuAndNeuralEngine

do {
    let pipeline = try StableDiffusionPipeline(
        resourcesAt: resourceURL,
        configuration: config,
        disableSafety: false,
        reduceMemory: false
    )
    
    print("✓ Pipeline loaded successfully!")
    print("Generating image...")
    
    let prompt = "portrait photo of a beautiful woman, professional lighting, detailed face"
    let negativePrompt = "ugly, blurry, low quality"
    
    let images = try pipeline.generateImages(
        prompt: prompt,
        negativePrompt: negativePrompt,
        imageCount: 1,
        stepCount: 20,
        seed: 42,
        guidanceScale: 7.5,
        disableSafety: false
    )
    
    if let cgImage = images.compactMap({ $0 }).first {
        let outputURL = URL(fileURLWithPath: "/Users/mac/HeyIm/benchmarks/results/test_output.png")
        let destData = cfDataFromCGImage(cgImage)!
        let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImageFromSource(dest, destData, 0, nil)
        
        if CGImageDestinationFinalize(dest) {
            print("✓ Image saved to: \(outputURL.path)")
        }
    }
    
} catch {
    print("✗ Error: \(error)")
}

func cfDataFromCGImage(_ cgImage: CGImage) -> CGImageSource? {
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(dest, cgImage, nil)
    guard CGImageDestinationFinalize(dest) else { return nil }
    return CGImageSourceCreateWithData(data, nil)
}
