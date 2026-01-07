# HeyIm — Ứng dụng Web Tạo Hình Ảnh bằng AI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.8+](https://img.shields.io/badge/Swift-5.8+-orange.svg)](https://swift.org)
[![Next.js 16](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org)

> 🇻🇳 Tiếng Việt | 🇬🇧 [English](README.en.md)

Website: https://heyim.truyenthong.edu.vn

**🎉 Status:** PRODUCTION READY!

Ứng dụng web tạo hình ảnh AI tối ưu cho Apple Silicon (Mac Mini M2). Toàn bộ inference chạy native bằng Core ML + ANE (Neural Engine).

## Tổng quan

HeyIm sử dụng **RealisticVision v5.1** - mô hình Stable Diffusion 1.5 finetuned chuyên về chân dung và portrait photography, được tối ưu hoá cho Apple Neural Engine.

## Tính năng chính

- ⚡ **Tốc độ nhanh**: 8-10 giây mỗi ảnh
- �� **Chất lượng cao**: Chuyên về portraits, faces, people- 🖼️ **Image-to-Image**: Upload và chỉnh sửa ảnh, thay đổi context/behavior- 🖥️ **Tối ưu M2**: Chạy hoàn toàn trên ANE
- 🌐 **Giao diện web**: Next.js + TypeScript
- �� **An toàn**: Xử lý local, không gửi data ra ngoài

## Performance

**Mac Mini M2 base (16GB RAM):**
- Steps 20: ~7-8s
- Steps 30: ~9-10s ⭐ Khuyến nghị
- Steps 40: ~12-13s

**Hardware Usage:**
- ANE: 80-100% (UNet 1.6GB)
- CPU: 10-20%
- GPU: 0%
- RAM: ~4-5GB

## Quick Start

```bash
# Backend
cd backend && swift build -c release
.build/release/HeyImServer

# Frontend  
cd frontend && npm install && npm run dev
```

Truy cập: http://localhost:5859

## Model: RealisticVision v5.1

- Size: 3.6GB (Core ML, FP16)
- Type: Stable Diffusion 1.5
- Specialization: Portrait photography
- Format: SPLIT_EINSUM (ANE optimized)

## API

### Generate Image (Text-to-Image)
```bash
POST http://localhost:5858/api/generate
{
  "prompt": "portrait photo of a woman, professional photography",
  "steps": 30,
  "cfgScale": 8.0
}
```

### Image-to-Image Editing
```bash
POST http://localhost:5858/api/generate
{
  "prompt": "same person but in business suit, office background",
  "steps": 25,
  "cfgScale": 7.5,
  "inputImage": "base64_encoded_image_data",
  "strength": 0.7
}
```

**Strength Guide:**
- `0.1-0.3`: Subtle changes (lighting, colors)
- `0.4-0.7`: Moderate changes (style, clothing, expression)
- `0.8-1.0`: Major changes (full composition)

### Status
```bash
GET http://localhost:5858/api/status
```

## Prompting Tips

**Good prompts:**
```
portrait photo of a beautiful woman, long hair, professional photography,
soft lighting, bokeh, 8k uhd, high quality
```

**Negative prompt:**
```
ugly, blurry, low quality, distorted, deformed, bad anatomy
```

## Cấu trúc

```
HeyIm/
├── backend/          # Swift + Vapor
├── frontend/         # Next.js
├── models/           # Core ML models (3.6GB)
└── scripts/          # Utilities
```

## Production Deployment

### Caddy (Reverse Proxy)
```caddyfile
heyim.truyenthong.edu.vn {
    reverse_proxy localhost:5860
}
```

### Cloudflare Tunnel
```bash
cloudflared tunnel --url http://localhost:5860
```

## License

MIT License

---

**Made with ❤️ for Mac Mini M2**
