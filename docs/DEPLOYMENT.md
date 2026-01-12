# Deployment Guide for GitHub Actions CI/CD with Discord Notifications

## Quick Setup

### 1. GitHub Repository Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
DISCORD_WEBHOOK          = https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
STAGE_HOST               = staging.example.com
PROD_HOST                = prod.example.com
DEPLOY_USER              = deploy
SSH_PRIVATE_KEY          = (paste contents of ~/.ssh/id_rsa)
STAGE_APP_URL            = https://staging.example.com
PROD_APP_URL             = https://prod.example.com
```

### 2. Discord Webhook Setup

1. Go to your Discord server → Settings → Integrations → Webhooks
2. Create a New Webhook
3. Copy the Webhook URL
4. Add to repository secrets as `DISCORD_WEBHOOK`

### 3. SSH Setup for Deployment

On your local machine:
```bash
# Generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/deploy_key -N ""

# Copy public key to staging/prod servers
ssh-copy-id -i ~/.ssh/deploy_key.pub deploy@staging.example.com
ssh-copy-id -i ~/.ssh/deploy_key.pub deploy@prod.example.com

# Add private key to GitHub secrets
cat ~/.ssh/deploy_key | base64 | xclip  # Copy to GITHUB SECRET
```

On staging/production servers:
```bash
# As root or sudo
useradd -m deploy
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh

# Add public key
echo "ssh-rsa AAAA... your-key" > /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

# Create deploy directory
sudo mkdir -p /home/deploy/deploy
sudo chown deploy:deploy /home/deploy/deploy

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker deploy

# (Optional) Install Nomad
# Download from https://releases.hashicorp.com/nomad/
```

## Workflow Triggers

| File | Trigger | Action |
|------|---------|--------|
| **ci.yml** | Any push or PR | Build & push images to GHCR, notify Discord |
| **deploy-staging.yml** | Push to `develop` | Build, SSH deploy to staging, notify Discord |
| **deploy-production.yml** | Push to `main`/`master` | Build, SSH deploy to production, notify Discord |
| **notify-issue.yml** | New issue opened | Send Discord notification, post bot comment |
| **notify-pr.yml** | PR opened/reopened | Send Discord notification |

## Discord Notification Examples

### CI Success
```
Title: CI Success: user/repo
Body: Images pushed: ghcr.io/user/repo-frontend:latest and ghcr.io/user/repo-backend:latest
Status: success (green embed)
```

### Staging Deploy Success
```
Title: Staging Deployed: user/repo
Body: Staging URL: https://staging.example.com
Status: success (green embed)
```

### Deploy Failure
```
Title: Staging Deploy Failed: user/repo
Body: Logs: https://github.com/user/repo/actions/runs/12345
Status: failure (red embed)
```

### New Issue
```
Title: New Issue: Bug report for login page
Body: https://github.com/user/repo/issues/42
       Opened by: @username
Status: info (blue embed)
```

## Local Testing

### Dry-run with act
To test workflows locally without pushing to GitHub:

```bash
# Install act: https://github.com/nektos/act
brew install act

# Test CI workflow
act push -j build

# Test deploy (requires SSH credentials)
act push -e .actrc -s DEPLOY_USER=deploy -s SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)"
```

### Manual validation
```bash
./scripts/validate.sh
docker-compose build
docker-compose up
```

## Troubleshooting

### Workflow fails with "unknown host"
- Verify `STAGE_HOST` and `PROD_HOST` secrets are correct IP/hostname
- Test SSH manually: `ssh deploy@staging.example.com`

### Docker images not pushed to GHCR
- Ensure GitHub token has `write:packages` permission
- Check if GHCR is private; add Personal Access Token if needed

### Discord notification not sent
- Verify webhook URL in `DISCORD_WEBHOOK` secret
- Check that the Discord channel exists and webhook is still valid
- View workflow logs for curl error details

### PGBouncer connection fails
- Generate correct MD5 hash: `bash pgbouncer/gen-hash.sh changeme`
- Update `pgbouncer/userlist.txt`
- Verify `pgbouncer.ini` database definitions match

### SSH deployment hangs
- Check if deploy user can sudo without password (for Docker)
- Verify `~/.ssh/authorized_keys` on target server
- Test manually: `ssh deploy@prod-host 'bash ~/deploy/deploy.sh'`

## Advanced Configuration

### Slack instead of Discord
Replace the discord-notify action with a Slack notification:
```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.24.0
  with:
    payload: |
      {
        "text": "CI passed: ${{ github.repository }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Multiple environments
Duplicate deploy workflows for `test`, `staging`, `production`:
- Push to `test/*` → test env
- Push to `stage/*` → staging env
- Push to `main` → production env

### Auto-rollback on failed health check
Add a post-deploy health check:
```bash
#!/bin/bash
for i in {1..30}; do
  if curl -f https://prod.example.com/health; then
    exit 0
  fi
  sleep 10
done
exit 1  # Trigger rollback
```

### Matrix builds for multiple platforms
```yaml
strategy:
  matrix:
    platform: [ linux/amd64, linux/arm64 ]
```

## Monitoring Deployments

### Check deployment status
```bash
# Docker Swarm
docker service ls
docker service logs app_prod_backend

# Nomad
nomad status backend
nomad logs -f backend -task api

# Nginx logs
docker logs nginx
```

### Verify SSL/TLS
```bash
curl -vI https://prod.example.com
```

## Next Steps

1. Configure CloudFlare/DNS for your domain
2. Set up Let's Encrypt for HTTPS
3. Add database backups (e.g., automated daily PostgreSQL dumps)
4. Set up monitoring (Prometheus, Grafana, ELK)
5. Add database migrations to deploy workflow
6. Implement feature flags for safe rollouts
7. Configure log aggregation (ELK, Datadog, etc.)

---

For more details, see [README.md](../README.md)
