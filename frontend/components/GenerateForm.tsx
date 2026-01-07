'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { Textarea } from '@/components/ui/Textarea';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Slider } from '@/components/ui/Slider';
import { ImageUpload } from '@/components/ImageUpload';
import type { GenerateRequest, QualityPreset, PromptExample } from '@/types';

interface GenerateFormProps {
  onSubmit: (request: GenerateRequest) => void;
  isGenerating: boolean;
}

export const GenerateForm = React.memo(function GenerateForm({ onSubmit, isGenerating }: GenerateFormProps) {
  const [prompt, setPrompt] = useState('');
  const [negativePrompt, setNegativePrompt] = useState('');
  const [steps, setSteps] = useState(30);
  const [cfgScale, setCfgScale] = useState(8.0);
  const [seed, setSeed] = useState<number | undefined>(undefined);
  const [showAdvanced, setShowAdvanced] = useState(false);
  // Single-model app: always use fast pipeline
  const modelType = 'fast';
  
  // Image-to-Image state
  const [inputImage, setInputImage] = useState<string | null>(null);
  const [strength, setStrength] = useState(0.5);
  
  const [presets, setPresets] = useState<{ [key: string]: QualityPreset }>({});
  const [categories, setCategories] = useState<any[]>([]);
  const [selectedCategory, setSelectedCategory] = useState(0);
  const [selectedPreset, setSelectedPreset] = useState<string>('fast');

  // Load presets and categories
  useEffect(() => {
    fetch('/prompts.json')
      .then((res) => res.json())
      .then((data) => {
        setPresets(data.qualityPresets);
        setCategories(data.promptCategories || []);
      })
      .catch(console.error);
  }, []);

  const currentExamples = categories[selectedCategory]?.examples || [];

  const handleSubmit = useCallback((e: React.FormEvent) => {
    e.preventDefault();
    if (!prompt.trim()) return;

    onSubmit({
      prompt,
      negativePrompt: negativePrompt || undefined,
      steps,
      cfgScale,
      seed,
      modelType, // Include model selection
      // Image-to-image fields
      inputImage: inputImage || undefined,
      strength: inputImage ? strength : undefined,
    });
    // Keep form state for easy iterations
  }, [prompt, negativePrompt, steps, cfgScale, seed, modelType, inputImage, strength, onSubmit]);

  const handleClearForm = useCallback(() => {
    if (confirm('Clear all fields and start fresh?')) {
      setPrompt('');
      setNegativePrompt('');
      setSteps(30);
      setCfgScale(8.0);
      setSeed(undefined);
      setSelectedPreset('fast');
      // Clear img2img fields
      setInputImage(null);
      setStrength(0.5);
    }
  }, []);

  const applyPreset = useCallback((preset: QualityPreset, key: string) => {
    setSteps(preset.steps);
    setCfgScale(preset.cfgScale);
    setSelectedPreset(key);
  }, []);

  const applyExample = useCallback((example: PromptExample) => {
    setPrompt(example.prompt);
    setNegativePrompt(example.negativePrompt);
    setSteps(example.recommendedSteps);
    setCfgScale(example.recommendedCfg);
  }, []);

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Single Model - RealisticVision v5.1 */}
      <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-lg p-4">
        <div className="flex items-center gap-3">
          <div className="text-3xl">⚡</div>
          <div>
            <div className="font-semibold text-gray-900">RealisticVision v5.1</div>
            <div className="text-sm text-gray-600">Optimized for M2 • ~10 seconds • ANE accelerated</div>
          </div>
        </div>
      </div>

      {/* Image Upload for Image-to-Image */}
      <ImageUpload
        onImageUpload={setInputImage}
        currentImage={inputImage}
        disabled={isGenerating}
      />

      {/* Strength Slider (only show when image is uploaded) */}
      {inputImage && (
        <Card className="p-4 bg-orange-50 border-orange-200">
          <Slider
            label="Strength"
            value={strength}
            min={0.1}
            max={1.0}
            step={0.05}
            onChange={setStrength}
          />
          <p className="text-xs text-orange-700 mt-2">
            <strong>0.3-0.5 (Recommended):</strong> Keep people/subjects identical, change background/style only<br />
            <strong>0.6-0.7:</strong> Modify clothing, pose, expression while keeping likeness<br />
            <strong>0.8-1.0:</strong> Major transformation, subjects may change significantly
          </p>
          <p className="text-xs text-orange-600 mt-1 font-medium">
            💡 Tip: Use prompts like "same person, keep face identical, change background to..." for best results
          </p>
        </Card>
      )}

      {/* Quality Presets */}
      <Card className="p-4 hover:shadow-md transition-shadow duration-200">
        <h3 className="text-sm font-semibold mb-3 text-gray-700">Quality Presets</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          {Object.entries(presets).map(([key, preset]) => (
            <Button
              key={key}
              type="button"
              variant={selectedPreset === key ? 'default' : 'outline'}
              size="sm"
              onClick={() => applyPreset(preset, key)}
              className="hover:scale-105 transition-transform"
            >
              <div className="text-center">
                <div className="font-semibold">{preset.name}</div>
                <div className="text-xs opacity-70">{preset.estimatedTime}</div>
              </div>
            </Button>
          ))}
        </div>
      </Card>

      {/* Prompt Input */}
      <div className="space-y-2">
        <label className="text-sm font-medium text-gray-700">
          Prompt <span className="text-red-500">*</span>
        </label>
        <Textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder={inputImage 
            ? "same person, keep face identical, change background to beach with palm trees, tropical paradise..."
            : "professional portrait of a beautiful woman, detailed face, high quality..."}
          className="min-h-[100px]"
          required
        />
        <div className="text-xs text-gray-500">
          {prompt.length} characters
        </div>
      </div>

      {/* Example Prompts */}
      {categories.length > 0 && (
        <div className="space-y-3">
          <label className="text-sm font-medium text-gray-700">
            Example Prompts
          </label>
          
          {/* Category Tabs */}
          <div className="flex gap-2 overflow-x-auto pb-3 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-transparent">
            {categories.map((category, idx) => (
              <Button
                key={idx}
                type="button"
                variant={selectedCategory === idx ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedCategory(idx)}
                className="whitespace-nowrap"
              >
                <span className="mr-1">{category.icon}</span>
                {category.name}
              </Button>
            ))}
          </div>
          
          {/* Examples Grid */}
          <div className="grid grid-cols-2 gap-2">
            {currentExamples.map((example: any, idx: number) => (
              <Button
                key={idx}
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => applyExample(example)}
                className="justify-start text-left h-auto py-2 hover:bg-blue-50 hover:border-blue-200 border border-transparent transition-all"
              >
                <div className="w-full">
                  <div className="font-medium text-xs">{example.title}</div>
                  <div className="text-xs text-gray-500 truncate">
                    {example.prompt?.substring(0, 50) ?? ''}...
                  </div>
                </div>
              </Button>
            ))}
          </div>
        </div>
      )}

      {/* Negative Prompt */}
      <div className="space-y-2">
        <label className="text-sm font-medium text-gray-700">
          Negative Prompt
        </label>
        <Textarea
          value={negativePrompt}
          onChange={(e) => setNegativePrompt(e.target.value)}
          placeholder="ugly, deformed, disfigured, bad anatomy..."
          className="min-h-[80px]"
        />
      </div>

      {/* Advanced Settings */}
      <div>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="mb-4"
        >
          {showAdvanced ? '▼' : '▶'} Advanced Settings
        </Button>

        {showAdvanced && (
          <Card className="p-4 space-y-4">
            <Slider
              label="Steps"
              value={steps}
              min={10}
              max={50}
              step={5}
              onChange={setSteps}
            />
            
            <Slider
              label="CFG Scale"
              value={cfgScale}
              min={1}
              max={15}
              step={0.5}
              onChange={setCfgScale}
            />
            
            <div className="space-y-2">
              <label className="text-sm font-medium text-gray-700">
                Seed (optional)
              </label>
              <input
                type="number"
                value={seed ?? ''}
                onChange={(e) => setSeed(e.target.value ? Number(e.target.value) : undefined)}
                placeholder="Random"
                className="w-full h-10 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm"
              />
              <p className="text-xs text-gray-500">
                Leave empty for random. Use same seed to reproduce images.
              </p>
            </div>
          </Card>
        )}
      </div>

      {/* Submit Button */}
      {/* Generate Button */}
      <div className="space-y-2">
        <Button
          type="submit"
          size="lg"
          disabled={isGenerating || !prompt.trim()}
          className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 shadow-lg hover:shadow-xl transition-all duration-200"
        >
          {isGenerating ? (
            <>
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating...
            </>
          ) : (
            'Generate Image'
          )}
        </Button>
        
        {/* Clear Form Button */}
        {(prompt || negativePrompt) && !isGenerating && (
          <Button
            type="button"
            size="sm"
            variant="ghost"
            onClick={handleClearForm}
            className="w-full text-gray-500 hover:text-gray-700"
          >
            🗑️ Clear Form
          </Button>
        )}
        
        {/* Iteration Tip */}
        {prompt && !isGenerating && (
          <p className="text-xs text-center text-gray-500 italic">
            💡 Tip: Form keeps your settings for easy iterations
          </p>
        )}
      </div>
    </form>
  );
});
