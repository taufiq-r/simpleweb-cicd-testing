#!/bin/bash
# Local test script to verify CI/CD workflows and configs

set -e

echo "[*] Running local validation checks..."

# Check if docker-compose is valid
if command -v docker-compose &> /dev/null; then
  echo "[*] Validating docker-compose.yml..."
  docker-compose config > /dev/null && echo "[+] docker-compose.yml is valid"
fi

# Check if frontend Dockerfile exists
if [ -f frontend/Dockerfile ]; then
  echo "[+] frontend/Dockerfile found"
else
  echo "[-] frontend/Dockerfile not found"
  exit 1
fi

# Check if backend Dockerfile exists
if [ -f backend/Dockerfile ]; then
  echo "[+] backend/Dockerfile found"
else
  echo "[-] backend/Dockerfile not found"
  exit 1
fi

# Check GitHub Actions workflows
if [ -d .github/workflows ]; then
  echo "[*] Found GitHub Actions workflows:"
  ls -la .github/workflows/*.yml
fi

echo "[+] Local validation passed!"
echo ""
echo "Next steps:"
echo "  1. Run: docker-compose build"
echo "  2. Run: docker-compose up"
echo "  3. Access: http://localhost (via nginx)"
