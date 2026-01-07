'use client';

import { useState, useCallback } from 'react';
import { api } from '@/lib/api/client';
import type { GenerateRequest, GenerateResponse } from '@/types';

interface UseGenerateReturn {
  generate: (request: GenerateRequest) => Promise<GenerateResponse>;
  isGenerating: boolean;
  error: string | null;
  progress: number;
  statusMessage: string;
}

export function useGenerate(): UseGenerateReturn {
  const [isGenerating, setIsGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [statusMessage, setStatusMessage] = useState('');

  const generate = useCallback(async (request: GenerateRequest) => {
    setIsGenerating(true);
    setError(null);
    setProgress(0);
    
    const totalSteps = request.steps || 30;

    try {
      // Status updates
      setStatusMessage('Preparing generation...');
      setProgress(5);
      
      await new Promise(resolve => setTimeout(resolve, 300));
      
      setStatusMessage('Initializing models...');
      setProgress(10);
      
      await new Promise(resolve => setTimeout(resolve, 300));
      
      setStatusMessage(`Running diffusion (${totalSteps} steps)...`);
      setProgress(15);

      // Simulate progress during generation
      const progressInterval = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 85) return prev;
          return prev + 5;
        });
      }, (totalSteps * 1000 / 15)); // Update every few seconds based on steps

      const response = await api.generate(request);

      clearInterval(progressInterval);
      
      setStatusMessage('Processing results...');
      setProgress(90);
      
      await new Promise(resolve => setTimeout(resolve, 200));
      
      setStatusMessage('Finalizing...');
      setProgress(95);
      
      await new Promise(resolve => setTimeout(resolve, 200));
      
      setProgress(100);
      setStatusMessage('Complete!');

      return response;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error';
      setError(errorMessage);
      setStatusMessage('Generation failed');
      throw err;
    } finally {
      setIsGenerating(false);
      setTimeout(() => {
        setProgress(0);
        setStatusMessage('');
      }, 1000);
    }
  }, []);

  return {
    generate,
    isGenerating,
    error,
    progress,
    statusMessage,
  };
}
