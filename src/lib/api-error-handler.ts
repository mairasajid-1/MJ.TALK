// API Error Handler Utility
// Provides consistent error handling and user-friendly messages

export interface ApiErrorResponse {
  error: string;
  details?: string;
  missingConfig?: string[];
  debugInfo?: string;
}

export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number = 500,
    public isConfigError: boolean = false
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export function isConfigurationError(error: any): boolean {
  if (!error) return false;
  
  const message = error.message || error.details || '';
  const missingConfig = error.missingConfig || [];
  
  return (
    error.statusCode === 503 ||
    message.includes('Setup required') ||
    message.includes('configuration') ||
    message.includes('placeholder') ||
    missingConfig.length > 0
  );
}

export function formatErrorMessage(error: any): string {
  if (typeof error === 'string') return error;
  
  if (error.error) return error.error;
  if (error.message) return error.message;
  
  return 'An unexpected error occurred';
}

export async function handleApiResponse(response: Response) {
  const data = await response.json();
  
  if (!response.ok) {
    const error = new ApiError(
      data.error || 'Request failed',
      response.status,
      isConfigurationError(data)
    );
    
    throw error;
  }
  
  return data;
}