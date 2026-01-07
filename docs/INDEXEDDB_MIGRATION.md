# IndexedDB Storage Migration

## Overview
HeyIm now uses **IndexedDB** for efficient browser-side image storage instead of localStorage.

## Benefits

### 1. **Much Larger Storage Capacity**
- **localStorage**: ~5-10 MB limit
- **IndexedDB**: Typically 50% of available disk space (can be GBs)
- Can store 100+ high-quality images without issues

### 2. **Better Performance**
- Images stored as **Blobs** instead of base64
- **~30% smaller** file size (no base64 encoding overhead)
- Faster read/write operations
- Non-blocking async operations

### 3. **Automatic Cleanup**
- Auto-removes oldest images when exceeding 100 images
- Prevents storage quota issues

## Technical Details

### Storage Structure
```typescript
interface ImageRecord {
  id: string;
  imageBlob: Blob;           // Native binary format
  prompt: string;
  negativePrompt?: string;
  steps: number;
  cfgScale: number;
  seed: number;
  generationTime: number;
  timestamp: number;
}
```

### Database Info
- **Database Name**: `HeyImDB`
- **Object Store**: `images`
- **Index**: `timestamp` (for sorting)
- **Max Images**: 100 (auto-cleanup)

## Migration Process

### Automatic Migration
On first load after update, the app will:
1. Check for old localStorage data (`heyim_history`)
2. Convert base64 strings to Blobs
3. Save to IndexedDB
4. Remove localStorage data
5. Show migration count in console

### Manual Migration
If needed, use the debug tool:
```
https://heyim.truyenthong.edu.vn/debug.html
```

Options:
- **Inspect IndexedDB**: View current database contents
- **Check localStorage**: See if legacy data exists
- **Validate Images**: Preview all stored images
- **Clear IndexedDB**: Delete all images
- **Clear localStorage**: Remove legacy data

## Storage Monitoring

The History tab now shows storage usage:
```
Browser storage: 45.2 MB / 10.5 GB
```

## API

### Usage in Code
```typescript
import { imageDB } from '@/lib/storage/indexedDB';

// Add image
await imageDB.addImage(generatedImage);

// Get all images
const images = await imageDB.getAllImages();

// Delete image
await imageDB.deleteImage(id);

// Clear all
await imageDB.clearAll();

// Get storage info
const { usage, quota } = await imageDB.getStorageEstimate();
```

## Browser Support

IndexedDB is supported in all modern browsers:
- Chrome/Edge 24+
- Firefox 16+
- Safari 10+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Troubleshooting

### "Database not initialized" error
- The database will auto-initialize on first use
- Check browser console for errors
- Try clearing browser cache and reload

### Images not showing
1. Open debug tool: https://heyim.truyenthong.edu.vn/debug.html
2. Click "Validate Images"
3. Check for corrupted records
4. Clear and regenerate if needed

### Storage quota exceeded
- The app auto-limits to 100 images
- Manually clear old images via History tab
- Or use debug tool to clear all

## Comparison: Before vs After

| Feature | localStorage | IndexedDB |
|---------|-------------|-----------|
| Storage Limit | ~5-10 MB | ~GBs |
| Data Format | Base64 string | Native Blob |
| Overhead | +33% size | No overhead |
| Max Images | ~10-20 | 100+ |
| Performance | Blocking | Async |
| Auto-cleanup | No | Yes |

## Server Impact

**Zero impact on server:**
- All images stored in browser only
- Server only generates and returns base64
- No server-side storage or file system access
- Reduces server load and bandwidth

## Privacy

Images are stored **locally in your browser only**:
- Not sent to any server after generation
- Not accessible by other websites
- Cleared when you clear browser data
- Private to your device

## Next Steps

Consider future enhancements:
1. Export/import history
2. Cloud sync (optional)
3. Image compression options
4. Batch operations
5. Search/filter by prompt
