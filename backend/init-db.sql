-- ===========================================
-- Cobalt Platform — Database Initialization
-- ===========================================
-- This script runs once when the PostgreSQL container starts.
-- It creates the database schemas that Flyway will populate.
-- Tables are managed by Flyway migrations in each service.

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS notification;
CREATE SCHEMA IF NOT EXISTS violations;
