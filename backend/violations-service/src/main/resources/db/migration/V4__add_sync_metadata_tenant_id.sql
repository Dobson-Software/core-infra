ALTER TABLE violations.sync_metadata ADD COLUMN tenant_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE violations.sync_metadata ALTER COLUMN tenant_id DROP DEFAULT;
CREATE INDEX idx_sync_metadata_tenant ON violations.sync_metadata(tenant_id);
