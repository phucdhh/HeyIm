# Phase 3 Planning: Frontend Development

**Duration:** Weeks 5-7 (3 weeks)  
**Status:** 🔜 Ready to Start  
**Prerequisites:** ✅ All Complete

---

## Overview

Build a modern, responsive web interface for the HeyIm AI image generation system using React/Next.js.

---

## Tech Stack

### Core
- **Framework:** Next.js 14+ (App Router)
- **Language:** TypeScript
- **UI Library:** React 18+
- **Styling:** Tailwind CSS 3+
- **State Management:** React Context / Zustand

### Additional Libraries
- **Form Handling:** React Hook Form
- **Image Display:** React Image Gallery / Lightbox
- **Notifications:** React Hot Toast
- **Icons:** Lucide React / Heroicons
- **HTTP Client:** Built-in fetch / Axios

---

## Features Roadmap

### Week 5: Basic UI Setup

#### 5.1 Project Initialization
- [ ] Create Next.js project with TypeScript
- [ ] Setup Tailwind CSS
- [ ] Configure ESLint & Prettier
- [ ] Setup folder structure

#### 5.2 Core Components
- [ ] Layout component (header, main, footer)
- [ ] Prompt input form
- [ ] Parameter controls (steps, CFG scale)
- [ ] Generate button with loading state
- [ ] Image display area

#### 5.3 API Integration
- [ ] API client setup
- [ ] Connect to backend endpoints
- [ ] Handle loading states
- [ ] Error handling & display

**Deliverable:** Basic working interface that can generate images

---

### Week 6: Core Features

#### 6.1 Advanced Controls
- [ ] Negative prompt input
- [ ] Advanced settings panel (collapsible)
- [ ] Seed input for reproducibility
- [ ] Resolution selector
- [ ] Preset prompt templates

#### 6.2 Generation History
- [ ] History state management
- [ ] Grid view of generated images
- [ ] Click to view full size
- [ ] Download images
- [ ] Copy generation parameters

#### 6.3 Progress & Feedback
- [ ] Real-time progress indicator
- [ ] Generation time display
- [ ] Success/error notifications
- [ ] Loading skeletons

**Deliverable:** Full-featured image generation interface

---

### Week 7: Polish & Enhancement

#### 7.1 UX Improvements
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Dark/light theme toggle
- [ ] Keyboard shortcuts
- [ ] Drag & drop for img2img (future)
- [ ] Tooltips and help text

#### 7.2 Performance
- [ ] Image lazy loading
- [ ] API request debouncing
- [ ] Optimistic UI updates
- [ ] Client-side caching

#### 7.3 Additional Features
- [ ] Gallery view with filters
- [ ] Export batch as ZIP
- [ ] Share generated images
- [ ] Copy prompt to clipboard
- [ ] Generation metadata display

**Deliverable:** Production-ready frontend

---

## File Structure

```
frontend/
├── app/
│   ├── layout.tsx                 # Root layout
│   ├── page.tsx                   # Home page
│   ├── generate/
│   │   └── page.tsx              # Generation interface
│   ├── gallery/
│   │   └── page.tsx              # History/gallery
│   └── api/                       # API routes (if needed)
│
├── components/
│   ├── ui/                        # Reusable UI components
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Card.tsx
│   │   ├── Slider.tsx
│   │   └── ...
│   ├── generate/
│   │   ├── PromptInput.tsx
│   │   ├── ParameterControls.tsx
│   │   ├── GenerateButton.tsx
│   │   └── ImageDisplay.tsx
│   ├── gallery/
│   │   ├── ImageGrid.tsx
│   │   ├── ImageCard.tsx
│   │   └── ImageModal.tsx
│   └── layout/
│       ├── Header.tsx
│       ├── Sidebar.tsx
│       └── Footer.tsx
│
├── lib/
│   ├── api/
│   │   ├── client.ts             # API client
│   │   └── types.ts              # TypeScript types
│   ├── hooks/
│   │   ├── useGenerate.ts        # Generation hook
│   │   └── useHistory.ts         # History management
│   └── utils/
│       ├── image.ts              # Image utilities
│       └── validation.ts         # Input validation
│
├── styles/
│   └── globals.css               # Global styles
│
├── public/
│   └── images/                   # Static images
│
└── types/
    └── index.ts                  # Shared types
```

---

## Component Specifications

### 1. PromptInput Component

```typescript
interface PromptInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  maxLength?: number;
}
```

**Features:**
- Textarea with auto-resize
- Character counter
- Prompt suggestions/templates
- Clear button

---

### 2. ParameterControls Component

```typescript
interface ParameterControlsProps {
  steps: number;
  cfgScale: number;
  onStepsChange: (value: number) => void;
  onCfgScaleChange: (value: number) => void;
}
```

**Features:**
- Slider for steps (10-100)
- Slider for CFG scale (1-20)
- Real-time value display
- Preset buttons (Fast/Balanced/Quality)

---

### 3. ImageDisplay Component

```typescript
interface ImageDisplayProps {
  imageUrl: string;
  loading: boolean;
  metadata?: GenerationMetadata;
  onDownload: () => void;
  onRegenerate: () => void;
}
```

