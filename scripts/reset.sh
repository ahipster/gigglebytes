#!/bin/bash
echo "=== Resetting GRIP Development Environment ==="
echo "WARNING: This will delete all data in docker volumes!"

read -p "Are you sure? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

docker-compose -f docker/docker-compose.yml down -v
echo "Volumes removed."
echo "Run ./scripts/setup.sh to restart."
