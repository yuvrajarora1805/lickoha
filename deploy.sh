#!/bin/bash

# ============================================================
# Koha AMC License - Deployment Script
# ============================================================

set -e

echo "🚀 Pulling latest code from Git..."
git pull origin main

echo "🛑 Stopping Koha and destroying old database volume..."
# We use -v to ensure the database starts completely fresh if needed
docker compose down -v

echo "🏗️ Rebuilding and starting the Koha environment..."
# --build forces Docker to inject any new files/scripts from our repo
docker compose up -d --build koha-app

echo "✅ Deployment complete! Koha is starting up."
echo "👀 Watching logs... (Press Ctrl+C to exit logs)"
docker logs -f koha_app
