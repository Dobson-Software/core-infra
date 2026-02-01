import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Card, FormGroup, InputGroup, Button, Callout, H2 } from '@blueprintjs/core';
import { useRegister } from '../hooks/useRegister';

export function RegisterPage() {
  const [companyName, setCompanyName] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate();
  const register = useRegister();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    register.mutate(
      { companyName, firstName, lastName, email, password },
      { onSuccess: () => navigate('/dashboard') }
    );
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
        <H2>Create Account</H2>
        <p className="bp5-text-muted">Start managing your business with Cobalt</p>
        {register.isError && (
          <Callout intent="danger" style={{ marginBottom: 16 }}>
            Registration failed. Please try again.
          </Callout>
        )}
        <form onSubmit={handleSubmit}>
          <FormGroup label="Company Name" labelFor="companyName">
            <InputGroup
              id="companyName"
              placeholder="Your Company"
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
              required
            />
          </FormGroup>
          <FormGroup label="First Name" labelFor="firstName">
            <InputGroup
              id="firstName"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              required
            />
          </FormGroup>
          <FormGroup label="Last Name" labelFor="lastName">
            <InputGroup
              id="lastName"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              required
            />
          </FormGroup>
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
              minLength={8}
            />
          </FormGroup>
          <Button
            type="submit"
            intent="primary"
            fill
            loading={register.isPending}
            text="Create Account"
          />
        </form>
        <p style={{ marginTop: 16, textAlign: 'center' }}>
          Already have an account? <Link to="/login">Sign In</Link>
        </p>
      </Card>
    </div>
  );
}
