import { useState } from 'react';
import { Card, HTMLTable, Tag, InputGroup, HTMLSelect, Icon } from '@blueprintjs/core';

// Mock audit data - would come from API
const mockAuditLogs = [
  {
    id: '1',
    actor: 'john@example.com',
    actorType: 'user',
    action: 'deployment.triggered',
    resourceType: 'deployment',
    resourceId: 'dep-123',
    details: { service: 'payment-service', environment: 'production' },
    ipAddress: '192.168.1.100',
    createdAt: '2025-01-30T14:32:00Z',
  },
  {
    id: '2',
    actor: 'ai-session-abc123',
    actorType: 'ai',
    action: 'runbook.executed',
    resourceType: 'runbook',
    resourceId: 'rb-456',
    details: { runbook: 'Scale Up Workers', approved_by: 'john@example.com' },
    ipAddress: '10.0.0.1',
    createdAt: '2025-01-30T14:28:00Z',
  },
  {
    id: '3',
    actor: 'system',
    actorType: 'system',
    action: 'incident.created',
    resourceType: 'incident',
    resourceId: 'inc-789',
    details: { source: 'pagerduty', severity: 'critical' },
    ipAddress: '',
    createdAt: '2025-01-30T14:15:00Z',
  },
  {
    id: '4',
    actor: 'jane@example.com',
    actorType: 'user',
    action: 'service.updated',
    resourceType: 'service',
    resourceId: 'svc-abc',
    details: { changes: ['description', 'tier'] },
    ipAddress: '192.168.1.105',
    createdAt: '2025-01-30T13:45:00Z',
  },
  {
    id: '5',
    actor: 'ai-session-def456',
    actorType: 'ai',
    action: 'kubectl.exec',
    resourceType: 'cluster',
    resourceId: 'prod-east-1',
    details: { command: 'kubectl get pods -n payments', approved_by: 'john@example.com' },
    ipAddress: '10.0.0.1',
    createdAt: '2025-01-30T13:30:00Z',
  },
];

export function AuditLogPage() {
  const [actorTypeFilter, setActorTypeFilter] = useState('');
  const [search, setSearch] = useState('');

  const filteredLogs = mockAuditLogs.filter((log) => {
    if (actorTypeFilter && log.actorType !== actorTypeFilter) return false;
    if (search) {
      const searchLower = search.toLowerCase();
      return (
        log.actor.toLowerCase().includes(searchLower) ||
        log.action.toLowerCase().includes(searchLower) ||
        log.resourceType.toLowerCase().includes(searchLower)
      );
    }
    return true;
  });

  const actorIcon = (type: string) => {
    switch (type) {
      case 'user':
        return 'person';
      case 'ai':
        return 'chat';
      case 'system':
        return 'cog';
      default:
        return 'help';
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>Audit Log</h1>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 24 }}>
        <InputGroup
          leftIcon="search"
          placeholder="Search by actor, action, or resource..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{ width: 400 }}
        />
        <HTMLSelect
          value={actorTypeFilter}
          onChange={(e) => setActorTypeFilter(e.target.value)}
        >
          <option value="">All Actor Types</option>
          <option value="user">User</option>
          <option value="ai">AI</option>
          <option value="system">System</option>
        </HTMLSelect>
      </div>

      <Card style={{ padding: 0 }}>
        <HTMLTable bordered condensed style={{ width: '100%' }}>
          <thead>
            <tr>
              <th>Timestamp</th>
              <th>Actor</th>
              <th>Action</th>
              <th>Resource</th>
              <th>Details</th>
              <th>IP Address</th>
            </tr>
          </thead>
          <tbody>
            {filteredLogs.map((log) => (
              <tr key={log.id}>
                <td style={{ whiteSpace: 'nowrap' }}>
                  {new Date(log.createdAt).toLocaleString()}
                </td>
                <td>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <Icon icon={actorIcon(log.actorType) as never} size={14} />
                    <span>{log.actor}</span>
                    <Tag minimal small>
                      {log.actorType}
                    </Tag>
                  </div>
                </td>
                <td>
                  <code style={{ fontSize: 12 }}>{log.action}</code>
                </td>
                <td>
                  <Tag minimal>
                    {log.resourceType}:{log.resourceId}
                  </Tag>
                </td>
                <td style={{ maxWidth: 300 }}>
                  <code
                    style={{
                      fontSize: 11,
                      color: '#a7b6c2',
                      display: 'block',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                    title={JSON.stringify(log.details)}
                  >
                    {JSON.stringify(log.details)}
                  </code>
                </td>
                <td>
                  <code style={{ fontSize: 11, color: '#a7b6c2' }}>
                    {log.ipAddress || '-'}
                  </code>
                </td>
              </tr>
            ))}
          </tbody>
        </HTMLTable>
      </Card>
    </div>
  );
}
