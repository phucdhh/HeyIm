#!/usr/bin/env bash
set -euo pipefail

# convert_controlnet.sh — Convert ControlNet models sang Core ML
#
# Yêu cầu:
# - MochiDiffusion conversion env setup
# - Models đã tải từ coreml-community hoặc convert từ PyTorch

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="${PROJECT_ROOT}/models"
MOCHI_CONVERSION_DIR="${HOME}/MochiDiffusion/conversion"

# Chọn ControlNet model để convert
CONTROLNET_TYPE="${1:-canny}"  # canny, openpose, depth, tile

case "$CONTROLNET_TYPE" in
  canny)
    MODEL_ID="lllyasviel/control_v11p_sd15_canny"
    MODEL_NAME="ControlNet_Canny"
    ;;
  openpose)
    MODEL_ID="lllyasviel/control_v11p_sd15_openpose"
    MODEL_NAME="ControlNet_OpenPose"
    ;;
  depth)
    MODEL_ID="lllyasviel/control_v11f1p_sd15_depth"
    MODEL_NAME="ControlNet_Depth"
    ;;
  tile)
    MODEL_ID="lllyasviel/control_v11f1e_sd15_tile"
    MODEL_NAME="ControlNet_Tile"
    ;;
  *)
    echo "Usage: $0 [canny|openpose|depth|tile]"
    echo ""
    echo "Available ControlNet models:"
    echo "  canny    - Edge detection (recommended for line art, composition)"
    echo "  openpose - Pose control (recommended for human figures)"
    echo "  depth    - Depth map control"
    echo "  tile     - Detail enhancement for upscaling"
    exit 1
    ;;
esac

OUTPUT_DIR="${MODELS_DIR}/${MODEL_NAME}_CoreML"

echo "=== ControlNet Conversion Pipeline ==="
echo "Type: ${CONTROLNET_TYPE}"
echo "Model: ${MODEL_ID}"
echo "Output: ${OUTPUT_DIR}"
echo ""

# Check if coreml-community has pre-converted version
echo "Note: Kiểm tra coreml-community trước khi convert từ đầu:"
echo "  https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML"
echo ""
echo "Nếu có sẵn Core ML version, tải trực tiếp:"
echo "  git lfs install"
echo "  git clone https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML"
echo "  cp -r ControlNet-Models-For-Core-ML/CN/${CONTROLNET_TYPE}/* ${OUTPUT_DIR}/"
echo ""
read -p "Muốn convert từ PyTorch hay đã tải Core ML version? (convert/skip): " choice

if [[ "$choice" == "skip" ]]; then
  echo "Skipping conversion. Vui lòng tải và đặt Core ML models vào: $OUTPUT_DIR"
  exit 0
fi

# Kiểm tra MochiDiffusion conversion env
if [[ ! -d "$MOCHI_CONVERSION_DIR" ]]; then
  echo "ERROR: MochiDiffusion conversion directory not found."
  echo "Clone first: git clone https://github.com/MochiDiffusion/MochiDiffusion.git ~/MochiDiffusion"
  exit 1
fi

cd "$MOCHI_CONVERSION_DIR"

# Tải ControlNet model
if [[ ! -d "${MODEL_NAME}_pytorch" ]]; then
  echo "Downloading ControlNet model from Hugging Face..."
  git lfs install
  git clone "https://huggingface.co/${MODEL_ID}" "${MODEL_NAME}_pytorch"
fi

# Convert sang Core ML (theo MochiDiffusion wiki)
echo "Converting ControlNet to Core ML..."
echo "Note: Tham khảo https://github.com/MochiDiffusion/MochiDiffusion/wiki/How-to-convert-ControlNet-models-to-Core-ML"
echo ""

# Example command (cần điều chỉnh theo actual script của MochiDiffusion)
echo "Lệnh convert mẫu (điều chỉnh theo ControlNet conversion script):"
cat <<CMD
uv run python convert_controlnet_to_coreml.py \\
  --model_id ${MODEL_ID} \\
  --output_dir ${OUTPUT_DIR} \\
  --attention-implementation SPLIT_EINSUM
CMD

echo ""
echo "⚠️  ControlNet conversion scripts có thể khác nhau. Vui lòng:"
echo "1. Đọc MochiDiffusion wiki: How-to-convert-ControlNet-models-to-Core-ML"
echo "2. Hoặc tải pre-converted từ coreml-community (khuyến nghị)"
echo ""
echo "Pre-converted models location:"
echo "  https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML/tree/main/CN"
echo ""
