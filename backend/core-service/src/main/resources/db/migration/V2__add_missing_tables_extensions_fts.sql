-- ===========================================
-- V2: Missing tables, extensions, full-text search
-- ===========================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Part categories and parts
CREATE TABLE core.part_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_part_categories_tenant ON core.part_categories(tenant_id);

CREATE TABLE core.parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    category_id UUID REFERENCES core.part_categories(id),
    part_number VARCHAR(100) NOT NULL,
    description TEXT,
    manufacturer VARCHAR(255),
    unit_price DECIMAL(12,2),
    unit_of_measure VARCHAR(50) DEFAULT 'EACH',
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(tenant_id, part_number)
);
CREATE INDEX idx_parts_tenant ON core.parts(tenant_id);
CREATE INDEX idx_parts_category ON core.parts(tenant_id, category_id);

-- Payments
CREATE TABLE core.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    invoice_id UUID NOT NULL REFERENCES core.invoices(id),
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    stripe_payment_id VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    paid_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_payments_tenant ON core.payments(tenant_id);
CREATE INDEX idx_payments_invoice ON core.payments(tenant_id, invoice_id);

-- Attachments
CREATE TABLE core.attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    file_size BIGINT,
    uploaded_by UUID REFERENCES core.users(id),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_attachments_tenant ON core.attachments(tenant_id);
CREATE INDEX idx_attachments_entity ON core.attachments(tenant_id, entity_type, entity_id);

-- Estimate line items
CREATE TABLE core.estimate_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    estimate_id UUID NOT NULL REFERENCES core.estimates(id) ON DELETE CASCADE,
    part_id UUID REFERENCES core.parts(id),
    description VARCHAR(500) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_estimate_items_tenant ON core.estimate_line_items(tenant_id);
CREATE INDEX idx_estimate_items_estimate ON core.estimate_line_items(estimate_id);

-- Invoice line items
CREATE TABLE core.invoice_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES core.tenants(id),
    invoice_id UUID NOT NULL REFERENCES core.invoices(id) ON DELETE CASCADE,
    part_id UUID REFERENCES core.parts(id),
    description VARCHAR(500) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_invoice_items_tenant ON core.invoice_line_items(tenant_id);
CREATE INDEX idx_invoice_items_invoice ON core.invoice_line_items(invoice_id);

-- Full-text search columns
ALTER TABLE core.customers ADD COLUMN search_vector tsvector;
ALTER TABLE core.jobs ADD COLUMN search_vector tsvector;

-- GIN indexes for full-text search
CREATE INDEX idx_customers_search ON core.customers USING GIN(search_vector);
CREATE INDEX idx_jobs_search ON core.jobs USING GIN(search_vector);

-- Trigram indexes for fuzzy matching
CREATE INDEX idx_customers_name_trgm ON core.customers USING GIN(
    (first_name || ' ' || last_name) gin_trgm_ops
);
CREATE INDEX idx_parts_description_trgm ON core.parts USING GIN(description gin_trgm_ops);

-- Composite indexes for common query patterns
CREATE INDEX idx_jobs_tenant_customer ON core.jobs(tenant_id, customer_id);
CREATE INDEX idx_estimates_tenant_customer ON core.estimates(tenant_id, customer_id);
CREATE INDEX idx_invoices_tenant_customer ON core.invoices(tenant_id, customer_id);
CREATE INDEX idx_invoices_due_date ON core.invoices(tenant_id, status, due_date);

-- updated_at trigger function
CREATE OR REPLACE FUNCTION core.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables
CREATE TRIGGER trg_tenants_updated_at BEFORE UPDATE ON core.tenants
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON core.customers
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_service_addresses_updated_at BEFORE UPDATE ON core.service_addresses
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_jobs_updated_at BEFORE UPDATE ON core.jobs
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_estimates_updated_at BEFORE UPDATE ON core.estimates
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON core.invoices
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_equipment_updated_at BEFORE UPDATE ON core.equipment
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_parts_updated_at BEFORE UPDATE ON core.parts
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_part_categories_updated_at BEFORE UPDATE ON core.part_categories
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();
CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON core.payments
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at();

-- Customer search vector trigger
CREATE OR REPLACE FUNCTION core.update_customer_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = to_tsvector('english',
        coalesce(NEW.first_name, '') || ' ' ||
        coalesce(NEW.last_name, '') || ' ' ||
        coalesce(NEW.email, '') || ' ' ||
        coalesce(NEW.company_name, '') || ' ' ||
        coalesce(NEW.phone, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_search_vector
    BEFORE INSERT OR UPDATE ON core.customers
    FOR EACH ROW EXECUTE FUNCTION core.update_customer_search_vector();

-- Job search vector trigger
CREATE OR REPLACE FUNCTION core.update_job_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = to_tsvector('english',
        coalesce(NEW.title, '') || ' ' ||
        coalesce(NEW.description, '') || ' ' ||
        coalesce(NEW.notes, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_jobs_search_vector
    BEFORE INSERT OR UPDATE ON core.jobs
    FOR EACH ROW EXECUTE FUNCTION core.update_job_search_vector();
