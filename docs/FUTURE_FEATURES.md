# Future Features - To be Implemented

## Phase 3 Extended Features (Post-MVP)

### 1. ControlNet Integration
**Priority:** High  
**Estimated Time:** 1-2 hours  
**Description:**
- Upload reference image for ControlNet (Canny/OpenPose/Depth)
- Preview ControlNet reference
- ControlNet type selector
- Backend already supports ControlNet, just need UI

**Tasks:**
- [ ] Add image upload component
- [ ] ControlNet type dropdown (Canny, OpenPose, Depth)
- [ ] Reference image preview
- [ ] Update API client to send ControlNet params
- [ ] Update GenerateRequest type

### 2. Settings Page
**Priority:** Medium  
**Estimated Time:** 30-45 minutes  
**Description:**
- Configure default generation parameters
- Theme settings (optional)
- Language toggle (if needed)

**Tasks:**
- [ ] Create Settings page component
- [ ] Default parameters form (steps, CFG, negative prompt)
- [ ] Save settings to localStorage
- [ ] Apply settings on form load

### 3. img2img Feature
**Priority:** Medium  
**Estimated Time:** 2-3 hours  
**Description:**
- Upload initial image
- Strength/denoising slider (0.0-1.0)
- Preview uploaded image
- Backend may need img2img endpoint

**Tasks:**
- [ ] Add img2img tab/mode toggle
- [ ] Image upload component
- [ ] Strength slider UI
- [ ] Update API client for img2img
- [ ] Backend: implement img2img endpoint (if not exists)

### 4. Batch Generation
**Priority:** Low  
**Estimated Time:** 1-2 hours  
**Description:**
- Generate multiple variations with same prompt
- Different seeds for each
- Display all results in grid

**Tasks:**
- [ ] Add batch count input (1-4)
- [ ] Generate multiple images in parallel/sequence
- [ ] Display results in grid view
- [ ] Batch download option

### 5. Advanced Metadata & EXIF
**Priority:** Low  
**Estimated Time:** 1 hour  
**Description:**
- Embed generation parameters in PNG metadata
- Display full metadata in modal
- Copy metadata as JSON

**Tasks:**
- [ ] Backend: embed EXIF in PNG
- [ ] Frontend: metadata modal component
- [ ] Copy metadata button
- [ ] Display model version, timestamp

### 6. E2E Testing
**Priority:** Medium  
**Estimated Time:** 1-2 hours  
**Description:**
- Basic smoke tests for critical flows
- Playwright or Cypress setup

**Tasks:**
- [ ] Setup test framework (Playwright)
- [ ] Test: load page → generate image → download
- [ ] Test: view history → click image → regenerate
- [ ] Test: apply example prompt → generate
- [ ] CI integration (optional)

### 7. Image Comparison Tool
**Priority:** Low  
**Description:**
- Compare two generated images side-by-side
- Slider to swipe between versions
- Useful for testing parameters

### 8. Favorites System
**Priority:** Low  
**Description:**
- Mark images as favorites
- Separate "Favorites" tab
- Export favorites collection

### 9. Prompt Library
**Priority:** Low  
**Description:**
- Save custom prompts
- Organize by tags/categories
- Share prompts with others

### 10. Real-time Collaboration
**Priority:** Very Low  
**Description:**
- Share generation sessions
- Live preview for multiple users
- Requires WebSocket infrastructure

## Quality Improvements

### Performance
- [ ] Lazy load history images (virtualization)
- [ ] Image compression for localStorage
- [ ] Optimize re-renders with more granular memoization

### UX Enhancements
- [ ] Keyboard shortcuts (Enter to generate, etc.)
- [ ] Drag & drop image upload
- [ ] Toast notifications for all actions
- [ ] Loading skeletons instead of spinners
- [ ] Dark mode support

### Accessibility
- [ ] ARIA labels for all interactive elements
- [ ] Keyboard navigation support
- [ ] Screen reader testing
- [ ] High contrast mode

## Documentation Needed
- [ ] User guide (Vietnamese)
- [ ] API documentation
- [ ] Troubleshooting guide
- [ ] Video tutorials

## Notes
- Prioritize features based on user feedback after deployment
- ControlNet is highest priority as it's in original Phase 3 plan
- Settings page is quick win for better UX
- img2img requires backend changes, coordinate with backend team
