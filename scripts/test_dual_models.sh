#!/bin/bash
# Test dual-model system after Juggernaut XL conversion completes

set -e

BACKEND_URL="http://localhost:8080"
OUTPUT_DIR="/Users/mac/HeyIm/test_outputs"

echo "🧪 Testing HeyIm Dual-Model System"
echo "=================================="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Test 1: Fast Mode (RealisticVision) - Portrait
echo "Test 1: Fast Mode - Portrait"
echo "----------------------------"
curl -X POST "$BACKEND_URL/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "professional portrait of a beautiful woman, detailed face, bokeh background, high quality",
    "negativePrompt": "ugly, blurry, low quality",
    "modelType": "fast",
    "steps": 30,
    "cfgScale": 8.0
  }' \
  --output "$OUTPUT_DIR/fast_portrait.json"

echo "✅ Fast Mode test complete"
echo ""

# Test 2: Quality Mode (Juggernaut XL) - Product
echo "Test 2: Quality Mode - Product Photography"
echo "-------------------------------------------"
curl -X POST "$BACKEND_URL/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Product Photography: modern wireless keyboard for iMac, clean white background, professional studio lighting, 8k uhd, high quality, sharp focus",
    "negativePrompt": "blurry, low quality, distorted",
    "modelType": "quality",
    "steps": 35,
    "cfgScale": 5.0
  }' \
  --output "$OUTPUT_DIR/quality_keyboard.json"

echo "✅ Quality Mode test complete"
echo ""

# Test 3: Quality Mode - Food Photography
echo "Test 3: Quality Mode - Food Photography"
echo "---------------------------------------"
curl -X POST "$BACKEND_URL/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Food Photography: gourmet pasta dish, professional restaurant plating, warm lighting, shallow depth of field, magazine quality",
    "negativePrompt": "blurry, unappetizing",
    "modelType": "quality",
    "steps": 35,
    "cfgScale": 4.5
  }' \
  --output "$OUTPUT_DIR/quality_food.json"

echo "✅ Food Photography test complete"
echo ""

# Extract image paths and generation times
echo "📊 Test Results:"
echo "==============="
echo ""

for file in "$OUTPUT_DIR"/*.json; do
  name=$(basename "$file" .json)
  time=$(jq -r '.metadata.generationTime' "$file" 2>/dev/null || echo "N/A")
  model=$(jq -r '.metadata.modelType' "$file" 2>/dev/null || echo "N/A")
  image=$(jq -r '.imageUrl' "$file" 2>/dev/null || echo "N/A")
  
  echo "$name:"
  echo "  Model: $model"
  echo "  Time: ${time}s"
  echo "  Image: $image"
  echo ""
done

echo "✅ All tests complete!"
echo ""
echo "🎯 Next steps:"
echo "  1. View images in frontend: http://localhost:3000"
echo "  2. Compare Fast vs Quality mode results"
echo "  3. Verify keyboard prompt works with Quality Mode"
