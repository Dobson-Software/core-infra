import { apiClient } from './client';
import type { CostRecord, CostSummary, ApiResponse } from '../types';

export const costsApi = {
  getCostSummary: (params: {
    startDate: string;
    endDate: string;
    environment?: string;
  }): Promise<ApiResponse<CostSummary[]>> =>
    apiClient.get('/costs/summary', { params }),

  getCostsByService: (params: {
    startDate: string;
    endDate: string;
    serviceId?: string;
  }): Promise<ApiResponse<CostRecord[]>> =>
    apiClient.get('/costs/by-service', { params }),

  getCostsByResource: (params: {
    startDate: string;
    endDate: string;
    resourceType?: string;
  }): Promise<ApiResponse<CostRecord[]>> =>
    apiClient.get('/costs/by-resource', { params }),

  getCostTrend: (params: {
    startDate: string;
    endDate: string;
    granularity: 'daily' | 'weekly' | 'monthly';
  }): Promise<ApiResponse<Array<{ date: string; cost: number }>>> =>
    apiClient.get('/costs/trend', { params }),

  triggerCostSync: (): Promise<ApiResponse<{ message: string }>> =>
    apiClient.post('/costs/sync'),
};
