-- ===========================================
-- Notification Service — Initial Schema
-- ===========================================

CREATE TABLE notification.templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    subject VARCHAR(500),
    body TEXT NOT NULL,
    variables JSONB,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_templates_tenant
    ON notification.templates(tenant_id);

CREATE TABLE notification.logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    template_id UUID REFERENCES notification.templates(id),
    recipient VARCHAR(255) NOT NULL,
    channel VARCHAR(20) NOT NULL,
    subject VARCHAR(500),
    body TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    error_message TEXT,
    sent_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_logs_tenant
    ON notification.logs(tenant_id);
CREATE INDEX idx_notification_logs_status
    ON notification.logs(tenant_id, status);

CREATE TABLE notification.preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    channel VARCHAR(20) NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, user_id, channel, notification_type)
);

CREATE INDEX idx_notification_prefs_tenant
    ON notification.preferences(tenant_id);
