-- ===========================================
-- Violations Service — Initial Schema
-- ===========================================

CREATE TABLE violations.dob_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    isn_dob_bis_viol VARCHAR(100) UNIQUE,
    boro VARCHAR(50),
    bin VARCHAR(20),
    block VARCHAR(20),
    lot VARCHAR(20),
    issue_date DATE,
    violation_type_code VARCHAR(20),
    violation_number VARCHAR(50),
    house_number VARCHAR(50),
    street VARCHAR(255),
    disposition_date DATE,
    disposition_comments TEXT,
    device_number VARCHAR(50),
    description TEXT,
    ecb_number VARCHAR(50),
    number VARCHAR(50),
    violation_category VARCHAR(100),
    violation_type VARCHAR(100),
    raw_data JSONB,
    synced_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_violations_tenant
    ON violations.dob_violations(tenant_id);
CREATE INDEX idx_violations_bin
    ON violations.dob_violations(bin);
CREATE INDEX idx_violations_boro
    ON violations.dob_violations(boro);
CREATE INDEX idx_violations_issue_date
    ON violations.dob_violations(issue_date);
CREATE INDEX idx_violations_type
    ON violations.dob_violations(violation_type);

CREATE TABLE violations.sync_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    last_sync_at TIMESTAMP,
    records_processed INTEGER DEFAULT 0,
    records_inserted INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'IDLE',
    error_message TEXT,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE violations.watches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    filter_type VARCHAR(50) NOT NULL,
    filter_value VARCHAR(255) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_watches_tenant
    ON violations.watches(tenant_id);

CREATE TABLE violations.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    watch_id UUID NOT NULL REFERENCES violations.watches(id),
    violation_id UUID NOT NULL
        REFERENCES violations.dob_violations(id),
    read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_tenant
    ON violations.alerts(tenant_id);
CREATE INDEX idx_alerts_unread
    ON violations.alerts(tenant_id, read)
    WHERE read = false;
