# Documentation Index

Welcome! Here's where to find everything you need.

## 🚀 Getting Started (5 minutes)

### **Start here:** [QUICKSTART.md](QUICKSTART.md)
- Project overview
- Quick local setup (docker-compose)
- GitHub secrets configuration (5 steps)
- Workflow triggers and Discord notifications

## 📚 Main Documentation

### 1. [README.md](README.md) — Full Project Overview
- Technology stack breakdown
- Project structure
- Local development setup
- Multi-tenant PostgreSQL with pgbouncer
- Orchestration options (Docker Swarm vs Nomad)
- Authentication & authorization
- Next steps

### 2. [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md) — CI/CD Setup & Configuration
- Detailed secrets setup (7 required secrets)
- Discord webhook creation
- SSH key generation and deployment
- All 5 workflows explained
- Common issues and fixes
- Advanced customization (email, Slack, tests, quality checks)
- Local testing with `act`

### 3. [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — Server Setup & Deployment
- GitHub Actions secrets reference
- CI/CD workflow triggers
- Discord notification examples
- Database configuration
- Multi-tenant setup
- Docker Swarm vs Nomad comparison
- Deployment script examples
- Monitoring and logging
- Troubleshooting guide
- Advanced configurations (multiple environments, auto-rollback)

### 4. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System Design
- Complete system architecture diagram
- Component breakdown (frontend, backend, database, etc.)
- Authentication flow (JWT tokens)
- Authorization models (RBAC, ABAC, RBA)
- Data flow (request → response)
- Deployment pipeline
- Scaling considerations (horizontal, caching, monitoring)
- Security checklist
- Environment configuration

## 🏗️ Project Structure

### File Tree
```
testing/
├── frontend/                   # React + Vite + TS
├── backend/                    # Bun + Hono
├── docker-compose.yml          # Local dev (postgres, pgbouncer, services)
├── .github/
│   ├── actions/discord-notify/ # Reusable Discord action
│   └── workflows/              # 6 CI/CD workflows
├── pgbouncer/                  # Connection pooling config
├── nginx/                      # Reverse proxy config
├── nomad/                      # Nomad job definitions
├── stack/                      # Docker Swarm stack
├── scripts/                    # Deployment scripts
└── docs/                       # This documentation
```

See [PROJECT_STRUCTURE.txt](PROJECT_STRUCTURE.txt) for detailed breakdown.

## ⚙️ CI/CD Workflows

| Workflow | Trigger | Purpose | Location |
|----------|---------|---------|----------|
| **ci.yml** | Any push/PR | Build & push images | [.github/workflows/ci.yml](.github/workflows/ci.yml) |
| **deploy-staging.yml** | Push to `develop` | Deploy to staging | [.github/workflows/deploy-staging.yml](.github/workflows/deploy-staging.yml) |
| **deploy-production.yml** | Push to `main` | Deploy to production | [.github/workflows/deploy-production.yml](.github/workflows/deploy-production.yml) |
| **notify-issue.yml** | New issue opened | Discord + bot comment | [.github/workflows/notify-issue.yml](.github/workflows/notify-issue.yml) |
| **notify-pr.yml** | PR opened/reopened | Discord notification | [.github/workflows/notify-pr.yml](.github/workflows/notify-pr.yml) |
| **lint-test.yml** | Any push/PR | Optional linting/tests | [.github/workflows/lint-test.yml](.github/workflows/lint-test.yml) |

## 🔧 Quick Reference

### Local Development
```bash
docker-compose up --build
# Frontend: http://localhost:8080
# Backend: http://localhost:3000
```

### GitHub Secrets (7 required)
- `DISCORD_WEBHOOK` — Discord webhook URL
- `STAGE_HOST` — Staging server IP/hostname
- `PROD_HOST` — Production server IP/hostname
- `DEPLOY_USER` — SSH user (default: `deploy`)
- `SSH_PRIVATE_KEY` — Private SSH key for deployments
- `STAGE_APP_URL` — Staging application URL
- `PROD_APP_URL` — Production application URL

