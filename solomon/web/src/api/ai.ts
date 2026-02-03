import { apiClient } from './client';
import type { AISession, AIAction, ApiResponse, PaginatedResponse } from '../types';

export interface CreateSessionRequest {
  contextType?: string;
  contextId?: string;
  initialPrompt?: string;
}

export const aiApi = {
  // Sessions
  getSessions: (params?: {
    status?: string;
    page?: number;
    size?: number;
  }): Promise<PaginatedResponse<AISession>> =>
    apiClient.get('/ai/sessions', { params }),

  getSession: (id: string): Promise<ApiResponse<AISession>> =>
    apiClient.get(`/ai/sessions/${id}`),

  createSession: (data: CreateSessionRequest): Promise<ApiResponse<AISession>> =>
    apiClient.post('/ai/sessions', data),

  endSession: (id: string): Promise<ApiResponse<AISession>> =>
    apiClient.post(`/ai/sessions/${id}/end`),

  // Actions
  getSessionActions: (sessionId: string): Promise<ApiResponse<AIAction[]>> =>
    apiClient.get(`/ai/sessions/${sessionId}/actions`),

  approveAction: (sessionId: string, actionId: string): Promise<ApiResponse<AIAction>> =>
    apiClient.post(`/ai/sessions/${sessionId}/actions/${actionId}/approve`),

  rejectAction: (sessionId: string, actionId: string, reason: string): Promise<ApiResponse<AIAction>> =>
    apiClient.post(`/ai/sessions/${sessionId}/actions/${actionId}/reject`, { reason }),

  // Send message (for streaming, use WebSocket)
  sendMessage: (sessionId: string, message: string): Promise<ApiResponse<{ acknowledged: boolean }>> =>
    apiClient.post(`/ai/sessions/${sessionId}/message`, { message }),

  // Available tools
  getAvailableTools: (): Promise<ApiResponse<Array<{ name: string; description: string; requiresApproval: boolean }>>> =>
    apiClient.get('/ai/tools'),
};

// WebSocket connection for real-time AI streaming
export function createAIWebSocket(sessionId: string): WebSocket {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const token = localStorage.getItem('solomon_token');
  return new WebSocket(`${protocol}//${window.location.host}/ws/ai/${sessionId}?token=${token}`);
}
