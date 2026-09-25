#!/bin/bash
set -e

echo "🚀 Starting Render deployment..."

# Run the deploy script
chmod +x deploy-render.sh
./deploy-render.sh

# Start the application
npm run start:prod