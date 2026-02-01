import type { ReactNode } from 'react';
import type { UserRole } from '@cobalt/api-client';

interface RoleGateProps {
  allowedRoles: UserRole[];
  userRole: UserRole;
  children: ReactNode;
}

export function RoleGate({ allowedRoles, userRole, children }: RoleGateProps) {
  if (!allowedRoles.includes(userRole)) {
    return null;
  }
  return <>{children}</>;
}
