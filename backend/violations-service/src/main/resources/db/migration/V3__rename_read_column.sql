-- Drop the partial index that references the old column name
DROP INDEX IF EXISTS violations.idx_alerts_unread;

-- Rename the column
ALTER TABLE violations.alerts RENAME COLUMN "read" TO is_read;

-- Recreate the partial index with the new column name
CREATE INDEX idx_alerts_unread ON violations.alerts(tenant_id, is_read)
    WHERE is_read = false;
