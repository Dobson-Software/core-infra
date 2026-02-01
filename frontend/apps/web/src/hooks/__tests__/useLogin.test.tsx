import { renderHook } from '@testing-library/react';
import React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useLogin } from '../useLogin';

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  });
  return function Wrapper({ children }: { children: React.ReactNode }) {
    return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
  };
}

describe('useLogin', () => {
  it('returns a mutation function', () => {
    const { result } = renderHook(() => useLogin(), { wrapper: createWrapper() });

    expect(result.current.mutate).toBeDefined();
    expect(result.current.isIdle).toBe(true);
  });

  it('starts in idle state', () => {
    const { result } = renderHook(() => useLogin(), { wrapper: createWrapper() });

    expect(result.current.isPending).toBe(false);
    expect(result.current.isSuccess).toBe(false);
    expect(result.current.isError).toBe(false);
  });
});
