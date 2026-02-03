import { apiClient } from './client';
import type {
  Service,
  Environment,
  Dependency,
  Runbook,
  ApiResponse,
  PaginatedResponse,
} from '../types';

export const servicesApi = {
  // Services
  getServices: (params?: { team?: string; tier?: string }): Promise<PaginatedResponse<Service>> =>
    apiClient.get('/services', { params }),

  getService: (id: string): Promise<ApiResponse<Service>> =>
    apiClient.get(`/services/${id}`),

  createService: (data: Partial<Service>): Promise<ApiResponse<Service>> =>
    apiClient.post('/services', data),

  updateService: (id: string, data: Partial<Service>): Promise<ApiResponse<Service>> =>
    apiClient.put(`/services/${id}`, data),

  deleteService: (id: string): Promise<void> =>
    apiClient.delete(`/services/${id}`),

  // Environments
  getEnvironments: (serviceId: string): Promise<ApiResponse<Environment[]>> =>
    apiClient.get(`/services/${serviceId}/environments`),

  createEnvironment: (serviceId: string, data: Partial<Environment>): Promise<ApiResponse<Environment>> =>
    apiClient.post(`/services/${serviceId}/environments`, data),

  updateEnvironment: (serviceId: string, envId: string, data: Partial<Environment>): Promise<ApiResponse<Environment>> =>
    apiClient.put(`/services/${serviceId}/environments/${envId}`, data),

  deleteEnvironment: (serviceId: string, envId: string): Promise<void> =>
    apiClient.delete(`/services/${serviceId}/environments/${envId}`),

  // Dependencies
  getDependencies: (serviceId: string): Promise<ApiResponse<Dependency[]>> =>
    apiClient.get(`/services/${serviceId}/dependencies`),

  addDependency: (serviceId: string, data: Partial<Dependency>): Promise<ApiResponse<Dependency>> =>
    apiClient.post(`/services/${serviceId}/dependencies`, data),

  removeDependency: (serviceId: string, depId: string): Promise<void> =>
    apiClient.delete(`/services/${serviceId}/dependencies/${depId}`),

  // Runbooks
  getRunbooks: (serviceId: string): Promise<ApiResponse<Runbook[]>> =>
    apiClient.get(`/services/${serviceId}/runbooks`),

  getRunbook: (serviceId: string, runbookId: string): Promise<ApiResponse<Runbook>> =>
    apiClient.get(`/services/${serviceId}/runbooks/${runbookId}`),

  createRunbook: (serviceId: string, data: Partial<Runbook>): Promise<ApiResponse<Runbook>> =>
    apiClient.post(`/services/${serviceId}/runbooks`, data),

  updateRunbook: (serviceId: string, runbookId: string, data: Partial<Runbook>): Promise<ApiResponse<Runbook>> =>
    apiClient.put(`/services/${serviceId}/runbooks/${runbookId}`, data),

  deleteRunbook: (serviceId: string, runbookId: string): Promise<void> =>
    apiClient.delete(`/services/${serviceId}/runbooks/${runbookId}`),
};
