#!/usr/bin/env python3
"""
Compile .mlpackage files to .mlmodelc for deployment
"""
import os
import sys
from pathlib import Path
import coremltools as ct

def compile_model(mlpackage_path, output_dir):
    """Compile a single mlpackage to mlmodelc"""
    mlpackage_path = Path(mlpackage_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    model_name = mlpackage_path.stem
    output_path = output_dir / f"{model_name}.mlmodelc"
    
    print(f"Compiling {mlpackage_path.name}...")
    try:
        # Load and compile
        model = ct.models.MLModel(str(mlpackage_path))
        model.save(str(output_path))
        print(f"✓ Compiled to {output_path}")
        return True
    except Exception as e:
        print(f"✗ Error compiling {mlpackage_path.name}: {e}")
        return False

def main():
    model_dir = Path("/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum")
    output_dir = model_dir / "compiled"
    
    mlpackages = list(model_dir.glob("*.mlpackage"))
    print(f"Found {len(mlpackages)} models to compile\n")
    
    success_count = 0
    for mlpackage in mlpackages:
        if compile_model(mlpackage, output_dir):
            success_count += 1
        print()
    
    print(f"Compilation complete: {success_count}/{len(mlpackages)} successful")

if __name__ == "__main__":
    main()
