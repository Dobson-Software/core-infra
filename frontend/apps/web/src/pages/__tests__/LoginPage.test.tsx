import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../../test/msw/server';
import { renderWithProviders } from '../../test/test-utils';
import { LoginPage } from '../LoginPage';
import { clearTokens } from '@cobalt/api-client';

describe('LoginPage', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('renders sign in form with email and password fields', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByRole('heading', { name: 'Sign In' })).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Password')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
  });

  it('renders link to register page', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByText('Register')).toBeInTheDocument();
    expect(screen.getByText('Register').closest('a')).toHaveAttribute('href', '/register');
  });

  it('submits form with valid credentials and calls API', async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.type(screen.getByLabelText('Email'), 'admin@demo.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      // After successful login, tokens should be stored
      expect(localStorage.getItem('cobalt_access_token')).toBe('test-access-token');
      expect(localStorage.getItem('cobalt_refresh_token')).toBe('test-refresh-token');
    });
  });

  it('displays error message on failed login', async () => {
    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.type(screen.getByLabelText('Email'), 'wrong@example.com');
    await user.type(screen.getByLabelText('Password'), 'wrongpassword');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(screen.getByText('Invalid email or password.')).toBeInTheDocument();
    });
  });

  it('displays error message when server returns 500', async () => {
    server.use(
      http.post('/api/v1/auth/login', () => {
        return HttpResponse.json(
          { type: 'https://cobalt.com/errors/internal', title: 'Internal Error', status: 500 },
          { status: 500 }
        );
      })
    );

    const user = userEvent.setup();
    renderWithProviders(<LoginPage />);

    await user.type(screen.getByLabelText('Email'), 'admin@demo.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(screen.getByText('Invalid email or password.')).toBeInTheDocument();
    });
  });

  it('shows Cobalt Platform subtitle', () => {
    renderWithProviders(<LoginPage />);

    expect(screen.getByText('Cobalt Platform')).toBeInTheDocument();
  });
});
