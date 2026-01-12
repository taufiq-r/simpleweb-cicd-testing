#!/bin/bash
# Initialize a fresh staging/production server for deployments

set -e

echo "[*] Setting up deployment environment..."

# Create deploy directory
mkdir -p ~/deploy/pgbouncer ~/deploy/nginx

echo "[+] Created ~/deploy directory"

# Copy config files (from local repo)
# Example: scp -r pgbouncer/ user@server:~/deploy/
# Example: scp -r nginx/ user@server:~/deploy/

echo "[*] Next steps:"
echo "  1. Copy pgbouncer configs: scp -r pgbouncer/ user@host:~/deploy/"
echo "  2. Copy nginx configs: scp -r nginx/ user@host:~/deploy/"
echo "  3. Copy docker-stack.yml: scp stack/docker-stack.yml user@host:~/deploy/"
echo "  4. Update docker-stack.yml with correct image tags"
echo "  5. Make deploy.sh executable: chmod +x ~/deploy/deploy.sh"
echo "[+] Setup complete!"
