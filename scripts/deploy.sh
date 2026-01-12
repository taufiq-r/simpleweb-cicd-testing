#!/bin/bash
# Deployment script for staging/production servers
# Run this on the target server or via SSH from CI/CD

set -e

IMAGE_REGISTRY="${IMAGE_REGISTRY:-ghcr.io}"
IMAGE_OWNER="${IMAGE_OWNER:-your-github-user}"
REPO_NAME="${REPO_NAME:-your-repo}"
ENV="${ENV:-staging}"

FRONTEND_IMAGE="${IMAGE_REGISTRY}/${IMAGE_OWNER}/${REPO_NAME}-frontend:latest"
BACKEND_IMAGE="${IMAGE_REGISTRY}/${IMAGE_OWNER}/${REPO_NAME}-backend:latest"

echo "[*] Deploying to $ENV environment..."
echo "[*] Frontend image: $FRONTEND_IMAGE"
echo "[*] Backend image: $BACKEND_IMAGE"

# Pull latest images
echo "[*] Pulling images..."
docker pull "$FRONTEND_IMAGE"
docker pull "$BACKEND_IMAGE"

# Deploy with Docker Swarm (if initialized)
if [ -f /var/run/docker.sock ] && command -v docker &> /dev/null; then
  if docker info | grep -q "Swarm: active"; then
    echo "[*] Docker Swarm detected. Deploying stack..."
    if [ -f ~/deploy/docker-stack.yml ]; then
      docker stack deploy -c ~/deploy/docker-stack.yml "app_${ENV}"
      sleep 5
      echo "[*] Stack deployed. Services:"
      docker service ls
    fi
  fi
fi

# Deploy with Nomad (if available)
if command -v nomad &> /dev/null; then
  echo "[*] Nomad detected. Running jobs..."
  # Note: Update image references in nomad job files first
  # nomad job run ~/deploy/backend.nomad
  # nomad job run ~/deploy/frontend.nomad
fi

echo "[+] Deployment complete!"
