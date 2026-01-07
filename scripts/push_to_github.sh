#!/bin/bash

# Script to prepare and push HeyIm to GitHub
# Run this from the project root: ./scripts/push_to_github.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}HeyIm - GitHub Push Preparation${NC}"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "backend" ]; then
    echo -e "${RED}Error: Must run from HeyIm project root${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Check for sensitive data${NC}"
echo "----------------------------------------"

# Check for common sensitive patterns
SENSITIVE_FOUND=0

# Check for OpenAI/Anthropic API keys (sk-...)
if grep -r "sk-[A-Za-z0-9]\{40,\}" --include="*.swift" --include="*.ts" --include="*.tsx" backend/ frontend/app frontend/components 2>/dev/null; then
    echo -e "${RED}✗ Found potential API keys in source code${NC}"
    SENSITIVE_FOUND=1
fi

# Check for secrets in deployment config (excluding standard env var names)
if grep -ri "password.*=.*[^placeholder]\|secret.*=.*[^placeholder]\|token.*=.*[^placeholder]" deploy/*.plist 2>/dev/null | grep -v "StandardOutPath\|StandardErrorPath"; then
    echo -e "${RED}✗ Found potential secrets in deployment files${NC}"
    SENSITIVE_FOUND=1
fi

if [ $SENSITIVE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No sensitive data detected${NC}"
else
    echo -e "${RED}Please remove sensitive data before pushing!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Verify required files${NC}"
echo "----------------------------------------"

required_files=("LICENSE" "README.md" "README.en.md" "CONTRIBUTING.md" ".gitignore")
missing_files=0

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file missing${NC}"
        missing_files=1
    fi
done

if [ $missing_files -eq 1 ]; then
    echo -e "${RED}Please create missing files!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 3: Check .gitignore coverage${NC}"
echo "----------------------------------------"

# Verify large files are ignored
if [ -d "models" ]; then
    MODEL_SIZE=$(du -sh models/ | cut -f1)
    echo "Models directory size: $MODEL_SIZE"
    
    if git check-ignore models/*.mlpackage 2>/dev/null; then
        echo -e "${GREEN}✓ Models properly ignored${NC}"
    else
        echo -e "${RED}⚠ Warning: Models might not be fully ignored${NC}"
    fi
fi

if [ -d "node_modules" ]; then
    if git check-ignore frontend/node_modules 2>/dev/null; then
        echo -e "${GREEN}✓ node_modules ignored${NC}"
    else
        echo -e "${RED}✗ node_modules not ignored!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Step 4: Initialize Git (if needed)${NC}"
echo "----------------------------------------"

if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
else
    echo -e "${GREEN}✓ Git already initialized${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Stage files${NC}"
echo "----------------------------------------"

# Add all files respecting .gitignore
git add .

# Show what will be committed
echo ""
echo "Files to be committed:"
git status --short

echo ""
echo -e "${YELLOW}Step 6: Create initial commit${NC}"
echo "----------------------------------------"

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    echo "Creating commit..."
    git commit -m "Initial commit: HeyIm AI image generation web app

Features:
- Swift/Vapor backend with Core ML integration
- Next.js frontend with TypeScript
- Image-to-image support with PNDM scheduler
- Optimized for Apple Silicon (ANE)
- Production-ready deployment scripts

Tech stack:
- Backend: Swift 5.8+, Vapor, Core ML
- Frontend: Next.js 16, React 19, TypeScript
- Model: RealisticVision v5.1 (SD 1.5)
- Deployment: launchd, Cloudflare Tunnel"
    
    echo -e "${GREEN}✓ Initial commit created${NC}"
fi

echo ""
echo -e "${YELLOW}Step 7: Add remote and push${NC}"
echo "----------------------------------------"

# Check if remote exists
if git remote | grep -q "origin"; then
    echo "Remote 'origin' already exists:"
    git remote get-url origin
else
    echo "Adding remote repository..."
    git remote add origin https://github.com/phucdhh/HeyIm.git
    echo -e "${GREEN}✓ Remote added${NC}"
fi

echo ""
echo -e "${GREEN}Ready to push!${NC}"
echo ""
echo "To push to GitHub, run:"
echo -e "${YELLOW}  git branch -M main${NC}"
echo -e "${YELLOW}  git push -u origin main${NC}"
echo ""
echo "Or if you want to force push (be careful!):"
echo -e "${RED}  git push -u origin main --force${NC}"
echo ""

read -p "Push to GitHub now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch -M main
    git push -u origin main
    echo ""
    echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
    echo ""
    echo "View your repository at:"
    echo "  https://github.com/phucdhh/HeyIm"
else
    echo ""
    echo -e "${YELLOW}Push cancelled. You can push manually later.${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
