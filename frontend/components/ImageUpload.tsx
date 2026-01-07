'use client';

import React, { useCallback, useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Upload, X, Image as ImageIcon } from 'lucide-react';

interface ImageUploadProps {
  onImageUpload: (base64: string | null) => void;
  currentImage?: string | null;
  disabled?: boolean;
}

export function ImageUpload({ onImageUpload, currentImage, disabled = false }: ImageUploadProps) {
  const [dragOver, setDragOver] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const processFile = useCallback(async (file: File) => {
    if (!file.type.startsWith('image/')) {
      alert('Please select a valid image file');
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      alert('Image size should be less than 10MB');
      return;
    }

    setIsLoading(true);
    try {
      const base64 = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
          if (typeof reader.result === 'string') {
            // Remove data URL prefix to get just base64
            const base64Data = reader.result.split(',')[1];
            resolve(base64Data);
          } else {
            reject(new Error('Failed to read file'));
          }
        };
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });

      onImageUpload(base64);
    } catch (error) {
      console.error('Error processing image:', error);
      alert('Error processing image. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, [onImageUpload]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    
    if (disabled) return;
    
    const file = e.dataTransfer.files[0];
    if (file) {
      processFile(file);
    }
  }, [disabled, processFile]);

  const handleFileInput = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      processFile(file);
    }
    // Reset input value to allow selecting the same file again
    e.target.value = '';
  }, [processFile]);

  const clearImage = useCallback(() => {
    onImageUpload(null);
  }, [onImageUpload]);

  return (
    <Card className="p-4 space-y-3">
      <div className="flex items-center justify-between">
        <label className="text-sm font-medium text-gray-700">
          Input Image (optional)
        </label>
        {currentImage && !disabled && (
          <Button
            type="button"
            variant="ghost"
            size="sm"
            onClick={clearImage}
            className="text-red-500 hover:text-red-700"
          >
            <X className="w-4 h-4 mr-1" />
            Clear
          </Button>
        )}
      </div>

      {currentImage ? (
        /* Preview uploaded image */
        <div className="space-y-2">
          <div className="relative">
            <img
              src={`data:image/png;base64,${currentImage}`}
              alt="Input image"
              className="w-full max-h-64 object-contain rounded-lg border border-gray-200"
            />
            {!disabled && (
              <Button
                type="button"
                variant="secondary"
                size="sm"
                onClick={clearImage}
                className="absolute top-2 right-2"
              >
                <X className="w-4 h-4" />
              </Button>
            )}
          </div>
          <p className="text-xs text-gray-500 text-center">
            🎨 Your image will be used as a base for generation
          </p>
        </div>
      ) : (
        /* Upload area */
        <div
          className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${
            dragOver
              ? 'border-blue-400 bg-blue-50'
              : disabled
              ? 'border-gray-200 bg-gray-50'
              : 'border-gray-300 hover:border-gray-400'
          }`}
          onDrop={handleDrop}
          onDragOver={(e) => {
            e.preventDefault();
            if (!disabled) setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
        >
          {isLoading ? (
            <div className="space-y-2">
              <div className="animate-spin w-8 h-8 mx-auto border-2 border-blue-600 border-t-transparent rounded-full"></div>
              <p className="text-sm text-gray-600">Processing image...</p>
            </div>
          ) : (
            <div className="space-y-3">
              <ImageIcon className="w-12 h-12 mx-auto text-gray-400" />
              <div className="space-y-1">
                <p className="text-sm font-medium text-gray-700">
                  Drop an image here or click to upload
                </p>
                <p className="text-xs text-gray-500">
                  Supports JPG, PNG, WebP • Max 10MB
                </p>
              </div>
              <input
                type="file"
                accept="image/*"
                onChange={handleFileInput}
                disabled={disabled}
                className="hidden"
                id="image-upload"
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                disabled={disabled}
                onClick={() => document.getElementById('image-upload')?.click()}
              >
                <Upload className="w-4 h-4 mr-2" />
                Select Image
              </Button>
            </div>
          )}
        </div>
      )}

      {currentImage && (
        <div className="text-xs text-gray-600 bg-blue-50 p-3 rounded-lg">
          <strong>💡 Tip:</strong> The AI will use this image as a starting point. 
          Higher strength values change more of the original image, 
          while lower values preserve more details.
        </div>
      )}
    </Card>
  );
}