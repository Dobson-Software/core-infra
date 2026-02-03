// Service Catalog
export interface Service {
  id: string;
  name: string;
  displayName: string;
  description: string;
  repository: string;
  team: string;
  tier: 'critical' | 'standard' | 'experimental';
  language: string;
  framework: string;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface Environment {
  id: string;
  serviceId: string;
  name: string;
  cluster: string;
  namespace: string;
  config: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface Dependency {
  id: string;
  serviceId: string;
  dependsOnId: string;
  type: 'runtime' | 'build' | 'optional';
  description: string;
}

export interface Runbook {
  id: string;
  serviceId: string;
  title: string;
  trigger: string;
  content: string;
  automatable: boolean;
  aiPrompt: string;
  createdAt: string;
  updatedAt: string;
}

// Deployments
export type DeploymentStatus = 'pending' | 'in_progress' | 'succeeded' | 'failed' | 'rolled_back';

export interface Deployment {
  id: string;
  serviceId: string;
  environmentId: string;
  imageTag: string;
  gitCommit: string;
  status: DeploymentStatus;
  initiatedBy: string;
  initiatedVia: 'api' | 'gitops' | 'ai' | 'manual';
  startedAt: string;
  completedAt: string | null;
  metadata: Record<string, unknown>;
}

// Incidents
export type IncidentSeverity = 'critical' | 'high' | 'medium' | 'low';
export type IncidentStatus = 'triggered' | 'acknowledged' | 'investigating' | 'identified' | 'monitoring' | 'resolved';

export interface Incident {
  id: string;
  title: string;
  description: string;
  severity: IncidentSeverity;
  status: IncidentStatus;
  sourceType: string;
  sourceAlertId: string;
  affectedServices: string[];
  affectedEnvironments: string[];
  assignee: string | null;
  acknowledgedAt: string | null;
  resolvedAt: string | null;
  postmortem: Record<string, unknown> | null;
  createdAt: string;
  updatedAt: string;
}

export interface IncidentTimelineEvent {
  id: string;
  incidentId: string;
  eventType: string;
  actor: string;
  content: string;
  metadata: Record<string, unknown>;
  createdAt: string;
}

// AI Sessions
export type AISessionStatus = 'active' | 'paused' | 'completed' | 'failed';

export interface AISession {
  id: string;
  userId: string;
  contextType: string | null;
  contextId: string | null;
  status: AISessionStatus;
  model: string;
  startedAt: string;
  endedAt: string | null;
  metadata: Record<string, unknown>;
}

export interface AIAction {
  id: string;
  sessionId: string;
  actionType: string;
  toolName: string;
  input: Record<string, unknown>;
  output: Record<string, unknown> | null;
  status: 'pending' | 'approved' | 'rejected' | 'executed' | 'failed';
  requiresApproval: boolean;
  approvedBy: string | null;
  approvedAt: string | null;
  executedAt: string | null;
  createdAt: string;
}

// Costs
export interface CostRecord {
  id: string;
  date: string;
  environment: string;
  serviceId: string | null;
  resourceType: string;
  resourceId: string;
  costUsd: number;
  usageQuantity: number;
  usageUnit: string;
  metadata: Record<string, unknown>;
}

export interface CostSummary {
  environment: string;
  totalCost: number;
  previousPeriodCost: number;
  changePercent: number;
  topServices: Array<{
    serviceId: string;
    serviceName: string;
    cost: number;
  }>;
}

// Audit Log
export interface AuditLogEntry {
  id: string;
  actor: string;
  actorType: 'user' | 'ai' | 'system';
  action: string;
  resourceType: string;
  resourceId: string;
  details: Record<string, unknown>;
  ipAddress: string;
  userAgent: string;
  createdAt: string;
}

// API Response wrappers
export interface ApiResponse<T> {
  data: T;
  meta: {
    timestamp: string;
    requestId: string;
  };
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    size: number;
    totalElements: number;
    totalPages: number;
  };
}

// Dashboard
export interface DashboardStats {
  totalServices: number;
  healthyServices: number;
  activeDeployments: number;
  openIncidents: number;
  mttr: number; // mean time to resolve in minutes
  deploymentSuccessRate: number;
  monthlySpend: number;
  monthlySpendChange: number;
}
