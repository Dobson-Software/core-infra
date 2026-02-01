import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { DashboardPage } from '../DashboardPage';
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

function renderDashboard(options?: { authenticated?: boolean }) {
  const queryClient = createTestQueryClient();

  if (options?.authenticated !== false) {
    setTokens('test-access-token', 'test-refresh-token');
  }

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <AuthProvider>
          <DashboardPage />
        </AuthProvider>
      </MemoryRouter>
    </QueryClientProvider>
  );
}

describe('DashboardPage', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('renders welcome message with user first name when authenticated', async () => {
    renderDashboard({ authenticated: true });

    expect(await screen.findByText('Welcome, Admin!')).toBeInTheDocument();
  });

  it('renders business overview subtitle', async () => {
    renderDashboard({ authenticated: true });

    expect(await screen.findByText('Here is your business overview.')).toBeInTheDocument();
  });

  it('renders metric cards', async () => {
    renderDashboard({ authenticated: true });

    // Wait for user data to load and dashboard to render
    expect(await screen.findByRole('heading', { name: /Welcome/ })).toBeInTheDocument();

    // Each metric title appears twice (in <p> and in <Tag>), so use getAllByText
    expect(screen.getAllByText('Jobs Today').length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('Open Estimates').length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('Pending Invoices').length).toBeGreaterThanOrEqual(1);
    expect(screen.getAllByText('Active Violations').length).toBeGreaterThanOrEqual(1);
  });

  it('renders Revenue card for ADMIN role', async () => {
    renderDashboard({ authenticated: true });

    // Wait for user data to load
    expect(await screen.findByRole('heading', { name: /Welcome/ })).toBeInTheDocument();

    // The MSW handler returns role: 'ADMIN', so Revenue card should show
    expect(screen.getAllByText('Revenue (MTD)').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('$0.00')).toBeInTheDocument();
  });

  it('renders nothing when user is not available', () => {
    renderDashboard({ authenticated: false });

    expect(screen.queryByText(/Welcome/)).not.toBeInTheDocument();
  });
});
