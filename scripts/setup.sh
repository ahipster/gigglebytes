#!/bin/bash
set -e

echo "=== GRIP Development Environment Setup ==="

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "Docker required but not installed. Aborting."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Node.js required but not installed. Aborting."; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Installing pnpm..."; npm install -g pnpm; }

# Create .env from example if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
fi

# Start Docker services
echo "Starting Docker services..."
docker-compose -f docker/docker-compose.yml up -d

# Wait for services to be healthy
echo "Waiting for services to be ready..."
sleep 10

# Check service health
docker-compose -f docker/docker-compose.yml ps

# Install dependencies
echo "Installing Node.js dependencies..."
pnpm install

echo ""
echo "=== Setup Complete ==="
echo "Services running at:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - Kafka: localhost:9092"
echo "  - Elasticsearch: localhost:9200"
echo "  - Neo4j: localhost:7474"
echo "  - Mailhog: localhost:8025"
