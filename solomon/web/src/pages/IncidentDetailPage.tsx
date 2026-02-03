import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Card,
  Button,
  Tag,
  Spinner,
  Breadcrumbs,
  Icon,
  TextArea,
  Callout,
} from '@blueprintjs/core';
import { useState } from 'react';
import { incidentsApi } from '../api';

export function IncidentDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [newNote, setNewNote] = useState('');

  const { data: incident, isLoading } = useQuery({
    queryKey: ['incidents', id],
    queryFn: () => incidentsApi.getIncident(id!),
    enabled: !!id,
  });

  const { data: timeline } = useQuery({
    queryKey: ['incidents', id, 'timeline'],
    queryFn: () => incidentsApi.getTimeline(id!),
    enabled: !!id,
  });

  const { data: suggestedRunbooks } = useQuery({
    queryKey: ['incidents', id, 'runbooks'],
    queryFn: () => incidentsApi.getSuggestedRunbooks(id!),
    enabled: !!id,
  });

  const acknowledgeMutation = useMutation({
    mutationFn: () => incidentsApi.acknowledgeIncident(id!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incidents', id] });
    },
  });

  const addNoteMutation = useMutation({
    mutationFn: (content: string) =>
      incidentsApi.addTimelineEvent(id!, { eventType: 'note', content }),
    onSuccess: () => {
      setNewNote('');
      queryClient.invalidateQueries({ queryKey: ['incidents', id, 'timeline'] });
    },
  });

  if (isLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spinner size={50} />
      </div>
    );
  }

  const inc = incident?.data;

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

  return (
    <div>
      <Breadcrumbs
        items={[
          { text: 'Incidents', onClick: () => navigate('/incidents') },
          { text: inc?.title || 'Incident' },
        ]}
        style={{ marginBottom: 16 }}
      />

      <div className="page-header">
        <div>
          <h1>{inc?.title}</h1>
          <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
            <Tag intent={severityIntent(inc?.severity || '')} large>
              {inc?.severity?.toUpperCase()}
            </Tag>
            <Tag minimal large>
              {inc?.status}
            </Tag>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {inc?.status === 'triggered' && (
            <Button
              intent="warning"
              icon="eye-open"
              text="Acknowledge"
              onClick={() => acknowledgeMutation.mutate()}
              loading={acknowledgeMutation.isPending}
            />
          )}
          {inc?.status !== 'resolved' && (
            <Button intent="success" icon="tick" text="Resolve" />
          )}
          <Button icon="chat" text="Start AI Debug Session" intent="primary" />
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 24 }}>
        {/* Main content */}
        <div>
          <Card style={{ marginBottom: 24 }}>
            <h3 style={{ margin: '0 0 12px' }}>Description</h3>
            <p style={{ color: '#a7b6c2', margin: 0, lineHeight: 1.6 }}>
              {inc?.description || 'No description provided.'}
            </p>
          </Card>

          {/* Timeline */}
          <Card>
            <h3 style={{ margin: '0 0 16px' }}>Timeline</h3>

            <div style={{ marginBottom: 16 }}>
              <TextArea
                fill
                placeholder="Add a note..."
                value={newNote}
                onChange={(e) => setNewNote(e.target.value)}
                style={{ marginBottom: 8 }}
              />
              <Button
                small
                text="Add Note"
                onClick={() => addNoteMutation.mutate(newNote)}
                disabled={!newNote.trim()}
                loading={addNoteMutation.isPending}
              />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {(timeline?.data || []).map((event) => (
                <div
                  key={event.id}
                  style={{
                    display: 'flex',
                    gap: 12,
                    paddingLeft: 12,
                    borderLeft: '2px solid #383e47',
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        marginBottom: 4,
                      }}
                    >
                      <strong>{event.actor}</strong>
                      <span style={{ color: '#a7b6c2', fontSize: 12 }}>
                        {new Date(event.createdAt).toLocaleString()}
                      </span>
                    </div>
                    <Tag minimal small style={{ marginBottom: 4 }}>
                      {event.eventType}
                    </Tag>
                    <p style={{ margin: 0, color: '#a7b6c2' }}>{event.content}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Sidebar */}
        <div>
          <Card style={{ marginBottom: 16 }}>
            <h4 style={{ margin: '0 0 12px' }}>Details</h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <div>
                <span style={{ color: '#a7b6c2' }}>Source:</span>{' '}
                {inc?.sourceType}
              </div>
              <div>
                <span style={{ color: '#a7b6c2' }}>Assignee:</span>{' '}
                {inc?.assignee || 'Unassigned'}
              </div>
              <div>
                <span style={{ color: '#a7b6c2' }}>Created:</span>{' '}
                {inc?.createdAt && new Date(inc.createdAt).toLocaleString()}
              </div>
              {inc?.acknowledgedAt && (
                <div>
                  <span style={{ color: '#a7b6c2' }}>Acknowledged:</span>{' '}
                  {new Date(inc.acknowledgedAt).toLocaleString()}
                </div>
              )}
              {inc?.resolvedAt && (
                <div>
                  <span style={{ color: '#a7b6c2' }}>Resolved:</span>{' '}
                  {new Date(inc.resolvedAt).toLocaleString()}
                </div>
              )}
            </div>
          </Card>

          <Card style={{ marginBottom: 16 }}>
            <h4 style={{ margin: '0 0 12px' }}>Affected Services</h4>
            {(inc?.affectedServices || []).length === 0 ? (
              <span style={{ color: '#a7b6c2' }}>None specified</span>
            ) : (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                {inc?.affectedServices.map((svc) => (
                  <Tag key={svc} minimal>
                    {svc}
                  </Tag>
                ))}
              </div>
            )}
          </Card>

          {(suggestedRunbooks?.data || []).length > 0 && (
            <Callout intent="primary" icon="lightbulb" title="Suggested Runbooks">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {suggestedRunbooks?.data.map((runbook, i) => (
                  <Button
                    key={i}
                    small
                    minimal
                    icon={<Icon icon="document" />}
                    text={runbook}
                  />
                ))}
              </div>
            </Callout>
          )}
        </div>
      </div>
    </div>
  );
}
