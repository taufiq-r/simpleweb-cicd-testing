# Complete Setup Guide - Debian Laptop + Server Deployment

**Status:** Ready for local testing + production deployment

---

## PHASE 1: Local Testing (Debian Laptop)

### 1.1 Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker compose version
```

### 1.2 Clone Repository (when ready)

```bash
# Create workspace
mkdir -p ~/projects
cd ~/projects

# Clone your GitHub repo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO
```

### 1.3 Run Locally

```bash
# Build and start all services
docker compose up --build

# Or daemonize
docker compose up -d --build

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Access:**
- Frontend: `http://localhost:3000`
- Nginx Proxy: `http://localhost:8000`
- API: `http://localhost:8000/api/health`
- Database: `localhost:5432` (user: `app`, pass: `changeme`)

### 1.4 Troubleshooting Local

```bash
# See all logs
docker compose logs -f

# See backend logs only
docker compose logs -f backend

# Restart backend
docker compose restart backend

# Reset everything
docker compose down -v
docker compose up -d --build

# Check connections
docker compose exec backend curl http://localhost:3000/api/health
docker compose exec nginx wget -qO- http://backend:3000/
```

---

## PHASE 2: GitHub Setup

### 2.1 Create GitHub Repository

```bash
# Initialize git (if new)
cd ~/projects/YOUR_REPO
git init
git add .
git commit -m "Initial scaffold"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main

# Create develop branch
git checkout -b develop
git push -u origin develop
```

### 2.2 Configure GitHub Secrets

Go to: **GitHub repo → Settings → Secrets and variables → Actions**

#### 2.2.1 Add DISCORD_WEBHOOK (Required for CI)

```
Name: DISCORD_WEBHOOK
Value: https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

**How to get Discord webhook:**
1. Open your Discord server
2. Settings → Integrations → Webhooks
3. New Webhook → Name it "CI/CD Notifier"
4. Copy the Webhook URL
5. Paste in GitHub secret

#### 2.2.2 Add Deployment Secrets (Optional - for staging/prod)

```
STAGE_HOST          → staging.example.com (or IP)
PROD_HOST           → prod.example.com (or IP)
DEPLOY_USER         → deploy (username on server)
SSH_PRIVATE_KEY     → (contents of private key)
STAGE_APP_URL       → https://staging.example.com
PROD_APP_URL        → https://example.com
```

### 2.3 Test CI Pipeline

```bash
# Push to GitHub
git push origin main

# Check Actions tab
# Expected:
# ✅ Checkout code
# ✅ Build frontend image
# ✅ Build backend image
# ✅ Push to GHCR
# ✅ Discord notification sent
```

**Check GHCR (GitHub Container Registry):**
- Go to your GitHub profile → Packages
- See: `repo-frontend:latest` and `repo-backend:latest`

---

## PHASE 3: Server Deployment Setup

### 3.1 Prepare Deployment Server (Debian)

**SSH into your server:**
```bash
ssh root@YOUR_SERVER_IP
```

**Install Docker:**
```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose-v2

# Enable Docker service
systemctl enable docker
systemctl start docker
```

**Create deploy user:**
```bash
# Create user
useradd -m -s /bin/bash deploy
passwd deploy  # Set password

# Add to docker group
usermod -aG docker deploy

# Configure sudo (optional)
usermod -aG sudo deploy

# Create deploy directory
mkdir -p /home/deploy/deploy
mkdir -p /home/deploy/.ssh
chown -R deploy:deploy /home/deploy/deploy
chown -R deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
```

### 3.2 Generate SSH Deploy Key (Local Machine)

**On your Debian laptop:**
```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""

# Show private key (copy this to GitHub secret SSH_PRIVATE_KEY)
cat ~/.ssh/github_deploy

# Show public key (copy this to server)
cat ~/.ssh/github_deploy.pub
```

### 3.3 Add Public Key to Server

**On your server (as root or sudo):**
```bash
# Copy public key from your laptop to server
# Option A: Copy manually
sudo -u deploy bash -c 'echo "ssh-rsa AAAA... your-key" >> /home/deploy/.ssh/authorized_keys'
chmod 600 /home/deploy/.ssh/authorized_keys

