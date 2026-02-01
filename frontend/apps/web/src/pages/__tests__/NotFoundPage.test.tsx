import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { NotFoundPage } from '../NotFoundPage';

function renderNotFound() {
  return render(
    <MemoryRouter initialEntries={['/unknown']}>
      <Routes>
        <Route path="/" element={<div>Home Page</div>} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </MemoryRouter>
  );
}

describe('NotFoundPage', () => {
  it('renders page not found title', () => {
    renderNotFound();
    expect(screen.getByText('Page Not Found')).toBeInTheDocument();
  });

  it('renders description text', () => {
    renderNotFound();
    expect(
      screen.getByText('The page you are looking for does not exist or has been moved.')
    ).toBeInTheDocument();
  });

  it('renders go home button', () => {
    renderNotFound();
    expect(screen.getByText('Go to Home')).toBeInTheDocument();
  });

  it('navigates to home when button is clicked', async () => {
    const user = userEvent.setup();
    renderNotFound();
    await user.click(screen.getByText('Go to Home'));
    expect(screen.getByText('Home Page')).toBeInTheDocument();
  });
});
