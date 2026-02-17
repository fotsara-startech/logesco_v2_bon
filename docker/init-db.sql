-- LOGESCO v2 - PostgreSQL Database Initialization

-- Create database if not exists (handled by Docker)
-- CREATE DATABASE IF NOT EXISTS logesco;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create indexes for better performance
-- These will be created after Prisma migrations

-- Set timezone
SET timezone = 'UTC';

-- Create backup user (optional)
-- CREATE USER backup_user WITH PASSWORD 'backup_password';
-- GRANT CONNECT ON DATABASE logesco TO backup_user;
-- GRANT USAGE ON SCHEMA public TO backup_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup_user;