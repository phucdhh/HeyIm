'use client';

import React from 'react';
import { Card } from '@/components/ui/Card';
import type { ModelType } from '@/types';

interface ModelSelectorProps {
  selectedModel: ModelType;
  onChange: (model: ModelType) => void;
  disabled?: boolean;
}

const MODEL_INFO = {
  fast: {
    icon: '⚡',
    name: 'Fast Mode',
    model: 'RealisticVision v5.1',
    time: '~10 seconds',
    bestFor: ['Portraits', 'Faces', 'Close-ups'],
    description: 'Optimized for portrait photography with quick generation',
    tips: [
      'Best for face close-ups and portraits',
      'Use detailed anatomy keywords',
      'Steps: 25-35, CFG: 7.5-8.5',
      'Fast iteration for portrait refinement'
    ]
  },
  quality: {
    icon: '✨',
    name: 'Quality Mode',
    model: 'Juggernaut XL v9',
    time: '⚠️ ~5 minutes',
    bestFor: ['Products', 'Food', 'Architecture', 'Versatile'],
    description: 'High-quality generation (slow on M2 - recommend Fast Mode)',
    tips: [
      'Excellent for products, food, architecture',
      'Use photography keywords (e.g., "Food Photography")',
      'Steps: 30-40, CFG: 3-7 (lower = more realistic)',
      'Natural language prompts work better'
    ]
  }
} as const;

export const ModelSelector: React.FC<ModelSelectorProps> = ({ 
  selectedModel, 
  onChange, 
  disabled = false 
}) => {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-700">Generation Mode</h3>
        <span className="text-xs text-gray-500">
          {MODEL_INFO[selectedModel].time}
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {(Object.keys(MODEL_INFO) as ModelType[]).map((modelType) => {
          const info = MODEL_INFO[modelType];
          const isSelected = selectedModel === modelType;
          
          return (
            <button
              key={modelType}
              type="button"
              onClick={() => onChange(modelType)}
              disabled={disabled}
              className={`
                relative p-4 rounded-lg border-2 text-left transition-all
                hover:shadow-md focus:outline-none focus:ring-2 focus:ring-blue-500
                ${isSelected 
                  ? 'border-blue-500 bg-blue-50 shadow-sm' 
                  : 'border-gray-300 bg-white hover:border-gray-400'
                }
                ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}
              `}
            >
              {/* Badge for Fast Mode (default) */}
              {modelType === 'fast' && (
                <div className="absolute -top-2 -right-2 bg-blue-500 text-white text-xs px-2 py-0.5 rounded-full font-semibold">
                  RECOMMENDED
                </div>
              )}

              <div className="flex items-start gap-3">
                <div className="text-3xl">{info.icon}</div>
                <div className="flex-1">
                  <div className="font-semibold text-gray-900">{info.name}</div>
                  <div className="text-xs text-gray-500 mt-0.5">{info.model}</div>
                  <div className="text-sm text-gray-600 mt-2">
                    {info.description}
                  </div>
                  
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {info.bestFor.map((tag) => (
                      <span 
                        key={tag}
                        className={`
                          text-xs px-2 py-0.5 rounded-full
                          ${isSelected 
                            ? 'bg-blue-100 text-blue-700' 
                            : 'bg-gray-100 text-gray-700'
                          }
                        `}
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </button>
          );
        })}
      </div>

      {/* Tips for selected model */}
      <Card className="bg-gradient-to-br from-blue-50 to-indigo-50 border-blue-200">
        <div className="p-4">
          <h4 className="text-sm font-semibold text-gray-800 mb-2 flex items-center gap-2">
            {MODEL_INFO[selectedModel].icon} {MODEL_INFO[selectedModel].name} Tips
          </h4>
          <ul className="space-y-1.5">
            {MODEL_INFO[selectedModel].tips.map((tip, i) => (
              <li key={i} className="text-sm text-gray-700 flex items-start gap-2">
                <span className="text-blue-500 mt-0.5">•</span>
                <span>{tip}</span>
              </li>
            ))}
          </ul>
        </div>
      </Card>
    </div>
  );
};
