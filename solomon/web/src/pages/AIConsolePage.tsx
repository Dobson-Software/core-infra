import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Card,
  Button,
  HTMLTable,
  Tag,
  Dialog,
  FormGroup,
  InputGroup,
  HTMLSelect,
  Icon,
} from '@blueprintjs/core';
import { aiApi } from '../api';
import { AITerminal } from '../components/AITerminal';
import { useAppStore } from '../stores/useAppStore';

export function AIConsolePage() {
  const { sessionId } = useParams<{ sessionId: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { activeSessionId, setActiveSessionId } = useAppStore();
  const [showNewDialog, setShowNewDialog] = useState(false);
  const [contextType, setContextType] = useState('');
  const [initialPrompt, setInitialPrompt] = useState('');

  const currentSessionId = sessionId || activeSessionId;

  const { data: sessions } = useQuery({
    queryKey: ['ai', 'sessions'],
    queryFn: () => aiApi.getSessions({ size: 20 }),
  });

  const { data: tools } = useQuery({
    queryKey: ['ai', 'tools'],
    queryFn: () => aiApi.getAvailableTools(),
  });

  const createSessionMutation = useMutation({
    mutationFn: () =>
      aiApi.createSession({
        contextType: contextType || undefined,
        initialPrompt: initialPrompt || undefined,
      }),
    onSuccess: (response) => {
      const newSessionId = response.data.id;
      setActiveSessionId(newSessionId);
      navigate(`/ai/${newSessionId}`);
      setShowNewDialog(false);
      queryClient.invalidateQueries({ queryKey: ['ai', 'sessions'] });
    },
  });

  const handleNewSession = () => {
    createSessionMutation.mutate();
  };

  const handleSessionEnd = () => {
    setActiveSessionId(null);
    navigate('/ai');
    queryClient.invalidateQueries({ queryKey: ['ai', 'sessions'] });
  };

  return (
    <div style={{ display: 'flex', height: 'calc(100vh - 98px)', gap: 24 }}>
      {/* Main Terminal Area */}
      <div style={{ flex: 1 }}>
        {currentSessionId ? (
          <AITerminal sessionId={currentSessionId} onSessionEnd={handleSessionEnd} />
        ) : (
          <Card
            style={{
              height: '100%',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Icon icon="chat" size={64} style={{ color: '#5c7080', marginBottom: 24 }} />
            <h2 style={{ margin: '0 0 8px' }}>AI Console</h2>
            <p style={{ color: '#a7b6c2', marginBottom: 24, textAlign: 'center' }}>
              Start a new AI session to debug issues, deploy services, or run
              automated runbooks with Claude.
            </p>
            <Button
              intent="primary"
              large
              icon="plus"
              text="New Session"
              onClick={() => setShowNewDialog(true)}
            />
          </Card>
        )}
      </div>

      {/* Sidebar */}
      <div style={{ width: 350, display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* Available Tools */}
        <Card style={{ flex: 0 }}>
          <h4 style={{ margin: '0 0 12px' }}>Available Tools</h4>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
            {(tools?.data || []).map((tool) => (
              <Tag
                key={tool.name}
                minimal
                intent={tool.requiresApproval ? 'warning' : 'none'}
                title={tool.description}
              >
                {tool.requiresApproval && (
                  <Icon icon="lock" size={10} style={{ marginRight: 4 }} />
                )}
                {tool.name}
              </Tag>
            ))}
          </div>
        </Card>

        {/* Recent Sessions */}
        <Card style={{ flex: 1, overflow: 'auto' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 12,
            }}
          >
            <h4 style={{ margin: 0 }}>Recent Sessions</h4>
            <Button
              small
              intent="primary"
              icon="plus"
              text="New"
              onClick={() => setShowNewDialog(true)}
            />
          </div>

          <HTMLTable condensed style={{ width: '100%' }}>
            <thead>
              <tr>
                <th>Session</th>
                <th>Status</th>
                <th>Started</th>
              </tr>
            </thead>
            <tbody>
              {(sessions?.data || []).map((session) => (
                <tr
                  key={session.id}
                  onClick={() => {
                    setActiveSessionId(session.id);
                    navigate(`/ai/${session.id}`);
                  }}
                  style={{
                    cursor: 'pointer',
                    backgroundColor:
                      session.id === currentSessionId
                        ? 'rgba(99, 102, 241, 0.1)'
                        : undefined,
                  }}
                >
                  <td>
                    <code style={{ fontSize: 11 }}>{session.id.slice(0, 8)}</code>
                  </td>
                  <td>
                    <Tag
                      minimal
                      intent={
                        session.status === 'active'
                          ? 'success'
                          : session.status === 'failed'
                          ? 'danger'
                          : 'none'
                      }
                    >
                      {session.status}
                    </Tag>
                  </td>
                  <td style={{ fontSize: 11, color: '#a7b6c2' }}>
                    {new Date(session.startedAt).toLocaleTimeString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </HTMLTable>
        </Card>
      </div>

      {/* New Session Dialog */}
      <Dialog
        isOpen={showNewDialog}
        onClose={() => setShowNewDialog(false)}
        title="New AI Session"
        style={{ width: 500 }}
      >
        <div style={{ padding: 20 }}>
          <FormGroup label="Context Type" labelInfo="(optional)">
            <HTMLSelect
              fill
              value={contextType}
              onChange={(e) => setContextType(e.target.value)}
            >
              <option value="">None</option>
              <option value="service">Service</option>
              <option value="incident">Incident</option>
              <option value="deployment">Deployment</option>
            </HTMLSelect>
          </FormGroup>

          <FormGroup
            label="Initial Prompt"
            labelInfo="(optional)"
            helperText="What would you like help with?"
          >
            <InputGroup
              placeholder="e.g., Debug the high latency on payment-service"
              value={initialPrompt}
              onChange={(e) => setInitialPrompt(e.target.value)}
            />
          </FormGroup>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 20 }}>
            <Button text="Cancel" onClick={() => setShowNewDialog(false)} />
            <Button
              intent="primary"
              text="Start Session"
              onClick={handleNewSession}
              loading={createSessionMutation.isPending}
            />
          </div>
        </div>
      </Dialog>
    </div>
  );
}
