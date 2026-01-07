#!/usr/bin/env bash
set -euo pipefail

# convert_coreml.sh — wrapper mẫu để chuyển Stable Diffusion -> Core ML
# GHI CHÚ: Chạy script này trên macOS với Python 3.10+ và các phụ thuộc đã cài.

usage(){
  cat <<EOF
Usage: $0 --model <huggingface-id> --out <output-dir> [--method mochidiffusion|apple]

Options:
  --model    Hugging Face model id (e.g. runwayml/stable-diffusion-v1-5)
  --out      Output folder for Core ML bundle
  --method   Conversion method: "mochidiffusion" (recommended) or "apple"
  --help     Show this help

Examples:
  $0 --model runwayml/stable-diffusion-v1-5 --out Models/SD15_CoreML --method mochidiffusion
EOF
}

MODEL=""
OUT=""
METHOD="mochidiffusion"

while [[ $# -gt 0 ]]; do
  case $1 in
    --model) MODEL="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --method) METHOD="$2"; shift 2;;
    --help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -z "$MODEL" || -z "$OUT" ]]; then
  usage; exit 1
fi

mkdir -p "$OUT"

echo "Converting model: $MODEL -> $OUT (method=$METHOD)"

if [[ "$METHOD" == "mochidiffusion" ]]; then
  echo "Using MochiDiffusion conversion pipeline (recommended)."
  echo "Please ensure you have cloned https://github.com/MochiDiffusion/MochiDiffusion and installed its conversion env."

  cat <<CMD
# Example commands to run inside MochiDiffusion/conversion env:
git clone https://github.com/MochiDiffusion/MochiDiffusion.git
cd MochiDiffusion/conversion
# Follow their README to create python venv and install requirements
# Then run (example):
python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-unet --convert-text-encoder --convert-vae \
  --model-version ${MODEL} \
  --bundle-resources-for-swift-cli \
  -o ${OUT}
CMD

  echo "If you prefer full automation, run the above inside the MochiDiffusion conversion environment."

elif [[ "$METHOD" == "apple" ]]; then
  echo "Using Apple's conversion script (coremltools). Make sure coremltools is installed."
  cat <<CMD
# Example (requires coremltools + proper conversion tooling):
python -m python_coreml_stable_diffusion.torch2coreml \
  --convert-unet --convert-text-encoder --convert-vae \
  --model-version ${MODEL} \
  -o ${OUT}
CMD
else
  echo "Unknown method: $METHOD"; exit 1
fi

echo "Conversion wrapper finished. See notes above for manual steps to execute inside the conversion environment."