**Features:**
- Loading skeleton
- Zoom/fullscreen
- Download button
- Regenerate with same params
- Metadata overlay

---

### 4. ImageGrid Component

```typescript
interface ImageGridProps {
  images: GeneratedImage[];
  onImageClick: (image: GeneratedImage) => void;
}
```

**Features:**
- Responsive grid layout
- Hover effects
- Quick actions (download, delete)
- Infinite scroll / pagination

---

## API Integration

### API Client

```typescript
// lib/api/client.ts
class HeyImAPI {
  private baseURL = 'http://localhost:5858';

  async getStatus(): Promise<StatusResponse> {
    const response = await fetch(`${this.baseURL}/api/status`);
    return response.json();
  }

  async loadModels(): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${this.baseURL}/api/load`, {
      method: 'POST'
    });
    return response.json();
  }

  async generate(request: GenerateRequest): Promise<GenerateResponse> {
    const response = await fetch(`${this.baseURL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request)
    });
    return response.json();
  }
}

export const api = new HeyImAPI();
```

---

## State Management

### Generation State

```typescript
interface GenerationState {
  // Current generation
  prompt: string;
  negativePrompt: string;
  steps: number;
  cfgScale: number;
  seed?: number;
  
  // Status
  isGenerating: boolean;
  currentImage?: string;
  error?: string;
  
  // History
  history: GeneratedImage[];
}
```

### Actions

```typescript
interface GenerationActions {
  setPrompt: (prompt: string) => void;
  setNegativePrompt: (prompt: string) => void;
  setSteps: (steps: number) => void;
  setCfgScale: (scale: number) => void;
  generate: () => Promise<void>;
  addToHistory: (image: GeneratedImage) => void;
  clearHistory: () => void;
}
```

---

## Design System

### Colors

```typescript
// Tailwind config
colors: {
  primary: {
    50: '#f0f9ff',
    100: '#e0f2fe',
    // ... up to 900
  },
  secondary: {
    // ...
  }
}
```

### Typography

- **Headings:** Inter font family
- **Body:** System font stack
- **Monospace:** JetBrains Mono (for metadata)

### Spacing

- Base unit: 4px (0.25rem)
- Common: 4, 8, 12, 16, 24, 32, 48, 64

---

## Responsive Breakpoints

```typescript
screens: {
  'sm': '640px',   // Mobile landscape
  'md': '768px',   // Tablet
  'lg': '1024px',  // Desktop
  'xl': '1280px',  // Large desktop
  '2xl': '1536px'  // Extra large
}
```

---

## User Flows

### 1. First Visit
1. Land on homepage
2. See example images
3. Click "Generate" CTA
4. Enter prompt
5. Click generate
6. Wait for result
7. View & download image

### 2. Regular Usage
1. Open app
2. Enter prompt
3. Adjust parameters (optional)
4. Generate
5. View in history
6. Regenerate with tweaks

### 3. Advanced Usage
1. Use advanced settings
2. Set custom seed
3. Use negative prompts
4. Save favorite presets
5. Batch generation
6. Gallery management

---

## Testing Strategy

### Unit Tests
- Component rendering
- State management
- API client functions
- Utility functions

### Integration Tests
- API integration
- Full generation flow
- History management
- Download functionality

### E2E Tests
- Complete user journeys
- Cross-browser compatibility
- Responsive design
- Performance benchmarks

---

## Deployment Considerations

### Development
```bash
npm run dev
# Runs on http://localhost:3000
```

### Production
```bash
npm run build
npm run start
# Or deploy to Vercel/Netlify
```

### Environment Variables
```env
NEXT_PUBLIC_API_URL=http://localhost:5858
NEXT_PUBLIC_GA_ID=UA-XXXXXXXXX-X
```

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Page Load Time | <2s | Lighthouse |
| Time to Interactive | <3s | Lighthouse |
| Generation Success Rate | >95% | Analytics |
| User Satisfaction | >4.5/5 | Survey |
| Mobile Responsiveness | 100% | Manual testing |

---

## Dependencies (Estimated)

```json
{
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^5.0.0",
    "tailwindcss": "^3.3.0",
    "zustand": "^4.4.0",
    "react-hook-form": "^7.48.0",
    "react-hot-toast": "^2.4.1",
    "lucide-react": "^0.294.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/node": "^20.0.0",
    "eslint": "^8.54.0",
    "eslint-config-next": "^14.0.0",
    "prettier": "^3.1.0"
  }
}
```

---

## Timeline Summary

**Week 5:** Basic UI + API Integration  
**Week 6:** Advanced Features + History  
**Week 7:** Polish + Responsive Design

**Total:** 3 weeks for MVP frontend

---

## Next Action Items

1. Initialize Next.js project
2. Setup Tailwind & TypeScript
3. Create basic layout
4. Implement prompt input
5. Connect to backend API
6. Test first generation
7. Iterate and improve

---

**Ready to Start Phase 3!** 🚀

Let me know when you want to begin frontend development.
