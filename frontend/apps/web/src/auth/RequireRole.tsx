import { NonIdealState } from '@blueprintjs/core';
import type { UserRole } from '@cobalt/api-client';
import { useAuth } from './AuthProvider';

interface RequireRoleProps {
  allowedRoles: UserRole[];
  children: React.ReactNode;
}

export function RequireRole({ allowedRoles, children }: RequireRoleProps) {
  const { user } = useAuth();

  if (!user || !allowedRoles.includes(user.role)) {
    return (
      <NonIdealState
        icon="lock"
        title="Access Denied"
        description="You do not have permission to view this page."
      />
    );
  }

  return <>{children}</>;
}
