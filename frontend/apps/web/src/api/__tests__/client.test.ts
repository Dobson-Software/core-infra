import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../../test/msw/server';
import { apiClient, getAccessToken, setTokens, clearTokens } from '@cobalt/api-client';

describe('API Client', () => {
  beforeEach(() => {
    clearTokens();
  });

  describe('token management', () => {
    it('setTokens stores access and refresh tokens', () => {
      setTokens('access-123', 'refresh-456');

      expect(getAccessToken()).toBe('access-123');
      expect(localStorage.getItem('cobalt_refresh_token')).toBe('refresh-456');
    });

    it('clearTokens removes all tokens', () => {
      setTokens('access-123', 'refresh-456');
      clearTokens();

      expect(getAccessToken()).toBeNull();
      expect(localStorage.getItem('cobalt_refresh_token')).toBeNull();
    });

    it('getAccessToken returns null when no token is set', () => {
      expect(getAccessToken()).toBeNull();
    });
  });

  describe('request interceptor', () => {
    it('attaches Authorization header when token exists', async () => {
      server.use(
        http.get('/api/v1/test/data', ({ request }) => {
          const authHeader = request.headers.get('Authorization');
          return HttpResponse.json({
            data: { message: 'success', authHeader },
            meta: { timestamp: new Date().toISOString(), requestId: 'test-123' },
          });
        })
      );

      setTokens('my-token', 'my-refresh');

      const result = await apiClient.get('/api/v1/test/data');

      expect((result as unknown as { authHeader: string }).authHeader).toBe('Bearer my-token');
    });

    it('does not attach Authorization header when no token exists', async () => {
      server.use(
        http.get('/api/v1/test/data', ({ request }) => {
          const authHeader = request.headers.get('Authorization');
          return HttpResponse.json({
            data: { message: 'success', authHeader },
            meta: { timestamp: new Date().toISOString(), requestId: 'test-123' },
          });
        })
      );

      clearTokens();

      const result = await apiClient.get('/api/v1/test/data');

      expect((result as unknown as { authHeader: string | null }).authHeader).toBeNull();
    });
  });

  describe('response interceptor', () => {
    it('unwraps ApiResponse envelope (extracts data from data.data)', async () => {
      server.use(
        http.get('/api/v1/test/data', () => {
          return HttpResponse.json({
            data: { message: 'success' },
            meta: { timestamp: new Date().toISOString(), requestId: 'test-123' },
          });
        })
      );

      const result = await apiClient.get('/api/v1/test/data');

      expect((result as unknown as { message: string }).message).toBe('success');
    });

    it('returns raw response when not ApiResponse envelope', async () => {
      server.use(
        http.get('/api/v1/test/raw', () => {
          return HttpResponse.json({ raw: 'response' });
        })
      );

      const result = await apiClient.get('/api/v1/test/raw');

      expect((result as unknown as { raw: string }).raw).toBe('response');
    });
  });

  describe('token refresh', () => {
    it('refreshes token on 401 and retries the request', async () => {
      let callCount = 0;
      server.use(
        http.get('/api/v1/test/protected', ({ request }) => {
          callCount++;
          const authHeader = request.headers.get('Authorization');
          if (authHeader === 'Bearer refreshed-token') {
            return HttpResponse.json({
              data: { message: 'success after refresh' },
              meta: { timestamp: new Date().toISOString(), requestId: 'test-456' },
            });
          }
          return HttpResponse.json(null, { status: 401 });
        }),
        http.post('/api/v1/auth/refresh', async ({ request }) => {
          const body = (await request.json()) as { refreshToken: string };
          if (body.refreshToken === 'valid-refresh-token') {
            return HttpResponse.json({
              data: {
                accessToken: 'refreshed-token',
                refreshToken: 'new-refresh-token',
                expiresIn: 3600000,
                userId: '00000000-0000-0000-0000-000000000001',
                email: 'admin@demo.com',
                role: 'ADMIN',
                tenantId: '00000000-0000-0000-0000-000000000000',
              },
              meta: { timestamp: new Date().toISOString(), requestId: 'refresh-test' },
            });
          }
          return HttpResponse.json(null, { status: 401 });
        })
      );

      setTokens('expired-token', 'valid-refresh-token');

      const result = await apiClient.get('/api/v1/test/protected');

      expect((result as unknown as { message: string }).message).toBe('success after refresh');
      expect(getAccessToken()).toBe('refreshed-token');
      expect(callCount).toBe(2); // First call fails, retry succeeds
    });

    it('clears tokens when no refresh token is available', async () => {
      server.use(
        http.get('/api/v1/test/protected', () => {
          return HttpResponse.json(null, { status: 401 });
        })
      );

      // No refresh token stored
      clearTokens();

      try {
        await apiClient.get('/api/v1/test/protected');
      } catch {
        // Expected to fail
      }
      expect(getAccessToken()).toBeNull();
    });
  });
});
