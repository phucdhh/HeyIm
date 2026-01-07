# Kế Hoạch Phát Triển HeyIm (12 tuần)

Phiên bản này tóm tắt kế hoạch phát triển chi tiết cho dự án HeyIm — ứng dụng web tạo hình ảnh AI chạy native trên Mac Mini M2 (Core ML + ANE).

## Mục tiêu tổng quát
- Xây dựng backend (Swift + Vapor) tận dụng Core ML để chạy inference trên ANE.
- Xây dựng frontend (Next.js + TypeScript) có giao diện tiếng Việt, responsive.
- Hỗ trợ txt2img, img2img, ControlNet, LoRA; hệ thống queue giới hạn job (1–2 concurrent).
- Triển khai production trực tiếp trên Mac Mini M2 với HTTPS (Caddy) và monitoring cơ bản.

## Tiền đề & Chuẩn bị
- Máy: Mac Mini M2 (khuyến nghị 16–32 GB RAM; SDXL nên 32 GB).
- Hệ điều hành: macOS (Sonoma/ Ventura); Xcode CLT.
- Công cụ: Python, Homebrew, coremltools, (tùy chọn) Docker.
- Tài nguyên: truy cập Hugging Face / coreml-community + repo MochiDiffusion (conversion scripts).

## Đánh giá tính khả thi & mục tiêu độ chính xác ảnh ✅

### Kết luận khả thi
**KHẢ THI cao** — dự án có thể triển khai với độ chính xác ảnh tối ưu nếu:
- Chọn đúng base models (finetuned cho realism/detail)
- Sử dụng ControlNet cho prompt adherence
- Tích hợp upscaling (RealESRGAN) cho chi tiết cao
- Điều chỉnh inference parameters tối ưu

### Chiến lược đạt độ chính xác cao
1. **Model Selection (quan trọng nhất)**
   - SD1.5: chọn models finetuned chất lượng cao từ coreml-community
     - RealisticVision v5.1, DreamShaper v8, Deliberate v3
   - SDXL: JuggernautXL, RealVisXL (yêu cầu 32GB RAM)
   - Tránh base models (SD v1.5 vanilla) — ưu tiên finetuned với photorealism

2. **ControlNet Integration (bắt buộc cho precision)**
   - OpenPose: kiểm soát tư thế người chính xác
   - Canny/Depth: bảo toàn composition và structure
   - Tile: upscale với coherent details
   - **Khuyến nghị:** convert ít nhất 2–3 ControlNet models trong Phase 1

3. **Inference Parameters (tinh chỉnh)**
   - Sampling steps: 30–50 (cao hơn = chi tiết tốt hơn, latency cao hơn)
   - CFG Scale: 7–12 (balance creativity vs prompt adherence)
   - Sampler: DPM++ 2M Karras hoặc Euler a (nếu Core ML hỗ trợ)
   - Negative prompts mạnh: "blurry, low quality, distorted, malformed"

4. **Upscaling Pipeline (RealESRGAN)**
   - Tích hợp RealESRGAN x4 sau inference để tăng resolution
   - MochiDiffusion có sẵn upscale feature — tái sử dụng
   - Target: 512×512 → 2048×2048 với detail enhancement

5. **Quality Metrics cần theo dõi**
   - Prompt adherence: đánh giá thủ công hoặc CLIP score
   - Detail preservation: so sánh độ sắc nét edges
   - Composition accuracy: kiểm tra với ControlNet references

## Các tiêu chí chấp nhận (High-level)
- SD1.5 512×512 latency ≤ ~8s (sau lần compile đầu); với steps=30–50 có thể lên ~15–20s  
- Ổn định: không OOM trong giới hạn job đã định  
- API trả progress + kết quả (image URL/base64)  
- Giao diện cho phép gửi prompt, xem tiến độ, tải ảnh  
- **Thêm:** hỗ trợ ControlNet input và upscaling option

