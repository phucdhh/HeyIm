import {
  GenerateRequest,
  GenerateResponse,
  StatusResponse,
  ServerInfo,
} from '@/types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5858';

class HeyImAPI {
  private baseURL: string;

  constructor(baseURL: string = API_BASE_URL) {
    this.baseURL = baseURL;
  }

  /**
   * Check if server is healthy
   */
  async healthCheck(): Promise<{ status: string }> {
    const response = await fetch(`${this.baseURL}/health`);
    const text = await response.text();
    return { status: text };
  }

  /**
   * Get server information
   */
  async getInfo(): Promise<ServerInfo> {
    const response = await fetch(`${this.baseURL}/api/info`);
    if (!response.ok) {
      throw new Error(`Failed to get server info: ${response.statusText}`);
    }
    return response.json();
  }

  /**
   * Get current server status
   */
  async getStatus(): Promise<StatusResponse> {
    const response = await fetch(`${this.baseURL}/api/status`);
    if (!response.ok) {
      throw new Error(`Failed to get status: ${response.statusText}`);
    }
    return response.json();
  }

  /**
   * Load models into memory
   */
  async loadModels(): Promise<{ success: boolean; message: string }> {
    const response = await fetch(`${this.baseURL}/api/load`, {
      method: 'POST',
    });
    if (!response.ok) {
      throw new Error(`Failed to load models: ${response.statusText}`);
    }
    return response.json();
  }

  /**
   * Generate an image
   */
  async generate(request: GenerateRequest): Promise<GenerateResponse> {
    const response = await fetch(`${this.baseURL}/api/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`Failed to generate image: ${response.statusText}`);
    }

    return response.json();
  }
}

// Export singleton instance
export const api = new HeyImAPI();

// Export class for testing
export { HeyImAPI };