# Option B: From your laptop
ssh-copy-id -i ~/.ssh/github_deploy.pub deploy@YOUR_SERVER_IP
```

**Test SSH connection:**
```bash
# From your laptop
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# If successful, you're in the server
whoami  # Should show: deploy
```

### 3.4 Setup Deploy Directories on Server

**SSH into server as deploy user:**
```bash
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# Create app directory
mkdir -p /home/deploy/app
cd /home/deploy/app

# Create docker-compose file
cat > docker-compose.prod.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:17
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: app
      POSTGRES_PASSWORD: changeme
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    restart: unless-stopped

  pgbouncer:
    image: edoburu/pgbouncer:latest
    environment:
      DATABASE_URL: postgres://app:changeme@postgres:5432/appdb
    ports:
      - "127.0.0.1:6432:6432"
    depends_on:
      - postgres
    restart: unless-stopped

  backend:
    image: ghcr.io/YOUR_USERNAME/YOUR_REPO-backend:latest
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://app:changeme@pgbouncer:6432/appdb
      PORT: 3000
    ports:
      - "127.0.0.1:3000:3000"
    depends_on:
      - pgbouncer
    restart: unless-stopped

  frontend:
    image: ghcr.io/YOUR_USERNAME/YOUR_REPO-frontend:latest
    ports:
      - "127.0.0.1:3001:80"
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
      - frontend
    restart: unless-stopped

volumes:
  pgdata:

networks:
  default:
    name: appnet
EOF
```

### 3.5 Create Nginx Config for Production

**SSH into server as deploy user:**
```bash
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# Create nginx config directory
mkdir -p /home/deploy/app/nginx