## Tổng quan timeline (12 tuần)
- Phase 0 — Chuẩn bị & xác thực (Tuần 0–1)
- Phase 1 — Convert models & Benchmark (Tuần 1–2)
- Phase 2 — Backend: API, Queue, Model Loader (Tuần 3–5)
- Phase 3 — Frontend: UI & Integration (Tuần 6–8)
- Phase 4 — Deploy trên Mac Mini M2 (Tuần 9–10)
- Phase 5 — Tối ưu, vận hành, bảo mật (Tuần 11–12)

---

## Phase 0 — Chuẩn bị & xác thực (Tuần 0–1)
Tasks:
- Chuẩn bị môi trường dev/server (macOS, Xcode CLT, Python).
- Clone `MochiDiffusion` và đọc thư mục `conversion` + wiki chuyển đổi.
- Lập danh sách model ưu tiên (SD1.5, SDXL-lite, Flux.schnell, ControlNet).
- Khởi tạo khung thư mục dự án (`backend/`, `frontend/`, `models/`, `scripts/`, `deploy/`).
Deliverables:
- `ENV.md` hoặc checklist môi trường sẵn sàng.
- Danh sách model + link nguồn.
Acceptance:
- Có thể chạy dry-run convert command trên máy (hoặc xác nhận downloaded models).

## Phase 1 — Convert models & Benchmark (Tuần 1–2)
Tasks:
- Chọn pipeline convert: dùng scripts của MochiDiffusion hoặc coremltools/Apple toolchain.
- **Convert high-quality finetuned models:**
  - SD1.5: RealisticVision v5.1 hoặc DreamShaper v8 (split_einsum) for ANE
  - Tải từ coreml-community nếu có sẵn, hoặc convert từ safetensors
- **Convert ControlNet models (tối thiểu 2):**
  - Canny + OpenPose (hoặc Depth)
  - Tham khảo: https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML
- Thử 1 LoRA nếu cần (optional trong Phase 1).
- **Chạy quality benchmarks:**
  - Latency, memory, compile time
  - Test generation với prompts phức tạp (chi tiết, composition)
  - So sánh output giữa base model vs finetuned model
  - Test ControlNet accuracy với reference images
Deliverables:
- `models/RealisticVision_CoreML` (hoặc DreamShaper) với `*.mlmodelc` bundles
- `models/ControlNet_Canny/`, `models/ControlNet_OpenPose/`
- `benchmarks/SD15_quality_comparison.md` — so sánh base vs finetuned
- `benchmarks/ControlNet_accuracy.md` — test adherence với reference
- Script convert đã cập nhật trong `scripts/convert_coreml.sh`
Acceptance:
- Finetuned SD1.5 inference hoàn tất < ~15s với steps=40 (512×512)
- ControlNet output visually accurate theo reference image
Deliverables:
- `models/SD15_CoreML` chứa `Unet.mlmodelc`, `TextEncoder.mlmodelc`, `VAEDecoder.mlmodelc`, `vocab.json`, `merges.txt`.
- `benchmarks/SD15_512x512.md` với kết quả chi tiết.
- `scripts/convert_coreml.sh` (mẫu) có docs.
Acceptance:
- SD1.5 512×512 inference hoàn tất < ~8s trong môi trường thử nghiệm.

## Phase 2 — Backend: Swift + Vapor + Model Loader + Queue (Tuần 3–5)
Week 3 (skeleton + API design):
- Scaffold Swift Package (Vapor), routes cơ bản và logging.
- Viết OpenAPI / API spec ngắn cho các endpoint (thêm ControlNet params).
Week 4 (model loader + inference wrapper):
- Implement model loader: scan `models/` và load `.mlmodelc` lazy.
- **Implement advanced inference wrapper:**
  - Core ML/Swift bindings với configurable parameters (steps, CFG, sampler)
  - ControlNet pipeline integration (load ControlNet models + process images)
  - Tái sử dụng logic từ MochiDiffusion khi phù hợp
