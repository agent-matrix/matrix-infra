#!/usr/bin/env bash
set -euo pipefail

# This script deploys the Matrix AI and Matrix Guardian services on an Oracle VM.
# It is intended to be executed via SSH from a GitHub Actions workflow.  The
# working directory should be the `platforms/oracle/compose` folder on the VM.

echo "[deploy] Pulling latest container images..."
docker compose pull

echo "[deploy] Applying environment variables from .env..."
if [ ! -f .env ]; then
  echo "Error: .env file not found.  Please create it based on .env.example." >&2
  exit 1
fi

echo "[deploy] Restarting services..."
docker compose up -d --remove-orphans

echo "[deploy] Deployment complete.  Running containers:"
docker compose ps