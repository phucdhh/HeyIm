#!/usr/bin/env bash
set -euo pipefail

# convert_juggernaut_xl.sh - Convert Juggernaut XL to Core ML
# Model: RunDiffusion/Juggernaut-XL-v9 (SDXL 1.0 based)
# Purpose: Quality Mode for products, food, architecture, versatile subjects

echo "======================================"
echo "Juggernaut XL → Core ML Conversion"
echo "======================================"
echo ""
echo "Model: RunDiffusion/Juggernaut-XL-v9"
echo "Base: SDXL 1.0 (6.62 GB)"
echo "Output: Core ML with SPLIT_EINSUM (ANE optimized)"
echo "Purpose: Quality Mode - Products, Food, Architecture"
echo ""

# Configuration
MODEL_ID="RunDiffusion/Juggernaut-XL-v9"
MODEL_NAME="Juggernaut_XL_v9"
MODELS_DIR="/Users/mac/HeyIm/models"
OUTPUT_DIR="${MODELS_DIR}/${MODEL_NAME}_split-einsum"
CONVERSION_DIR="$HOME/Documents/MochiDiffusion/conversion"

# Check if MochiDiffusion conversion env exists
if [[ ! -d "$CONVERSION_DIR" ]]; then
  echo "ERROR: MochiDiffusion conversion directory not found."
  echo "Expected: $CONVERSION_DIR"
  echo ""
  echo "Please ensure MochiDiffusion is cloned with conversion scripts."
  exit 1
fi

cd "$CONVERSION_DIR"

# Activate virtual environment
if [[ -d ".venv" ]]; then
  echo "✓ Found .venv, activating..."
  source .venv/bin/activate
else
  echo "⚠️  No .venv found. Using uv run instead."
fi

echo ""
echo "=== Conversion Pipeline ==="
echo ""

# Step 1: Download model from HuggingFace
echo "[Step 1/3] Downloading Juggernaut XL from HuggingFace..."
echo "This will download ~6.62 GB model weights."
echo ""

SAFETENSORS_FILE="${MODEL_NAME}.safetensors"

if [[ ! -f "$SAFETENSORS_FILE" ]]; then
  echo "Downloading model weights..."
  wget "https://huggingface.co/${MODEL_ID}/resolve/main/Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors" \
    -O "$SAFETENSORS_FILE" || {
    echo "ERROR: Download failed."
    echo "Please manually download from:"
    echo "  https://huggingface.co/${MODEL_ID}/tree/main"
    echo "  Correct filename: Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors"
    exit 1
  }
  echo "✓ Download complete: $SAFETENSORS_FILE"
else
  echo "✓ Model file already exists, skipping download."
fi

# Step 2: Convert safetensors → diffusers format
echo ""
echo "[Step 2/3] Converting to diffusers format..."

if [[ ! -d "${MODEL_NAME}_diffusers" ]]; then
  echo "Converting SDXL safetensors to diffusers..."
  
  uv run python convert_original_stable_diffusion_to_diffusers.py \
    --checkpoint_path "$SAFETENSORS_FILE" \
    --from_safetensors \
    --device cpu \
    --pipeline_type "stable-diffusion-xl" \
    --dump_path "${MODEL_NAME}_diffusers" || {
    echo "ERROR: Diffusers conversion failed."
    echo ""
    echo "Note: SDXL conversion may require:"
    echo "  1. Updated diffusers library (pip install -U diffusers)"
    echo "  2. Sufficient RAM (recommend 16GB+)"
    echo "  3. Use --pipeline_type stable-diffusion-xl flag"
    exit 1
  }
  
  echo "✓ Diffusers conversion complete: ${MODEL_NAME}_diffusers"
else
  echo "✓ Diffusers format already exists, skipping."
fi

# Step 3: Convert diffusers → Core ML (SPLIT_EINSUM for ANE)
echo ""
echo "[Step 3/3] Converting to Core ML (SPLIT_EINSUM for ANE)..."
echo "This takes ~30-45 minutes for SDXL. Progress will be shown..."
echo ""

mkdir -p "$OUTPUT_DIR"

# SDXL requires both text encoders and larger UNet
uv run python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-vae-decoder \
  --convert-vae-encoder \
  --convert-unet \
  --convert-text-encoder \
  --model-version "${MODEL_NAME}_diffusers" \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  --xl-version \
  -o "$OUTPUT_DIR" || {
  echo "ERROR: Core ML conversion failed."
  echo ""
  echo "Common issues:"
  echo "  1. Insufficient RAM (SDXL needs 16GB+ during conversion)"
  echo "  2. Missing --xl-version flag"
  echo "  3. Missing --convert-text-encoder-2 (SDXL requires 2 encoders)"
  echo ""
  echo "Try closing other apps and run again."
  exit 1
}

echo ""
echo "=== Conversion Complete ==="
echo "Output location: $OUTPUT_DIR"
echo ""
echo "Expected files:"
echo "  - Stable_Diffusion_version_*_unet.mlpackage"
echo "  - Stable_Diffusion_version_*_text_encoder.mlpackage"
echo "  - Stable_Diffusion_version_*_text_encoder_2.mlpackage"
echo "  - Stable_Diffusion_version_*_vae_decoder.mlpackage"
echo "  - Stable_Diffusion_version_*_vae_encoder.mlpackage"
echo "  - vocab.json, vocab_2.json"
echo "  - merges.txt, merges_2.txt"
echo ""

# Verify files
echo "Verifying converted files..."
REQUIRED_FILES=(
  "vocab.json"
  "merges.txt"
)

MISSING=0
for file in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$OUTPUT_DIR/$file" ]]; then
    echo "⚠️  Missing: $file"
    MISSING=1
  fi
done

if [[ $MISSING -eq 0 ]]; then
  echo "✓ All required files present!"
else
  echo "⚠️  Some files missing. Conversion may be incomplete."
fi

echo ""
echo "Next steps:"
echo "1. Test model with MochiDiffusion app"
echo "2. Update backend ModelService.swift to load Juggernaut XL"
echo "3. Add model selection to frontend"
echo "4. Test product photography quality"
echo ""
echo "Recommended settings for Juggernaut XL:"
echo "  - Steps: 30-40 (Quality Mode)"
echo "  - CFG Scale: 3-7"
echo "  - Scheduler: DPM++ 2M Karras"
echo "  - Resolution: 832×1216 or 1024×1024"
echo ""
echo "=== Done! ==="
