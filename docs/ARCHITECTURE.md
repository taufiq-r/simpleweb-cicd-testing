# Architecture & Infrastructure Design

## Overview

This project follows a modular, scalable infrastructure design with:
- **Frontend**: React + Vite served via Nginx
- **Backend**: Bun + Hono API server
- **Database**: PostgreSQL 17 with pgbouncer connection pooling
- **Orchestration**: Docker Swarm or Nomad for service orchestration
- **CI/CD**: GitHub Actions with automated builds, pushes, and deployments
- **Object Storage**: Wasabi S3 (optional)

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub / Git Push                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           v
        ┌──────────────────────────────────────┐
        │   GitHub Actions CI/CD Pipeline      │
        │  - Build images                      │
        │  - Push to GHCR                      │
        │  - Deploy to servers                 │
        │  - Notify Discord                    │
        └──────────────────┬───────────────────┘
                           │
                ┌──────────┴──────────┐
                v                     v
          ┌─────────────┐      ┌──────────────┐
          │   Staging   │      │  Production  │
          │   Server    │      │   Server(s)  │
          └────┬────────┘      └───────┬──────┘
               │                       │
        ┌──────v──────────────────────v──────┐
        │   Docker Swarm / Nomad              │
        │   Service Orchestration             │
        └──────┬───────────────────────┬──────┘
               │                       │
    ┌──────────v────────┐   ┌─────────v────────┐
    │  Frontend Stack   │   │  Backend Stack   │
    ├──────────────────┤   ├──────────────────┤
    │ React App        │   │ Hono API Server  │
    │ (Port 80)        │   │ (Port 3000)      │
    └──────────┬───────┘   └────────┬─────────┘
               │                    │
               └────────┬───────────┘
                        │
                   ┌────v────┐
                   │  Nginx  │
                   │ (Proxy) │
                   │(Port 80)│
                   └────┬────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
    ┌───v────┐                   ┌─────v──────┐
    │ /       │                   │ /api/*     │
    │ React   │                   │ Backend    │
    └─────────┘                   └────────────┘


┌────────────────────────────────────────────────────────────────┐
│                    Shared Infrastructure                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────┐                                         │
│  │   PostgreSQL     │         ┌──────────────┐               │
│  │      (17)        │────────→│  PGBouncer   │               │
│  │                  │         │ (Connection  │               │
│  │   - appdb        │         │   Pooling)   │               │
│  │   - Multi-tenant │         └──────────────┘               │
│  └──────────────────┘          (Port 6432)                   │
│                                                                │
│  ┌──────────────────┐          (Optional)                    │
│  │ Wasabi S3        │  ←── Backend & Frontend               │
│  │ (Object Storage) │       Object uploads/downloads         │
│  └──────────────────┘                                         │
│                                                                │
│  ┌──────────────────┐                                         │
│  │ Discord Webhooks │  ← GitHub Actions notifications        │
│  │  (Notifications) │                                         │
│  └──────────────────┘                                         │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Component Breakdown

### 1. Frontend (React + Vite + TypeScript)

**Stack:**
- React 18.2
- Vite (fast build tool)
- TypeScript for type safety
- Zustand (lightweight state management)
- TanStack Query (data fetching & caching)
- TanStack Router (file-based routing)
- shadcn UI + Tailwind CSS 4
- Tabler/Iconly icons
- Zod (schema validation)

**Deployment:**
- Docker image: node:18-alpine + nginx:alpine
- Listening on port 80
- Served via Nginx reverse proxy

### 2. Backend (Bun + Hono)

**Stack:**
- Bun (runtime)
- Hono (lightweight HTTP handler)
- TypeScript
- Drizzle ORM (placeholder; implement migrations)
- Zod (validation)
- JWT authentication (implement custom)
- Scalar (OpenAPI documentation)

**Deployment:**
- Docker image: oven/bun:latest
- Listening on port 3000
- Connected to pgbouncer for database access

**API Routes:**
- `GET /` → Health check
- `GET /api/health` → Detailed health check
- `POST /api/auth/login` → (implement)
- `POST /api/auth/refresh` → (implement)
- `GET /api/users` → (implement with RBAC)

### 3. Database (PostgreSQL 17 + PGBouncer)

**PostgreSQL:**
- Version 17
- Database: `appdb` (default)
- User: `app` (with changeable password)
- Support for multi-tenant schema (partition by tenant_id)

**PGBouncer (Connection Pooler):**
- Runs on port 6432
- Pool mode: `transaction` (connection released per transaction)
- Max connections: 100 clients
- Default pool size: 20 per database
- Auth type: MD5

**Multi-Tenant:**
1. Add tenant column to relevant tables
2. Implement Row Level Security (RLS) in PostgreSQL
3. Use PGBouncer to route connections

### 4. Reverse Proxy (Nginx)

**Features:**
- Single entry point (port 80)
- Routes `/api/*` → Backend (Hono)
- Routes `/` → Frontend (React)
- Can add SSL/TLS termination
- Can add load balancing to multiple backend instances

### 5. CI/CD Pipeline (GitHub Actions)

**Workflows:**

| Workflow | Trigger | Actions |
|----------|---------|---------|
| **CI** | Any push/PR | Build frontend + backend images, push to GHCR, notify Discord |
| **Deploy Staging** | Push to `develop` | Build, SSH deploy, notify Discord with staging URL |
| **Deploy Production** | Push to `main` | Build, SSH deploy, notify Discord with prod URL |
| **Notify Issue** | New issue | Send Discord notification, post bot comment |
| **Notify PR** | PR opened/reopened | Send Discord notification |

### 6. Orchestration (Docker Swarm or Nomad)

**Docker Swarm:**
- Simple, built-in to Docker
- `docker stack deploy -c docker-stack.yml app_prod`
- Service discovery via internal DNS
- Rolling updates with constraints

**Nomad:**
- More advanced scheduling
- Service discovery via Consul
- Multi-region/multi-cloud support
- Better bin-packing and resource allocation

## Authentication & Authorization

### Token Flow
1. **Login** → Generate access_token (short-lived) + refresh_token (long-lived)
2. **Request** → Include access_token in Authorization header or cookie
3. **Refresh** → Use refresh_token to get new access_token when expired
4. **Logout** → Invalidate refresh_token in database or cache

### Authorization Models

Implement one of:
- **RBAC** (Role-Based): Users have roles (admin, user, viewer); routes check role
- **ABAC** (Attribute-Based): Policies check user attributes (department, project, etc.)
- **RBA** (Resource-Based): Permissions attached to resources (can be checked in backend)

Example Hono middleware:
```typescript
app.use('/api/admin/*', authenticate, authorize(['admin']))
```

## Data Flow: Request → Response

1. **Frontend** sends request to Nginx on port 80
2. **Nginx** routes to Backend on port 3000 (for `/api/*`) or Frontend (for `/`)
3. **Backend** processes request:
   - Validates input with Zod
   - Checks authentication/authorization
   - Queries database via pgbouncer (port 6432)
   - Returns JSON response
4. **Frontend** receives response, updates state (Zustand), re-renders UI

## Deployment Pipeline (Simplified)

```
1. Developer pushes to GitHub
   ↓
2. CI workflow triggers:
   - npm install (frontend)
   - npm build (frontend)
   - bun install (backend)
   - docker build (both)
   - docker push to GHCR
   ↓
3. If push to develop:
   - Deploy workflow triggers
   - SSH into staging server
   - docker pull images
   - docker stack deploy (or nomad job run)
   - Run health checks
   ↓
4. If push to main:
   - Deploy workflow triggers
   - SSH into production server
   - docker pull images
   - docker stack deploy
   - Run health checks
   ↓
5. Discord notification sent with:
   - Success: staging/prod URL
   - Failure: error log link
```

## Scaling Considerations

### Horizontal Scaling

**Frontend:**
- Static files served by Nginx
- No state to share
- Add more Nginx replicas behind load balancer
- Serve assets from CDN (CloudFlare, AWS CloudFront)

**Backend:**
- Stateless Hono server
- Can run multiple replicas
- Use database connection pooling (pgbouncer)
- Add load balancer (Nginx or cloud provider)

**Database:**
- Single primary PostgreSQL (scale reads with replicas)
- Read replicas can serve read-heavy queries
- pgbouncer sits in front of primary + replicas

### Caching

- **Frontend**: TanStack Query with stale-while-revalidate
- **Backend**: Redis (optional; implement for frequently accessed data)
- **CDN**: Cache static assets globally

### Monitoring & Logging

- **Prometheus**: Collect metrics (request latency, error rates)
- **Grafana**: Visualize metrics
- **ELK Stack**: Aggregate logs (Elasticsearch, Logstash, Kibana)
- **Jaeger**: Distributed tracing

## Security

1. **Database**: Use MD5/SCRAM auth, limit network access
2. **Secrets**: GitHub Actions secrets (not in code)
3. **API**: HTTPS/TLS, CORS headers, rate limiting
4. **Frontend**: Content Security Policy (CSP), XSS protection
5. **SSH Keys**: Strong 4096-bit RSA keys, restricted deploy user

## Environment Configuration

| Environment | Branch | Server | URL |
|---|---|---|---|
| **Local** | (any) | Docker Compose | http://localhost |
| **Staging** | `develop` | Staging server | https://staging.example.com |
| **Production** | `main` | Production server(s) | https://example.com |

---

For deployment steps, see [DEPLOYMENT.md](DEPLOYMENT.md)
For setup instructions, see [README.md](../README.md)
