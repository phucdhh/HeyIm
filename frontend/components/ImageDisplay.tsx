'use client';

import React, { useMemo } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Download, RotateCw, Info } from 'lucide-react';
import { downloadImage, formatTime } from '@/lib/utils';
import type { GenerationMetadata } from '@/types';

interface ImageDisplayProps {
  imageBase64?: string;
  isGenerating: boolean;
  metadata?: GenerationMetadata;
  progress?: number;
  statusMessage?: string;
  onRegenerate?: () => void;
}

export const ImageDisplay = React.memo(function ImageDisplay({
  imageBase64,
  isGenerating,
  metadata,
  progress = 0,
  statusMessage = '',
  onRegenerate,
}: ImageDisplayProps) {
  const [showMetadata, setShowMetadata] = React.useState(false);

  const handleDownload = () => {
    if (imageBase64) {
      const timestamp = new Date().getTime();
      downloadImage(imageBase64, `heyim_${timestamp}.png`);
    }
  };

  return (
    <Card className="overflow-hidden animate-fade-in">
      {/* Image Area */}
      <div className="relative aspect-square bg-gray-100">
        {isGenerating ? (
          <div className="absolute inset-0 flex flex-col items-center justify-center p-6">
            <div className="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4"></div>
            <p className="text-base font-medium text-gray-700 mb-2">
              {statusMessage || 'Generating image...'}
            </p>
            {progress > 0 && (
              <div className="w-full max-w-md">
                <div className="w-full bg-gray-200 rounded-full h-2.5 mb-2">
                  <div
                    className="bg-gradient-to-r from-blue-500 to-indigo-600 h-2.5 rounded-full transition-all duration-300"
                    style={{ width: `${progress}%` }}
                  />
                </div>
                <p className="text-sm text-gray-600 text-center">
                  {progress}% complete
                </p>
              </div>
            )}
          </div>
        ) : imageBase64 ? (
          <img
            src={`data:image/png;base64,${imageBase64}`}
            alt="Generated image"
            className="w-full h-full object-contain animate-scale-in"
            loading="lazy"
          />
        ) : (
          <div className="absolute inset-0 flex items-center justify-center text-gray-400">
            <div className="text-center">
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
                  d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <p className="text-sm">Your generated image will appear here</p>
            </div>
          </div>
        )}
      </div>

      {/* Actions */}
      {imageBase64 && !isGenerating && (
        <div className="p-4 border-t border-gray-200 bg-gray-50">
          <div className="flex items-center gap-2">
            <Button
              onClick={handleDownload}
              variant="default"
              size="sm"
              className="flex-1"
            >
              <Download className="w-4 h-4 mr-2" />
              Download
            </Button>
            
            {onRegenerate && (
              <Button
                onClick={onRegenerate}
                variant="outline"
                size="sm"
                className="flex-1"
              >
                <RotateCw className="w-4 h-4 mr-2" />
                Regenerate
              </Button>
            )}
            
            <Button
              onClick={() => setShowMetadata(!showMetadata)}
              variant="ghost"
              size="sm"
            >
              <Info className="w-4 h-4" />
            </Button>
          </div>

          {/* Metadata */}
          {showMetadata && metadata && (
            <div className="mt-4 p-3 bg-white rounded-lg text-xs space-y-2">
              <div className="font-semibold text-gray-700 mb-2">Generation Details</div>
              
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <span className="text-gray-500">Steps:</span>
                  <span className="ml-2 font-medium">{metadata.steps}</span>
                </div>
                <div>
                  <span className="text-gray-500">CFG Scale:</span>
                  <span className="ml-2 font-medium">{metadata.cfgScale}</span>
                </div>
                <div>
                  <span className="text-gray-500">Seed:</span>
                  <span className="ml-2 font-medium">{metadata.seed}</span>
                </div>
                <div>
                  <span className="text-gray-500">Time:</span>
                  <span className="ml-2 font-medium">
                    {formatTime(metadata.generationTime)}
                  </span>
                </div>
              </div>

              <div className="pt-2 border-t border-gray-200">
                <div className="text-gray-500 mb-1">Prompt:</div>
                <div className="text-gray-700 text-xs break-words">
                  {metadata.prompt}
                </div>
              </div>

              {metadata.negativePrompt && (
                <div className="pt-2 border-t border-gray-200">
                  <div className="text-gray-500 mb-1">Negative Prompt:</div>
                  <div className="text-gray-700 text-xs break-words">
                    {metadata.negativePrompt}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </Card>
  );
});
