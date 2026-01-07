# HeyIm API Documentation

**Base URL:** `http://localhost:5858`  
**Version:** 0.1.0  
**Protocol:** HTTP/REST  
**Content-Type:** `application/json`

---

## Table of Contents
1. [Quick Start](#quick-start)
2. [Endpoints](#endpoints)
3. [Data Models](#data-models)
4. [Error Handling](#error-handling)
5. [Examples](#examples)

---

## Quick Start

### Starting the Server
```bash
cd /Users/mac/HeyIm/backend
swift build
.build/debug/HeyImServer
```

Server will start on port `5858`.

### Health Check
```bash
curl http://localhost:5858/health
# Response: OK
```

---

## Endpoints

### 1. Health Check

**Endpoint:** `GET /health`

**Description:** Simple health check to verify server is running.

**Response:**
```
OK
```

**Example:**
```bash
curl http://localhost:5858/health
```

---

### 2. Server Info

**Endpoint:** `GET /api/info`

**Description:** Get server information and status.

**Response:**
```json
{
  "name": "HeyIm AI Image Generation",
  "version": "0.1.0",
  "status": "ready",
  "model_path": "/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum"
}
```

**Fields:**
- `name` (string): Server name
- `version` (string): API version
- `status` (string): Server status ("ready" or "initializing")
- `model_path` (string): Path to Core ML models

**Example:**
```bash
curl http://localhost:5858/api/info
```

---

### 3. Model Status

**Endpoint:** `GET /api/status`

**Description:** Get current model loading status and generation queue.

**Response:**
```json
{
  "modelStatus": "loaded",
  "queueSize": 0,
  "isGenerating": false
}
```

**Fields:**
- `modelStatus` (string): "loaded" or "unloaded"
- `queueSize` (number): Number of pending generation requests
- `isGenerating` (boolean): Whether a generation is currently in progress

**Example:**
```bash
curl http://localhost:5858/api/status
```

---

### 4. Load Models

**Endpoint:** `POST /api/load`

**Description:** Load Stable Diffusion models into memory. Must be called before first generation.

**Response:**
```json
{
  "success": "true",
  "message": "Models loaded successfully"
}
```

**Notes:**
- First load takes 30-60 seconds
- Subsequent calls return immediately if already loaded
- Models are loaded from: `/Users/mac/HeyIm/models/RealisticVision_v51_split-einsum/`

**Example:**
```bash
curl -X POST http://localhost:5858/api/load
```

---

### 5. Generate Image

**Endpoint:** `POST /api/generate`

**Description:** Generate an image from a text prompt.

**Request Body:**
```json
{
  "prompt": "a beautiful landscape, mountains, sunset",
  "negativePrompt": "ugly, blurry, low quality",
  "steps": 20,
  "cfgScale": 7.5,
  "seed": 123456,
  "width": 512,
  "height": 512
}
```

**Request Fields:**

| Field | Type | Required | Default | Range | Description |
|-------|------|----------|---------|-------|-------------|
| `prompt` | string | ✅ Yes | - | - | Text description of desired image |
| `negativePrompt` | string | ❌ No | "" | - | What to avoid in the image |
| `steps` | number | ❌ No | 20 | 10-100 | Number of denoising steps (more = higher quality, slower) |
| `cfgScale` | number | ❌ No | 7.5 | 1.0-20.0 | Classifier-free guidance scale (higher = more prompt adherence) |
| `seed` | number | ❌ No | random | - | Random seed for reproducibility |
| `width` | number | ❌ No | 512 | - | Image width in pixels |
| `height` | number | ❌ No | 512 | - | Image height in pixels |

**Response:**
```json
{
  "success": true,
  "imageBase64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "metadata": {
    "prompt": "a beautiful landscape, mountains, sunset",
    "negativePrompt": "ugly, blurry, low quality",
    "steps": 20,
    "generationTime": 9.32,
    "cfgScale": 7.5,
    "seed": 842564325
  }
}
```

**Response Fields:**
- `success` (boolean): Whether generation succeeded
- `imageBase64` (string): Base64-encoded PNG image
- `error` (string, optional): Error message if failed
- `metadata` (object): Generation parameters and timing

**Example:**
```bash
curl -X POST http://localhost:5858/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful woman, portrait, professional photography",
    "negativePrompt": "ugly, blurry, low quality",
    "steps": 20,
    "cfgScale": 7.5
  }'
```

---

## Data Models

### GenerateRequest

```typescript
interface GenerateRequest {
  prompt: string;                    // Required
  negativePrompt?: string;           // Optional, default: ""
  steps?: number;                    // Optional, default: 20, range: 10-100
  cfgScale?: number;                 // Optional, default: 7.5, range: 1-20
  seed?: number;                     // Optional, random if not provided
  width?: number;                    // Optional, default: 512
  height?: number;                   // Optional, default: 512
}
```

### GenerateResponse

```typescript
interface GenerateResponse {
  success: boolean;
  imageBase64?: string;              // Base64 PNG
  error?: string;                    // Error message if failed
  metadata?: GenerationMetadata;
}
```

### GenerationMetadata

```typescript
interface GenerationMetadata {
  prompt: string;
  negativePrompt: string;
  steps: number;
  generationTime: number;            // Seconds
  cfgScale: number;
  seed: number;
}
```

### StatusResponse

```typescript
interface StatusResponse {
  modelStatus: "loaded" | "unloaded";
  queueSize: number;
  isGenerating: boolean;
}
```

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": "Error message here"
}
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Models not loaded" | Models not initialized | Call `/api/load` first |
| "Invalid prompt" | Empty or invalid prompt | Provide valid text prompt |
| "Steps must be between 10-100" | Invalid step count | Use 10-100 range |
| "CFG scale must be between 1-20" | Invalid CFG scale | Use 1-20 range |
| "Generation failed" | Model error | Check server logs |

### HTTP Status Codes

- `200 OK`: Successful request
- `400 Bad Request`: Invalid input parameters
- `500 Internal Server Error`: Server/model error

---

## Examples

### Example 1: Basic Generation

```javascript
// JavaScript/TypeScript
const response = await fetch('http://localhost:5858/api/generate', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    prompt: 'a beautiful sunset over mountains',
    steps: 20
  })
});

const data = await response.json();

if (data.success) {
  const imgElement = document.getElementById('output');
  imgElement.src = `data:image/png;base64,${data.imageBase64}`;
  console.log(`Generated in ${data.metadata.generationTime}s`);
}
```

### Example 2: With All Parameters

```python
# Python
import requests
import base64

response = requests.post('http://localhost:5858/api/generate', json={
    'prompt': 'a beautiful woman, portrait, professional photography',
    'negativePrompt': 'ugly, blurry, low quality, deformed',
    'steps': 25,
    'cfgScale': 8.0,
    'seed': 123456
})

data = response.json()

if data['success']:
    # Decode and save image
    img_data = base64.b64decode(data['imageBase64'])
    with open('output.png', 'wb') as f:
        f.write(img_data)
    
    print(f"Generated in {data['metadata']['generationTime']}s")
    print(f"Seed: {data['metadata']['seed']}")
```

### Example 3: React Component

```typescript
// React + TypeScript
import React, { useState } from 'react';

function ImageGenerator() {
  const [prompt, setPrompt] = useState('');
  const [image, setImage] = useState('');
  const [loading, setLoading] = useState(false);

  const generate = async () => {
    setLoading(true);
    
    try {
      const response = await fetch('http://localhost:5858/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          prompt,
          steps: 20,
          cfgScale: 7.5
        })
      });

      const data = await response.json();
      
      if (data.success) {
        setImage(`data:image/png;base64,${data.imageBase64}`);
      } else {
        alert(data.error);
      }
    } catch (error) {
      alert('Generation failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <input
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        placeholder="Enter your prompt..."
      />
      <button onClick={generate} disabled={loading}>
        {loading ? 'Generating...' : 'Generate'}
      </button>
      {image && <img src={image} alt="Generated" />}
    </div>
  );
}
```

### Example 4: Batch Generation

```bash
# Bash script for batch generation
for i in {1..5}; do
  echo "Generating image $i..."
  
  curl -X POST http://localhost:5858/api/generate \
    -H "Content-Type: application/json" \
    -d "{\"prompt\": \"landscape number $i\", \"steps\": 15}" \
    -o "output_$i.json"
  
  # Extract and save image
  cat "output_$i.json" | \
    python3 -c "import sys,json,base64; \
      data=json.load(sys.stdin); \
      open('image_$i.png','wb').write(base64.b64decode(data['imageBase64']))"
  
  echo "Done!"
done
```

---

## Performance Guidelines

### Generation Time vs Steps

| Steps | Approx. Time | Quality |
|-------|-------------|---------|
| 10 | 5s | Fast, lower quality |
| 15 | 7s | Balanced |
| 20 | 9s | Good quality |
| 25 | 12s | High quality |
| 30 | 15s | Very high quality |
| 50 | 25s | Maximum quality |

### CFG Scale Guidelines

| CFG Scale | Effect |
|-----------|--------|
| 1.0-3.0 | More creative, less adherence to prompt |
| 5.0-7.5 | Balanced (recommended) |
| 8.0-12.0 | Strong prompt adherence |
| 13.0-20.0 | Very strict, may over-saturate |

### Recommended Settings

**Fast Preview:**
```json
{
  "steps": 10,
  "cfgScale": 7.0
}
```

**Balanced:**
```json
{
  "steps": 20,
  "cfgScale": 7.5
}
```

**High Quality:**
```json
{
  "steps": 30,
  "cfgScale": 8.0
}
```

---

## Tips & Best Practices

### Prompt Engineering

✅ **Good Prompts:**
- "a beautiful woman, portrait, professional photography, studio lighting"
- "sunset over mountains, landscape photography, golden hour, cinematic"
- "modern architecture, minimalist design, white building, blue sky"

❌ **Poor Prompts:**
- "woman" (too vague)
- "something cool" (not descriptive)
- "asdfghjkl" (nonsense)

### Negative Prompts

Common negative prompts to improve quality:
```
"ugly, blurry, low quality, deformed, disfigured, bad anatomy, 
bad proportions, watermark, text, signature, out of frame"
```

### Reproducibility

To get the same image again:
1. Use the same `seed` value
2. Keep all other parameters identical
3. The `seed` is returned in the response metadata

---

## WebSocket Support (Future)

Currently not implemented. Future versions will support WebSocket for:
- Real-time progress updates
- Streaming generation
- Live preview

---

## Rate Limiting

Currently no rate limiting is implemented. For production:
- Consider implementing queue system
- Limit concurrent generations to 1-2
- Add request throttling

---

## Security Considerations

⚠️ **Development Only:** This API has no authentication and should only be used in local development.

For production deployment:
- Add API authentication (JWT, API keys)
- Implement rate limiting
- Add input sanitization
- Use HTTPS
- Add CORS properly

---

## Support

For issues or questions:
- Check server logs: `/Users/mac/HeyIm/backend/server.log`
- Review Phase 2 completion report
- Contact: HeyIm Development Team

---

**Last Updated:** January 1, 2026  
**API Version:** 0.1.0  
**Server:** Vapor 4.99+ on macOS 14+
