# Environment Setup — HeyIm Project

Hướng dẫn chuẩn bị môi trường cho dự án HeyIm trên Mac Mini M2.

## Yêu cầu phần cứng
- Mac Mini M2 (hoặc Mac với Apple Silicon)
- RAM: tối thiểu 16GB (khuyến nghị 32GB cho SDXL)
- Storage: ~50GB free space (cho models và conversion workspace)

## Yêu cầu phần mềm

### 1. macOS
- macOS Sonoma (14.x) hoặc Ventura (13.x)
- Cập nhật lên phiên bản mới nhất:
```bash
softwareupdate -l
sudo softwareupdate -i -a
```

### 2. Xcode Command Line Tools
```bash
# Cài đặt
xcode-select --install

# Hoặc tải Xcode full từ App Store, sau đó:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Verify
xcode-select -p
# Output: /Applications/Xcode.app/Contents/Developer (hoặc /Library/Developer/CommandLineTools)
```

### 3. Homebrew
```bash
# Cài đặt Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow "Next steps" instructions để thêm Homebrew vào PATH
# Thường là:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify
brew --version
```

### 4. Python và uv
```bash
# Cài Python (nếu chưa có)
brew install python@3.11

# Cài uv (Python package manager nhanh, dùng bởi MochiDiffusion)
brew install uv

# Verify
python3 --version  # Python 3.11.x
uv --version       # uv x.x.x
```

### 5. Git LFS (cho tải large models)
```bash
brew install git-lfs
git lfs install

# Verify
git lfs version
```

### 6. Hugging Face CLI (optional, để tải models dễ hơn)
```bash
pip3 install huggingface-hub

# Login (cần HF token với read access)
huggingface-cli login
# Paste token từ https://huggingface.co/settings/tokens
```

## Setup MochiDiffusion Conversion Environment

```bash
# Clone MochiDiffusion repo
cd ~
git clone https://github.com/MochiDiffusion/MochiDiffusion.git
cd MochiDiffusion/conversion

# Tạo virtual environment với uv
uv venv

# Download conversion scripts
./download-script.sh

# Activate env (nếu cần)
source .venv/bin/activate

# Test
uv run python --version
```

## Chuẩn bị thư mục dự án

```bash
# Tạo thư mục models
cd ~/HeyIm
mkdir -p models benchmarks scripts/helpers

# Set permissions
chmod +x scripts/*.sh
```

## Checklist môi trường sẵn sàng ✓

- [ ] macOS Sonoma/Ventura updated
- [ ] Xcode CLT installed và configured
- [ ] Homebrew installed
- [ ] Python 3.11+ installed
- [ ] uv installed
- [ ] Git LFS installed
- [ ] MochiDiffusion cloned và conversion env setup
- [ ] Hugging Face token configured (nếu cần tải models)
- [ ] Disk space ≥ 50GB free
- [ ] `scripts/*.sh` có execute permission

## Troubleshooting

### Issue: `xcrun: error: unable to find utility "coremlcompiler"`
**Fix:** Mở Xcode → Settings → Locations → Command Line Tools dropdown → re-select Xcode version.

### Issue: `zsh: killed python` khi convert
**Fix:** Thiếu RAM. Đóng apps khác, hoặc dùng `nice -n 10` trước command, hoặc reboot.

### Issue: Git LFS download quá chậm
**Fix:** Dùng `wget` hoặc `curl` để tải trực tiếp file `.safetensors` từ Hugging Face thay vì git clone.

### Issue: Conversion script báo lỗi shard size
**Fix:** Với SDXL, edit conversion script line 188 để tăng `max_shard_size="15GB"` hoặc dùng `--half` flag.

## Tài nguyên
- MochiDiffusion conversion wiki: https://github.com/MochiDiffusion/MochiDiffusion/wiki/How-to-convert-Stable-Diffusion-models-to-Core-ML
- coreml-community models: https://huggingface.co/coreml-community
- Apple ml-stable-diffusion: https://github.com/apple/ml-stable-diffusion

---

Khi hoàn tất checklist, bạn sẵn sàng chạy `scripts/convert_realisticvision.sh` để bắt đầu Phase 1.
