-- Remove tenant_id from dob_violations (shared public NYC data)
ALTER TABLE violations.dob_violations DROP CONSTRAINT IF EXISTS uq_violations_tenant_isn;
ALTER TABLE violations.dob_violations ADD CONSTRAINT uq_violations_isn UNIQUE(isn_dob_bis_viol);

-- Drop tenant-scoped indexes
DROP INDEX IF EXISTS violations.idx_violations_tenant;
DROP INDEX IF EXISTS violations.idx_violations_tenant_bin;
DROP INDEX IF EXISTS violations.idx_violations_tenant_boro_date;

-- Add non-tenant indexes to replace
CREATE INDEX IF NOT EXISTS idx_violations_bin_only ON violations.dob_violations(bin);
CREATE INDEX IF NOT EXISTS idx_violations_boro_date ON violations.dob_violations(boro, issue_date);

-- Drop the column
ALTER TABLE violations.dob_violations DROP COLUMN IF EXISTS tenant_id;
