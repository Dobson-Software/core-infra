import { Component, type ErrorInfo, type ReactNode } from 'react';
import { NonIdealState, Button } from '@blueprintjs/core';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught:', error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <NonIdealState
          icon="error"
          title="Something went wrong"
          description={this.state.error?.message || 'An unexpected error occurred'}
          action={
            <Button intent="primary" onClick={this.handleReset}>
              Try Again
            </Button>
          }
        />
      );
    }

    return this.props.children;
  }
}
