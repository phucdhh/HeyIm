#!/bin/bash

# Test script for img2img functionality

echo "🧪 Testing HeyIm Image-to-Image functionality..."

# First generate a base image
echo "📸 Step 1: Generating base image..."
RESPONSE=$(curl -s -X POST http://localhost:5858/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "prompt": "beautiful woman portrait, photorealistic", 
    "steps": 20,
    "cfgScale": 7.0
  }')

# Extract base64 image
BASE_IMAGE=$(echo "$RESPONSE" | jq -r '.imageBase64')

if [ "$BASE_IMAGE" = "null" ] || [ -z "$BASE_IMAGE" ]; then
    echo "❌ Failed to generate base image"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

echo "✅ Base image generated (${#BASE_IMAGE} characters)"

# Now test img2img with the base image
echo "🎨 Step 2: Testing img2img transformation..."
IMG2IMG_RESPONSE=$(curl -s -X POST http://localhost:5858/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "prompt": "same woman but in fantasy armor, medieval style", 
    "steps": 25,
    "cfgScale": 8.0,
    "inputImage": "'"$BASE_IMAGE"'",
    "strength": 0.7
  }')

# Check img2img result
IMG2IMG_SUCCESS=$(echo "$IMG2IMG_RESPONSE" | jq -r '.success')
IMG2IMG_IMAGE=$(echo "$IMG2IMG_RESPONSE" | jq -r '.imageBase64')
HAS_INPUT=$(echo "$IMG2IMG_RESPONSE" | jq -r '.metadata.hasInputImage')

if [ "$IMG2IMG_SUCCESS" = "true" ] && [ "$IMG2IMG_IMAGE" != "null" ]; then
    echo "✅ Image-to-image transformation successful!"
    echo "   Original image: ${#BASE_IMAGE} chars"
    echo "   Transformed image: ${#IMG2IMG_IMAGE} chars" 
    echo "   Had input image: $HAS_INPUT"
    echo "   Metadata:"
    echo "$IMG2IMG_RESPONSE" | jq '.metadata'
else
    echo "❌ Image-to-image transformation failed"
    echo "$IMG2IMG_RESPONSE" | jq '.'
    exit 1
fi

echo ""
echo "🎉 All tests passed! Image-to-image functionality is working."