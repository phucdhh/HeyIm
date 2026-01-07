# Model Conversion Guide

This guide explains how to convert Stable Diffusion models to Core ML format for use with HeyIm.

## Prerequisites

- macOS 13.1+
- Python 3.8+
- Apple ml-stable-diffusion toolkit
- Hugging Face account and token

## Setup Environment

```bash
# Create Python environment
conda create -n coreml_sd python=3.8 -y
conda activate coreml_sd

# Clone Apple's ml-stable-diffusion
git clone https://github.com/apple/ml-stable-diffusion.git
cd ml-stable-diffusion
pip install -e .

# Login to Hugging Face
huggingface-cli login
```

## Converting RealisticVision v5.1

### 1. Download the Model

The RealisticVision v5.1 model is available on Hugging Face or Civitai.

### 2. Convert to Core ML

```bash
python -m python_coreml_stable_diffusion.torch2coreml \
  --model-version SG161222/Realistic_Vision_V5.1_noVAE \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  --compute-unit ALL \
  --convert-unet \
  --convert-text-encoder \
  --convert-vae-decoder \
  --convert-vae-encoder \
  --quantize-nbits 16 \
  -o ~/HeyIm/models/RealisticVision_v51
```

### 3. Verify Conversion

Check that these files exist:

```
models/RealisticVision_v51/Resources/
├── TextEncoder.mlmodelc
├── Unet.mlmodelc
├── VAEDecoder.mlmodelc
├── VAEEncoder.mlmodelc
├── vocab.json
└── merges.txt
```

## Converting Other Models

### For Standard SD 1.5 Models

```bash
python -m python_coreml_stable_diffusion.torch2coreml \
  --model-version runwayml/stable-diffusion-v1-5 \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  --compute-unit ALL \
  --convert-unet \
  --convert-text-encoder \
  --convert-vae-decoder \
  --convert-vae-encoder \
  -o ~/HeyIm/models/SD15
```

### For SD XL Models (Experimental)

```bash
python -m python_coreml_stable_diffusion.torch2coreml \
  --model-version stabilityai/stable-diffusion-xl-base-1.0 \
  --xl-version \
  --bundle-resources-for-swift-cli \
  --attention-implementation SPLIT_EINSUM \
  --compute-unit ALL \
  --convert-unet \
  --convert-text-encoder \
  --convert-text-encoder-2 \
  --convert-vae-decoder \
  -o ~/HeyIm/models/SDXL_Base
```

Note: SDXL requires more memory and is slower on M2 base.

## Important Flags

- `--attention-implementation SPLIT_EINSUM`: Best for ANE performance
- `--compute-unit ALL`: Use ANE + CPU + GPU (ANE preferred)
- `--quantize-nbits 16`: FP16 quantization (good quality/size balance)
- `--chunk-unet`: Split UNet for iOS/iPadOS (not needed for Mac)
- `--bundle-resources-for-swift-cli`: Prepare for Swift package

## Configuration in HeyIm

After conversion, update the model path in `backend/Sources/HeyImServer/ModelService.swift`:

```swift
let modelPath = URL(fileURLWithPath: "/Users/mac/HeyIm/models/RealisticVision_v51/Resources")
```

## Troubleshooting

### Conversion Fails

- Check Python environment: `python --version`
- Verify Hugging Face login: `huggingface-cli whoami`
- Ensure enough disk space (5-10GB per model)

### Model Doesn't Load

- Verify .mlmodelc format (compiled models)
- Check file permissions: `chmod -R 755 models/`
- Review error logs in backend console

### Poor Performance

- Confirm SPLIT_EINSUM attention is used
- Check compute units are set to ALL
- Monitor ANE usage with Activity Monitor

## Model Size Comparison

| Model | Original | Core ML FP16 | Core ML FP32 |
|-------|----------|--------------|--------------|
| SD 1.5 | 4.2GB | 3.6GB | 7.2GB |
| SDXL | 6.9GB | 5.8GB | 11.6GB |

## Performance Tips

1. **Use FP16**: Good quality, 2x smaller than FP32
2. **SPLIT_EINSUM**: Essential for ANE performance
3. **Cache Models**: First load is slow, subsequent loads are fast
4. **Monitor Memory**: Keep RAM usage under 70%

## Further Reading

- [Apple ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion)
- [Core ML Tools Documentation](https://coremltools.readme.io/)
- [Stable Diffusion on Hugging Face](https://huggingface.co/models?search=stable-diffusion)
