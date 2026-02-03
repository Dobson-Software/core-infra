import { Card, FormGroup, InputGroup, Switch, Button, Tabs, Tab, Callout, Tag } from '@blueprintjs/core';

export function SettingsPage() {
  return (
    <div>
      <div className="page-header">
        <h1>Settings</h1>
      </div>

      <Tabs id="settings-tabs" large>
        <Tab
          id="integrations"
          title="Integrations"
          panel={
            <div style={{ paddingTop: 16, maxWidth: 800 }}>
              {/* ArgoCD */}
              <Card style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h4 style={{ margin: '0 0 4px' }}>ArgoCD</h4>
                    <p style={{ color: '#a7b6c2', margin: 0, fontSize: 14 }}>
                      GitOps deployment synchronization
                    </p>
                  </div>
                  <Tag intent="success">Connected</Tag>
                </div>
                <div style={{ marginTop: 16 }}>
                  <FormGroup label="Server URL">
                    <InputGroup
                      defaultValue="https://argocd.example.com"
                      readOnly
                    />
                  </FormGroup>
                </div>
              </Card>

              {/* PagerDuty */}
              <Card style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h4 style={{ margin: '0 0 4px' }}>PagerDuty</h4>
                    <p style={{ color: '#a7b6c2', margin: 0, fontSize: 14 }}>
                      Incident management and alerting
                    </p>
                  </div>
                  <Tag intent="success">Connected</Tag>
                </div>
                <div style={{ marginTop: 16 }}>
                  <FormGroup label="Service ID">
                    <InputGroup defaultValue="P1234567" readOnly />
                  </FormGroup>
                </div>
              </Card>

              {/* AWS */}
              <Card style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h4 style={{ margin: '0 0 4px' }}>AWS</h4>
                    <p style={{ color: '#a7b6c2', margin: 0, fontSize: 14 }}>
                      Cost Explorer and infrastructure access
                    </p>
                  </div>
                  <Tag intent="success">Connected</Tag>
                </div>
                <div style={{ marginTop: 16 }}>
                  <FormGroup label="Region">
                    <InputGroup defaultValue="us-east-1" readOnly />
                  </FormGroup>
                  <FormGroup label="Cost Explorer">
                    <Switch defaultChecked label="Enabled" />
                  </FormGroup>
                </div>
              </Card>

              {/* Axiom */}
              <Card style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h4 style={{ margin: '0 0 4px' }}>Axiom</h4>
                    <p style={{ color: '#a7b6c2', margin: 0, fontSize: 14 }}>
                      Log aggregation and search
                    </p>
                  </div>
                  <Tag intent="warning">Not Configured</Tag>
                </div>
                <div style={{ marginTop: 16 }}>
                  <FormGroup label="Organization ID">
                    <InputGroup placeholder="org-xxxxx" />
                  </FormGroup>
                  <FormGroup label="API Token">
                    <InputGroup placeholder="xapt-xxxxx" type="password" />
                  </FormGroup>
                  <Button intent="primary" text="Connect" />
                </div>
              </Card>
            </div>
          }
        />

        <Tab
          id="ai"
          title="AI Configuration"
          panel={
            <div style={{ paddingTop: 16, maxWidth: 800 }}>
              <Card style={{ marginBottom: 16 }}>
                <h4 style={{ margin: '0 0 16px' }}>Claude Configuration</h4>
                <FormGroup label="Default Model">
                  <InputGroup defaultValue="claude-sonnet-4-20250514" />
                </FormGroup>
                <FormGroup label="Max Tokens">
                  <InputGroup defaultValue="4096" type="number" />
                </FormGroup>
              </Card>

              <Card style={{ marginBottom: 16 }}>
                <h4 style={{ margin: '0 0 16px' }}>Tool Permissions</h4>
                <p style={{ color: '#a7b6c2', marginBottom: 16, fontSize: 14 }}>
                  Configure which tools require human approval before execution.
                </p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <Switch defaultChecked={false} label="kubectl - Read operations (get, describe, logs)" />
                  <Switch defaultChecked label="kubectl - Write operations (apply, delete, scale)" />
                  <Switch defaultChecked label="ArgoCD - Sync applications" />
                  <Switch defaultChecked label="GitHub - Create/merge pull requests" />
                  <Switch defaultChecked label="AWS - Modify infrastructure" />
                </div>
              </Card>

              <Callout intent="primary" icon="info-sign" title="AI Safety">
                Tools marked as requiring approval will pause AI execution and wait for
                human confirmation before proceeding. This provides an additional layer of
                safety for potentially destructive operations.
              </Callout>
            </div>
          }
        />

        <Tab
          id="notifications"
          title="Notifications"
          panel={
            <div style={{ paddingTop: 16, maxWidth: 800 }}>
              <Card style={{ marginBottom: 16 }}>
                <h4 style={{ margin: '0 0 16px' }}>Slack</h4>
                <FormGroup label="Webhook URL">
                  <InputGroup placeholder="https://hooks.slack.com/services/..." type="password" />
                </FormGroup>
                <FormGroup label="Default Channel">
                  <InputGroup placeholder="#platform-alerts" />
                </FormGroup>
                <Button intent="primary" text="Test Connection" />
              </Card>

              <Card>
                <h4 style={{ margin: '0 0 16px' }}>Notification Rules</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                  <Switch defaultChecked label="Critical incidents" />
                  <Switch defaultChecked label="Deployment failures" />
                  <Switch defaultChecked label="Cost anomalies (>20% increase)" />
                  <Switch label="All deployments" />
                  <Switch label="AI session activity" />
                </div>
              </Card>
            </div>
          }
        />

        <Tab
          id="users"
          title="Users & Teams"
          panel={
            <div style={{ paddingTop: 16, maxWidth: 800 }}>
              <Callout intent="primary" icon="info-sign">
                User management is handled through your identity provider (OIDC).
                Contact your administrator to add or remove users.
              </Callout>
            </div>
          }
        />
      </Tabs>
    </div>
  );
}
