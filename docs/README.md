# Services Documentation

This directory contains documentation for all services running in the k3s homelab.

## Service Categories

- [Authentication](#authentication)
- [Media](#media)
- [Network & Infrastructure](#network--infrastructure)
- [Productivity](#productivity)
- [Gaming](#gaming)
- [Communication](#communication)
- [Development](#development)
- [Management & Dashboard](#management--dashboard)

---

## Authentication

### [LLDAP](lldap.md) - Lightweight LDAP Server
- **Namespace:** `auth`
- **Purpose:** Central authentication directory for all homelab services
- **URL:** https://ldap.picklemustard.dev
- **Ports:** 3890 (LDAP), 17170 (HTTP UI)
- **Storage:** 10Gi PVC (`lldap-data`)

### [Authelia](authelia.md) - Single Sign-On Provider
- **Namespace:** `lldap`
- **Purpose:** 2FA authentication and SSO middleware for web applications
- **URL:** https://auth.picklemustard.dev
- **Port:** 9091
- **Storage:** 1Gi PVC (`authelia-data-pvc`)
- **Integrations:** LLDAP, Stalwart Mail

### [Vaultwarden](vaultwarden.md) - Password Manager
- **Namespace:** `vaultwarden`
- **Purpose:** Self-hosted Bitwarden-compatible password manager
- **URL:** https://vault.picklemustard.dev
- **Port:** 80
- **Database:** PostgreSQL (postgres.svc.cluster.local)
- **Features:** Push notifications, SMTP email, Bitwarden client compatible

### [Vaultwarden-LDAP](vaultwarden-ldap.md) - LDAP Integration
- **Namespace:** `vaultwarden`
- **Purpose:** LDAP authentication integration for Vaultwarden
- **Integration:** Connects Vaultwarden with LLDAP for centralized authentication
- **Features:** LDAP-based user authentication, user synchronization

---

## Media

### [Jellyfin](jellyfin.md) - Media Server
- **Namespace:** `media`
- **Purpose:** Stream and organize media files (movies, TV shows, music)
- **URL:** https://jellyfin.picklemustard.dev
- **Port:** 8096
- **Hardware:** NVIDIA GPU for transcoding
- **Storage:** 
  - `media-data` - Media files storage
  - `jellyfin-data` - Configuration data (10Gi)

### [Starr Stack](starr.md) - Media Management
- **Namespace:** `media`
- **Services:** Sonarr (TV shows), Radarr (movies)
- **Purpose:** Automate downloading and organizing media content
- **Note:** Configuration files stored in `starr-config/`

---

## Network & Infrastructure

### [Traefik](traefik.md) - Ingress Controller & Reverse Proxy
- **Namespace:** `traefik`
- **Purpose:** Entry point for all external traffic, SSL termination, routing
- **Ports:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- **Dashboard:** https://traefik.picklemustard.dev
- **Features:** Automatic HTTPS, Let's Encrypt certificates, dynamic configuration

### [AdGuard Home](adguard.md) - DNS Server & Ad Blocker
- **Deployment:** Docker Compose (not Kubernetes)
- **Purpose:** DNS filtering, ad blocking, network-level protection
- **Configuration:** Stored in `adguard/conf/` and `adguard/work/`

### [Cloudflare DDNS](cloudflare-ddns.md) - Dynamic DNS
- **Deployment:** Docker Compose (not Kubernetes)
- **Purpose:** Automatically update Cloudflare DNS records for dynamic IP
- **Configuration:** Stored in `cloudflare-ddns/docker-compose.yml`

---

## Productivity

### [Firefly III](firefly.md) - Personal Finance Manager
- **Namespace:** `finance` (Helm)
- **Purpose:** Track personal finances, budgets, transactions
- **URL:** https://firefly.picklemustard.dev
- **Features:** Transaction importing, budgeting, account management
- **Components:** Firefly III, Firefly Importer

### [Nextcloud](nextcloud.md) - File Share & Collaboration Platform
- **Namespace:** `nextcloud` (Helm)
- **Purpose:** Self-hosted file storage, synchronization, and collaboration
- **URL:** https://nextcloud.picklemustard.dev
- **Database:** PostgreSQL (postgres.svc.cluster.local)
- **Features:** File storage, calendar, contacts, document editing, video conferencing

---

## Gaming

### [Pterodactyl](pterodactyl.md) - Game Server Panel
- **Namespace:** `pterodactyl`
- **Purpose:** Manage and deploy game servers (Minecraft, etc.)
- **URL:** https://pterodactyl.picklemustard.dev
- **Port:** 80
- **Database:** PostgreSQL (postgres.svc.cluster.local)
- **Cache:** Redis (redis.svc.cluster.local)
- **Storage:**
  - `pterodactyl-app-claim` - Application data
  - `pterodactyl-nginx-claim` - Nginx configuration
  - `pterodactyl-le-claim` - Let's Encrypt certificates
  - `pterodactyl-logs-claim` - Application logs

### [Minecraft Servers](minecraft.md)
- **Namespace:** `minecraft`
- **Purpose:** Minecraft server hosting
- **Deployment:** Agones (Kubernetes game server operator)
- **Configs:**
  - `itzg-config/` - itzg/minecraft-server configuration
  - `shulker-config/` - Shulker management configuration
  - `bukkit-configmap.yml` - Bukkit server properties
  - `spigot-configmap.yml` - Spigot server properties

### [Agones](agones.md) - Game Server Operator
- **Namespace:** `agones-system`
- **Purpose:** Kubernetes game server orchestration platform
- **Components:** Controller, Allocator, Extensions, Ping Service
- **Use Case:** Provides infrastructure for Minecraft server management

---

## Communication

### [Stalwart Mail](stalwart.md) - Mail Server
- **Namespace:** `stalwart`
- **Purpose:** Full-featured IMAP/SMTP email server
- **URL:** https://mail.picklemustard.dev (web UI)
- **Ports:**
  - 25 (SMTP), 587 (Submission), 465 (Submissions)
  - 143 (IMAP), 993 (IMAPS)
  - 110 (POP3), 995 (POP3S)
  - 14190 (Sieve)
- **Storage:** 50Gi PVC (`stalwart`)
- **Features:** TLS encryption, spam filtering, Sieve filters

---

## Development

### [PostgreSQL](postgres.md) - Database Service
- **Namespace:** `postgres`
- **Purpose:** Shared PostgreSQL database for multiple services
- **Deployment:** Helm chart
- **Port:** 5432
- **Clients:** Vaultwarden, Pterodactyl, Firefly III, Nextcloud
- **Authentication:** LDAP integration with LLDAP

### [Redis](redis.md) - In-Memory Data Store
- **Namespace:** `redis`
- **Purpose:** Caching and message queue for Pterodactyl
- **Deployment:** Helm chart
- **Port:** 6379

### [Nextcloud](nextcloud.md) - File Share & Collaboration
- **Namespace:** `nextcloud`
- **Purpose:** Self-hosted file storage, synchronization, and collaboration platform
- **URL:** https://nextcloud.picklemustard.dev
- **Database:** PostgreSQL (postgres.svc.cluster.local)
- **Features:** File storage, calendar, contacts, document editing, video conferencing

## Management & Dashboard

### [Homarr](homarr.md) - Dashboard
- **Namespace:** `homarr`
- **Purpose:** Centralized dashboard for all self-hosted services
- **URL:** http://dashboard.andromeda.picklemustard.dev
- **Features:** Customizable widgets, service status, quick access, Docker integration

---

## Certificate Management

### cert-manager
- **Purpose:** Automated TLS certificate management
- **Issuer:** Let's Encrypt ACME
- **Configuration:** `cert-manager-acme-issuer.yaml`

---

## Architecture Overview

```
External Traffic
       ↓
   Traefik (Ingress)
       ↓
   Services (by namespace)
       ├─ auth: LLDAP, Authelia
       ├─ media: Jellyfin, Sonarr, Radarr
       ├─ vaultwarden: Vaultwarden, Vaultwarden-LDAP
       ├─ pterodactyl: Pterodactyl Panel
       ├─ minecraft: Minecraft Servers
       ├─ stalwart: Stalwart Mail
       ├─ finance: Firefly III
       ├─ nextcloud: Nextcloud
       ├─ homarr: Homarr Dashboard
       ├─ agones-system: Agones Game Server Operator
       └─ postgres, redis: Data stores
```

## Common Patterns

### Authentication Flow
1. User accesses service (e.g., Vaultwarden)
2. Authelia intercepts request
3. User authenticates with LLDAP credentials
4. Authelia issues session
5. User granted access to service

### Database Connections
- **PostgreSQL:** `postgres-postgresql.postgres.svc.cluster.local:5432`
- **Redis:** `redis-master.redis.svc.cluster.local:6379`

### Naming Convention
- Services: `<service>.picklemustard.dev`
- Secrets: `<service>-credentials` or `<service>-env`
- PVCs: `<service>-data` or descriptive name

---

## Maintenance

### Backup Strategy
- Regular backups of PVCs using Velero (if configured)
- Critical services: LLDAP, Vaultwarden, PostgreSQL, Stalwart Mail

### Monitoring
- Check pod status: `kubectl get all -n <namespace>`
- View logs: `kubectl logs -f deployment/<name> -n <namespace>`
- Ingress issues: Check Traefik dashboard

### Common Commands
```bash
# Apply all files in a directory
kubectl apply -f <service>/

# Describe a deployment
kubectl describe deployment <name> -n <namespace>

# Check ingress
kubectl get ingress -n <namespace>

# Validate YAML
kubectl apply --dry-run=client -f <file.yml>
```

---

## Troubleshooting

### Services Not Accessible
1. Check Ingress: `kubectl get ingress -n <namespace>`
2. Check Traefik dashboard for routing issues
3. Verify DNS records point to cluster IP
4. Check firewall rules

### Authentication Issues
1. Verify LLDAP is running: `kubectl get pods -n auth`
2. Check Authelia logs: `kubectl logs -f deployment/authelia -n lldap`
3. Verify secret references in deployments

### Storage Issues
1. Check PVC status: `kubectl get pvc -n <namespace>`
2. Verify storage class: `kubectl get storageclass`
3. Check disk space on nodes

---

See individual service documentation files for detailed information.
