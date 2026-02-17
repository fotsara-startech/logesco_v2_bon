#!/bin/bash

# LOGESCO v2 - Build Complete Cloud Package

set -e

echo "=========================================="
echo "LOGESCO v2 - Build Cloud Package"
echo "=========================================="

DIST_DIR="$(dirname "$0")/../dist"
PACKAGE_DIR="$DIST_DIR/LOGESCO-Cloud-Package"

# Clean distribution directory
if [ -d "$DIST_DIR" ]; then
    echo "Cleaning distribution directory..."
    rm -rf "$DIST_DIR"
fi

mkdir -p "$DIST_DIR"
mkdir -p "$PACKAGE_DIR"

echo ""
echo "Step 1/6: Building Flutter Web Application..."
cd "$(dirname "$0")/../logesco_v2"
flutter clean
flutter pub get
flutter build web --release --web-renderer html --dart-define=API_URL=\${API_URL}
cd ..

echo ""
echo "Step 2/6: Preparing Backend for Docker..."
cd backend
npm ci --only=production
npm run generate
cd ..

echo ""
echo "Step 3/6: Building Docker Images..."
docker build -f docker/Dockerfile.api -t logesco-api:latest .
docker build -f docker/Dockerfile.web -t logesco-web:latest .

echo ""
echo "Step 4/6: Creating deployment package..."

# Create package structure
mkdir -p "$PACKAGE_DIR/docker"
mkdir -p "$PACKAGE_DIR/scripts"
mkdir -p "$PACKAGE_DIR/config"
mkdir -p "$PACKAGE_DIR/docs"

# Copy Docker configurations
cp docker-compose.yml "$PACKAGE_DIR/"
cp docker-compose.prod.yml "$PACKAGE_DIR/"
cp docker/nginx.conf "$PACKAGE_DIR/docker/"
cp docker/init-db.sql "$PACKAGE_DIR/docker/"

# Copy deployment scripts
cp scripts/deploy-cloud.sh "$PACKAGE_DIR/scripts/"
cp scripts/backup-database.sh "$PACKAGE_DIR/scripts/"
cp scripts/restore-database.sh "$PACKAGE_DIR/scripts/"
cp scripts/health-check.sh "$PACKAGE_DIR/scripts/"

# Make scripts executable
chmod +x "$PACKAGE_DIR/scripts/"*.sh

# Copy configuration files
cp .env.example "$PACKAGE_DIR/config/"

# Create documentation
cat > "$PACKAGE_DIR/docs/DEPLOYMENT_GUIDE.md" << 'EOF'
# LOGESCO v2 - Cloud Deployment Guide

## Prerequisites

- Docker and Docker Compose installed
- Domain name configured (for production)
- SSL certificates (for HTTPS)

## Quick Start

1. Copy `.env.example` to `.env` and configure your environment variables
2. Run the deployment script:
   ```bash
   ./scripts/deploy-cloud.sh production
   ```

## Configuration

### Environment Variables

Copy `config/.env.example` to `.env` and update the following variables:

- `POSTGRES_PASSWORD`: Strong password for PostgreSQL
- `JWT_SECRET`: Strong secret for JWT tokens
- `CORS_ORIGIN`: Your domain(s)
- SSL configuration (if using HTTPS)

### SSL/HTTPS Setup

For production deployment with HTTPS:

1. Obtain SSL certificates for your domain
2. Update nginx configuration in `docker/nginx.conf`
3. Set SSL environment variables in `.env`

## Deployment Commands

### Production Deployment
```bash
./scripts/deploy-cloud.sh production
```

### Staging Deployment
```bash
./scripts/deploy-cloud.sh staging
```

### View Logs
```bash
docker-compose logs -f
```

### Stop Services
```bash
docker-compose down
```

## Backup and Restore

### Create Backup
```bash
./scripts/backup-database.sh
```

### Restore from Backup
```bash
./scripts/restore-database.sh backup_file.sql.gz
```

## Monitoring

### Health Check
```bash
./scripts/health-check.sh
```

### Service Status
```bash
docker-compose ps
```

## Troubleshooting

### Check Service Logs
```bash
docker-compose logs api
docker-compose logs web
docker-compose logs database
```

### Restart Services
```bash
docker-compose restart
```

### Reset Database
```bash
docker-compose down
docker volume rm logesco_postgres_data
./scripts/deploy-cloud.sh production
```

## Support

For technical support, please refer to the main documentation or contact the development team.
EOF

# Create installation script
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash

echo "=========================================="
echo "LOGESCO v2 - Cloud Installation"
echo "=========================================="

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp config/.env.example .env
    echo "Please edit .env file with your configuration before running deployment"
    exit 0
fi

# Run deployment
echo "Starting deployment..."
./scripts/deploy-cloud.sh production

echo "Installation completed!"
EOF

chmod +x "$PACKAGE_DIR/install.sh"

echo ""
echo "Step 5/6: Exporting Docker Images..."
docker save logesco-api:latest | gzip > "$PACKAGE_DIR/logesco-api-image.tar.gz"
docker save logesco-web:latest | gzip > "$PACKAGE_DIR/logesco-web-image.tar.gz"

echo ""
echo "Step 6/6: Creating deployment archive..."
cd "$DIST_DIR"
tar -czf "LOGESCO-v2-Cloud-Deployment.tar.gz" LOGESCO-Cloud-Package/

echo ""
echo "=========================================="
echo "Cloud package created successfully!"
echo "=========================================="
echo ""
echo "Generated files:"
echo "- Complete package: $PACKAGE_DIR"
echo "- Deployment archive: $DIST_DIR/LOGESCO-v2-Cloud-Deployment.tar.gz"
echo ""
echo "To deploy:"
echo "1. Extract the archive on your server"
echo "2. Configure .env file"
echo "3. Run ./install.sh"
echo ""
echo "=========================================="