- Implement job queue (in-memory hoặc lightweight persistent queue) với concurrency limit configurable.
Week 5 (progress + auth + tests + upscaling):
- SSE hoặc WebSocket progress streaming.
- **Integrate RealESRGAN upscaling:**
  - Sử dụng Core ML variant hoặc Python subprocess
  - Optional upscale flag trong API
- Basic auth / rate limiting middleware.
- Smoke tests cho endpoints + quality assertions.
Deliverables:
- `backend/` với working endpoints (generate, img2img, controlnet, upscale).
- `docs/api.md` với ControlNet và upscaling parameters documented.
- Sample test prompts trong `backend/tests/` để verify quality.
Acceptance:
- Endpoint `/api/generate` với ControlNet reference trả về accurate output.
- Upscaling hoạt động (512×512 → 2048×2048 < 5s additional).

## Phase 3 — Frontend: Next.js + TypeScript (Tuần 6–8)
Week 6:
- Scaffold Next.js (App Router), core pages: Home, Generate, History, Settings.
- Form gửi prompt (prompt/negative, steps, CFG, seed, model select).
Week 7:
- Integrate upload cho ControlNet.
- Show realtime progress (SSE/WebSocket) and final image with EXIF prompt info.
Week 8:
- Polish UI (responsive, Vietnamese copy), add local history (localStorage) and basic E2E smoke tests.
Deliverables:
- `frontend/` deployable, README hướng dẫn chạy local.
Acceptance:
- Người dùng có thể gửi prompt, theo dõi tiến độ, tải ảnh.

## Phase 4 — Deploy trên Mac Mini M2 (Tuần 9–10)
Tasks:
- Bổ sung vào cấu hình Cloudflared hiện có, tạo tên miền heyim.truyenthong.edu.vn và cấu hình nó trỏ về Mac Mini. Lưu ý, không làm ảnh hưởng tới các dịch vụ đã cấu hình cloudflared hiện có và không gây xung đột với các port đang sử dụng. Có thể chọn port 5858.
- Viết `launchd` plist hoặc startup scripts; giới thiệu cách chạy dưới `tmux`. Nhớ dùng Launchd Daemons, vì chúng ta chạy Mac Mini M2 dưới dạng Headless server.
- Setup firewall, monitoring cơ bản (UptimeRobot), backup models weekly.
- Dry-run load test (1–2 concurrent jobs).
Deliverables:
- `deploy/Caddyfile`, `deploy/launchd.plist`, `deploy/README-deploy.md`.
Acceptance:
- Service reachable via HTTPS; service auto-restarts khi crash.

## Phase 5 — Tối ưu, Bảo mật, Vận hành (Tuần 11–12)
Tasks:
- Rate limiting & quotas (per IP / per account).
- Persistent logging + rotation + backups cho models.
- Alerts (Telegram/email) khi service down or OOM.
- Performance tuning: thử quantized models, reduce memory footprint.
- Viết runbook vận hành và hướng dẫn cập nhật model/rollback.
Deliverables:
- `ops/` folder: runbook, backup scripts, alert config.
Acceptance:
- Hệ thống stable 24–72h, backup verified, alerts hoạt động.

---

## Kiểm thử và QA
- Smoke tests cho API endpoints.
- Performance tests: median latency trên 10 runs.
- Stability: 24h uptime test.

## Rủi ro & Biện pháp giảm thiểu
- RAM không đủ cho SDXL → bắt đầu với SD1.5 finetuned, hoặc dùng model quantized/SDXL-lite.
- Conversion thất bại → dùng models đã được convert sẵn từ `coreml-community` hoặc dùng MochiDiffusion conversion scripts.
- ANE compile time → pre-compile tại setup và warm caches.
- **Độ chính xác ảnh không đạt:**
  - Mitigation: chọn finetuned models (RealisticVision, DreamShaper) thay vì base
  - Sử dụng ControlNet cho prompts phức tạp
  - Tăng sampling steps (30–50) và CFG scale (8–12)
  - A/B test nhiều models và parameters để tìm sweet spot
