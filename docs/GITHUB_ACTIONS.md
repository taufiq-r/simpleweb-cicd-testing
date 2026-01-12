# GitHub Actions CI/CD Setup Guide

## Quick Reference

This repo has **5 GitHub Actions workflows** that automate building, testing, deploying, and notifying:

### Workflows Summary

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci.yml` | Any push/PR | Build & push Docker images |
| `.github/workflows/deploy-staging.yml` | Push to `develop` | Deploy to staging server |
| `.github/workflows/deploy-production.yml` | Push to `main`/`master` | Deploy to production |
| `.github/workflows/notify-issue.yml` | New issue opened | Discord + bot comment |
| `.github/workflows/notify-pr.yml` | PR opened/reopened | Discord notification |

### Composite Action

**`.github/actions/discord-notify/`** — Reusable Discord webhook notifier used by all workflows.

---

## Step-by-Step Setup

### Step 1: Create Repository Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**

Add the following secrets:

#### Essential Secrets (for all workflows)
```
DISCORD_WEBHOOK
Type: Secret
Value: https://discord.com/api/webhooks/YOUR_ID/YOUR_TOKEN
```

#### Deployment Secrets (for staging/prod deployments)
```
STAGE_HOST
Value: staging.example.com or IP address

PROD_HOST
Value: prod.example.com or IP address

DEPLOY_USER
Value: deploy (or your deploy username)

SSH_PRIVATE_KEY
Value: (contents of ~/.ssh/id_rsa or deploy key - base64 encoded)

STAGE_APP_URL
Value: https://staging.example.com

PROD_APP_URL
Value: https://example.com
```

### Step 2: Create Discord Webhook

1. Open your Discord server
2. Go to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it (e.g., "CI/CD Notifier")
5. Copy the webhook URL
6. Paste into `DISCORD_WEBHOOK` secret

### Step 3: Generate SSH Deploy Key

On your local machine:
```bash
# Generate a new SSH key for deployments
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""

# Print private key (to add to GitHub secret)
cat ~/.ssh/github_deploy
```

Add the **contents** (not filename) to `SSH_PRIVATE_KEY` secret.

### Step 4: Add Public Key to Deployment Servers

For both staging and production servers:

```bash
# As root or with sudo
useradd -m deploy
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh

# Add your public key
echo "ssh-rsa AAAA... your-key@github" >> /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

# Give deploy user Docker permissions
usermod -aG docker deploy

# Create deploy directory
mkdir -p /home/deploy/deploy
chown deploy:deploy /home/deploy/deploy
```

### Step 5: Test Secrets

Push a commit to your repo and check **Actions** tab:
- If secrets are missing, the workflow will fail with a clear error
- If secrets are correct, images will build and push successfully

---

## Workflow Details

### CI Workflow (`ci.yml`)

**Triggers:** Any push or pull request to any branch

**Steps:**
1. Checkout code
2. Set up Docker buildx
3. Log in to GitHub Container Registry (GHCR)
4. Build frontend Docker image
5. Push frontend image to GHCR
6. Build backend Docker image
7. Push backend image to GHCR
8. Send Discord notification (success or failure)

**Failure scenario:**
- Discord message with build error log link
- Example: `https://github.com/your-user/your-repo/actions/runs/12345`

**Success scenario:**
- Discord message with image names pushed
- Example: `ghcr.io/your-user/your-repo-frontend:latest`

### Deploy Staging Workflow (`deploy-staging.yml`)

**Triggers:** Push to `develop` branch only

**Steps:**
1. Build frontend image
2. Push frontend image to GHCR
3. Build backend image
4. Push backend image to GHCR
5. **SSH into staging server** (using `STAGE_HOST`, `DEPLOY_USER`, `SSH_PRIVATE_KEY`)
6. Pull latest images
7. Deploy with Docker Stack or Nomad
8. Send Discord notification with staging URL

**Example Discord message:**
```
Title: Staging Deployed: your-user/your-repo
Body: Staging URL: https://staging.example.com
Status: Success (green embed)
```

### Deploy Production Workflow (`deploy-production.yml`)

**Triggers:** Push to `main` or `master` branch only

**Steps:** Same as staging but for production servers and `PROD_HOST`

### Issue Notification Workflow (`notify-issue.yml`)

**Triggers:** When a new issue is opened

**Steps:**
1. Send Discord webhook with issue title and link
2. Post a bot comment on the issue: "Thanks for the report! A team bot thread has been created in the Dev channel."

**Example Discord message:**
```
Title: New Issue: Fix login button bug
Body: https://github.com/your-user/your-repo/issues/42
       Opened by: @username
Status: Info (blue embed)
```

### PR Notification Workflow (`notify-pr.yml`)

**Triggers:** When a PR is opened or reopened

**Steps:**
1. Send Discord webhook with PR title and link

