-- Email uniqueness is per-tenant, not global (multi-tenant support)
ALTER TABLE core.users ADD CONSTRAINT uq_users_tenant_email UNIQUE(tenant_id, email);
