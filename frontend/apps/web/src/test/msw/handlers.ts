import { http, HttpResponse } from 'msw';

export const handlers = [
  http.post('/api/v1/auth/login', async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string };
    if (body.email === 'admin@demo.com' && body.password === 'password123') {
      return HttpResponse.json({
        data: {
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          expiresIn: 3600000,
          userId: '00000000-0000-0000-0000-000000000001',
          email: body.email,
          role: 'ADMIN',
          tenantId: '00000000-0000-0000-0000-000000000000',
        },
        meta: { timestamp: new Date().toISOString(), requestId: 'test' },
      });
    }
    return HttpResponse.json(
      {
        type: 'https://cobalt.com/errors/unauthorized',
        title: 'Unauthorized',
        status: 401,
        detail: 'Invalid credentials',
      },
      { status: 401 }
    );
  }),

  http.post('/api/v1/auth/register', async () => {
    return HttpResponse.json({
      data: {
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresIn: 3600000,
        userId: '00000000-0000-0000-0000-000000000002',
        email: 'new@test.com',
        role: 'ADMIN',
        tenantId: '00000000-0000-0000-0000-000000000001',
      },
      meta: { timestamp: new Date().toISOString(), requestId: 'test' },
    });
  }),

  http.get('/api/v1/auth/me', ({ request }) => {
    const authHeader = request.headers.get('Authorization');
    if (authHeader === 'Bearer test-access-token') {
      return HttpResponse.json({
        data: {
          id: '00000000-0000-0000-0000-000000000001',
          tenantId: '00000000-0000-0000-0000-000000000000',
          email: 'admin@demo.com',
          firstName: 'Admin',
          lastName: 'User',
          role: 'ADMIN',
        },
        meta: { timestamp: new Date().toISOString(), requestId: 'test' },
      });
    }
    return HttpResponse.json(null, { status: 401 });
  }),

  http.post('/api/v1/auth/logout', () => {
    return HttpResponse.json({
      data: null,
      meta: { timestamp: new Date().toISOString(), requestId: 'test' },
    });
  }),

  http.post('/api/v1/auth/refresh', () => {
    return HttpResponse.json({
      data: {
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
        expiresIn: 3600000,
        userId: '00000000-0000-0000-0000-000000000001',
        email: 'admin@demo.com',
        role: 'ADMIN',
        tenantId: '00000000-0000-0000-0000-000000000000',
      },
      meta: { timestamp: new Date().toISOString(), requestId: 'test' },
    });
  }),
];
