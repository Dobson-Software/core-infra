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

export interface ApiError {
  type: string;
  title: string;
  status: number;
  detail: string;
  instance: string;
  errors?: Array<{ field: string; message: string }>;
}

export type UserRole = 'ADMIN' | 'MANAGER' | 'TECHNICIAN';

export interface User {
  id: string;
  tenantId: string;
  email: string;
  firstName: string;
  lastName: string;
  role: UserRole;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse extends AuthTokens {
  userId: string;
  email: string;
  role: UserRole;
  tenantId: string;
}

export interface RegisterRequest {
  companyName: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export type RegisterResponse = LoginResponse;
