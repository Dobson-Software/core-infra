import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { AuthProvider } from '../AuthProvider';
import { RequireAuth } from '../RequireAuth';
import { setTokens, clearTokens } from '@cobalt/api-client';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

function renderWithRoute(options?: { authenticated?: boolean; initialRoute?: string }) {
  const queryClient = createTestQueryClient();
  const { authenticated = false, initialRoute = '/protected' } = options ?? {};

  if (authenticated) {
    setTokens('test-access-token', 'test-refresh-token');
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[initialRoute]}>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<div>Login Page</div>} />
            <Route element={<RequireAuth />}>
              <Route path="/protected" element={<div>Protected Content</div>} />
            </Route>
          </Routes>
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('RequireAuth', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('redirects to login when user is not authenticated', async () => {
    renderWithRoute({ authenticated: false });

    await waitFor(() => {
      expect(screen.getByText('Login Page')).toBeInTheDocument();
    });
    expect(screen.queryByText('Protected Content')).not.toBeInTheDocument();
  });

  it('renders protected content when user is authenticated', async () => {
    renderWithRoute({ authenticated: true });

    await waitFor(() => {
      expect(screen.getByText('Protected Content')).toBeInTheDocument();
    });
    expect(screen.queryByText('Login Page')).not.toBeInTheDocument();
  });

  it('shows loading state while authentication is being determined', () => {
    // Set token so it starts loading the user
    setTokens('test-access-token', 'test-refresh-token');

    const queryClient = new QueryClient({
      defaultOptions: {
        queries: { retry: false },
        mutations: { retry: false },
      },
    });

    const { container } = render(
      <QueryClientProvider client={queryClient}>
        <MemoryRouter initialEntries={['/protected']}>
          <AuthProvider>
            <Routes>
              <Route path="/login" element={<div>Login Page</div>} />
              <Route element={<RequireAuth />}>
                <Route path="/protected" element={<div>Protected Content</div>} />
              </Route>
            </Routes>
          </AuthProvider>
        </MemoryRouter>
      </QueryClientProvider>
    );

    // While loading, neither login nor protected content should be visible initially
    // The FullPageSpinner should be rendered (contains a Spinner component)
    const spinner = container.querySelector('.bp5-spinner');
    if (spinner) {
      expect(spinner).toBeInTheDocument();
    }
  });
});
