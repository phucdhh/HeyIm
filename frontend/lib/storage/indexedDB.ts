/**
 * IndexedDB wrapper for storing images efficiently
 * Stores images as Blobs instead of base64 to save space (~30% reduction)
 */

import type { GeneratedImage } from '@/types';

const DB_NAME = 'HeyImDB';
const DB_VERSION = 1;
const STORE_NAME = 'images';
const MAX_IMAGES = 100; // Maximum images to store

interface ImageRecord {
  id: string;
  imageBlob: Blob;
  prompt: string;
  negativePrompt?: string;
  steps: number;
  cfgScale: number;
  seed: number;
  generationTime: number;
  timestamp: number;
}

class ImageDatabase {
  private db: IDBDatabase | null = null;
  private initPromise: Promise<void> | null = null;

  /**
   * Initialize database connection
   */
  async init(): Promise<void> {
    if (this.db) return;
    if (this.initPromise) return this.initPromise;

    this.initPromise = new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error('IndexedDB error:', request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        console.log('✓ IndexedDB initialized');
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          const store = db.createObjectStore(STORE_NAME, { keyPath: 'id' });
          store.createIndex('timestamp', 'timestamp', { unique: false });
          console.log('✓ IndexedDB object store created');
        }
      };
    });

    return this.initPromise;
  }

  /**
   * Convert base64 to Blob
   */
  private base64ToBlob(base64: string, contentType = 'image/png'): Blob {
    const byteCharacters = atob(base64);
    const byteArrays: Uint8Array[] = [];

    for (let offset = 0; offset < byteCharacters.length; offset += 512) {
      const slice = byteCharacters.slice(offset, offset + 512);
      const byteNumbers = new Array(slice.length);
      
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }
      
      byteArrays.push(new Uint8Array(byteNumbers));
    }

    return new Blob(byteArrays as BlobPart[], { type: contentType });
  }

  /**
   * Convert Blob to base64
   */
  private async blobToBase64(blob: Blob): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64 = reader.result as string;
        // Remove data:image/png;base64, prefix
        const base64Data = base64.split(',')[1];
        resolve(base64Data);
      };
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  /**
   * Add image to database
   */
  async addImage(image: GeneratedImage): Promise<void> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    // Convert base64 to Blob for efficient storage
    const imageBlob = this.base64ToBlob(image.imageData);

    const record: ImageRecord = {
      id: image.id,
      imageBlob,
      prompt: image.prompt,
      negativePrompt: image.negativePrompt,
      steps: image.steps,
      cfgScale: image.cfgScale,
      seed: image.seed,
      generationTime: image.generationTime,
      timestamp: image.timestamp,
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.put(record);

      request.onsuccess = async () => {
        // Check if we exceed max images and cleanup old ones
        await this.cleanupOldImages();
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get all images from database
   */
  async getAllImages(): Promise<GeneratedImage[]> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    // First, collect all records (synchronously within transaction)
    const records = await new Promise<ImageRecord[]>((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const index = store.index('timestamp');
      const request = index.openCursor(null, 'prev'); // Newest first

      const results: ImageRecord[] = [];

      request.onsuccess = (event) => {
        const cursor = (event.target as IDBRequest).result;
        
        if (cursor) {
          results.push(cursor.value as ImageRecord);
          cursor.continue();
        } else {
          resolve(results);
        }
      };

      request.onerror = () => reject(request.error);
    });

    // Then convert Blobs to base64 (outside transaction)
    const images: GeneratedImage[] = [];
    for (const record of records) {
      try {
        const imageData = await this.blobToBase64(record.imageBlob);
        
        // Debug: Check converted data
        if (images.length === 0) {
          console.log('First image from IndexedDB:', {
            id: record.id,
            blobSize: record.imageBlob.size,
            blobType: record.imageBlob.type,
            convertedLength: imageData.length,
            convertedPrefix: imageData.substring(0, 50),
            isValidBase64: /^[A-Za-z0-9+/=]+$/.test(imageData.substring(0, 100)),
          });
        }
        
        images.push({
          id: record.id,
          imageData,
          prompt: record.prompt,
          negativePrompt: record.negativePrompt,
          steps: record.steps,
          cfgScale: record.cfgScale,
          seed: record.seed,
          generationTime: record.generationTime,
          timestamp: record.timestamp,
        });
      } catch (error) {
        console.error('Failed to convert blob for image:', record.id, error);
      }
    }

    return images;
  }

  /**
   * Delete image by ID
   */
  async deleteImage(id: string): Promise<void> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.delete(id);

      request.onsuccess = () => resolve();
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Clear all images
   */
  async clearAll(): Promise<void> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.clear();

      request.onsuccess = () => {
        console.log('✓ All images cleared from IndexedDB');
        resolve();
      };
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get total count of images
   */
  async getCount(): Promise<number> {
    await this.init();
    if (!this.db) throw new Error('Database not initialized');

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readonly');
      const store = transaction.objectStore(STORE_NAME);
      const request = store.count();

      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Cleanup old images if exceeding MAX_IMAGES
   */
  private async cleanupOldImages(): Promise<void> {
    const count = await this.getCount();
    
    if (count <= MAX_IMAGES) return;

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([STORE_NAME], 'readwrite');
      const store = transaction.objectStore(STORE_NAME);
      const index = store.index('timestamp');
      const request = index.openCursor(null, 'next'); // Oldest first

      let deleted = 0;
      const toDelete = count - MAX_IMAGES;

      request.onsuccess = (event) => {
        const cursor = (event.target as IDBRequest).result;
        
        if (cursor && deleted < toDelete) {
          store.delete(cursor.primaryKey);
          deleted++;
          cursor.continue();
        } else {
          console.log(`✓ Cleaned up ${deleted} old images`);
          resolve();
        }
      };

      request.onerror = () => reject(request.error);
    });
  }

  /**
   * Get storage usage estimate
   */
  async getStorageEstimate(): Promise<{ usage: number; quota: number }> {
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      const estimate = await navigator.storage.estimate();
      return {
        usage: estimate.usage || 0,
        quota: estimate.quota || 0,
      };
    }
    return { usage: 0, quota: 0 };
  }

  /**
   * Migrate from localStorage to IndexedDB
   */
  async migrateFromLocalStorage(storageKey: string): Promise<number> {
    try {
      const stored = localStorage.getItem(storageKey);
      if (!stored) return 0;

      const data = JSON.parse(stored) as GeneratedImage[];
      console.log(`Migrating ${data.length} images from localStorage...`);

      let migrated = 0;
      for (const image of data) {
        try {
          await this.addImage(image);
          migrated++;
        } catch (error) {
          console.error('Failed to migrate image:', image.id, error);
        }
      }

      // Clear localStorage after successful migration
      if (migrated > 0) {
        localStorage.removeItem(storageKey);
        console.log(`✓ Migrated ${migrated} images, localStorage cleared`);
      }

      return migrated;
    } catch (error) {
      console.error('Migration error:', error);
      return 0;
    }
  }
}

// Export singleton instance
export const imageDB = new ImageDatabase();
