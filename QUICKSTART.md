# Project Summary & Quick Start

**Repository:** Full-Stack Infrastructure-Focused Application  
**Created:** January 2026

## What Was Built

A complete, production-ready scaffold with:

### ✅ Frontend
- React 18 + Vite + TypeScript
- Zustand (state), TanStack Query (fetch), TanStack Router (routing)
- shadcn UI + Tailwind CSS 4
- Zod validation
- Dockerfile (Node Alpine → Nginx)

### ✅ Backend
- Bun runtime + Hono web framework
- Zod validation
- Ready for Drizzle ORM, Scalar OpenAPI docs
- Dockerfile (Bun lightweight)

### ✅ Infrastructure
- PostgreSQL 17 (database)
- PGBouncer (connection pooling)
- Nginx (reverse proxy)
- Docker Compose (local dev)
- Docker Swarm stack file
- Nomad job files (5 jobs: postgres, pgbouncer, backend, frontend, nginx)

### ✅ CI/CD (GitHub Actions)
1. **ci.yml** — Build & push images (all branches)
2. **deploy-staging.yml** — Deploy to staging (develop → staging server)
3. **deploy-production.yml** — Deploy to prod (main → prod server)
4. **notify-issue.yml** — Discord + bot comment on new issues
5. **notify-pr.yml** — Discord notification on new PRs
6. **lint-test.yml** — Optional linting/testing
7. **Composite action** — Reusable Discord webhook notifier

### ✅ Documentation
- **README.md** — Project overview, quick start, tech stack
- **docs/ARCHITECTURE.md** — System design, scaling, security
- **docs/DEPLOYMENT.md** — Server setup, SSH, workflows
- **docs/GITHUB_ACTIONS.md** — Secrets setup, debugging

---

## Project Structure

```
testing/
├── .github/
│   ├── actions/discord-notify/action.yml
│   └── workflows/
│       ├── ci.yml
│       ├── deploy-staging.yml
│       ├── deploy-production.yml
│       ├── notify-issue.yml
│       ├── notify-pr.yml
│       └── lint-test.yml
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.ts
│   ├── index.html
│   └── src/{main.tsx, App.tsx}
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── src/index.ts
├── docker-compose.yml           # Local dev: postgres + pgbouncer + all services
├── pgbouncer/
│   ├── pgbouncer.ini
│   ├── userlist.txt
│   └── gen-hash.sh
├── nginx/nginx.conf
├── nomad/                       # Nomad job definitions
│   ├── postgres.nomad
│   ├── pgbouncer.nomad
│   ├── backend.nomad
│   ├── frontend.nomad
│   └── nginx.nomad
├── stack/docker-stack.yml       # Docker Swarm stack
├── scripts/
│   ├── deploy.sh
│   ├── setup-server.sh
│   ├── validate.sh
│   └── gen-pgbouncer-pwd.sh
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   └── GITHUB_ACTIONS.md
├── README.md
├── .gitignore
└── .env.example
```

---

## Quick Start (Local)

### 1. Clone & Install
```bash
git clone <repo> && cd testing
cp .env.example .env
```

### 2. Run Locally
```bash
docker-compose up --build
```

### 3. Access
- **Frontend**: http://localhost:8080 (via Nginx)
- **API**: http://localhost:3000/api/health
- **Reverse Proxy**: http://localhost:80
- **Database**: localhost:5432 (app/changeme)
- **PGBouncer**: localhost:6432

---

## GitHub Actions Setup (5 minutes)

### Step 1: Add Repository Secrets
Go to **GitHub Repo → Settings → Secrets and variables → Actions**, then add:

| Secret | Value |
|--------|-------|
| `DISCORD_WEBHOOK` | Discord webhook URL |
| `STAGE_HOST` | staging.example.com |
| `PROD_HOST` | prod.example.com |
| `DEPLOY_USER` | deploy |
| `SSH_PRIVATE_KEY` | Private SSH key contents |
| `STAGE_APP_URL` | https://staging.example.com |
| `PROD_APP_URL` | https://example.com |

### Step 2: Create Discord Webhook
1. Discord server → Integrations → Webhooks
2. Create webhook, copy URL → paste in `DISCORD_WEBHOOK` secret

### Step 3: Generate SSH Key
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github_deploy -N ""
cat ~/.ssh/github_deploy    # Add to SSH_PRIVATE_KEY secret
```

### Step 4: Add Public Key to Servers
```bash
# On staging/prod servers (as deploy user)
mkdir -p ~/.ssh
echo "ssh-rsa AAAA... " >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Step 5: Test
- Push to any branch → CI workflow builds images (check Actions tab)
- Push to `develop` → Deploy to staging
- Push to `main` → Deploy to production

---

## Workflow Triggers