- **ControlNet performance:** ControlNet tăng latency ~2–4s → cân nhắc optional flag trong API
- **Upscaling bottleneck:** RealESRGAN có thể chậm → chạy async hoặc dùng Core ML variant nếu khả dụng

## Tài liệu & artifacts cần chuẩn bị
- `ENV.md` — môi trường & cài đặt.
- `scripts/convert_coreml.sh` — script mẫu convert.
- `backend/README.md`, `frontend/README.md`.
- `deploy/` và `ops/` folder.

## Checkpoints & Phê duyệt
- Checkpoint 1 (tuần 2): models converted + **quality benchmarks pass** — phê duyệt tiếp Phase 2.
  - Quality criteria: finetuned model output tốt hơn base model rõ rệt
  - ControlNet accuracy ≥ 80% visual match với reference
- Checkpoint 2 (tuần 5): backend + queue + **quality features** working — phê duyệt tiếp Phase 3.
  - ControlNet integration tested với sample images
  - Upscaling produces sharp 2048×2048 outputs
- Checkpoint 3 (tuần 8): frontend integration + **quality controls** — phê duyệt deploy.
  - User có thể điều chỉnh steps, CFG, negative prompts
  - ControlNet upload và preview hoạt động
- Final review (tuần 12): nghiệm thu, tài liệu vận hành, **quality validation report**.

## Quality Benchmarks & Metrics (Đánh giá chất lượng)

### 1. Prompt Adherence (Độ trung thực với prompt)
- Test với 10 prompts phức tạp (chi tiết cụ thể: màu sắc, vật thể, composition)
- Đánh giá thủ công (scale 1–5): ảnh có bao gồm tất cả yếu tố trong prompt?
- Target: ≥ 4.0/5.0 average score

### 2. Visual Quality (Chất lượng hình ảnh)
- Sharpness: không bị blur, edges rõ ràng
- Coherence: không có artifacts, deformed objects
- Lighting/color: tự nhiên, không oversaturated
- Target: ≥ 80% images rated "good" hoặc "excellent"

### 3. ControlNet Accuracy (Độ chính xác ControlNet)
- Test với 5 reference images (poses, edges, depth maps)
- Visual comparison: output có match reference structure?
- Target: ≥ 80% structural match

### 4. Comparison Tests
- Base model (SD1.5 vanilla) vs Finetuned (RealisticVision)
- No ControlNet vs With ControlNet
- No upscaling vs RealESRGAN upscaling
- Document kết quả trong `benchmarks/quality_comparison.md`

### 5. Performance vs Quality Trade-offs
- steps=20 vs steps=40 vs steps=50
- CFG=7 vs CFG=10 vs CFG=12
- Tìm sweet spot: balance giữa latency và quality
- Document recommended settings cho từng use case

## Tài nguyên tham khảo
- MochiDiffusion repo: https://github.com/MochiDiffusion/MochiDiffusion
- coreml-community models (Hugging Face): https://huggingface.co/coreml-community
  - RealisticVision: https://huggingface.co/coreml-community/coreml-RealisticVision-v5.1
  - ControlNet: https://huggingface.co/coreml-community/ControlNet-Models-For-Core-ML
- Apple ml-stable-diffusion: https://github.com/apple/ml-stable-diffusion
- RealESRGAN Core ML: tìm variants trên GitHub hoặc convert từ PyTorch

---

**Tiếp theo:** Dựa trên đánh giá khả thi và các tinh chỉnh trên, bạn có thể:
- (A) Bắt đầu Phase 1: convert high-quality models (RealisticVision + ControlNet)
- (B) Tạo quality benchmark templates để test ngay khi có models
- (C) Review và approve kế hoạch, sau đó tôi tạo scripts chi tiết hơn

Hãy cho biết bước tiếp theo.
