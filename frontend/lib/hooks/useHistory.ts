'use client';

import { useState, useEffect, useCallback } from 'react';
import { imageDB } from '@/lib/storage/indexedDB';
import type { GeneratedImage } from '@/types';

const STORAGE_KEY = 'heyim_history'; // For migration only

export function useHistory() {
  const [history, setHistory] = useState<GeneratedImage[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [storageInfo, setStorageInfo] = useState<{ usage: number; quota: number }>({ usage: 0, quota: 0 });

  // Load history from IndexedDB on mount
  useEffect(() => {
    const loadHistory = async () => {
      try {
        // Migrate from localStorage if exists
        await imageDB.migrateFromLocalStorage(STORAGE_KEY);
        
        // Load from IndexedDB
        const images = await imageDB.getAllImages();
        setHistory(images);
        
        // Get storage info
        const info = await imageDB.getStorageEstimate();
        setStorageInfo(info);
        
        console.log(`✓ Loaded ${images.length} images from IndexedDB`);
        console.log(`Storage: ${(info.usage / 1024 / 1024).toFixed(2)} MB / ${(info.quota / 1024 / 1024 / 1024).toFixed(2)} GB`);
      } catch (error) {
        console.error('Failed to load history from IndexedDB:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadHistory();
  }, []);

  const addToHistory = useCallback(async (image: GeneratedImage) => {
    try {
      // Save to IndexedDB
      await imageDB.addImage(image);
      
      // Update state
      setHistory((prev) => [image, ...prev]);
      
      // Update storage info
      const info = await imageDB.getStorageEstimate();
      setStorageInfo(info);
      
      console.log(`✓ Image saved to IndexedDB: ${image.id}`);
    } catch (error) {
      console.error('Failed to save image:', error);
      throw error;
    }
  }, []);

  const removeFromHistory = useCallback(async (id: string) => {
    try {
      // Delete from IndexedDB
      await imageDB.deleteImage(id);
      
      // Update state
      setHistory((prev) => prev.filter((item) => item.id !== id));
      
      // Update storage info
      const info = await imageDB.getStorageEstimate();
      setStorageInfo(info);
      
      console.log(`✓ Image deleted: ${id}`);
    } catch (error) {
      console.error('Failed to delete image:', error);
      throw error;
    }
  }, []);

  const clearHistory = useCallback(async () => {
    try {
      // Clear IndexedDB
      await imageDB.clearAll();
      
      // Update state
      setHistory([]);
      
      // Update storage info
      const info = await imageDB.getStorageEstimate();
      setStorageInfo(info);
      
      console.log('✓ All images cleared');
    } catch (error) {
      console.error('Failed to clear history:', error);
      throw error;
    }
  }, []);

  return {
    history,
    addToHistory,
    removeFromHistory,
    clearHistory,
    isLoading,
    storageInfo,
  };
}
