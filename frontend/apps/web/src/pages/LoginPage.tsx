import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Card, FormGroup, InputGroup, Button, Callout, H2 } from '@blueprintjs/core';
import { useLogin } from '../hooks/useLogin';

export function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();
  const login = useLogin();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login.mutate({ email, password }, { onSuccess: () => navigate('/dashboard') });
  };

  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        height: '100vh',
        background: 'var(--bp5-dark-app-background-color)',
      }}
    >
      <Card elevation={2} style={{ width: 400, padding: 32 }}>
        <H2>Sign In</H2>
        <p className="bp5-text-muted">Cobalt Platform</p>
        {login.isError && (
          <Callout intent="danger" style={{ marginBottom: 16 }}>
            Invalid email or password.
          </Callout>
        )}
        <form onSubmit={handleSubmit}>
          <FormGroup label="Email" labelFor="email">
            <InputGroup
              id="email"
              type="email"
              placeholder="you@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </FormGroup>
          <FormGroup label="Password" labelFor="password">
            <InputGroup
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </FormGroup>
          <Button type="submit" intent="primary" fill loading={login.isPending} text="Sign In" />
        </form>
        <p style={{ marginTop: 16, textAlign: 'center' }}>
          Don&apos;t have an account? <Link to="/register">Register</Link>
        </p>
      </Card>
    </div>
  );
}
