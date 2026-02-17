#!/bin/bash

# LOGESCO v2 - Health Check Script

set -e

# Configuration
API_URL=${API_URL:-http://localhost:3000}
WEB_URL=${WEB_URL:-http://localhost:80}
DB_HOST=${POSTGRES_HOST:-localhost}
DB_PORT=${POSTGRES_PORT:-5432}
DB_NAME=${POSTGRES_DB:-logesco}
DB_USER=${POSTGRES_USER:-logesco_user}

echo "=========================================="
echo "LOGESCO v2 - Health Check"
echo "=========================================="
echo "Timestamp: $(date)"

# Function to check service
check_service() {
    local service_name="$1"
    local url="$2"
    local timeout="${3:-10}"
    
    echo -n "Checking $service_name... "
    
    if curl -f -s --max-time "$timeout" "$url" > /dev/null; then
        echo "✓ OK"
        return 0
    else
        echo "✗ FAILED"
        return 1
    fi
}

# Function to check database
check_database() {
    echo -n "Checking database... "
    
    if PGPASSWORD="$POSTGRES_PASSWORD" pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        echo "✓ OK"
        return 0
    else
        echo "✗ FAILED"
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    echo -n "Checking disk space... "
    
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$usage" -lt 90 ]; then
        echo "✓ OK ($usage% used)"
        return 0
    else
        echo "✗ WARNING ($usage% used)"
        return 1
    fi
}

# Function to check memory
check_memory() {
    echo -n "Checking memory... "
    
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    
    if [ "$mem_usage" -lt 90 ]; then
        echo "✓ OK ($mem_usage% used)"
        return 0
    else
        echo "✗ WARNING ($mem_usage% used)"
        return 1
    fi
}

# Run health checks
FAILED=0

check_database || FAILED=1
check_service "API" "$API_URL/api/health" || FAILED=1
check_service "Web" "$WEB_URL/health" || FAILED=1
check_disk_space || FAILED=1
check_memory || FAILED=1

echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo "All health checks passed ✓"
    exit 0
else
    echo "Some health checks failed ✗"
    exit 1
fi