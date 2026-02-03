import { useState } from 'react';
import { Card, Button, HTMLTable, Tag, InputGroup, HTMLSelect, Icon } from '@blueprintjs/core';
import { useQuery } from '@tanstack/react-query';
import { deploymentsApi } from '../api';

export function DeploymentsPage() {
  const [statusFilter, setStatusFilter] = useState('');

  const { data: deployments, isLoading } = useQuery({
    queryKey: ['deployments', { status: statusFilter }],
    queryFn: () =>
      deploymentsApi.getDeployments({
        status: statusFilter || undefined,
        size: 50,
      }),
  });

  const statusIntent = (status: string) => {
    switch (status) {
      case 'succeeded':
        return 'success';
      case 'failed':
        return 'danger';
      case 'rolled_back':
        return 'warning';
      case 'in_progress':
      case 'pending':
        return 'primary';
      default:
        return 'none';
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>Deployments</h1>
        <Button intent="primary" icon="cloud-upload" text="New Deployment" />
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 24 }}>
        <InputGroup
          leftIcon="search"
          placeholder="Search by service or tag..."
          style={{ width: 300 }}
        />
        <HTMLSelect
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="in_progress">In Progress</option>
          <option value="succeeded">Succeeded</option>
          <option value="failed">Failed</option>
          <option value="rolled_back">Rolled Back</option>
        </HTMLSelect>
      </div>

      <Card style={{ padding: 0 }}>
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: 48, color: '#a7b6c2' }}>
            Loading deployments...
          </div>
        ) : (
          <HTMLTable bordered condensed style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Service</th>
                <th>Image Tag</th>
                <th>Environment</th>
                <th>Status</th>
                <th>Initiated By</th>
                <th>Via</th>
                <th>Started</th>
                <th>Duration</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {(deployments?.data || []).map((dep) => (
                <tr key={dep.id}>
                  <td>{dep.serviceId}</td>
                  <td>
                    <code>{dep.imageTag}</code>
                  </td>
                  <td>{dep.environmentId}</td>
                  <td>
                    <Tag intent={statusIntent(dep.status)} minimal>
                      {dep.status}
                    </Tag>
                  </td>
                  <td>{dep.initiatedBy}</td>
                  <td>
                    <Tag minimal>
                      <Icon
                        icon={
                          dep.initiatedVia === 'ai'
                            ? 'chat'
                            : dep.initiatedVia === 'gitops'
                            ? 'git-branch'
                            : 'person'
                        }
                        size={12}
                        style={{ marginRight: 4 }}
                      />
                      {dep.initiatedVia}
                    </Tag>
                  </td>
                  <td>{new Date(dep.startedAt).toLocaleString()}</td>
                  <td>
                    {dep.completedAt
                      ? `${Math.round(
                          (new Date(dep.completedAt).getTime() -
                            new Date(dep.startedAt).getTime()) /
                            1000
                        )}s`
                      : '-'}
                  </td>
                  <td>
                    <Button small minimal icon="console" text="Logs" />
                    {dep.status === 'succeeded' && (
                      <Button small minimal icon="undo" text="Rollback" />
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </HTMLTable>
        )}
      </Card>
    </div>
  );
}
