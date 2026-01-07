#!/usr/bin/env python3
"""
Simple inference test using Core ML models directly
Uses the converted .mlpackage files
"""
import time
from pathlib import Path
import sys

# Add MochiDiffusion conversion env to path
sys.path.insert(0, str(Path.home() / "Documents/MochiDiffusion/conversion/.venv/lib/python3.8/site-packages"))

try:
    import coremltools as ct
    print("✓ CoreMLTools imported")
except ImportError:
    print("✗ CoreMLTools not found")
    sys.exit(1)

def test_model_loading():
    """Test loading individual Core ML models"""
    model_dir = Path("/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum")
    
    models = {
        "UNet": model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_unet.mlpackage",
        "TextEncoder": model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder.mlpackage",
        "VAEDecoder": model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_decoder.mlpackage",
    }
    
    print(f"\nTesting model loading from: {model_dir}\n")
    
    results = {}
    for name, path in models.items():
        print(f"Loading {name}...")
        start = time.time()
        try:
            model = ct.models.MLModel(str(path))
            elapsed = time.time() - start
            
            # Get model info
            spec = model.get_spec()
            print(f"  ✓ Loaded in {elapsed:.2f}s")
            print(f"    Inputs: {len(spec.description.input)}")
            print(f"    Outputs: {len(spec.description.output)}")
            
            results[name] = "SUCCESS"
        except Exception as e:
            print(f"  ✗ Error: {e}")
            results[name] = f"FAILED: {e}"
        print()
    
    return results

def main():
    print("="*60)
    print("RealisticVision Core ML Model Test")
    print("="*60)
    
    results = test_model_loading()
    
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    for model, status in results.items():
        symbol = "✓" if status == "SUCCESS" else "✗"
        print(f"{symbol} {model}: {status}")
    
    all_success = all(v == "SUCCESS" for v in results.values())
    
    if all_success:
        print("\n✓ All models loaded successfully!")
        print("\nModels are ready for inference.")
        print("To generate images, you'll need to:")
        print("  1. Install full Xcode for Swift CLI, OR")
        print("  2. Use Python with StableDiffusionPipeline, OR")
        print("  3. Build custom Swift app with StableDiffusion framework")
        return 0
    else:
        print("\n✗ Some models failed to load")
        return 1

if __name__ == "__main__":
    sys.exit(main())
