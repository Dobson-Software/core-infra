import { describe, it, expect } from 'vitest';
import { queryClient } from '../query-client';

describe('queryClient', () => {
  it('is a valid QueryClient instance', () => {
    expect(queryClient).toBeDefined();
    expect(queryClient.getDefaultOptions()).toBeDefined();
  });

  it('has staleTime set to 5 minutes', () => {
    const defaults = queryClient.getDefaultOptions();
    expect(defaults.queries?.staleTime).toBe(5 * 60 * 1000);
  });

  it('has retry set to 1', () => {
    const defaults = queryClient.getDefaultOptions();
    expect(defaults.queries?.retry).toBe(1);
  });

  it('has refetchOnWindowFocus disabled', () => {
    const defaults = queryClient.getDefaultOptions();
    expect(defaults.queries?.refetchOnWindowFocus).toBe(false);
  });
});
