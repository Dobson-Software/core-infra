import { apiClient } from './client';
import type { DashboardStats, ApiResponse } from '../types';

export const dashboardApi = {
  getStats: (): Promise<ApiResponse<DashboardStats>> =>
    apiClient.get('/dashboard/stats'),

  getRecentDeployments: (limit?: number): Promise<ApiResponse<Array<{
    id: string;
    serviceName: string;
    environment: string;
    status: string;
    startedAt: string;
  }>>> =>
    apiClient.get('/dashboard/recent-deployments', { params: { limit } }),

  getActiveIncidents: (): Promise<ApiResponse<Array<{
    id: string;
    title: string;
    severity: string;
    status: string;
    createdAt: string;
  }>>> =>
    apiClient.get('/dashboard/active-incidents'),

  getServiceHealth: (): Promise<ApiResponse<Array<{
    serviceId: string;
    serviceName: string;
    status: 'healthy' | 'degraded' | 'down';
    lastChecked: string;
  }>>> =>
    apiClient.get('/dashboard/service-health'),
};
