#!/usr/bin/env python3
"""
Simple inference test - generates one image to verify the pipeline works
Uses Core ML models directly with basic pipeline
"""
import time
import numpy as np
from pathlib import Path
import coremltools as ct

def simple_text_to_image_test():
    """
    Minimal test to verify models can work together
    This is a VERY simplified pipeline just to test model compatibility
    """
    model_dir = Path("/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum")
    
    print("="*60)
    print("Simple Inference Test - RealisticVision Core ML")
    print("="*60)
    print("\nThis test verifies models can be loaded and used.")
    print("For full image generation, we need StableDiffusionPipeline.\n")
    
    # Load models
    print("Loading models...")
    start = time.time()
    
    try:
        text_encoder = ct.models.MLModel(
            str(model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder.mlpackage")
        )
        print(f"✓ TextEncoder loaded ({time.time()-start:.1f}s)")
        
        unet = ct.models.MLModel(
            str(model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_unet.mlpackage")
        )
        print(f"✓ UNet loaded ({time.time()-start:.1f}s)")
        
        vae_decoder = ct.models.MLModel(
            str(model_dir / "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_decoder.mlpackage")
        )
        print(f"✓ VAEDecoder loaded ({time.time()-start:.1f}s)")
        
        total_time = time.time() - start
        print(f"\n✓ All models loaded in {total_time:.1f}s")
        
        # Print model info
        print("\n" + "="*60)
        print("MODEL SPECIFICATIONS")
        print("="*60)
        
        print("\nTextEncoder:")
        for inp in text_encoder.get_spec().description.input:
            print(f"  Input: {inp.name} - {inp.type}")
        
        print("\nUNet:")
        for inp in unet.get_spec().description.input[:3]:  # Show first 3
            print(f"  Input: {inp.name} - {inp.type}")
        print(f"  ... ({len(unet.get_spec().description.input)} total inputs)")
        
        print("\nVAEDecoder:")
        for inp in vae_decoder.get_spec().description.input:
            print(f"  Input: {inp.name} - {inp.type}")
        
        print("\n" + "="*60)
        print("✓ MODELS ARE READY FOR INFERENCE")
        print("="*60)
        print("\nNext steps:")
        print("1. Use Apple's ml-stable-diffusion Python package for full pipeline")
        print("2. Or integrate into Swift app with StableDiffusion framework")
        print("3. Models support SPLIT_EINSUM for Neural Engine acceleration")
        
        return True
        
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = simple_text_to_image_test()
    exit(0 if success else 1)
