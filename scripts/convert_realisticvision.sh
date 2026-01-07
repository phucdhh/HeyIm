#!/usr/bin/env bash
set -euo pipefail

# convert_realisticvision.sh — Tự động tải và convert RealisticVision v5.1 sang Core ML
# 
# Yêu cầu:
# - MochiDiffusion repo đã clone và setup (conversion env)
# - Hugging Face CLI (huggingface-cli) hoặc git-lfs
# - Python 3.10+, uv, Xcode CLT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="${PROJECT_ROOT}/models"
MOCHI_CONVERSION_DIR="${HOME}/Documents/MochiDiffusion/conversion"

MODEL_ID="SG161222/Realistic_Vision_V5.1_noVAE"
MODEL_NAME="RealisticVision_v51"
OUTPUT_DIR="${MODELS_DIR}/${MODEL_NAME}_split-einsum"

echo "=== RealisticVision v5.1 Conversion Pipeline ==="
echo "Model: ${MODEL_ID}"
echo "Output: ${OUTPUT_DIR}"
echo ""

# Kiểm tra MochiDiffusion conversion env
if [[ ! -d "$MOCHI_CONVERSION_DIR" ]]; then
  echo "ERROR: MochiDiffusion conversion directory not found at $MOCHI_CONVERSION_DIR"
  echo "Please clone and setup MochiDiffusion first:"
  echo "  git clone https://github.com/MochiDiffusion/MochiDiffusion.git ~/MochiDiffusion"
  echo "  cd ~/MochiDiffusion/conversion"
  echo "  uv venv"
  echo "  ./download-script.sh"
  exit 1
fi

cd "$MOCHI_CONVERSION_DIR"

# Step 1: Tải model từ Hugging Face (nếu chưa có)
if [[ ! -d "${MODEL_NAME}.safetensors" && ! -d "${MODEL_NAME}_diffusers" ]]; then
  echo "[Step 1/3] Downloading model from Hugging Face..."
  echo "Note: Tải file .safetensors hoặc dùng huggingface-cli:"
  echo ""
  echo "  # Option A: Download safetensors manually"
  echo "  wget https://huggingface.co/${MODEL_ID}/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors -O ${MODEL_NAME}.safetensors"
  echo ""
  echo "  # Option B: Clone với git-lfs (lớn, ~2GB)"
  echo "  git lfs install"
  echo "  git clone https://huggingface.co/${MODEL_ID} ${MODEL_NAME}_hf"
  echo ""
  read -p "Đã tải model chưa? Nhấn Enter khi sẵn sàng hoặc Ctrl+C để thoát..."
else
  echo "[Step 1/3] Model already exists, skipping download."
fi

# Step 2: Convert safetensors → diffusers (nếu chưa có diffusers)
if [[ ! -d "${MODEL_NAME}_diffusers" ]]; then
  echo "[Step 2/3] Converting to Diffusers format..."
  
  # Tìm file .safetensors
  SAFETENSORS_FILE=$(find . -maxdepth 1 -name "${MODEL_NAME}*.safetensors" -o -name "Realistic_Vision*.safetensors" | head -n1)
  
  if [[ -z "$SAFETENSORS_FILE" ]]; then
    echo "ERROR: Không tìm thấy file .safetensors. Vui lòng tải thủ công:"
    echo "  wget https://huggingface.co/${MODEL_ID}/resolve/main/Realistic_Vision_V5.1_fp16-no-ema.safetensors -O ${MODEL_NAME}.safetensors"
    exit 1
  fi
  
  echo "Converting $SAFETENSORS_FILE to diffusers..."
  uv run python convert_original_stable_diffusion_to_diffusers.py \
    --checkpoint_path "$SAFETENSORS_FILE" \
    --from_safetensors \
    --device cpu \
    --extract_ema \
    --dump_path "${MODEL_NAME}_diffusers"
  
  echo "✓ Diffusers conversion complete: ${MODEL_NAME}_diffusers"
else
  echo "[Step 2/3] Diffusers format already exists, skipping."
fi

# Step 3: Convert diffusers → Core ML (SPLIT_EINSUM for ANE)
echo "[Step 3/3] Converting to Core ML (SPLIT_EINSUM for ANE)..."
echo "This takes ~20-30 minutes. Progress will be shown..."

# Run conversion với SPLIT_EINSUM (compatible với Neural Engine)
uv run python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-vae-decoder \
  --convert-vae-encoder \
  --convert-unet \
  --unet-support-controlnet \
  --convert-text-encoder \
  --model-version "${MODEL_NAME}_diffusers" \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  -o "$OUTPUT_DIR" &

# Run second pass without ControlNet support (for compatibility)
uv run python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-unet \
  --model-version "${MODEL_NAME}_diffusers" \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  -o "$OUTPUT_DIR"

wait

echo ""
echo "=== Conversion Complete ==="
echo "Output location: $OUTPUT_DIR"
echo "Files: TextEncoder.mlmodelc, Unet.mlmodelc, VAEDecoder.mlmodelc, etc."
echo ""
echo "Next steps:"
echo "1. Test model với MochiDiffusion app để verify"
echo "2. Run benchmarks: latency, memory, quality"
echo "3. Document kết quả trong benchmarks/RealisticVision_quality.md"
echo ""
