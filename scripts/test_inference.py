#!/usr/bin/env python3
"""
Test RealisticVision Core ML models with basic inference
Uses python_coreml_stable_diffusion from Apple's ml-stable-diffusion
"""
import sys
import time
from pathlib import Path

# Add Apple's Python package to path
sys.path.insert(0, str(Path.home() / "Documents/ml-stable-diffusion"))

try:
    from python_coreml_stable_diffusion import pipeline
    import numpy as np
    from PIL import Image
except ImportError as e:
    print(f"Error importing dependencies: {e}")
    print("Please ensure python_coreml_stable_diffusion is available")
    sys.exit(1)

def main():
    model_path = "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
    output_path = "/Users/mac/HeyIm/benchmarks/results/test_output.png"
    
    print(f"Loading models from: {model_path}")
    print("This may take 30-60 seconds on first load...\n")
    
    # Create pipeline
    try:
        pipe = pipeline.StableDiffusionPipeline(
            model_path,
            compute_unit="CPU_AND_NE",  # CPU + Neural Engine
            model_version="stabilityai/stable-diffusion-v1-5"
        )
        print("✓ Pipeline loaded successfully!\n")
    except Exception as e:
        print(f"✗ Error loading pipeline: {e}")
        return 1
    
    # Test generation
    prompt = "portrait photo of a beautiful woman, professional lighting, detailed face, natural skin texture"
    negative_prompt = "ugly, blurry, low quality, distorted, deformed"
    
    print(f"Prompt: {prompt}")
    print(f"Negative: {negative_prompt}")
    print(f"Steps: 20, Guidance: 7.5, Seed: 42\n")
    print("Generating image...")
    
    start_time = time.time()
    
    try:
        images = pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            num_inference_steps=20,
            guidance_scale=7.5,
            seed=42,
            num_images_per_prompt=1
        )
        
        elapsed = time.time() - start_time
        
        if images and len(images) > 0:
            image = images[0]
            if isinstance(image, np.ndarray):
                image = Image.fromarray(image.astype('uint8'))
            
            image.save(output_path)
            print(f"\n✓ Image generated successfully!")
            print(f"  Output: {output_path}")
            print(f"  Time: {elapsed:.2f}s")
            print(f"  Size: {image.size}")
            return 0
        else:
            print("✗ No images generated")
            return 1
            
    except Exception as e:
        print(f"\n✗ Error during generation: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
