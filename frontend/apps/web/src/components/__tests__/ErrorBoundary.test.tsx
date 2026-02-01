import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { ErrorBoundary } from '../ErrorBoundary';

function ProblemChild({ shouldThrow }: { shouldThrow: boolean }) {
  if (shouldThrow) {
    throw new Error('Test error message');
  }
  return <div>Child content rendered</div>;
}

describe('ErrorBoundary', () => {
  beforeEach(() => {
    // Suppress console.error for expected error boundary logs
    const originalError = console.error;
    console.error = (...args: unknown[]) => {
      if (
        typeof args[0] === 'string' &&
        (args[0].includes('ErrorBoundary caught') || args[0].includes('The above error occurred'))
      ) {
        return;
      }
      originalError(...args);
    };
  });

  it('renders children when no error occurs', () => {
    render(
      <ErrorBoundary>
        <ProblemChild shouldThrow={false} />
      </ErrorBoundary>
    );

    expect(screen.getByText('Child content rendered')).toBeInTheDocument();
  });

  it('shows default fallback UI when a child throws an error', () => {
    render(
      <ErrorBoundary>
        <ProblemChild shouldThrow={true} />
      </ErrorBoundary>
    );

    expect(screen.getByText('Something went wrong')).toBeInTheDocument();
    expect(screen.getByText('Test error message')).toBeInTheDocument();
    expect(screen.getByText('Try Again')).toBeInTheDocument();
  });

  it('shows custom fallback when provided and a child throws an error', () => {
    render(
      <ErrorBoundary fallback={<div>Custom fallback UI</div>}>
        <ProblemChild shouldThrow={true} />
      </ErrorBoundary>
    );

    expect(screen.getByText('Custom fallback UI')).toBeInTheDocument();
    expect(screen.queryByText('Something went wrong')).not.toBeInTheDocument();
  });

  it('resets error state when Try Again button is clicked', () => {
    let shouldThrow = true;

    function ToggleChild() {
      if (shouldThrow) {
        throw new Error('Temporary error');
      }
      return <div>Recovered content</div>;
    }

    const { rerender } = render(
      <ErrorBoundary>
        <ToggleChild />
      </ErrorBoundary>
    );

    expect(screen.getByText('Something went wrong')).toBeInTheDocument();

    // Fix the error before clicking reset
    shouldThrow = false;

    fireEvent.click(screen.getByText('Try Again'));

    rerender(
      <ErrorBoundary>
        <ToggleChild />
      </ErrorBoundary>
    );

    expect(screen.getByText('Recovered content')).toBeInTheDocument();
  });

  it('displays generic message when error has no message', () => {
    function NoMessageError(): never {
      throw new Error();
    }

    render(
      <ErrorBoundary>
        <NoMessageError />
      </ErrorBoundary>
    );

    expect(screen.getByText('Something went wrong')).toBeInTheDocument();
    expect(screen.getByText('An unexpected error occurred')).toBeInTheDocument();
  });
});