# Create nginx config
cat > /home/deploy/app/nginx/nginx.prod.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Add resolver for Docker DNS
    resolver 127.0.0.11 valid=10s;
    resolver_timeout 5s;

    # Backend upstream
    upstream backend {
        server backend:3000;
    }

    # Frontend upstream
    upstream frontend_app {
        server frontend:80;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name YOUR_DOMAIN.com;

        # SSL certificates (use certbot/Let's Encrypt)
        ssl_certificate /etc/letsencrypt/live/YOUR_DOMAIN.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN.com/privkey.pem;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # API routes → backend
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 60s;
            proxy_connect_timeout 60s;
        }

        # Frontend routes
        location / {
            proxy_pass http://frontend_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
```

### 3.6 Login to GHCR on Server

**SSH into server as deploy user:**
```bash
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# Create GitHub Personal Access Token:
# 1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. Scopes: read:packages
# 3. Copy the token

# Login to GHCR
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Verify login
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO-backend:latest
```

---

## PHASE 4: GitHub Actions Deployment Workflows

### 4.1 Update GitHub Secrets

Go to: **GitHub repo → Settings → Secrets and variables → Actions**

**Add these secrets:**

```
STAGE_HOST          = your-staging-server.com (or IP)
PROD_HOST           = your-prod-server.com (or IP)
DEPLOY_USER         = deploy
SSH_PRIVATE_KEY     = (contents of ~/.ssh/github_deploy)
STAGE_APP_URL       = https://staging.your-domain.com
PROD_APP_URL        = https://your-domain.com
DISCORD_WEBHOOK     = https://discord.com/api/webhooks/...
```

### 4.2 Deploy to Staging

```bash
# On your laptop
git checkout develop
git add .
git commit -m "Deploy to staging"
git push origin develop

# GitHub Actions will:
# 1. Build images
# 2. Push to GHCR
# 3. SSH to staging server
# 4. Pull latest images
# 5. Run docker compose up -d
# 6. Send Discord notification
```

**Check Actions tab** for build status.

### 4.3 Deploy to Production

```bash
# On your laptop
git checkout main
git merge develop
git push origin main

# GitHub Actions will:
# 1. Build images
# 2. Push to GHCR
# 3. SSH to production server
# 4. Pull latest images
# 5. Run docker compose up -d
# 6. Send Discord notification
```

---

## PHASE 5: Monitoring & Maintenance

### 5.1 View Server Logs

```bash
# SSH into server
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# View all logs
docker compose -f /home/deploy/app/docker-compose.prod.yml logs -f

# View specific service
docker compose -f /home/deploy/app/docker-compose.prod.yml logs -f backend
```

### 5.2 Database Backup

```bash
# SSH into server as deploy user
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# Create backup directory
mkdir -p /home/deploy/backups

# Backup database
docker compose -f /home/deploy/app/docker-compose.prod.yml exec postgres \
  pg_dump -U app appdb > /home/deploy/backups/backup-$(date +%Y%m%d-%H%M%S).sql

# Download to laptop
scp -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP:/home/deploy/backups/* ~/backups/
```

### 5.3 Update Application

```bash
# On your laptop
git add .
git commit -m "Your changes"
git push origin develop  # For staging
# or
git push origin main     # For production

# GitHub Actions will auto-deploy
```

---

## QUICK REFERENCE

### Local (Laptop)
```bash
docker compose up -d --build
docker compose logs -f
docker compose ps
curl http://localhost:3000
```

### GitHub Setup Checklist
- [ ] Create GitHub repository
- [ ] Push code to main + develop branches
- [ ] Add DISCORD_WEBHOOK secret
- [ ] Create Discord webhook
- [ ] Test CI workflow (push to main)

### Server Setup Checklist
- [ ] Install Docker on server
- [ ] Create deploy user
- [ ] Generate SSH keys
- [ ] Copy public key to server
- [ ] Test SSH connection
- [ ] Create app directories
- [ ] Create docker-compose.prod.yml
- [ ] Login to GHCR
- [ ] Add deployment secrets to GitHub
- [ ] Test deploy (push to develop/main)

### Workflows Summary
| Branch | Trigger | Action |
|--------|---------|--------|
| any | push | Build + push to GHCR + Discord notify |
| develop | push | Build + deploy to staging + Discord |
| main | push | Build + deploy to production + Discord |

---

## Troubleshooting

### SSH Key Not Working
```bash
# Check permissions on server
ls -la /home/deploy/.ssh/authorized_keys
# Should be 600

# Test key locally
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP
```

### Images Not Pulling
```bash
# Check GHCR login on server
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO-backend:latest

# If fails, re-login
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

### Deploy Workflow Failing
1. Check GitHub Actions logs: repo → Actions tab
2. Common causes:
   - SSH_PRIVATE_KEY secret missing
   - Server IP/hostname wrong
   - Deploy user doesn't exist
   - GHCR login failed on server

### Container Not Starting
```bash
# SSH into server
ssh -i ~/.ssh/github_deploy deploy@YOUR_SERVER_IP

# Check logs
docker compose -f /home/deploy/app/docker-compose.prod.yml logs backend
```

---

## Environment Variables

### Backend (.env for development)
```
NODE_ENV=development
DATABASE_URL=postgres://app:changeme@localhost:6432/appdb
PORT=3000
```

### Backend (docker-compose.prod.yml)
```yaml
environment:
  NODE_ENV: production
  DATABASE_URL: postgres://app:changeme@pgbouncer:6432/appdb
  PORT: 3000
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:8000/api
```

### Frontend (production)
```
VITE_API_URL=https://your-domain.com/api
```

---

## SSL/HTTPS Setup (Production)

### Install Let's Encrypt Certbot

```bash
# On server
sudo apt install -y certbot python3-certbot-nginx

# Generate certificate
sudo certbot certonly --standalone -d your-domain.com

# Verify
ls -la /etc/letsencrypt/live/your-domain.com/
```

### Update Nginx Config

Already in `nginx.prod.conf` above. Just update:
- `server_name YOUR_DOMAIN.com;`
- `ssl_certificate` path
- `ssl_certificate_key` path

### Auto-Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Should auto-renew via cron
```

---

## Next Steps

1. **Test locally** with `docker compose up -d`
2. **Push to GitHub** and configure DISCORD_WEBHOOK secret
3. **Test CI workflow** with git push
4. **Setup server** when ready (keep this guide)
5. **Add deployment secrets** to GitHub
6. **Test staging deployment** with git push to develop
7. **Deploy to production** when ready

Good luck! 🚀
