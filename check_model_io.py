#!/usr/bin/env python3
"""
Quick script to check CoreML model input/output specifications
"""
import coremltools as ct
import sys

model_path = sys.argv[1] if len(sys.argv) > 1 else "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum/Stable_Diffusion_version_RealisticVision_v51_diffusers_unet.mlpackage"

print(f"\n📦 Loading model: {model_path.split('/')[-1]}\n")

model = ct.models.MLModel(model_path)
spec = model.get_spec()

print("=" * 60)
print("INPUTS:")
print("=" * 60)
for input_desc in spec.description.input:
    print(f"  {input_desc.name}")
    if input_desc.type.HasField('multiArrayType'):
        ma = input_desc.type.multiArrayType
        shape = [d for d in ma.shape]
        print(f"    Shape: {shape}")
        print(f"    DataType: {ma.dataType}")
    print()

print("=" * 60)
print("OUTPUTS:")
print("=" * 60)
for output_desc in spec.description.output:
    print(f"  {output_desc.name}")
    if output_desc.type.HasField('multiArrayType'):
        ma = output_desc.type.multiArrayType
        shape = [d for d in ma.shape]
        print(f"    Shape: {shape}")
        print(f"    DataType: {ma.dataType}")
    print()
