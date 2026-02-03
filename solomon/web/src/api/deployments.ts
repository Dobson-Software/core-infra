import { apiClient } from './client';
import type { Deployment, ApiResponse, PaginatedResponse } from '../types';

export interface TriggerDeploymentRequest {
  serviceId: string;
  environmentId: string;
  imageTag: string;
  gitCommit?: string;
}

export const deploymentsApi = {
  getDeployments: (params?: {
    serviceId?: string;
    environmentId?: string;
    status?: string;
    page?: number;
    size?: number;
  }): Promise<PaginatedResponse<Deployment>> =>
    apiClient.get('/deployments', { params }),

  getDeployment: (id: string): Promise<ApiResponse<Deployment>> =>
    apiClient.get(`/deployments/${id}`),

  triggerDeployment: (data: TriggerDeploymentRequest): Promise<ApiResponse<Deployment>> =>
    apiClient.post('/deployments', data),

  rollbackDeployment: (id: string): Promise<ApiResponse<Deployment>> =>
    apiClient.post(`/deployments/${id}/rollback`),

  getDeploymentLogs: (id: string): Promise<ApiResponse<string[]>> =>
    apiClient.get(`/deployments/${id}/logs`),
};
