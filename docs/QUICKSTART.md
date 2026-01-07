# Quick Start Guide - HeyIm Backend

## Starting the Server

### Method 1: Direct Run
```bash
cd /Users/mac/HeyIm/backend
.build/debug/HeyImServer
```

### Method 2: Background Process
```bash
cd /Users/mac/HeyIm/backend
nohup .build/debug/HeyImServer > server.log 2>&1 &
echo $! > server.pid
```

### Method 3: With Rebuild
```bash
cd /Users/mac/HeyIm/backend
swift build && .build/debug/HeyImServer
```

## Stopping the Server

```bash
# Kill by name
pkill -9 HeyImServer

# Or kill by PID
kill $(cat /Users/mac/HeyIm/backend/server.pid)
```

## Quick Tests

### 1. Health Check
```bash
curl http://localhost:5858/health
```

### 2. Load Models
```bash
curl -X POST http://localhost:5858/api/load
```

### 3. Generate Image
```bash
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful landscape",
    "steps": 15
  }' | python3 -c "import sys,json,base64; \
    data=json.load(sys.stdin); \
    open('test.png','wb').write(base64.b64decode(data['imageBase64'])) \
      if data.get('success') else print('Error:', data.get('error'))"
```

## Checking Status

```bash
# Check if server is running
ps aux | grep HeyImServer | grep -v grep

# View server logs
tail -f /Users/mac/HeyIm/backend/server.log

# Check model status
curl -s http://localhost:5858/api/status | python3 -m json.tool
```

## Common Issues

### Port Already in Use
```bash
# Find process using port 5858
lsof -i :5858

# Kill it
kill -9 <PID>
```

### Models Not Found
Ensure models are compiled at:
```
/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum/
├── TextEncoder.mlmodelc
├── Unet.mlmodelc
├── VAEDecoder.mlmodelc
└── VAEEncoder.mlmodelc
```

If missing, recompile:
```bash
swift /Users/mac/HeyIm/compile_models.swift
```

## Performance Tips

- **Fast generation:** Use 10-15 steps
- **Balanced:** Use 20 steps (recommended)
- **High quality:** Use 25-30 steps
- **CFG Scale:** 7.0-7.5 for most prompts

## Server Info

- **Port:** 5858
- **Host:** 0.0.0.0 (accessible from network)
- **Platform:** macOS 14+
- **Compute:** CPU + Neural Engine
- **Memory:** ~2.5GB during generation

## Next Steps

1. ✅ Server running
2. ✅ Models loaded
3. ✅ Test generation successful
4. 🔜 Build frontend (Phase 3)

For full API documentation, see: `API_DOCUMENTATION.md`
