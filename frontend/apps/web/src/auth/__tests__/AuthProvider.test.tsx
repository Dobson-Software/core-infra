import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider, useAuth } from '../AuthProvider';
import { setTokens, clearTokens } from '@cobalt/api-client';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

function AuthConsumer() {
  const { user, isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <div data-testid="is-authenticated">{String(isAuthenticated)}</div>
      <div data-testid="user-email">{user?.email ?? 'none'}</div>
      <div data-testid="user-role">{user?.role ?? 'none'}</div>
      <div data-testid="user-first-name">{user?.firstName ?? 'none'}</div>
    </div>
  );
}

function renderWithAuth(options?: { authenticated?: boolean }) {
  const queryClient = createTestQueryClient();

  if (options?.authenticated !== false) {
    setTokens('test-access-token', 'test-refresh-token');
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <AuthProvider>
          <AuthConsumer />
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('AuthProvider', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('provides user data when authenticated with valid token', async () => {
    renderWithAuth({ authenticated: true });

    await waitFor(() => {
      expect(screen.getByTestId('is-authenticated')).toHaveTextContent('true');
    });
    expect(screen.getByTestId('user-email')).toHaveTextContent('admin@demo.com');
    expect(screen.getByTestId('user-role')).toHaveTextContent('ADMIN');
    expect(screen.getByTestId('user-first-name')).toHaveTextContent('Admin');
  });

  it('provides unauthenticated state when no token exists', async () => {
    renderWithAuth({ authenticated: false });

    await waitFor(() => {
      expect(screen.getByTestId('is-authenticated')).toHaveTextContent('false');
    });
    expect(screen.getByTestId('user-email')).toHaveTextContent('none');
  });

  it('provides isAuthenticated as false when no user data', async () => {
    renderWithAuth({ authenticated: false });

    await waitFor(() => {
      expect(screen.getByTestId('is-authenticated')).toHaveTextContent('false');
    });
  });

  it('provides logout function via context', async () => {
    function LogoutConsumer() {
      const { logout } = useAuth();
      return (
        <div>
          <div data-testid="has-logout">{typeof logout === 'function' ? 'yes' : 'no'}</div>
        </div>
      );
    }

    const queryClient = createTestQueryClient();

    render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter>
          <AuthProvider>
            <LogoutConsumer />
          </AuthProvider>
        </MemoryRouter>
      </QueryClientProvider>
    );

    expect(screen.getByTestId('has-logout')).toHaveTextContent('yes');
  });
});
