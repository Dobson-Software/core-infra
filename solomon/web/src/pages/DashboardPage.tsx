import { Card, Tag, Icon, Spinner, HTMLTable } from '@blueprintjs/core';
import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '../api';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['dashboard', 'stats'],
    queryFn: () => dashboardApi.getStats(),
  });

  const { data: recentDeployments } = useQuery({
    queryKey: ['dashboard', 'recent-deployments'],
    queryFn: () => dashboardApi.getRecentDeployments(5),
  });

  const { data: activeIncidents } = useQuery({
    queryKey: ['dashboard', 'active-incidents'],
    queryFn: () => dashboardApi.getActiveIncidents(),
  });

  const { data: serviceHealth } = useQuery({
    queryKey: ['dashboard', 'service-health'],
    queryFn: () => dashboardApi.getServiceHealth(),
  });

  if (statsLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spinner size={50} />
      </div>
    );
  }

  const dashboardStats = stats?.data;

  return (
    <div>
      <div className="page-header">
        <h1>Dashboard</h1>
      </div>

      {/* Stats Cards */}
      <div className="card-grid" style={{ marginBottom: 24 }}>
        <Card className="stat-card">
          <div className="stat-value">{dashboardStats?.totalServices || 0}</div>
          <div className="stat-label">Total Services</div>
          <Tag intent="success" minimal style={{ marginTop: 8 }}>
            {dashboardStats?.healthyServices || 0} healthy
          </Tag>
        </Card>

        <Card className="stat-card">
          <div className="stat-value">{dashboardStats?.activeDeployments || 0}</div>
          <div className="stat-label">Active Deployments</div>
          <Tag intent="primary" minimal style={{ marginTop: 8 }}>
            {((dashboardStats?.deploymentSuccessRate || 0) * 100).toFixed(0)}% success rate
          </Tag>
        </Card>

        <Card className="stat-card">
          <div className="stat-value">{dashboardStats?.openIncidents || 0}</div>
          <div className="stat-label">Open Incidents</div>
          <Tag intent="warning" minimal style={{ marginTop: 8 }}>
            MTTR: {dashboardStats?.mttr || 0}m
          </Tag>
        </Card>

        <Card className="stat-card">
          <div className="stat-value">
            ${((dashboardStats?.monthlySpend || 0) / 1000).toFixed(1)}k
          </div>
          <div className="stat-label">Monthly Spend</div>
          <Tag
            intent={
              (dashboardStats?.monthlySpendChange || 0) > 0 ? 'danger' : 'success'
            }
            minimal
            style={{ marginTop: 8 }}
          >
            {(dashboardStats?.monthlySpendChange || 0) > 0 ? '+' : ''}
            {((dashboardStats?.monthlySpendChange || 0) * 100).toFixed(1)}%
          </Tag>
        </Card>
      </div>

      {/* Charts and Tables */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 24 }}>
        {/* Cost Trend Chart */}
        <Card>
          <h3 style={{ margin: '0 0 16px' }}>Cost Trend (30 Days)</h3>
          <div style={{ height: 250 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart
                data={[
                  { date: 'Jan 1', cost: 1200 },
                  { date: 'Jan 8', cost: 1350 },
                  { date: 'Jan 15', cost: 1100 },
                  { date: 'Jan 22', cost: 1400 },
                  { date: 'Jan 29', cost: 1250 },
                ]}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#383e47" />
                <XAxis dataKey="date" stroke="#a7b6c2" />
                <YAxis stroke="#a7b6c2" />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#252a31',
                    border: '1px solid #383e47',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="cost"
                  stroke="#6366f1"
                  strokeWidth={2}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Service Health */}
        <Card>
          <h3 style={{ margin: '0 0 16px' }}>Service Health</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {(serviceHealth?.data || []).slice(0, 6).map((service) => (
              <div
                key={service.serviceId}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  padding: '8px 0',
                  borderBottom: '1px solid #383e47',
                }}
              >
                <span>{service.serviceName}</span>
                <span className={`status-badge ${service.status}`}>
                  <Icon
                    icon={
                      service.status === 'healthy'
                        ? 'tick-circle'
                        : service.status === 'degraded'
                        ? 'warning-sign'
                        : 'error'
                    }
                    size={12}
                  />
                  {service.status}
                </span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Recent Deployments & Active Incidents */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 24,
          marginTop: 24,
        }}
      >
        <Card>
          <h3 style={{ margin: '0 0 16px' }}>Recent Deployments</h3>
          <HTMLTable condensed style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Service</th>
                <th>Environment</th>
                <th>Status</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              {(recentDeployments?.data || []).map((dep) => (
                <tr key={dep.id}>
                  <td>{dep.serviceName}</td>
                  <td>{dep.environment}</td>
                  <td>
                    <Tag
                      intent={
                        dep.status === 'succeeded'
                          ? 'success'
                          : dep.status === 'failed'
                          ? 'danger'
                          : 'primary'
                      }
                      minimal
                    >
                      {dep.status}
                    </Tag>
                  </td>
                  <td style={{ color: '#a7b6c2' }}>
                    {new Date(dep.startedAt).toLocaleTimeString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </HTMLTable>
        </Card>

        <Card>
          <h3 style={{ margin: '0 0 16px' }}>Active Incidents</h3>
          {(activeIncidents?.data || []).length === 0 ? (
            <div
              style={{
                textAlign: 'center',
                padding: 32,
                color: '#a7b6c2',
              }}
            >
              <Icon icon="tick-circle" size={32} style={{ marginBottom: 8 }} />
              <div>No active incidents</div>
            </div>
          ) : (
            <HTMLTable condensed style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Severity</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {(activeIncidents?.data || []).map((incident) => (
                  <tr key={incident.id}>
                    <td>{incident.title}</td>
                    <td>
                      <Tag
                        intent={
                          incident.severity === 'critical'
                            ? 'danger'
                            : incident.severity === 'high'
                            ? 'warning'
                            : 'none'
                        }
                        minimal
                      >
                        {incident.severity}
                      </Tag>
                    </td>
                    <td>{incident.status}</td>
                  </tr>
                ))}
              </tbody>
            </HTMLTable>
          )}
        </Card>
      </div>
    </div>
  );
}
