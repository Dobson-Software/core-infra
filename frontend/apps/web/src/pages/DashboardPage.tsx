import { Card, H3, H1, Tag, type Intent } from '@blueprintjs/core';
import { RoleGate } from '@cobalt/ui';
import { useAuth } from '../auth/AuthProvider';

export function DashboardPage() {
  const { user } = useAuth();

  if (!user) {
    return null;
  }

  return (
    <div>
      <H1>Welcome, {user.firstName}!</H1>
      <p className="bp5-text-muted">Here is your business overview.</p>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
          gap: 16,
          marginTop: 24,
        }}
      >
        <MetricCard title="Jobs Today" value="0" intent="primary" />
        <MetricCard title="Open Estimates" value="0" intent="warning" />
        <MetricCard title="Pending Invoices" value="0" intent="danger" />
        <MetricCard title="Active Violations" value="0" intent="none" />
        <RoleGate allowedRoles={['ADMIN', 'MANAGER']} userRole={user.role}>
          <MetricCard title="Revenue (MTD)" value="$0.00" intent="success" />
        </RoleGate>
      </div>
    </div>
  );
}

function MetricCard({ title, value, intent }: { title: string; value: string; intent: Intent }) {
  return (
    <Card>
      <p className="bp5-text-muted" style={{ marginBottom: 4 }}>
        {title}
      </p>
      <H3 style={{ marginBottom: 0 }}>{value}</H3>
      <Tag minimal intent={intent} style={{ marginTop: 8 }}>
        {title}
      </Tag>
    </Card>
  );
}
