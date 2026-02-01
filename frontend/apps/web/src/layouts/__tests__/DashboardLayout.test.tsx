import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { DashboardLayout } from '../DashboardLayout';
import { AuthProvider } from '../../auth/AuthProvider';
import { setTokens, clearTokens } from '@cobalt/api-client';

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  });
}

function renderLayout(options?: { authenticated?: boolean; path?: string }) {
  const queryClient = createTestQueryClient();

  if (options?.authenticated !== false) {
    setTokens('test-access-token', 'test-refresh-token');
  }

  const initialPath = options?.path ?? '/dashboard';

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[initialPath]}>
        <AuthProvider>
          <Routes>
            <Route element={<DashboardLayout />}>
              <Route path="/dashboard" element={<div>Dashboard Content</div>} />
              <Route path="/jobs" element={<div>Jobs Content</div>} />
            </Route>
          </Routes>
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('DashboardLayout', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('renders sidebar with navigation items when authenticated', async () => {
    renderLayout();
    expect(await screen.findByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Jobs')).toBeInTheDocument();
    expect(screen.getByText('Customers')).toBeInTheDocument();
    expect(screen.getByText('Violations')).toBeInTheDocument();
  });

  it('renders topbar with user name when authenticated', async () => {
    renderLayout();
    expect(await screen.findByText('Admin User (ADMIN)')).toBeInTheDocument();
  });

  it('renders child route content', async () => {
    renderLayout();
    expect(await screen.findByText('Dashboard Content')).toBeInTheDocument();
  });

  it('renders Cobalt branding in sidebar', async () => {
    renderLayout();
    expect(await screen.findByText('Cobalt')).toBeInTheDocument();
  });

  it('shows settings for admin users', async () => {
    renderLayout();
    expect(await screen.findByText('Settings')).toBeInTheDocument();
  });

  it('renders nothing when not authenticated', () => {
    renderLayout({ authenticated: false });
    expect(screen.queryByText('Dashboard')).not.toBeInTheDocument();
  });

  it('renders logout button', async () => {
    renderLayout();
    expect(await screen.findByText('Logout')).toBeInTheDocument();
  });
});
