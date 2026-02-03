import { useState } from 'react';
import { Card, Button, HTMLTable, Tag, InputGroup, HTMLSelect, Icon } from '@blueprintjs/core';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { incidentsApi } from '../api';

export function IncidentsPage() {
  const navigate = useNavigate();
  const [statusFilter, setStatusFilter] = useState('');
  const [severityFilter, setSeverityFilter] = useState('');

  const { data: incidents, isLoading } = useQuery({
    queryKey: ['incidents', { status: statusFilter, severity: severityFilter }],
    queryFn: () =>
      incidentsApi.getIncidents({
        status: statusFilter || undefined,
        severity: severityFilter || undefined,
        size: 50,
      }),
  });

  const severityIntent = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'danger';
      case 'high':
        return 'warning';
      case 'medium':
        return 'primary';
      default:
        return 'none';
    }
  };

  const statusIcon = (status: string) => {
    switch (status) {
      case 'resolved':
        return 'tick-circle';
      case 'triggered':
        return 'error';
      case 'acknowledged':
        return 'eye-open';
      case 'investigating':
        return 'search';
      default:
        return 'time';
    }
  };

  return (
    <div>
      <div className="page-header">
        <h1>Incidents</h1>
        <Button intent="primary" icon="plus" text="Create Incident" />
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 24 }}>
        <InputGroup
          leftIcon="search"
          placeholder="Search incidents..."
          style={{ width: 300 }}
        />
        <HTMLSelect
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">All Statuses</option>
          <option value="triggered">Triggered</option>
          <option value="acknowledged">Acknowledged</option>
          <option value="investigating">Investigating</option>
          <option value="identified">Identified</option>
          <option value="monitoring">Monitoring</option>
          <option value="resolved">Resolved</option>
        </HTMLSelect>
        <HTMLSelect
          value={severityFilter}
          onChange={(e) => setSeverityFilter(e.target.value)}
        >
          <option value="">All Severities</option>
          <option value="critical">Critical</option>
          <option value="high">High</option>
          <option value="medium">Medium</option>
          <option value="low">Low</option>
        </HTMLSelect>
      </div>

      <Card style={{ padding: 0 }}>
        {isLoading ? (
          <div style={{ textAlign: 'center', padding: 48, color: '#a7b6c2' }}>
            Loading incidents...
          </div>
        ) : (
          <HTMLTable bordered condensed interactive style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Title</th>
                <th>Severity</th>
                <th>Status</th>
                <th>Source</th>
                <th>Assignee</th>
                <th>Created</th>
                <th>Duration</th>
              </tr>
            </thead>
            <tbody>
              {(incidents?.data || []).map((incident) => (
                <tr
                  key={incident.id}
                  onClick={() => navigate(`/incidents/${incident.id}`)}
                  style={{ cursor: 'pointer' }}
                >
                  <td>
                    <strong>{incident.title}</strong>
                  </td>
                  <td>
                    <Tag intent={severityIntent(incident.severity)}>
                      {incident.severity.toUpperCase()}
                    </Tag>
                  </td>
                  <td>
                    <Tag minimal>
                      <Icon
                        icon={statusIcon(incident.status) as never}
                        size={12}
                        style={{ marginRight: 4 }}
                      />
                      {incident.status}
                    </Tag>
                  </td>
                  <td>{incident.sourceType}</td>
                  <td>{incident.assignee || '-'}</td>
                  <td>{new Date(incident.createdAt).toLocaleString()}</td>
                  <td>
                    {incident.resolvedAt
                      ? `${Math.round(
                          (new Date(incident.resolvedAt).getTime() -
                            new Date(incident.createdAt).getTime()) /
                            60000
                        )} min`
                      : '-'}
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
