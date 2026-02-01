import { render, screen } from '@testing-library/react';
import { RoleGate } from '@cobalt/ui';

describe('RoleGate', () => {
  it('renders children for allowed role', () => {
    render(
      <RoleGate allowedRoles={['ADMIN', 'MANAGER']} userRole="ADMIN">
        <div>Secret Content</div>
      </RoleGate>
    );
    expect(screen.getByText('Secret Content')).toBeInTheDocument();
  });

  it('hides children for disallowed role', () => {
    render(
      <RoleGate allowedRoles={['ADMIN']} userRole="TECHNICIAN">
        <div>Secret Content</div>
      </RoleGate>
    );
    expect(screen.queryByText('Secret Content')).not.toBeInTheDocument();
  });
});