See [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md#step-1-create-repository-secrets) for setup.

### Deployment Flow
```
Push to develop → CI builds → Deploy to staging → Notify Discord
Push to main → CI builds → Deploy to prod → Notify Discord
```

### Docker Swarm (on server)
```bash
docker stack deploy -c stack/docker-stack.yml app_prod
docker service ls
docker service logs app_prod_backend
```

### Nomad (on server)
```bash
nomad job run nomad/backend.nomad
nomad status backend
nomad logs -f backend -task api
```

## 📖 Reading Guide

### By Role

**DevOps/Infrastructure:**
1. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System design
2. [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — Server setup
3. [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md) — CI/CD config

**Developers:**
1. [QUICKSTART.md](QUICKSTART.md) — Quick start
2. [README.md](README.md) — Project overview
3. [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md) — How CI/CD works

**DevOps + Backend Developer:**
1. [README.md](README.md) — Full stack overview
2. [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md) — Secrets & workflows
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System design

### By Task

**Set up GitHub Actions CI/CD:**
→ [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)

**Deploy to staging/production:**
→ [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)

**Understand system architecture:**
→ [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

**Run locally:**
→ [QUICKSTART.md](QUICKSTART.md) or [README.md](README.md)

**Fix deployment issues:**
→ [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting) or [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md#debugging-failed-workflows)

## 🎯 Common Tasks

### 1. Set up CI/CD (first time)
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Follow [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md#step-1-create-repository-secrets) (5 minutes)
3. Test by pushing to GitHub

### 2. Set up staging/production servers
1. Read [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#prerequisites-on-stagingproduction-servers)
2. Run setup script: `bash scripts/setup-server.sh`
3. Add SSH key to authorized_keys
4. Install Docker

### 3. Deploy to production
1. Push code to `develop` (stages to staging automatically)
2. Test on staging (staging URL in Discord message)
3. Create PR and merge to `main`
4. Production deployment runs automatically
5. Check Discord for production URL

### 4. Debug a failed deployment
1. Check GitHub Actions logs: **Repo → Actions → [failed workflow]**
2. Click the failed step for error details
3. See common fixes in [docs/GITHUB_ACTIONS.md#troubleshooting](docs/GITHUB_ACTIONS.md#troubleshooting) or [docs/DEPLOYMENT.md#troubleshooting](docs/DEPLOYMENT.md#troubleshooting)

### 5. Add a new environment (test, preview, etc.)
1. Duplicate `deploy-staging.yml` workflow
2. Change trigger branch (e.g., `test/*`)
3. Add new secrets (`TEST_HOST`, `TEST_APP_URL`)
4. Push and test

## 📋 Tech Stack

- **Frontend:** React 18 + Vite + TypeScript + Zustand + TanStack Query/Router + shadcn UI + Tailwind
- **Backend:** Bun + Hono + Zod (+ Drizzle ORM ready)
- **Database:** PostgreSQL 17 + PGBouncer
- **Proxy:** Nginx
- **Orchestration:** Docker Swarm & Nomad
- **CI/CD:** GitHub Actions
- **Registry:** GHCR (GitHub Container Registry)
- **Notifications:** Discord webhooks
- **Object Storage:** Wasabi S3 (optional)

## 📞 Support

### Finding Answers

1. **Quick questions?** → Check [QUICKSTART.md](QUICKSTART.md)
2. **Secrets/workflows?** → Check [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)
3. **Deployment issues?** → Check [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting)
4. **System design?** → Check [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
5. **Not found?** → Check full [README.md](README.md)

### Common Issues

- **CI fails to build** → Check [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md#debugging-failed-workflows)
- **SSH deployment fails** → Check [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting)
- **Discord notifications not sent** → Check [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md#discord-message-not-sent)
- **PGBouncer connection error** → Check [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#pgbouncer-connection-issues)

## 🚀 Next Steps

1. ✅ Read [QUICKSTART.md](QUICKSTART.md)
2. ✅ Configure GitHub secrets (5 min) — [docs/GITHUB_ACTIONS.md](docs/GITHUB_ACTIONS.md)
3. ✅ Test locally — `docker-compose up --build`
4. ✅ Push to GitHub and test CI/CD
5. ✅ Deploy to staging (develop branch)
6. ✅ Deploy to production (main branch)
7. 📋 Implement authentication (JWT)
8. 📋 Add Drizzle ORM migrations
9. 📋 Set up monitoring (Prometheus, Grafana)
10. 📋 Configure HTTPS (Let's Encrypt)

---

## 📑 All Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| **QUICKSTART.md** | 5-minute overview & setup | Everyone |
| **README.md** | Full project documentation | Everyone |
| **docs/GITHUB_ACTIONS.md** | Secrets, workflows, debugging | DevOps, Developers |
| **docs/DEPLOYMENT.md** | Server setup, manual deploy | DevOps, SREs |
| **docs/ARCHITECTURE.md** | System design, scaling | Architects, DevOps |
| **.env.example** | Environment variables template | Developers |
| **PROJECT_STRUCTURE.txt** | Directory tree & quick commands | Everyone |
| **docs/INDEX.md** | This file | Navigation |

---

Happy deploying! 🚀

**Still need help?** Start with [QUICKSTART.md](QUICKSTART.md)
