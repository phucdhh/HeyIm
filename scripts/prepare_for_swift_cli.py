#!/usr/bin/env python3
"""
Compile .mlpackage to .mlmodelc using xcrun coremlcompiler alternative
Since coremlcompiler requires Xcode, we'll use a workaround with coremltools
"""
import coremltools as ct
import shutil
import subprocess
from pathlib import Path

def compile_with_python(mlpackage_path, output_dir):
    """
    Load mlpackage and save as mlmodelc
    Note: This creates an uncompiled .mlmodel first, then we need system tools
    """
    mlpackage_path = Path(mlpackage_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    model_name = mlpackage_path.stem
    print(f"Processing {model_name}...")
    
    try:
        # Try using xcrun (even without full Xcode, sometimes works)
        output_path = output_dir / f"{model_name}.mlmodelc"
        
        result = subprocess.run(
            ["xcrun", "coremlcompiler", "compile", str(mlpackage_path), str(output_dir)],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print(f"✓ Compiled {model_name}")
            return True
        else:
            print(f"✗ xcrun failed: {result.stderr}")
            print("  Trying alternative method...")
            
            # Alternative: Just copy .mlpackage as-is (some tools can load it)
            alt_output = output_dir / mlpackage_path.name
            if alt_output.exists():
                shutil.rmtree(alt_output)
            shutil.copytree(mlpackage_path, alt_output, symlinks=True)
            print(f"✓ Copied {model_name} (runtime will compile on first load)")
            return True
            
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def main():
    model_dir = Path("/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum")
    output_dir = model_dir  # Compile in same directory
    
    # Standard model names needed by Swift CLI
    models_to_compile = {
        "Stable_Diffusion_version_RealisticVision_v51_diffusers_unet.mlpackage": "Unet",
        "Stable_Diffusion_version_RealisticVision_v51_diffusers_text_encoder.mlpackage": "TextEncoder",
        "Stable_Diffusion_version_RealisticVision_v51_diffusers_vae_decoder.mlpackage": "VAEDecoder",
    }
    
    print("Attempting to compile models...")
    print("Note: Without full Xcode, models will be loaded as .mlpackage\n")
    
    for source_name, target_name in models_to_compile.items():
        source_path = model_dir / source_name
        if source_path.exists():
            # Try compiling or copying
            compile_with_python(source_path, output_dir)
            
            # Create symlink with standard name if needed
            link_name_mlpackage = output_dir / f"{target_name}.mlpackage"
            if not link_name_mlpackage.exists():
                link_name_mlpackage.symlink_to(source_name)
                print(f"  → Created symlink: {target_name}.mlpackage")
        else:
            print(f"✗ Not found: {source_name}")
    
    print("\n✓ Setup complete!")
    print("\nModels can be used with:")
    print(f"  --resource-path {model_dir}")

if __name__ == "__main__":
    main()
