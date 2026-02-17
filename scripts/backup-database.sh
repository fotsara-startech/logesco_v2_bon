#!/bin/bash

# LOGESCO v2 - Database Backup Script

set -e

# Configuration
BACKUP_DIR="/backups/logesco"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="logesco_backup_${TIMESTAMP}.sql"
RETENTION_DAYS=30

# Database configuration from environment
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}
DB_NAME=${POSTGRES_DB:-logesco}
DB_USER=${POSTGRES_USER:-logesco_user}

echo "=========================================="
echo "LOGESCO v2 - Database Backup"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create database backup
echo "Creating database backup..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --verbose \
    --no-owner \
    --no-privileges \
    --format=custom \
    --file="$BACKUP_DIR/$BACKUP_FILE"

# Compress backup
echo "Compressing backup..."
gzip "$BACKUP_DIR/$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Verify backup
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    echo "ERROR: Backup failed!"
    exit 1
fi

# Clean old backups
echo "Cleaning old backups (older than $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "logesco_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Upload to S3 (if configured)
if [ -n "$BACKUP_S3_BUCKET" ]; then
    echo "Uploading backup to S3..."
    aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$BACKUP_S3_BUCKET/database-backups/"
    echo "Backup uploaded to S3: s3://$BACKUP_S3_BUCKET/database-backups/$BACKUP_FILE"
fi

echo "Backup completed successfully!"
echo "=========================================="