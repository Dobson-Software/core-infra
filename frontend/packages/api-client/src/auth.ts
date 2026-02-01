import { apiClient, setTokens, clearTokens } from './client';
import type { LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, User } from './types';

export const authApi = {
  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const result = (await apiClient.post('/api/v1/auth/login', data)) as unknown as LoginResponse;
    setTokens(result.accessToken, result.refreshToken);
    return result;
  },

  register: async (data: RegisterRequest): Promise<RegisterResponse> => {
    const result = (await apiClient.post(
      '/api/v1/auth/register',
      data
    )) as unknown as RegisterResponse;
    setTokens(result.accessToken, result.refreshToken);
    return result;
  },

  me: async (): Promise<User> => {
    return apiClient.get('/api/v1/auth/me') as Promise<User>;
  },

  logout: async (): Promise<void> => {
    try {
      await apiClient.post('/api/v1/auth/logout');
    } finally {
      clearTokens();
    }
  },
};