**Example Discord message:**
```
Title: New PR: Add dark mode feature
Body: https://github.com/your-user/your-repo/pull/99
       Opened by: @username
Status: Info (blue embed)
```

---

## Debugging Failed Workflows

### Check Logs

1. Go to your GitHub repo → **Actions**
2. Click the failed workflow run
3. Expand the failed step (e.g., "Build and push frontend image")
4. Check error output

### Common Issues

#### "unknown host" or SSH connection refused
- **Cause**: Incorrect `STAGE_HOST` or `PROD_HOST` secret
- **Fix**: Verify IP/hostname: `ping staging.example.com`

#### "Permission denied (publickey)"
- **Cause**: SSH key not added to server's `authorized_keys`
- **Fix**: Re-run setup Step 4 above

#### "docker: command not found" on server
- **Cause**: Docker not installed or deploy user can't access Docker
- **Fix**: Install Docker: `curl -fsSL https://get.docker.com | sh`

#### "Forbidden 403 Unauthenticated" when pushing to GHCR
- **Cause**: GitHub token permissions insufficient
- **Fix**: Use default `GITHUB_TOKEN` (provided by GitHub Actions)

#### Discord message not sent
- **Cause**: Invalid webhook URL
- **Fix**: Verify webhook in `DISCORD_WEBHOOK` secret is still active

---

## Advanced Customization

### Add Email Notifications

Add step to `deploy-staging.yml`:
```yaml
- name: Send email on failure
  if: failure()
  uses: dawidd6/action-send-mail@v3
  with:
    server_address: smtp.gmail.com
    server_port: 465
    username: your-email@gmail.com
    password: ${{ secrets.EMAIL_PASSWORD }}
    subject: Staging deployment failed
    to: team@example.com
    from: ci-bot@example.com
```

### Add Slack Notifications

Replace Discord with Slack:
```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1.24.0
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Staging deployed successfully!"
      }
```

### Add Automated Tests

Before building images, add:
```yaml
- name: Run frontend tests
  working-directory: frontend
  run: |
    npm ci
    npm run test

- name: Run backend tests
  working-directory: backend
  run: |
    bun install
    bun run test
```

### Add Code Quality Checks

```yaml
- name: Run ESLint (frontend)
  working-directory: frontend
  run: npm run lint

- name: Run SonarQube analysis
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

### Deploy to Multiple Servers

Use matrix strategy:
```yaml
strategy:
  matrix:
    server: [ staging1, staging2 ]
env:
  SERVER_IP: ${{ secrets[matrix.server] }}
```

---

## Local Testing (Optional)

To test workflows locally without pushing to GitHub:

### Using `act`

```bash
# Install act: https://github.com/nektos/act
brew install act  # macOS
# or
choco install act  # Windows
# or
apt-get install -y act  # Ubuntu

# Test CI workflow
act push -j build

# Test deploy workflow (requires secrets)
act push -e .actrc \
  -s DEPLOY_USER=deploy \
  -s STAGE_HOST=staging.local \
  -s SSH_PRIVATE_KEY="$(cat ~/.ssh/id_rsa)"
```

### Docker Compose (local testing)
```bash
docker-compose up --build
# Visit http://localhost
```

---

## Monitoring Deployments

### View Active Services

**Docker Swarm:**
```bash
docker service ls
docker service logs app_prod_backend
```

**Nomad:**
```bash
nomad status backend
nomad logs -f backend -task api
```

### Check Application Health

```bash
# Frontend
curl https://example.com/

# Backend
curl https://example.com/api/health

# Database
psql -h pgbouncer -p 6432 -U app -d appdb -c "SELECT 1"
```

---

## Rollback on Failure

If a deployment fails:

1. **Check Discord notification** for error details and logs
2. **Fix the issue** (code, config, secrets)
3. **Push a fix** to the branch (develop → staging, main → prod)
4. **New workflow runs** automatically
5. **Deployment updates** to the latest good version

For **manual rollback**:
```bash
# On the production server
docker service update --image ghcr.io/user/repo-backend:previous-tag app_prod_backend

# Or with Nomad
nomad job run -var='docker_image=ghcr.io/user/repo-backend:v1.0.0' backend.nomad
```

---

## Next Steps

1. ✅ Add Discord webhook
2. ✅ Create SSH deploy key
3. ✅ Add all secrets to GitHub
4. ✅ Test CI workflow (push to any branch)
5. ✅ Test deploy to staging (push to `develop`)
6. ✅ Test deploy to production (push to `main`)
7. 📋 Set up monitoring (Prometheus, Grafana)
8. 📋 Configure SSL/TLS (Let's Encrypt)
9. 📋 Add database backups
10. 📋 Implement feature flags

---

For more details, see:
- [ARCHITECTURE.md](ARCHITECTURE.md) — System design
- [DEPLOYMENT.md](DEPLOYMENT.md) — Manual deployment
- [README.md](../README.md) — Quick start