| Branch/Event | Workflow | Action |
|---|---|---|
| Any push/PR | **ci.yml** | Build frontend + backend, push to GHCR |
| Push to `develop` | **deploy-staging.yml** | Deploy to staging, notify Discord |
| Push to `main` | **deploy-production.yml** | Deploy to prod, notify Discord |
| New issue opened | **notify-issue.yml** | Discord + bot comment |
| PR opened/reopened | **notify-pr.yml** | Discord notification |

---

## Discord Notifications

All workflows send embeds to your Discord channel:

**Success**: ✅ Green embed with URLs
- CI: Images pushed to GHCR
- Deploy: App running at staging/prod URL

**Failure**: ❌ Red embed with log link
- Example: `https://github.com/user/repo/actions/runs/12345`

**Info**: ℹ️ Blue embed for issues/PRs
- Issue title + link + author
- PR title + link + author

---

## Deployment Options

### Local Development
```bash
docker-compose up --build
```

### Docker Swarm (Simple)
```bash
# On target server
docker swarm init  # If needed
docker stack deploy -c stack/docker-stack.yml app_prod
docker service ls
```

### Nomad (Advanced)
```bash
# On Nomad server
nomad job run nomad/backend.nomad
nomad job run nomad/frontend.nomad
nomad status backend
```

---

## Key Features

✨ **Tech Stack**
- Frontend: React 18 + Vite + TypeScript
- Backend: Bun + Hono
- Database: PostgreSQL 17 + PGBouncer
- Proxy: Nginx
- Orchestration: Docker Swarm & Nomad

✨ **CI/CD**
- Automatic build on push
- Automatic deployment on branch merge
- Docker image push to GHCR
- SSH deployment to servers
- Discord notifications with logs

✨ **Infrastructure**
- Multi-tenant ready (pgbouncer)
- Connection pooling (pgbouncer)
- Service orchestration (Nomad/Swarm)
- Reverse proxy with routing
- Health checks

✨ **Security**
- SSH key-based deployment
- GitHub Secrets (no hardcoded creds)
- Optional JWT auth (implement in backend)
- RBAC/ABAC ready

---

## Configuration & Customization

### Modify PostgreSQL Credentials
Edit `docker-compose.yml`:
```yaml
postgres:
  environment:
    POSTGRES_PASSWORD: your-password
```

Update `pgbouncer/pgbouncer.ini` and `pgbouncer/userlist.txt`.

### Change Deployment URLs
Edit GitHub secrets:
- `STAGE_APP_URL` → your staging domain
- `PROD_APP_URL` → your production domain

### Add Environment Variables
Edit `.env.example` and update `docker-compose.yml` `environment:` sections.

### Customize Nginx Routes
Edit `nginx/nginx.conf` to add SSL, caching, rate limiting, etc.

---

## Next Steps

### Immediate
1. ✅ Push to GitHub
2. ✅ Configure secrets (5 min)
3. ✅ Test CI workflow
4. ✅ Test deploy to staging

### Short Term (1–2 weeks)
- [ ] Implement authentication (JWT + Hono middleware)
- [ ] Add Drizzle ORM migrations
- [ ] Implement TanStack Router routing
- [ ] Add unit/integration tests

### Medium Term (1–2 months)
- [ ] Set up HTTPS (Let's Encrypt)
- [ ] Configure monitoring (Prometheus, Grafana)
- [ ] Add database backups
- [ ] Implement feature flags

### Long Term
- [ ] Multi-region deployment
- [ ] Advanced CI/CD (SonarQube, SAST, etc.)
- [ ] Service mesh (optional: Istio, Linkerd)
- [ ] Advanced caching (Redis, CDN)

---

## Troubleshooting

### CI workflow fails
→ Check GitHub Actions logs (Actions tab)  
→ Verify `DISCORD_WEBHOOK` secret is set

### Deploy fails: "unknown host"
→ Verify `STAGE_HOST`/`PROD_HOST` in secrets  
→ Test: `ping staging.example.com`

### SSH: "Permission denied"
→ Verify SSH key is added: `cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys`  
→ Ensure `authorized_keys` permissions: `chmod 600`

### PGBouncer can't connect
→ Generate correct MD5 hash: `bash pgbouncer/gen-hash.sh changeme`  
→ Update `pgbouncer/userlist.txt`

### Discord notifications not sent
→ Verify webhook still active in Discord  
→ Check workflow logs for curl errors

---

## Documentation

- **[README.md](README.md)** — Overview, structure, local setup
- **[docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)** — Secrets, workflows, debugging
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — Server setup, manual deployment
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design, scaling, security

---

## Support

For issues or questions:
1. Check docs/ folder for detailed guides
2. Review GitHub Actions logs (Actions → workflow → failed step)
3. Check Discord webhook in server settings
4. Verify all secrets are set correctly

---

**Ready to deploy?** Start with:
```bash
git push develop   # → Triggers deploy-staging.yml
# Wait for Discord notification with staging URL
# Check app at https://staging.example.com
# Then merge to main for production
git push main      # → Triggers deploy-production.yml
```

Enjoy! 🚀
