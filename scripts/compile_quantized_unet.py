#!/usr/bin/env python3
"""Compile quantized UNet mlpackage to mlmodelc format for backend usage."""

import coremltools as ct
import shutil
import os
from pathlib import Path

# Paths
quantized_dir = Path("/Users/mac/HeyIm/models/Juggernaut_XL_v9_quantized8bit")
split_einsum_dir = Path("/Users/mac/HeyIm/models/Juggernaut_XL_v9_split-einsum")

print("=" * 70)
print("Compiling Quantized SDXL Models for ANE")
print("=" * 70)
print()

# 1. Compile quantized UNet
print("📦 Step 1: Compiling quantized UNet...")
unet_package = quantized_dir / "Stable_Diffusion_version__Users_mac_HeyIm_models_Juggernaut_XL_v9_diffusers_unet.mlpackage"

if unet_package.exists():
    print(f"   Loading: {unet_package.name}")
    model = ct.models.MLModel(str(unet_package))
    
    print("   Compiling...")
    compiled_path = model.get_compiled_model_path()
    
    target_mlmodelc = quantized_dir / "Unet.mlmodelc"
    if target_mlmodelc.exists():
        print(f"   Removing old: {target_mlmodelc}")
        shutil.rmtree(target_mlmodelc)
    
    print(f"   Copying to: {target_mlmodelc}")
    shutil.copytree(compiled_path, target_mlmodelc)
    
    size_mb = sum(f.stat().st_size for f in target_mlmodelc.rglob('*') if f.is_file()) / (1024**2)
    print(f"   ✅ Done! Size: {size_mb:.1f} MB")
else:
    print(f"   ❌ Not found: {unet_package}")
    exit(1)

print()

# 2. Copy other models from split-einsum directory
print("📋 Step 2: Copying other models from split-einsum...")
models_to_copy = [
    "TextEncoder.mlmodelc",
    "TextEncoder2.mlmodelc",
    "VAEDecoder.mlmodelc",
    "VAEEncoder.mlmodelc"
]

for model_name in models_to_copy:
    source = split_einsum_dir / model_name
    target = quantized_dir / model_name
    
    if source.exists():
        if target.exists():
            print(f"   Skipping (exists): {model_name}")
        else:
            print(f"   Copying: {model_name}")
            shutil.copytree(source, target)
            size_mb = sum(f.stat().st_size for f in target.rglob('*') if f.is_file()) / (1024**2)
            print(f"   ✅ {size_mb:.1f} MB")
    else:
        print(f"   ❌ Not found: {source}")

print()

# 3. Copy vocab files
print("📝 Step 3: Copying vocabulary files...")
vocab_files = [
    "vocab.json",
    "vocab_2.json",
    "merges.txt",
    "merges_2.txt"
]

for filename in vocab_files:
    source = split_einsum_dir / filename
    target = quantized_dir / filename
    
    if source.exists():
        shutil.copy2(source, target)
        print(f"   ✅ {filename}")
    else:
        print(f"   ⚠️  Not found: {filename}")

print()

# 4. Summary
print("=" * 70)
print("✅ Compilation Complete!")
print("=" * 70)
print()
print("📁 Model directory:", quantized_dir)
print()
print("📊 Final sizes:")
for item in sorted(quantized_dir.iterdir()):
    if item.is_dir() and (item.suffix == ".mlmodelc" or item.suffix == ".mlpackage"):
        size_mb = sum(f.stat().st_size for f in item.rglob('*') if f.is_file()) / (1024**2)
        print(f"   {item.name}: {size_mb:.1f} MB")

total_size_gb = sum(f.stat().st_size for f in quantized_dir.rglob('*') if f.is_file()) / (1024**3)
print()
print(f"Total: {total_size_gb:.2f} GB")
print()
print("🚀 Next: Update ModelService.swift to use quantized model")
print(f"   Path: {quantized_dir}")
