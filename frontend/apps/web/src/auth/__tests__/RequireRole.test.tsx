import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { RequireRole } from '../RequireRole';
import { AuthProvider } from '../AuthProvider';
import { setTokens, clearTokens } from '@cobalt/api-client';
import type { UserRole } from '@cobalt/api-client';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

function renderWithRole(allowedRoles: UserRole[], options?: { authenticated?: boolean }) {
  const queryClient = createTestQueryClient();

  if (options?.authenticated !== false) {
    setTokens('test-access-token', 'test-refresh-token');
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <AuthProvider>
          <RequireRole allowedRoles={allowedRoles}>
            <div>Protected Content</div>
          </RequireRole>
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('RequireRole', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('renders children when user has an allowed role', async () => {
    renderWithRole(['ADMIN']);
    expect(await screen.findByText('Protected Content')).toBeInTheDocument();
  });

  it('shows access denied when user role is not allowed', async () => {
    renderWithRole(['TECHNICIAN']);
    // MSW returns ADMIN role, so TECHNICIAN-only should deny
    expect(await screen.findByText('Access Denied')).toBeInTheDocument();
    expect(screen.getByText('You do not have permission to view this page.')).toBeInTheDocument();
  });

  it('shows access denied when not authenticated', () => {
    renderWithRole(['ADMIN'], { authenticated: false });
    expect(screen.getByText('Access Denied')).toBeInTheDocument();
  });
});
