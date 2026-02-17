#!/bin/bash

# LOGESCO v2 - Database Restore Script

set -e

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 logesco_backup_20241104_120000.sql.gz"
    exit 1
fi

BACKUP_FILE="$1"
BACKUP_DIR="/backups/logesco"

# Database configuration from environment
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}
DB_NAME=${POSTGRES_DB:-logesco}
DB_USER=${POSTGRES_USER:-logesco_user}

echo "=========================================="
echo "LOGESCO v2 - Database Restore"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
echo "Backup file: $BACKUP_FILE"

# Check if backup file exists
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

# Confirmation prompt
read -p "This will REPLACE all data in database '$DB_NAME'. Are you sure? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Create a backup of current database before restore
echo "Creating backup of current database..."
CURRENT_BACKUP="logesco_pre_restore_$(date +"%Y%m%d_%H%M%S").sql"
PGPASSWORD="$POSTGRES_PASSWORD" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --format=custom \
    --file="$BACKUP_DIR/$CURRENT_BACKUP"

echo "Current database backed up to: $CURRENT_BACKUP"

# Decompress backup if needed
RESTORE_FILE="$BACKUP_DIR/$BACKUP_FILE"
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing backup file..."
    gunzip -c "$BACKUP_DIR/$BACKUP_FILE" > "$BACKUP_DIR/temp_restore.sql"
    RESTORE_FILE="$BACKUP_DIR/temp_restore.sql"
fi

# Drop and recreate database
echo "Dropping and recreating database..."
PGPASSWORD="$POSTGRES_PASSWORD" dropdb \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    "$DB_NAME"

PGPASSWORD="$POSTGRES_PASSWORD" createdb \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    "$DB_NAME"

# Restore database
echo "Restoring database from backup..."
PGPASSWORD="$POSTGRES_PASSWORD" pg_restore \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --verbose \
    --no-owner \
    --no-privileges \
    "$RESTORE_FILE"

# Clean up temporary file
if [[ "$BACKUP_FILE" == *.gz ]]; then
    rm -f "$BACKUP_DIR/temp_restore.sql"
fi

echo "Database restored successfully!"
echo "Previous database backed up to: $CURRENT_BACKUP"
echo "=========================================="