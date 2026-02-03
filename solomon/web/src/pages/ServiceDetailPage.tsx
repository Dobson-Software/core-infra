import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Card,
  Tabs,
  Tab,
  Button,
  Tag,
  HTMLTable,
  Spinner,
  Breadcrumbs,
  Icon,
} from '@blueprintjs/core';
import { servicesApi, deploymentsApi } from '../api';

export function ServiceDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const { data: service, isLoading: serviceLoading } = useQuery({
    queryKey: ['services', id],
    queryFn: () => servicesApi.getService(id!),
    enabled: !!id,
  });

  const { data: environments } = useQuery({
    queryKey: ['services', id, 'environments'],
    queryFn: () => servicesApi.getEnvironments(id!),
    enabled: !!id,
  });

  const { data: runbooks } = useQuery({
    queryKey: ['services', id, 'runbooks'],
    queryFn: () => servicesApi.getRunbooks(id!),
    enabled: !!id,
  });

  const { data: deployments } = useQuery({
    queryKey: ['deployments', { serviceId: id }],
    queryFn: () => deploymentsApi.getDeployments({ serviceId: id, size: 10 }),
    enabled: !!id,
  });

  if (serviceLoading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', padding: 100 }}>
        <Spinner size={50} />
      </div>
    );
  }

  const svc = service?.data;

  return (
    <div>
      <Breadcrumbs
        items={[
          { text: 'Services', onClick: () => navigate('/services') },
          { text: svc?.displayName || 'Service' },
        ]}
        style={{ marginBottom: 16 }}
      />

      <div className="page-header">
        <div>
          <h1 style={{ marginBottom: 4 }}>{svc?.displayName}</h1>
          <code style={{ color: '#a7b6c2' }}>{svc?.name}</code>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Button icon="play" text="Deploy" intent="primary" />
          <Button icon="edit" text="Edit" />
        </div>
      </div>

      <div style={{ display: 'flex', gap: 16, marginBottom: 24 }}>
        <Tag intent="primary" large>
          {svc?.tier}
        </Tag>
        <Tag minimal large>
          <Icon icon="code" size={12} style={{ marginRight: 4 }} />
          {svc?.language}
        </Tag>
        <Tag minimal large>
          <Icon icon="cube" size={12} style={{ marginRight: 4 }} />
          {svc?.framework}
        </Tag>
        <Tag minimal large>
          <Icon icon="people" size={12} style={{ marginRight: 4 }} />
          {svc?.team}
        </Tag>
      </div>

      <Tabs id="service-tabs" large>
        <Tab
          id="overview"
          title="Overview"
          panel={
            <div style={{ paddingTop: 16 }}>
              <Card style={{ marginBottom: 24 }}>
                <h3 style={{ margin: '0 0 12px' }}>Description</h3>
                <p style={{ color: '#a7b6c2', margin: 0, lineHeight: 1.6 }}>
                  {svc?.description || 'No description provided.'}
                </p>
              </Card>

              {svc?.repository && (
                <Card>
                  <h3 style={{ margin: '0 0 12px' }}>Repository</h3>
                  <a
                    href={svc.repository}
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ color: '#6366f1' }}
                  >
                    <Icon icon="git-branch" style={{ marginRight: 8 }} />
                    {svc.repository}
                  </a>
                </Card>
              )}
            </div>
          }
        />

        <Tab
          id="environments"
          title={`Environments (${environments?.data?.length || 0})`}
          panel={
            <div style={{ paddingTop: 16 }}>
              <HTMLTable bordered condensed style={{ width: '100%' }}>
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Cluster</th>
                    <th>Namespace</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {(environments?.data || []).map((env) => (
                    <tr key={env.id}>
                      <td>
                        <strong>{env.name}</strong>
                      </td>
                      <td>{env.cluster}</td>
                      <td>
                        <code>{env.namespace}</code>
                      </td>
                      <td>
                        <Button small minimal icon="play" text="Deploy" />
                        <Button small minimal icon="console" text="Logs" />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </HTMLTable>
            </div>
          }
        />

        <Tab
          id="deployments"
          title="Deployments"
          panel={
            <div style={{ paddingTop: 16 }}>
              <HTMLTable bordered condensed style={{ width: '100%' }}>
                <thead>
                  <tr>
                    <th>Image Tag</th>
                    <th>Environment</th>
                    <th>Status</th>
                    <th>Initiated By</th>
                    <th>Started</th>
                  </tr>
                </thead>
                <tbody>
                  {(deployments?.data || []).map((dep) => (
                    <tr key={dep.id}>
                      <td>
                        <code>{dep.imageTag}</code>
                      </td>
                      <td>{dep.environmentId}</td>
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
                      <td>{dep.initiatedBy}</td>
                      <td>{new Date(dep.startedAt).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </HTMLTable>
            </div>
          }
        />

        <Tab
          id="runbooks"
          title={`Runbooks (${runbooks?.data?.length || 0})`}
          panel={
            <div style={{ paddingTop: 16 }}>
              <div className="card-grid">
                {(runbooks?.data || []).map((runbook) => (
                  <Card key={runbook.id} style={{ padding: 16 }}>
                    <h4 style={{ margin: '0 0 8px' }}>{runbook.title}</h4>
                    <p style={{ color: '#a7b6c2', fontSize: 13, margin: '0 0 12px' }}>
                      Trigger: {runbook.trigger || 'Manual'}
                    </p>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <Button small text="View" />
                      {runbook.automatable && (
                        <Button small intent="primary" icon="play" text="Run with AI" />
                      )}
                    </div>
                  </Card>
                ))}
              </div>
            </div>
          }
        />
      </Tabs>
    </div>
  );
}
