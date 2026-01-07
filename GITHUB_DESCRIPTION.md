# GitHub Repository Setup

## Repository Description (Short)

Full-stack AI image generation web app optimized for Apple Silicon. RealisticVision v5.1 model running on Core ML + ANE. Swift/Vapor backend + Next.js frontend.

## Repository Description (Long)

HeyIm is a production-ready web application for AI image generation, optimized specifically for Apple Silicon (M1/M2/M3). It features a Swift/Vapor backend that leverages Core ML and the Apple Neural Engine for blazing-fast inference, paired with a modern Next.js frontend.

Key highlights:
- ⚡ 8-10 seconds per image on Mac Mini M2
- 🎨 RealisticVision v5.1 model (portrait specialist)
- 🖼️ Image-to-image with strength control
- 🧠 ANE optimization (80-100% utilization)
- 🌐 REST API + Web UI
- 🚀 Production deployment with launchd

Perfect for developers wanting to run Stable Diffusion locally without cloud APIs or Python dependencies.

## Topics (GitHub Tags)

- stable-diffusion
- core-ml
- apple-silicon
- swift
- vapor
- nextjs
- typescript
- ai
- image-generation
- neural-engine
- macos
- m1
- m2
- machine-learning
- webui

## README Badges

Add these to the top of README.md:

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.8+](https://img.shields.io/badge/Swift-5.8+-orange.svg)](https://swift.org)
[![Next.js 16](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3-blue)](https://www.apple.com/mac/)
```

## Social Media Announcement

### Twitter/X

🚀 Just open-sourced HeyIm - a full-stack Stable Diffusion web app for Apple Silicon!

⚡ 8-10s per image on M2
🧠 ANE-optimized Core ML
🖼️ Image-to-image support
🌐 Swift backend + Next.js frontend

Perfect for running SD locally without Python! 

https://github.com/phucdhh/HeyIm

#StableDiffusion #AppleSilicon #Swift #MachineLearning

### Reddit (r/StableDiffusion, r/MachineLearning)

Title: [P] HeyIm - Full-stack Stable Diffusion web app optimized for Apple Silicon (M1/M2/M3)

I built a production-ready web application for running Stable Diffusion locally on Mac, leveraging Core ML and the Apple Neural Engine for maximum performance.

**Key Features:**
- ⚡ 8-10 seconds per image (30 steps) on Mac Mini M2 base
- 🧠 ANE utilization: 80-100% (UNet runs entirely on Neural Engine)
- 🎨 RealisticVision v5.1 model (portrait specialist)
- 🖼️ Image-to-image with PNDM scheduler for face preservation
- 🌐 REST API + modern web UI (Next.js)
- 🚀 Production deployment scripts included

**Tech Stack:**
- Backend: Swift 5.8+ with Vapor framework
- Frontend: Next.js 16 + TypeScript + Tailwind
- ML: Core ML with SPLIT_EINSUM attention
- Deployment: launchd + Cloudflare Tunnel

**Why this vs Python?**
- No Python/conda environment needed
- Native performance on Apple Silicon
- Lower memory footprint
- Built-in macOS integration

GitHub: https://github.com/phucdhh/HeyIm

Happy to answer questions! This is my first open-source ML project.

### Hacker News

Title: Show HN: HeyIm – Stable Diffusion web app for Apple Silicon (Swift + Core ML)

Description: A full-stack web application for running Stable Diffusion locally on Mac using Swift, Core ML, and the Apple Neural Engine. 8-10 second generation time on M2, with image-to-image support and modern web UI.

## GitHub About Section

Website: (leave empty or add your demo URL)
Topics: stable-diffusion, core-ml, apple-silicon, swift, vapor, nextjs, ai, image-generation

## Initial Issue Templates

Create these in .github/ISSUES/

### Bug Report
```markdown
**Describe the bug**
A clear description of what the bug is.

**Environment**
- macOS version:
- Hardware (Mac Mini/MacBook/Mac Studio):
- RAM:
- Model being used:

**Steps to reproduce**
1. 
2. 
3. 

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened.

**Logs**
Paste relevant logs here.
```

### Feature Request
```markdown
**Feature description**
Clear description of the feature you'd like.

**Use case**
Why is this feature needed? What problem does it solve?

**Proposed implementation**
(Optional) Ideas on how this could be implemented.

**Alternatives considered**
(Optional) Other solutions you've thought about.
```

## Pull Request Template

```markdown
## Description
Brief description of what this PR does.

## Changes
- [ ] Backend changes
- [ ] Frontend changes
- [ ] Documentation updates
- [ ] New dependencies

## Testing
- [ ] Tested locally
- [ ] All existing tests pass
- [ ] Added new tests (if applicable)

## Screenshots
(If UI changes)

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] No sensitive data included
- [ ] Ready for review
```

## License Notice for README

Add to bottom of README:

```markdown
## License & Attribution

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Model License
The RealisticVision v5.1 model has its own license terms. Please ensure compliance with the model's license when using this software commercially.

### Acknowledgments
- **Apple** - [ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion) for Core ML conversion tools
- **StabilityAI** - Original Stable Diffusion architecture
- **RealisticVision** - Model fine-tuning

### Disclaimer
This project is for educational and research purposes. Always respect model licenses and usage terms.
```

## SEO & Discoverability

**GitHub Search Keywords** (include in README):
- "stable diffusion macos"
- "core ml image generation"
- "apple silicon ai"
- "swift machine learning"
- "local ai image generation"
- "m1 m2 stable diffusion"

**Make sure these appear naturally in:**
- README.md introduction
- Project description
- Documentation headers

## Community Engagement Plan

1. **Week 1**: Share on r/StableDiffusion, r/MachineLearning
2. **Week 2**: Post on Hacker News "Show HN"
3. **Week 3**: Tweet with relevant hashtags
4. **Week 4**: Write blog post with tutorial

**Engagement Tips:**
- Respond to issues within 24 hours
- Be open to contributions
- Acknowledge contributors
- Share progress updates
- Create roadmap for future features
