// Model Types
export type ModelType = 'fast' | 'quality';

export interface ModelInfo {
  type: ModelType;
  name: string;
  description: string;
  estimatedTime: string;
  bestFor: string[];
}

// API Types
export interface GenerateRequest {
  prompt: string;
  negativePrompt?: string;
  steps?: number;
  cfgScale?: number;
  seed?: number;
  modelType?: ModelType;  // New: Model selection
  // Image-to-Image support
  inputImage?: string;  // base64 encoded input image
  strength?: number;    // denoising strength (0.1 to 1.0)
}

export interface GenerationMetadata {
  prompt: string;
  negativePrompt?: string;
  steps: number;
  cfgScale: number;
  seed: number;
  generationTime: number;
  modelType?: ModelType;  // Track which model was used
  // Image-to-Image metadata
  hasInputImage?: boolean;
  strength?: number;
}

export interface GenerateResponse {
  success: boolean;
  imageBase64?: string;
  metadata?: GenerationMetadata;
  error?: string;
}

export interface StatusResponse {
  modelStatus: 'not_loaded' | 'loading' | 'loaded' | 'error';
  isGenerating: boolean;
  queueSize: number;
  currentModelType?: ModelType;  // Track current loaded model
}

export interface ServerInfo {
  version: string;
  modelPath: string;
  status: string;
}

// Quality Presets
export interface QualityPreset {
  name: string;
  steps: number;
  cfgScale: number;
  description: string;
  estimatedTime: string;
  useCase?: string;
  recommended?: boolean;
}

export interface QualityPresets {
  fast: QualityPreset;
  balanced: QualityPreset;
  premium: QualityPreset;
}

// Prompt Examples
export interface PromptExample {
  category: string;
  title: string;
  prompt: string;
  negativePrompt: string;
  recommendedSteps: number;
  recommendedCfg: number;
}

// Generated Image
export interface GeneratedImage {
  id: string;
  imageData: string; // base64
  prompt: string;
  negativePrompt?: string;
  steps: number;
  cfgScale: number;
  seed: number;
  generationTime: number;
  timestamp: number;
  modelType?: ModelType;  // Track which model generated this
  // Image-to-Image fields
  inputImageData?: string;  // base64 input image for img2img
  strength?: number;        // denoising strength used
}
