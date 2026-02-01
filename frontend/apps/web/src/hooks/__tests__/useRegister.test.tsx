import { renderHook, waitFor } from '@testing-library/react';
import { act } from 'react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../../test/msw/server';
import { useRegister } from '../useRegister';
import { clearTokens } from '@cobalt/api-client';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

describe('useRegister', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('returns a mutation function', () => {
    const { result } = renderHook(() => useRegister(), { wrapper: createWrapper() });

    expect(result.current.mutate).toBeDefined();
    expect(result.current.isIdle).toBe(true);
  });

  it('starts in idle state', () => {
    const { result } = renderHook(() => useRegister(), { wrapper: createWrapper() });

    expect(result.current.isPending).toBe(false);
    expect(result.current.isSuccess).toBe(false);
    expect(result.current.isError).toBe(false);
  });

  it('successfully registers and stores tokens', async () => {
    const { result } = renderHook(() => useRegister(), { wrapper: createWrapper() });

    act(() => {
      result.current.mutate({
        companyName: 'Test Company',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@test.com',
        password: 'password123',
      });
    });

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true);
    });

    expect(localStorage.getItem('cobalt_access_token')).toBe('test-access-token');
    expect(localStorage.getItem('cobalt_refresh_token')).toBe('test-refresh-token');
  });

  it('handles registration failure', async () => {
    server.use(
      http.post('/api/v1/auth/register', () => {
        return HttpResponse.json(
          {
            type: 'https://cobalt.com/errors/validation',
            title: 'Validation Failed',
            status: 400,
            detail: 'Email already exists',
          },
          { status: 400 }
        );
      })
    );

    const { result } = renderHook(() => useRegister(), { wrapper: createWrapper() });

    act(() => {
      result.current.mutate({
        companyName: 'Test Company',
        firstName: 'John',
        lastName: 'Doe',
        email: 'existing@test.com',
        password: 'password123',
      });
    });

    await waitFor(() => {
      expect(result.current.isError).toBe(true);
    });

    expect(result.current.isSuccess).toBe(false);
  });
});
