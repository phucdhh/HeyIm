# Architecture Overview

HeyIm is a full-stack web application for AI image generation, optimized for Apple Silicon.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Browser                         │
│                    (http://localhost:5859)                   │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP/REST
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     Next.js Frontend                         │
│                      (Port 5859)                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   React     │  │  TypeScript  │  │  Tailwind    │       │
│  │ Components  │  │    Types     │  │     CSS      │       │
│  └─────────────┘  └──────────────┘  └──────────────┘       │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTP/JSON API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Swift/Vapor Backend                        │
│                      (Port 5858)                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 REST API Endpoints                   │   │
│  │  • POST /api/generate   • GET /api/models           │   │
│  │  • GET /health          • GET /api/status           │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               Model Service Layer                    │   │
│  │  • Pipeline management  • Image processing          │   │
│  │  • Scheduler selection  • CFG/strength control      │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────┘
                           │ Core ML API
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Core ML Pipeline                          │
│  ┌─────────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │    Text     │→ │   UNet   │→ │   VAE    │→ │ Output  │ │
│  │  Encoder    │  │ (1.6GB)  │  │ Decoder  │  │  Image  │ │
│  └─────────────┘  └──────────┘  └──────────┘  └─────────┘ │
└──────────────────────────┬──────────────────────────────────┘
                           │ Hardware Acceleration
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    Apple Silicon M2                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │     ANE      │  │     CPU      │  │     GPU      │      │
│  │   (80-100%)  │  │  (10-20%)    │  │     (0%)     │      │
│  │  UNet runs   │  │  Overhead    │  │   Unused     │      │
│  │  here (fast) │  │              │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Frontend (Next.js 16)

**Technology Stack:**
- Next.js 16 with App Router
- React 19.2.3
- TypeScript
- Tailwind CSS
- shadcn/ui components

**Key Components:**
- `GenerateForm.tsx`: Main form with prompt, settings, img2img
- `ImageUpload.tsx`: Drag-drop image upload with preview
- `ImageDisplay.tsx`: Result display with download
- `HistoryGrid.tsx`: Generation history with IndexedDB storage

**State Management:**
- React hooks (useState, useEffect)
- Custom hooks (useGenerate, useHistory)
- IndexedDB for persistent history

**API Client:**
- Fetch-based client in `lib/api/client.ts`
- Type-safe request/response with TypeScript interfaces
- Error handling and retry logic

### Backend (Swift/Vapor)

**Technology Stack:**
- Swift 5.8+
- Vapor 4.x (web framework)
- Core ML for model inference
- Foundation for image processing

**Architecture Layers:**

1. **HTTP Layer** (`main.swift`)
   - Route definitions
   - Request/response handling
   - Middleware (CORS, body size limits)

2. **Service Layer** (`ModelService.swift`)
   - Model loading and caching
   - Pipeline configuration
   - Image generation orchestration

3. **Model Layer** (`Models.swift`)
   - Request/response DTOs
   - Type definitions
   - Validation logic

**Request Flow:**

```
HTTP Request → Router → Validation → Model Service → Core ML → Response
     ↓            ↓          ↓             ↓            ↓          ↓
   JSON       Decode    Validate      Generate     Inference   Encode
```

### Core ML Pipeline

**Models:**

1. **TextEncoder** (~100MB)
   - Converts text prompts to embeddings
   - Uses CLIP tokenizer
   - Max 77 tokens (~40 words)

2. **UNet** (~1.6GB)
   - Denoising network (main computation)
   - Runs on ANE for optimal performance
   - SPLIT_EINSUM attention implementation

3. **VAEDecoder** (~150MB)
   - Converts latents to RGB images
   - Upscales from 64x64 to 512x512

4. **VAEEncoder** (~150MB, img2img only)
   - Converts images to latent space
   - Required for image-to-image

**Inference Process:**

```
Text Prompt → TextEncoder → Embeddings
                               ↓
Image (optional) → VAEEncoder → Latent
                               ↓
         Noise + Embeddings + Latent
                               ↓
              UNet (30 steps)
                               ↓
          Denoised Latent
                               ↓
         VAEDecoder → RGB Image
```

## Data Flow

### Text-to-Image

```
User Input
    ↓
Frontend Form (prompt, steps, cfg)
    ↓
POST /api/generate
    ↓
Backend Validation
    ↓
TextEncoder (prompt → embeddings)
    ↓
Initialize random noise
    ↓
UNet denoising loop (30 steps)
  - Scheduler: DPM++
  - CFG: 7.0
    ↓
VAEDecoder (latent → image)
    ↓
Base64 encode
    ↓
JSON Response
    ↓
Frontend Display
```

### Image-to-Image

```
User Input + Image Upload
    ↓
Frontend Form (prompt, strength, image)
    ↓
POST /api/generate (with inputImage)
    ↓
Backend Validation
    ↓
Aspect-preserving resize (512x512)
    ↓
VAEEncoder (image → latent)
    ↓
TextEncoder (prompt → embeddings)
    ↓
Add noise to latent (based on strength)
    ↓
UNet denoising loop (30 steps * strength)
  - Scheduler: PNDM (better preservation)
  - CFG: 7.0 + 1.5 boost
    ↓
VAEDecoder (latent → image)
    ↓
Base64 encode
    ↓
JSON Response
    ↓
Frontend Display
```

## Performance Optimization

### ANE Optimization

1. **Model Format**: SPLIT_EINSUM attention
2. **Compute Units**: CPU_AND_NE (ANE preferred)
3. **Precision**: FP16 (good quality, 2x faster than FP32)
4. **Model Chunking**: Not needed on Mac (iOS only)

### Memory Management

- Lazy model loading (load on first use)
- Model caching (keep in memory after load)
- Automatic resource cleanup
- Batch size = 1 (optimal for ANE)

### Caching Strategy

**Backend:**
- Models cached in memory after first load
- No disk caching (Core ML handles it)
- Single pipeline instance (singleton)

**Frontend:**
- Generated images in IndexedDB
- Automatic cleanup (limit: 100 images)
- Prompt history in localStorage

## Security Considerations

### Current Implementation

- Local processing only (no external API calls)
- No user authentication (single-user app)
- CORS enabled for localhost
- 10MB request size limit

### Production Recommendations

1. **Add Authentication**
   - JWT tokens or session-based auth
   - Rate limiting per user
   - API key for backend access

2. **Input Validation**
   - Sanitize prompts (prevent injection)
   - Validate image formats
   - Limit file sizes

3. **Network Security**
   - HTTPS only in production
   - Restrict CORS to specific domains
   - Firewall rules (only 80/443 public)

4. **Model Security**
   - Read-only model directory
   - Verify model checksums
   - Sandboxed execution

## Scalability

### Current Limitations

- Single-user design
- Synchronous generation (one at a time)
- No queue system
- No distributed processing

### Scaling Options

1. **Horizontal Scaling**
   - Multiple Mac Minis with load balancer
   - Redis-based job queue
   - Shared storage for models

2. **Vertical Scaling**
   - Mac Studio (M2 Ultra) for 2x performance
   - More RAM for larger batch sizes
   - NVMe SSD for faster model loading

3. **Queue System**
   - Redis or RabbitMQ for job queue
   - Background workers for generation
   - WebSocket for real-time updates

## Monitoring & Debugging

### Logging

**Backend:**
- Console logs (development)
- File logs (production)
- Structured logging with levels

**Frontend:**
- Browser console (development)
- Error tracking (Sentry for production)
- Performance metrics (Web Vitals)

### Metrics to Track

- Generation time per image
- ANE utilization (should be 80-100%)
- Memory usage (RAM)
- Request rate (requests/minute)
- Error rate

### Debug Tools

```bash
# Monitor ANE usage
sudo powermetrics --samplers cpu_power,gpu_power,ane_power

# Monitor memory
top -o MEM -pid $(pgrep HeyImServer)

# Check backend logs
tail -f ~/HeyIm/logs/backend.log

# Test API
curl http://localhost:5858/health
```

## Deployment Strategies

### Development

```bash
# Terminal 1: Backend
cd backend && swift run

# Terminal 2: Frontend
cd frontend && npm run dev
```

### Production

**Option 1: launchd (recommended)**
- Auto-start on boot
- Auto-restart on crash
- Log rotation
- Resource limits

**Option 2: Docker (alternative)**
- Containerized deployment
- Easy version management
- Not ideal for ANE access

**Option 3: Kubernetes (advanced)**
- Multi-node orchestration
- Auto-scaling
- Requires Mac node support

## Future Enhancements

### Planned Features

1. **Model Management**
   - Hot-swap models without restart
   - Multiple models in memory
   - Model version control

2. **Advanced Controls**
   - ControlNet support
   - Inpainting/outpainting
   - Style transfer presets

3. **Performance**
   - Batch generation
   - Queue system
   - WebSocket for progress

4. **UI/UX**
   - Real-time preview
   - Advanced editing tools
   - Gallery with tags/search

### Technical Debt

- [ ] Add comprehensive tests (unit + integration)
- [ ] Improve error handling
- [ ] Add API documentation (OpenAPI/Swagger)
- [ ] Implement proper logging framework
- [ ] Add performance benchmarks
- [ ] Create Docker images

## References

- [Apple ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion)
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Vapor Documentation](https://docs.vapor.codes/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Stable Diffusion Paper](https://arxiv.org/abs/2112.10752)
