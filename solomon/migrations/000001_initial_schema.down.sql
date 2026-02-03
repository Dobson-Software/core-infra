-- Solomon Platform Control Plane — Rollback Initial Schema

DROP TRIGGER IF EXISTS incidents_updated_at ON incidents;
DROP TRIGGER IF EXISTS runbooks_updated_at ON runbooks;
DROP TRIGGER IF EXISTS environments_updated_at ON environments;
DROP TRIGGER IF EXISTS services_updated_at ON services;
DROP FUNCTION IF EXISTS update_updated_at();

DROP TRIGGER IF EXISTS audit_log_no_delete ON audit_log;
DROP FUNCTION IF EXISTS prevent_audit_delete();

DROP TABLE IF EXISTS cost_records;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS ai_actions;
DROP TABLE IF EXISTS ai_sessions;
DROP TABLE IF EXISTS incident_timeline;
DROP TABLE IF EXISTS incidents;
DROP TABLE IF EXISTS deployments;
DROP TABLE IF EXISTS runbooks;
DROP TABLE IF EXISTS dependencies;
DROP TABLE IF EXISTS environments;
DROP TABLE IF EXISTS services;
