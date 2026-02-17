#!/bin/bash

# LOGESCO v2 - Cloud Deployment Script

set -e

echo "=========================================="
echo "LOGESCO v2 - Cloud Deployment"
echo "=========================================="

# Configuration
ENVIRONMENT=${1:-production}
COMPOSE_FILE="docker-compose.yml"
PROD_COMPOSE_FILE="docker-compose.prod.yml"

echo "Environment: $ENVIRONMENT"
echo "Timestamp: $(date)"

# Validate environment
if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo "ERROR: Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found. Please create it from .env.example"
    exit 1
fi

# Load environment variables
source .env

# Pre-deployment checks
echo "Running pre-deployment checks..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running"
    exit 1
fi

# Check if required images exist or can be built
echo "Checking Docker images..."

# Build Flutter web if needed
if [ ! -d "logesco_v2/build/web" ]; then
    echo "Building Flutter web application..."
    cd logesco_v2
    flutter pub get
    flutter build web --release --web-renderer html
    cd ..
fi

# Pull latest images
echo "Pulling latest images..."
docker-compose -f "$COMPOSE_FILE" pull

# Stop existing services
echo "Stopping existing services..."
docker-compose -f "$COMPOSE_FILE" down

# Start database first
echo "Starting database..."
docker-compose -f "$COMPOSE_FILE" up -d database

# Wait for database to be ready
echo "Waiting for database to be ready..."
timeout 60 bash -c 'until docker-compose -f "$COMPOSE_FILE" exec -T database pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do sleep 2; done'

# Run database migrations
echo "Running database migrations..."
docker-compose -f "$COMPOSE_FILE" run --rm api npm run migrate:deploy

# Start all services
echo "Starting all services..."
if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f "$COMPOSE_FILE" -f "$PROD_COMPOSE_FILE" up -d
else
    docker-compose -f "$COMPOSE_FILE" up -d
fi

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 30

# Run health checks
echo "Running health checks..."
./scripts/health-check.sh

# Setup cron jobs for backups (production only)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "Setting up backup cron job..."
    (crontab -l 2>/dev/null; echo "0 2 * * * /path/to/logesco/scripts/backup-database.sh") | crontab -
fi

echo "=========================================="
echo "Deployment completed successfully!"
echo "=========================================="
echo "Services:"
echo "- Web: http://localhost:${WEB_PORT:-80}"
echo "- API: http://localhost:${API_PORT:-3000}"
echo "- Database: localhost:${POSTGRES_PORT:-5432}"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"
echo "=========================================="