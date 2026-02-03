-- Solomon Platform Control Plane — Initial Schema

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Service catalog
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    repository VARCHAR(500),
    team VARCHAR(100),
    tier VARCHAR(20) NOT NULL DEFAULT 'standard',
    language VARCHAR(50),
    framework VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_services_team ON services(team);
CREATE INDEX idx_services_tier ON services(tier);

CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    cluster VARCHAR(100) NOT NULL,
    namespace VARCHAR(100) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(service_id, name)
);

CREATE INDEX idx_environments_service ON environments(service_id);

CREATE TABLE dependencies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    depends_on_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL DEFAULT 'runtime',
    description TEXT,
    UNIQUE(service_id, depends_on_id)
);

CREATE TABLE runbooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    trigger VARCHAR(200),
    content TEXT NOT NULL,
    automatable BOOLEAN NOT NULL DEFAULT FALSE,
    ai_prompt TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_runbooks_service ON runbooks(service_id);

-- Deployments
CREATE TABLE deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id),
    environment_id UUID NOT NULL REFERENCES environments(id),
    image_tag VARCHAR(200) NOT NULL,
    git_commit VARCHAR(40),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    initiated_by VARCHAR(200) NOT NULL,
    initiated_via VARCHAR(50) NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_deployments_service ON deployments(service_id);
CREATE INDEX idx_deployments_env ON deployments(environment_id);
CREATE INDEX idx_deployments_status ON deployments(status);
CREATE INDEX idx_deployments_started ON deployments(started_at DESC);

-- Incidents
CREATE TABLE incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'triggered',
    source_type VARCHAR(50) NOT NULL,
    source_alert_id VARCHAR(200),
    affected_services UUID[] DEFAULT '{}',
    affected_environments VARCHAR(50)[] DEFAULT '{}',
    assignee VARCHAR(200),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP,
    postmortem JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_severity ON incidents(severity);
CREATE INDEX idx_incidents_created ON incidents(created_at DESC);

CREATE TABLE incident_timeline (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    incident_id UUID NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    actor VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_timeline_incident ON incident_timeline(incident_id);
CREATE INDEX idx_timeline_created ON incident_timeline(created_at);

-- AI Sessions
CREATE TABLE ai_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(200) NOT NULL,
    context_type VARCHAR(50),
    context_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    model VARCHAR(50) NOT NULL,
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_ai_sessions_user ON ai_sessions(user_id);
CREATE INDEX idx_ai_sessions_status ON ai_sessions(status);
CREATE INDEX idx_ai_sessions_started ON ai_sessions(started_at DESC);

CREATE TABLE ai_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES ai_sessions(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL,
    tool_name VARCHAR(100) NOT NULL,
    input JSONB NOT NULL,
    output JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by VARCHAR(200),
    approved_at TIMESTAMP,
    executed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_actions_session ON ai_actions(session_id);
CREATE INDEX idx_ai_actions_status ON ai_actions(status);

-- Audit log (append-only)
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor VARCHAR(200) NOT NULL,
    actor_type VARCHAR(20) NOT NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(200),
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_actor ON audit_log(actor);
CREATE INDEX idx_audit_resource ON audit_log(resource_type, resource_id);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- Prevent deletions from audit_log
CREATE OR REPLACE FUNCTION prevent_audit_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit log entries cannot be deleted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_no_delete
    BEFORE DELETE ON audit_log
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_delete();

-- Cost data
CREATE TABLE cost_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    environment VARCHAR(50) NOT NULL,
    service_id UUID REFERENCES services(id),
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(200),
    cost_usd DECIMAL(10, 4) NOT NULL,
    usage_quantity DECIMAL(20, 6),
    usage_unit VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    UNIQUE(date, environment, resource_type, resource_id)
);

CREATE INDEX idx_costs_date ON cost_records(date);
CREATE INDEX idx_costs_service ON cost_records(service_id);
CREATE INDEX idx_costs_env ON cost_records(environment);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER services_updated_at BEFORE UPDATE ON services
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER environments_updated_at BEFORE UPDATE ON environments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER runbooks_updated_at BEFORE UPDATE ON runbooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER incidents_updated_at BEFORE UPDATE ON incidents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
