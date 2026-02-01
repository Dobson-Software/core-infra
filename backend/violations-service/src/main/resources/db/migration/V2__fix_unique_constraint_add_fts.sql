-- ===========================================
-- V2: Fix tenant-scoped unique constraint + FTS
-- ===========================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Fix: unique constraint should be tenant-scoped
ALTER TABLE violations.dob_violations DROP CONSTRAINT IF EXISTS dob_violations_isn_dob_bis_viol_key;
ALTER TABLE violations.dob_violations ADD CONSTRAINT uq_violations_tenant_isn
    UNIQUE(tenant_id, isn_dob_bis_viol);

-- Full-text search
ALTER TABLE violations.dob_violations ADD COLUMN search_vector tsvector;

CREATE INDEX idx_violations_search ON violations.dob_violations USING GIN(search_vector);
CREATE INDEX idx_violations_street_trgm ON violations.dob_violations USING GIN(street gin_trgm_ops);
CREATE INDEX idx_violations_description_trgm ON violations.dob_violations USING GIN(description gin_trgm_ops);

-- Composite indexes
CREATE INDEX idx_violations_tenant_bin ON violations.dob_violations(tenant_id, bin);
CREATE INDEX idx_violations_tenant_boro_date ON violations.dob_violations(tenant_id, boro, issue_date);

-- Search vector trigger
CREATE OR REPLACE FUNCTION violations.update_violation_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = to_tsvector('english',
        coalesce(NEW.house_number, '') || ' ' ||
        coalesce(NEW.street, '') || ' ' ||
        coalesce(NEW.description, '') || ' ' ||
        coalesce(NEW.violation_type, '') || ' ' ||
        coalesce(NEW.violation_category, '') || ' ' ||
        coalesce(NEW.boro, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_violations_search_vector
    BEFORE INSERT OR UPDATE ON violations.dob_violations
    FOR EACH ROW EXECUTE FUNCTION violations.update_violation_search_vector();

-- updated_at trigger
CREATE OR REPLACE FUNCTION violations.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_violations_updated_at BEFORE UPDATE ON violations.dob_violations
    FOR EACH ROW EXECUTE FUNCTION violations.update_updated_at();
CREATE TRIGGER trg_watches_updated_at BEFORE UPDATE ON violations.watches
    FOR EACH ROW EXECUTE FUNCTION violations.update_updated_at();
