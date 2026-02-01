import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '../../test/msw/server';
import { renderWithProviders } from '../../test/test-utils';
import { RegisterPage } from '../RegisterPage';
import { clearTokens } from '@cobalt/api-client';

describe('RegisterPage', () => {
  beforeEach(() => {
    clearTokens();
  });

  it('renders registration form with all required fields', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByRole('heading', { name: 'Create Account' })).toBeInTheDocument();
    expect(screen.getByLabelText('Company Name')).toBeInTheDocument();
    expect(screen.getByLabelText('First Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Last Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Password')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /create account/i })).toBeInTheDocument();
  });

  it('renders link to sign in page', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('Sign In')).toBeInTheDocument();
    expect(screen.getByText('Sign In').closest('a')).toHaveAttribute('href', '/login');
  });

  it('shows subtitle text', () => {
    renderWithProviders(<RegisterPage />);

    expect(screen.getByText('Start managing your business with Cobalt')).toBeInTheDocument();
  });

  it('submits form with valid data and stores tokens', async () => {
    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await user.type(screen.getByLabelText('Company Name'), 'Test Plumbing Co');
    await user.type(screen.getByLabelText('First Name'), 'John');
    await user.type(screen.getByLabelText('Last Name'), 'Smith');
    await user.type(screen.getByLabelText('Email'), 'john@testplumbing.com');
    await user.type(screen.getByLabelText('Password'), 'securepassword123');
    await user.click(screen.getByRole('button', { name: /create account/i }));

    await waitFor(() => {
      expect(localStorage.getItem('cobalt_access_token')).toBe('test-access-token');
      expect(localStorage.getItem('cobalt_refresh_token')).toBe('test-refresh-token');
    });
  });

  it('displays error message on failed registration', async () => {
    server.use(
      http.post('/api/v1/auth/register', () => {
        return HttpResponse.json(
          {
            type: 'https://cobalt.com/errors/validation',
            title: 'Validation Failed',
            status: 400,
            detail: 'Email already in use',
            errors: [{ field: 'email', message: 'Email already in use' }],
          },
          { status: 400 }
        );
      })
    );

    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await user.type(screen.getByLabelText('Company Name'), 'Test Co');
    await user.type(screen.getByLabelText('First Name'), 'Jane');
    await user.type(screen.getByLabelText('Last Name'), 'Doe');
    await user.type(screen.getByLabelText('Email'), 'existing@test.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: /create account/i }));

    await waitFor(() => {
      expect(screen.getByText('Registration failed. Please try again.')).toBeInTheDocument();
    });
  });

  it('displays error message on server error', async () => {
    server.use(
      http.post('/api/v1/auth/register', () => {
        return HttpResponse.json(
          { type: 'https://cobalt.com/errors/internal', title: 'Server Error', status: 500 },
          { status: 500 }
        );
      })
    );

    const user = userEvent.setup();
    renderWithProviders(<RegisterPage />);

    await user.type(screen.getByLabelText('Company Name'), 'Test Co');
    await user.type(screen.getByLabelText('First Name'), 'Jane');
    await user.type(screen.getByLabelText('Last Name'), 'Doe');
    await user.type(screen.getByLabelText('Email'), 'test@test.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: /create account/i }));

    await waitFor(() => {
      expect(screen.getByText('Registration failed. Please try again.')).toBeInTheDocument();
    });
  });
});
