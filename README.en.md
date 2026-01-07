# HeyIm — AI Image Generation Web App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.8+](https://img.shields.io/badge/Swift-5.8+-orange.svg)](https://swift.org)
[![Next.js 16](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org)

**Full-stack AI image generation web application optimized for Apple Silicon (Mac Mini M2). All inference runs natively using Core ML + ANE (Apple Neural Engine).**

> 🇻🇳 [Tiếng Việt](README.md) | 🇬🇧 English

## Overview

HeyIm uses **RealisticVision v5.1** - a Stable Diffusion 1.5 model fine-tuned for portrait photography and optimized for Apple Neural Engine.

## Key Features

- ⚡ **Fast**: 8-10 seconds per image
- 🎨 **High Quality**: Specialized in portraits, faces, people
- 🖼️ **Image-to-Image**: Upload and edit images, modify context/behavior
- 🖥️ **M2 Optimized**: Runs entirely on ANE
- 🌐 **Web Interface**: Next.js + TypeScript
- 🔒 **Secure**: Local processing, no external data transmission

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Next.js   │─────▶│ Swift/Vapor  │─────▶│  Core ML    │
│  Frontend   │      │   Backend    │      │ (ANE/CPU)   │
│  Port 5859  │      │  Port 5858   │      │             │
└─────────────┘      └──────────────┘      └─────────────┘
```

## Performance

**Mac Mini M2 base (16GB RAM):**
- 20 steps: ~7-8s
- 30 steps: ~9-10s ⭐ Recommended
- 40 steps: ~12-13s

**Hardware Usage:**
- ANE: 80-100% (UNet 1.6GB)
- CPU: 10-20%
- GPU: 0%
- RAM: ~4-5GB

## Quick Start

### Prerequisites

- macOS 13.1+ (Ventura or later)
- Xcode 14.3+ with Command Line Tools
- Swift 5.8+
- Node.js 18+ and npm

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/phucdhh/HeyIm.git
cd HeyIm
```

2. **Download Core ML models:**

You need to convert Stable Diffusion models to Core ML format. See [Model Conversion Guide](docs/MODEL_CONVERSION.md) for detailed instructions.

Place the converted models in `models/` directory:
```
models/
├── RealisticVision_v51/
│   ├── TextEncoder.mlmodelc
│   ├── Unet.mlmodelc
│   ├── VAEDecoder.mlmodelc
│   ├── VAEEncoder.mlmodelc
│   ├── vocab.json
│   └── merges.txt
```

3. **Build and run backend:**
```bash
cd backend
swift build -c release
.build/release/HeyImServer
```

4. **Install and run frontend:**
```bash
cd frontend
npm install
npm run dev
```

5. **Access the app:**

Open http://localhost:5859 in your browser.

## Model: RealisticVision v5.1

- **Size**: 3.6GB (Core ML, FP16)
- **Type**: Stable Diffusion 1.5 based
- **Specialization**: Portrait photography, faces, people
- **Format**: SPLIT_EINSUM for optimal ANE performance

### Recommended Settings

- **Steps**: 30 (good balance of speed/quality)
- **CFG Scale**: 7.0 (default)
- **Scheduler**: PNDM (for img2img), DPM++ (for text-to-image)
- **Negative Prompt**: Use to avoid artifacts

## Image-to-Image (img2img)

Upload your portrait and modify background, pose, or style:

1. Upload base image (drag-drop or click)
2. Enter modification prompt
3. Adjust strength slider:
   - **0.3-0.5**: Keep subject identical, change background
   - **0.5-0.7**: Moderate modifications
   - **0.7-1.0**: Major transformations

### Technical Details

- **Aspect-preserving resize**: Images are resized to 512x512 with padding
- **PNDM Scheduler**: Better preserves facial features
- **CFG Boost**: Automatically increases guidance for img2img

## API Documentation

### Generate Image (Text-to-Image)

```bash
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "beautiful woman, professional portrait photography",
    "negativePrompt": "ugly, blurry, low quality",
    "steps": 30,
    "cfgScale": 7.0,
    "seed": 42
  }'
```

### Generate Image (Image-to-Image)

```bash
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "same person, beach background with palm trees",
    "steps": 30,
    "cfgScale": 7.0,
    "inputImage": "data:image/png;base64,...",
    "strength": 0.5
  }'
```

### Response

```json
{
  "success": true,
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "metadata": {
    "prompt": "...",
    "steps": 30,
    "cfgScale": 7.0,
    "seed": 123456,
    "duration": 8.234,
    "hasInputImage": false,
    "strength": null
  }
}
```

## Production Deployment

### Using launchd (recommended)

```bash
cd deploy
sudo ./deploy.sh
```

This will:
- Build release versions
- Install launchd daemons
- Configure auto-restart on failure
- Set up log rotation

### Manual Deployment

See [deployment guide](docs/DEPLOYMENT.md) for detailed instructions including Cloudflare Tunnel setup.

## Project Structure

```
HeyIm/
├── backend/              # Swift/Vapor API server
│   ├── Sources/
│   │   └── HeyImServer/
│   │       ├── main.swift
│   │       ├── ModelService.swift
│   │       └── Models.swift
│   └── Package.swift
├── frontend/             # Next.js web interface
│   ├── app/
│   ├── components/
│   └── types/
├── models/               # Core ML models (not in git)
├── deploy/               # Production deployment scripts
└── docs/                 # Documentation
```

## Development

### Backend Development

```bash
cd backend
swift build
.build/debug/HeyImServer
```

### Frontend Development

```bash
cd frontend
npm run dev
```

Hot reload enabled. Changes reflect immediately.

### Running Tests

```bash
# Backend tests
cd backend
swift test

# Frontend tests
cd frontend
npm test
```

## Troubleshooting

### Model Loading Errors

If you see "Model not found" errors:
1. Verify models are in `models/` directory
2. Check model paths in `ModelService.swift`
3. Ensure models are properly compiled (.mlmodelc format)

### Memory Issues

If the app crashes due to memory:
1. Close other apps
2. Reduce batch size to 1
3. Use lower step counts (20 instead of 30)

### Port Conflicts

If ports 5858 or 5859 are already in use:
```bash
# Find and kill processes
lsof -ti:5858 | xargs kill
lsof -ti:5859 | xargs kill
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Apple** - [ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) for Core ML conversion tools
- **StabilityAI** - Base Stable Diffusion architecture
- **RealisticVision** - Model fine-tuning for portraits

## Disclaimer

This project is for educational and research purposes. The RealisticVision v5.1 model has its own license terms. Please ensure compliance with all applicable licenses when using this software.

## Related Projects

- [Apple ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) - Official Core ML SD implementation (CLI only)
- [MochiDiffusion](https://github.com/godly-devotion/MochiDiffusion) - Native macOS SD app (desktop only)
- [HeyIm](https://github.com/phucdhh/HeyIm) - This project (full-stack web app)

## Contact

- GitHub: [@phucdhh](https://github.com/phucdhh)
- Issues: [GitHub Issues](https://github.com/phucdhh/HeyIm/issues)

---

Made with ❤️ and Apple Silicon
