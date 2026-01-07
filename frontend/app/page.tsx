'use client';

import React, { useState, useEffect } from 'react';
import { GenerateForm } from '@/components/GenerateForm';
import { ImageDisplay } from '@/components/ImageDisplay';
import { HistoryGrid } from '@/components/HistoryGrid';
import { Button } from '@/components/ui/Button';
import { useGenerate } from '@/lib/hooks/useGenerate';
import { useHistory } from '@/lib/hooks/useHistory';
import { generateId } from '@/lib/utils';
import { api } from '@/lib/api/client';
import { exportHistory, importHistory } from '@/lib/storage/export';
import type { GenerateRequest, GeneratedImage } from '@/types';
import { Toaster, toast } from 'react-hot-toast';

export default function Home() {
  const [currentImage, setCurrentImage] = useState<string | undefined>();
  const [currentMetadata, setCurrentMetadata] = useState<any>(undefined);
  const [activeTab, setActiveTab] = useState<'generate' | 'history'>('generate');
  const [modelsLoading, setModelsLoading] = useState(false);
  const [modelsLoaded, setModelsLoaded] = useState(false);
  
  const { generate, isGenerating, error, progress, statusMessage } = useGenerate();
  const { history, addToHistory, removeFromHistory, clearHistory, isLoading: historyLoading, storageInfo } = useHistory();

  // Check model status on mount
  useEffect(() => {
    const checkAndLoadModels = async () => {
      try {
        const status = await api.getStatus();
        
        if (status.modelStatus === 'loaded') {
          setModelsLoaded(true);
          toast.success('Models ready!');
        } else if (status.modelStatus === 'not_loaded') {
          // Auto-load models
          setModelsLoading(true);
          toast.loading('Loading AI models...', { id: 'load-models', duration: Infinity });
          
          try {
            await api.loadModels();
            setModelsLoaded(true);
            toast.success('Models loaded successfully!', { id: 'load-models' });
          } catch (err) {
            toast.error('Failed to load models. Please try again.', { id: 'load-models' });
          } finally {
            setModelsLoading(false);
          }
        }
      } catch (err) {
        console.error('Failed to check model status:', err);
        toast.error('Cannot connect to server');
      }
    };

    checkAndLoadModels();
  }, []);

  const handleGenerate = async (request: GenerateRequest) => {
    try {
      const response = await generate(request);
      
      if (response.success && response.imageBase64) {
        setCurrentImage(response.imageBase64);
        setCurrentMetadata(response.metadata);
        
        // Debug: Check base64 data before saving
        console.log('Generated image base64:', {
          length: response.imageBase64.length,
          prefix: response.imageBase64.substring(0, 50),
          hasDataPrefix: response.imageBase64.startsWith('data:'),
          isValidBase64: /^[A-Za-z0-9+/=]+$/.test(response.imageBase64.substring(0, 100)),
        });
        
        // Add to history
        const generatedImage: GeneratedImage = {
          id: generateId(),
          imageData: response.imageBase64,
          prompt: response.metadata!.prompt,
          negativePrompt: response.metadata!.negativePrompt,
          steps: response.metadata!.steps,
          cfgScale: response.metadata!.cfgScale,
          seed: response.metadata!.seed,
          generationTime: response.metadata!.generationTime,
          timestamp: Date.now(),
        };
        
        await addToHistory(generatedImage);
        toast.success('Image generated successfully!');
      } else {
        toast.error(response.error || 'Generation failed');
      }
    } catch (err) {
      toast.error(error || 'Failed to generate image');
    }
  };

  const handleImageClick = (image: GeneratedImage) => {
    setCurrentImage(image.imageData);
    setCurrentMetadata({
      prompt: image.prompt,
      negativePrompt: image.negativePrompt,
      steps: image.steps,
      cfgScale: image.cfgScale,
      seed: image.seed,
      generationTime: image.generationTime,
    });
    setActiveTab('generate');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleRegenerate = (image: GeneratedImage) => {
    setCurrentMetadata({
      prompt: image.prompt,
      negativePrompt: image.negativePrompt,
      steps: image.steps,
      cfgScale: image.cfgScale,
      seed: image.seed,
    });
    setActiveTab('generate');
    window.scrollTo({ top: 0, behavior: 'smooth' });
    toast.success('Settings loaded! Click Generate to recreate.');
  };

  const handleCopyPrompt = (prompt: string) => {
    toast.success('Prompt copied to clipboard!');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <Toaster position="top-center" />
      
      {/* Header */}
      <header className="bg-white shadow-md border-b border-gray-200 sticky top-0 z-50 backdrop-blur-sm bg-white/95">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3 animate-fade-in">
              <div className="w-10 h-10 bg-gradient-to-br from-blue-500 via-blue-600 to-indigo-600 rounded-lg flex items-center justify-center text-white text-xl font-bold shadow-lg hover:shadow-xl transition-shadow duration-200">
                H
              </div>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">HeyIm</h1>
                <p className="text-xs text-gray-500">AI Image Generation</p>
              </div>
            </div>
            
            <div className="flex gap-2">
              {modelsLoading && (
                <div className="flex items-center gap-2 text-sm text-gray-600 mr-4">
                  <div className="w-4 h-4 border-2 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
                  Loading models...
                </div>
              )}
              {modelsLoaded && !modelsLoading && (
                <div className="flex items-center gap-2 text-sm text-green-600 mr-4">
                  <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                  Models ready
                </div>
              )}
              <Button
                variant={activeTab === 'generate' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setActiveTab('generate')}
              >
                Generate
              </Button>
              <Button
                variant={activeTab === 'history' ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setActiveTab('history')}
              >
                History ({history.length})
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
        {activeTab === 'generate' ? (
          <div className="grid lg:grid-cols-2 gap-8">
            {/* Left: Form */}
            <div>
              <GenerateForm 
                onSubmit={handleGenerate} 
                isGenerating={isGenerating || modelsLoading}
              />
            </div>

            {/* Right: Image Display */}
            <div>
              <ImageDisplay
                imageBase64={currentImage}
                isGenerating={isGenerating}
                metadata={currentMetadata}
                progress={progress}
                statusMessage={statusMessage}
                onRegenerate={() => {
                  if (currentMetadata) {
                    handleGenerate({
                      prompt: currentMetadata.prompt,
                      negativePrompt: currentMetadata.negativePrompt,
                      steps: currentMetadata.steps,
                      cfgScale: currentMetadata.cfgScale,
                      seed: Math.floor(Math.random() * 2147483647),
                    });
                  }
                }}
              />
            </div>
          </div>
        ) : (
          <div>
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">
                  Generation History
                </h2>
                {storageInfo.quota > 0 && (
                  <p className="text-sm text-gray-500 mt-1">
                    Browser storage: {(storageInfo.usage / 1024 / 1024).toFixed(1)} MB / {(storageInfo.quota / 1024 / 1024 / 1024).toFixed(1)} GB
                  </p>
                )}
              </div>
              {history.length > 0 && (
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={async () => {
                      try {
                        await exportHistory();
                        toast.success('History exported successfully!');
                      } catch (error) {
                        toast.error('Export failed');
                      }
                    }}
                  >
                    📥 Export
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      const input = document.createElement('input');
                      input.type = 'file';
                      input.accept = 'application/json';
                      input.onchange = async (e) => {
                        const file = (e.target as HTMLInputElement).files?.[0];
                        if (file) {
                          try {
                            const count = await importHistory(file);
                            toast.success(`Imported ${count} images!`);
                            window.location.reload();
                          } catch (error) {
                            toast.error('Import failed');
                          }
                        }
                      };
                      input.click();
                    }}
                  >
                    📤 Import
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={async () => {
                      if (confirm('Clear all history? This will free up browser storage.')) {
                        await clearHistory();
                        toast.success('History cleared');
                      }
                    }}
                  >
                    🗑️ Clear All
                  </Button>
                </div>
              )}
            </div>
            
            {historyLoading ? (
              <div className="text-center py-12">
                <div className="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                <p className="text-gray-500">Loading history...</p>
              </div>
            ) : (
              <HistoryGrid
                images={history}
                onDelete={async (id) => {
                  await removeFromHistory(id);
                  toast.success('Image removed');
                }}
                onImageClick={handleImageClick}
                onRegenerate={handleRegenerate}
                onCopyPrompt={handleCopyPrompt}
              />
            )}
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="mt-16 py-6 text-center text-sm text-gray-500">
        <p>HeyIm - AI Image Generation powered by RealisticVision v5.1</p>
        <p className="mt-1">Built with Next.js & Swift/Vapor</p>
      </footer>
    </div>
  );
}
