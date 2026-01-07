'use client';

import React from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Download, Trash2, Copy, ChevronDown, ChevronUp, RefreshCw } from 'lucide-react';
import { downloadImage, formatTime } from '@/lib/utils';
import type { GeneratedImage } from '@/types';

interface HistoryGridProps {
  images: GeneratedImage[];
  onDelete: (id: string) => void;
  onImageClick: (image: GeneratedImage) => void;
  onRegenerate?: (image: GeneratedImage) => void;
  onCopyPrompt?: (prompt: string) => void;
}

export function HistoryGrid({ images, onDelete, onImageClick, onRegenerate, onCopyPrompt }: HistoryGridProps) {
  const [expandedCards, setExpandedCards] = React.useState<Set<string>>(new Set());

  const toggleExpand = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setExpandedCards(prev => {
      const newSet = new Set(prev);
      if (newSet.has(id)) {
        newSet.delete(id);
      } else {
        newSet.add(id);
      }
      return newSet;
    });
  };

  const handleCopyPrompt = (prompt: string, e: React.MouseEvent) => {
    e.stopPropagation();
    navigator.clipboard.writeText(prompt);
    onCopyPrompt?.(prompt);
  };
  // Debug: Check image data
  React.useEffect(() => {
    console.log('History images:', images.length);
    if (images.length > 0) {
      const firstImg = images[0];
      console.log('First image debug:', {
        id: firstImg.id,
        hasImageData: !!firstImg.imageData,
        dataLength: firstImg.imageData?.length,
        dataPrefix: firstImg.imageData?.substring(0, 50),
        hasDataPrefix: firstImg.imageData?.startsWith('data:'),
        isValidBase64: /^[A-Za-z0-9+/=]+$/.test(firstImg.imageData?.substring(0, 100) || ''),
      });
      
      // Test if we can create a valid data URL
      const testSrc = firstImg.imageData?.startsWith('data:') 
        ? firstImg.imageData 
        : `data:image/png;base64,${firstImg.imageData}`;
      console.log('Test image src length:', testSrc.length);
      console.log('Test src prefix:', testSrc.substring(0, 50));
    }
  }, [images]);

  if (images.length === 0) {
    return (
      <Card className="p-8 text-center">
        <div className="text-gray-400">
          <svg
            className="mx-auto h-12 w-12 mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
            />
          </svg>
          <p className="text-sm">No images generated yet</p>
        </div>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {images.map((image) => {
        const isExpanded = expandedCards.has(image.id);
        return (
          <Card key={image.id} className="overflow-hidden group hover:shadow-lg transition-all duration-200 hover-lift animate-fade-in">
            {/* Image */}
            <div
              className="relative aspect-square cursor-pointer bg-gray-100"
              onClick={() => onImageClick(image)}
            >
              {image.imageData ? (
                <img
                  src={`data:image/png;base64,${image.imageData}`}
                  alt={image.prompt}
                  className="w-full h-full object-cover absolute inset-0"
                  style={{ zIndex: 1 }}
                  onLoad={(e) => {
                    console.log('Image loaded:', image.id);
                    (e.target as HTMLImageElement).style.display = 'block';
                  }}
                  onError={(e) => {
                    console.error('Image load error:', {
                      id: image.id,
                      dataLength: image.imageData?.length,
                      dataPrefix: image.imageData?.substring(0, 50),
                    });
                    const target = e.target as HTMLImageElement;
                    target.style.display = 'none';
                  }}
                />
              ) : (
                <div className="absolute inset-0 flex items-center justify-center text-gray-400">
                  <p className="text-sm">No image data</p>
                </div>
              )}
              <div 
                className="absolute inset-0 transition-all duration-200 pointer-events-none opacity-0 group-hover:opacity-100 group-hover:pointer-events-auto" 
                style={{ zIndex: 10, backgroundColor: 'rgba(0,0,0,0.4)' }}
              >
                <div className="absolute bottom-0 left-0 right-0 p-2 translate-y-full group-hover:translate-y-0 transition-transform duration-200">
                  <div className="flex gap-1">
                    <Button
                      onClick={(e) => {
                        e.stopPropagation();
                        downloadImage(image.imageData, `heyim_${image.id}.png`);
                      }}
                      size="sm"
                      variant="secondary"
                      className="flex-1 text-xs"
                    >
                      <Download className="w-3 h-3" />
                    </Button>
                    <Button
                      onClick={(e) => {
                        e.stopPropagation();
                        if (confirm('Delete this image?')) {
                          onDelete(image.id);
                        }
                      }}
                      size="sm"
                      variant="secondary"
                      className="flex-1 text-xs"
                    >
                      <Trash2 className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              </div>
            </div>

            {/* Metadata Section */}
            <div className="p-3 bg-white border-t border-gray-100">
              {/* Quick Info */}
              <div className="flex items-start justify-between mb-2">
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-gray-600 truncate mb-1">
                    {image.prompt.substring(0, 60)}...
                  </p>
                  <div className="flex gap-2 text-xs text-gray-500">
                    <span>⚙️ {image.steps} steps</span>
                    <span>🎚️ {image.cfgScale}</span>
                    <span>⏱️ {image.generationTime.toFixed(1)}s</span>
                  </div>
                </div>
                <Button
                  onClick={(e) => toggleExpand(image.id, e)}
                  size="sm"
                  variant="ghost"
                  className="ml-2 p-1 h-6 w-6"
                >
                  {isExpanded ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                </Button>
              </div>

              {/* Expanded Details */}
              {isExpanded && (
                <div className="mt-3 pt-3 border-t border-gray-100 space-y-3 animate-fade-in">
                  {/* Full Prompt */}
                  <div>
                    <label className="text-xs font-semibold text-gray-700 mb-1 block">Prompt:</label>
                    <p className="text-xs text-gray-600 bg-gray-50 p-2 rounded break-words">
                      {image.prompt}
                    </p>
                  </div>

                  {/* Negative Prompt */}
                  {image.negativePrompt && (
                    <div>
                      <label className="text-xs font-semibold text-gray-700 mb-1 block">Negative:</label>
                      <p className="text-xs text-gray-500 bg-gray-50 p-2 rounded break-words">
                        {image.negativePrompt}
                      </p>
                    </div>
                  )}

                  {/* Technical Details */}
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div className="bg-blue-50 p-2 rounded">
                      <span className="font-semibold text-blue-900">Steps:</span>
                      <span className="ml-1 text-blue-700">{image.steps}</span>
                    </div>
                    <div className="bg-purple-50 p-2 rounded">
                      <span className="font-semibold text-purple-900">CFG:</span>
                      <span className="ml-1 text-purple-700">{image.cfgScale}</span>
                    </div>
                    <div className="bg-green-50 p-2 rounded">
                      <span className="font-semibold text-green-900">Seed:</span>
                      <span className="ml-1 text-green-700 font-mono">{image.seed}</span>
                    </div>
                    <div className="bg-orange-50 p-2 rounded">
                      <span className="font-semibold text-orange-900">Time:</span>
                      <span className="ml-1 text-orange-700">{image.generationTime.toFixed(1)}s</span>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="flex gap-2 pt-2">
                    <Button
                      onClick={(e) => handleCopyPrompt(image.prompt, e)}
                      size="sm"
                      variant="outline"
                      className="flex-1 text-xs"
                    >
                      <Copy className="h-3 w-3 mr-1" />
                      Copy Prompt
                    </Button>
                    {onRegenerate && (
                      <Button
                        onClick={(e) => {
                          e.stopPropagation();
                          onRegenerate(image);
                        }}
                        size="sm"
                        variant="outline"
                        className="flex-1 text-xs"
                      >
                        <RefreshCw className="h-3 w-3 mr-1" />
                        Regenerate
                      </Button>
                    )}
                  </div>
                </div>
              )}
            </div>
          </Card>
        );
      })}
    </div>
  );
}
