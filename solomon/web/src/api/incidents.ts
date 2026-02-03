import { apiClient } from './client';
import type {
  Incident,
  IncidentTimelineEvent,
  ApiResponse,
  PaginatedResponse,
} from '../types';

export const incidentsApi = {
  getIncidents: (params?: {
    status?: string;
    severity?: string;
    page?: number;
    size?: number;
  }): Promise<PaginatedResponse<Incident>> =>
    apiClient.get('/incidents', { params }),

  getIncident: (id: string): Promise<ApiResponse<Incident>> =>
    apiClient.get(`/incidents/${id}`),

  createIncident: (data: Partial<Incident>): Promise<ApiResponse<Incident>> =>
    apiClient.post('/incidents', data),

  updateIncident: (id: string, data: Partial<Incident>): Promise<ApiResponse<Incident>> =>
    apiClient.put(`/incidents/${id}`, data),

  acknowledgeIncident: (id: string): Promise<ApiResponse<Incident>> =>
    apiClient.post(`/incidents/${id}/acknowledge`),

  resolveIncident: (id: string, resolution: string): Promise<ApiResponse<Incident>> =>
    apiClient.post(`/incidents/${id}/resolve`, { resolution }),

  // Timeline
  getTimeline: (incidentId: string): Promise<ApiResponse<IncidentTimelineEvent[]>> =>
    apiClient.get(`/incidents/${incidentId}/timeline`),

  addTimelineEvent: (
    incidentId: string,
    data: { eventType: string; content: string }
  ): Promise<ApiResponse<IncidentTimelineEvent>> =>
    apiClient.post(`/incidents/${incidentId}/timeline`, data),

  // Suggested runbooks
  getSuggestedRunbooks: (incidentId: string): Promise<ApiResponse<string[]>> =>
    apiClient.get(`/incidents/${incidentId}/runbooks`),
};
