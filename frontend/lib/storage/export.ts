/**
 * Export/Import utilities for IndexedDB data
 * Allows users to backup and restore their generated images
 */

import { imageDB } from './indexedDB';
import type { GeneratedImage } from '@/types';

/**
 * Export all images to a JSON file
 */
export async function exportHistory(): Promise<void> {
  try {
    const images = await imageDB.getAllImages();
    
    if (images.length === 0) {
      throw new Error('No images to export');
    }

    // Create export data with metadata
    const exportData = {
      version: 1,
      exportDate: new Date().toISOString(),
      imageCount: images.length,
      images: images,
    };

    // Convert to JSON
    const jsonString = JSON.stringify(exportData, null, 2);
    const blob = new Blob([jsonString], { type: 'application/json' });
    
    // Create download link
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `heyim-history-${Date.now()}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    
    console.log(`✓ Exported ${images.length} images`);
  } catch (error) {
    console.error('Export failed:', error);
    throw error;
  }
}

/**
 * Import images from a JSON file
 */
export async function importHistory(file: File): Promise<number> {
  try {
    // Read file
    const text = await file.text();
    const data = JSON.parse(text);
    
    // Validate structure
    if (!data.version || !Array.isArray(data.images)) {
      throw new Error('Invalid export file format');
    }
    
    // Import each image
    let imported = 0;
    let skipped = 0;
    
    for (const image of data.images) {
      try {
        // Validate required fields
        if (!image.id || !image.imageData || !image.prompt) {
          skipped++;
          continue;
        }
        
        await imageDB.addImage(image as GeneratedImage);
        imported++;
      } catch (error) {
        console.error('Failed to import image:', image.id, error);
        skipped++;
      }
    }
    
    console.log(`✓ Imported ${imported} images, skipped ${skipped}`);
    return imported;
  } catch (error) {
    console.error('Import failed:', error);
    throw error;
  }
}

/**
 * Export storage statistics
 */
export async function getStorageStats() {
  const images = await imageDB.getAllImages();
  const { usage, quota } = await imageDB.getStorageEstimate();
  
  let totalImageSize = 0;
  images.forEach(img => {
    // Estimate base64 size (4/3 of binary)
    totalImageSize += img.imageData.length * 0.75;
  });
  
  return {
    imageCount: images.length,
    totalImageSize,
    browserUsage: usage,
    browserQuota: quota,
    usagePercent: quota > 0 ? (usage / quota) * 100 : 0,
  };
}
