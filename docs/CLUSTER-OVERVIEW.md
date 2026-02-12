# K3s Homelab Cluster Documentation

This document provides a comprehensive overview of the k3s homelab cluster, including infrastructure, services, and architecture.

## Cluster Overview

### Platform
- **Kubernetes Distribution:** k3s (lightweight Kubernetes)
- **Server Version:** Latest (managed via Rancher)
- **Cluster Name:** auth-context
- **API Server:** https://192.168.1.210:6443
- **Storage Class:** `local-path` (default)
- **Ingress Controller:** Traefik v2

### Infrastructure
- **Location:** Homelab environment
- **Network:** 192.168.1.x subnet
- **External Access:** Traefik LoadBalancer (192.168.1.142)
- **DNS:** Cloudflare DDNS (picklemustard.dev)
- **TLS:** Managed by Traefik and cert-manager

## Namespace Organization

The cluster is organized into the following namespaces:

### Core Infrastructure
- `default` - Default namespace for general resources
- `kube-system` - Kubernetes system components
- `kube-public` - Public resources
- `kube-node-lease` - Node lease management

### Services
- `auth` - Authentication services (LLDAP)
- `lldap` - Authelia deployment
- `media` - Media services (Jellyfin, Sonarr, Radarr)
- `vaultwarden` - Password manager and LDAP integration
- `pterodactyl` - Game server panel
- `minecraft` - Minecraft servers
- `stalwart` - Email server
- `postgres` - PostgreSQL database
- `redis` - Redis cache
- `finance` - Firefly III (not yet deployed)
- `nextcloud` - File storage and collaboration (not yet deployed)
- `homarr` - Dashboard (not yet deployed)
- `agones-system` - Game server operator

### Infrastructure
- `cert-manager` - Certificate management
- `traefik` - Ingress controller (kube-system)

## Service Architecture

### Authentication Flow
```
User Request
    ↓
Traefik Ingress
    ↓
Authelia (2FA/SSO)
    ↓
LLDAP (LDAP Auth)
    ↓
Service (Application)
```

### Database Layer
```
PostgreSQL (postgres namespace)
    ├─ Vaultwarden Database
    ├─ Pterodactyl Database
    ├─ Firefly III Database
    ├─ Nextcloud Database
    └─ Other Applications

Redis (redis namespace)
    └─ Pterodactyl Cache
```

### Network Layer
```
External Traffic
    ↓
Cloudflare DNS
    ↓
Traefik LoadBalancer (192.168.1.142)
    ├─ HTTP/HTTPS (80/443)
    ├─ LDAP (3890)
    ├─ Authelia (9091)
    ├─ PostgreSQL (5432)
    ├─ Minecraft (25565)
    └─ Email Ports (25, 587, 465, 143, 993, 110, 995, 4190)
    ↓
Services (by namespace)
```

## Core Components

### Traefik (Ingress Controller)
- **Version:** 34.2.0
- **Deployment:** Helm Chart
- **Namespace:** `kube-system`
- **LoadBalancer IP:** 192.168.1.142
- **Dashboard:** https://traefik-kube.picklemustard.dev
- **Ports:**
  - 80 (HTTP/web)
  - 443 (HTTPS/websecure)
  - 3890 (LDAP)
  - 9091 (Authelia)
  - 5432 (PostgreSQL)
  - 25565 (Minecraft)
  - 25, 587, 465, 143, 993, 110, 995, 4190 (Email)
- **Features:**
  - Automatic SSL termination
  - Dynamic configuration
  - Load balancing
  - Health checks

### Local-Path Storage
- **Storage Class:** `local-path`
- **Path:** `/opt/local-path-provisioner`
- **Type:** ReadWriteOnce
- **Provisioning:** Automatic on PVC creation
- **Capacity:** Per-node storage availability

### cert-manager
- **Namespace:** `cert-manager`
- **Issuer:** Let's Encrypt ACME
- **Purpose:** Automated TLS certificate management
- **Components:**
  - cert-manager
  - cert-manager-cainjector
  - cert-manager-webhook

## Authentication Services

### LLDAP
- **Purpose:** Lightweight LDAP directory
- **Namespace:** `auth`
- **Port:** 3890 (LDAP), 17170 (HTTP UI)
- **Storage:** 10Gi PVC
- **Base DN:** `dc=andromeda,dc=picklemustard,dc=dev`
- **Integration:** All services use LLDAP for authentication

### Authelia
- **Purpose:** SSO and 2FA provider
- **Namespace:** `lldap`
- **Port:** 9091
- **Storage:** 1Gi PVC
- **Features:**
  - 2FA (TOTP, WebAuthn)
  - Single Sign-On
  - Access control rules
  - LDAP integration

## Application Services

### Media Services
- **Jellyfin:** Media streaming server with GPU transcoding
- **Sonarr:** TV show management
- **Radarr:** Movie management
- **Prowlarr:** Indexer management
- **Bazarr:** Subtitle management
- **Namespace:** `media`

### Productivity Services
- **Vaultwarden:** Password manager
- **Vaultwarden-LDAP:** LDAP integration for Vaultwarden
- **Firefly III:** Personal finance management
- **Nextcloud:** File storage and collaboration

### Gaming Services
- **Pterodactyl:** Game server panel
- **Minecraft:** Multiple Minecraft servers via Agones
- **Agones:** Game server orchestration

### Communication Services
- **Stalwart Mail:** Full-featured email server
  - SMTP, IMAP, POP3
  - Spam filtering
  - Sieve filters
  - TLS encryption

### Dashboard Services
- **Homarr:** Centralized dashboard for all services

## Infrastructure Services

### Database
- **PostgreSQL:** Shared database service
  - Port: 5432
  - Namespace: `postgres`
  - LDAP authentication enabled
  - Clients: Vaultwarden, Pterodactyl, Firefly III, Nextcloud

### Cache
- **Redis:** In-memory cache
  - Port: 6379
  - Namespace: `redis`
  - Sentinel: Enabled
  - Client: Pterodactyl

### DNS
- **AdGuard Home:** DNS filtering and ad blocking
  - Deployment: Docker Compose
  - Location: Outside Kubernetes

### Dynamic DNS
- **Cloudflare DDNS:** Automatic DNS updates
  - Deployment: Docker Compose
  - Location: Outside Kubernetes

## External Services

### Cloudflare
- **DNS Provider:** Cloudflare
- **DDNS:** Automatic IP updates
- **DNS Records:** All services use `*.picklemustard.dev`

### Certificates
- **CA:** Let's Encrypt
- **Management:** cert-manager + Traefik
- **Domains:** `*.picklemustard.dev`

## Storage Architecture

### Persistent Volume Claims
- **Storage Class:** `local-path`
- **Access Mode:** ReadWriteOnce (RWO)
- **Provisioning:** Dynamic
- **Reclaim Policy:** Retain (for important data)

### Storage Locations
- `/opt/local-path-provisioner/` - Default storage path
- `/srv/media/` - Media files (hostPath for Jellyfin)
- Custom paths for specific services

## Network Configuration

### LoadBalancer
- **IP:** 192.168.1.142
- **Provider:** MetalLB (likely)
- **Type:** External Traffic Policy

### Internal DNS
- **Cluster DNS:** CoreDNS (k3s default)
- **Service Discovery:** `<service>.<namespace>.svc.cluster.local`
- **Example:** `postgres-postgresql.postgres.svc.cluster.local:5432`

### Service Naming Convention
- **External:** `<service>.picklemustard.dev`
- **Internal:** `<service>.<namespace>.svc.cluster.local`
- **Examples:**
  - jellyfin.picklemustard.dev → jellyfin.media.svc.cluster.local
  - vault.picklemustard.dev → vaultwarden.vaultwarden.svc.cluster.local

## Security

### Authentication
- **Central Auth:** LLDAP + Authelia
- **2FA:** Enforced via Authelia
- **LDAP:** All services use LDAP where possible

### Encryption
- **TLS:** Automatic via Traefik and cert-manager
- **Email:** STARTTLS/TLS for email services
- **Secrets:** Kubernetes secrets for sensitive data

### Network Security
- **Ingress:** Traefik with access control
- **DNS Filtering:** AdGuard Home
- **Firewall:** Port restrictions (only necessary ports exposed)

## Monitoring & Management

### Cluster Management
- **Rancher:** Cluster management UI (https://rancher.picklemustard.dev)
- **Traefik Dashboard:** Ingress monitoring
- **kubectl:** Command-line management

### Logging
- **Application Logs:** `kubectl logs -f deployment/<name> -n <namespace>`
- **System Logs:** k3s logs
- **Service Logs:** Individual service logging

### Backup Strategy
- **PVCs:** Manual backup of critical data
- **Databases:** PostgreSQL dumps
- **Configuration:** Git repository
- **Certificates:** Auto-renewed by cert-manager

## Deployment Patterns

### Standard Service Deployment
1. Create namespace (if needed)
2. Create PVCs for storage
3. Create ConfigMaps for configuration
4. Create Secrets for sensitive data
5. Create Deployment
6. Create Service
7. Create Ingress for external access

### Helm Chart Deployment
1. Create namespace
2. Create secrets
3. Create values file
4. Install using Helm
5. Configure ingress

### Docker Compose Deployment
1. Create docker-compose.yml
2. Run `docker-compose up -d`
3. Configure DNS records

## Common Commands

### Deployment
```bash
# Apply all files in directory
kubectl apply -f <service>/

# Apply specific file
kubectl apply -f <file.yml>

# Helm install
helm install --namespace <ns> <name> <chart> -f values.yml

# Update deployment
kubectl rollout restart deployment/<name> -n <namespace>
```

### Monitoring
```bash
# Get all resources
kubectl get all -n <namespace>

# Get pods
kubectl get pods -A

# Get deployments
kubectl get deployments -A

# Get services
kubectl get services -A

# Get ingress
kubectl get ingress -A
```

### Logs
```bash
# View deployment logs
kubectl logs -f deployment/<name> -n <namespace>

# View pod logs
kubectl logs -f <pod-name> -n <namespace>

# Previous pod logs
kubectl logs --previous <pod-name> -n <namespace>
```

### Troubleshooting
```bash
# Describe resource
kubectl describe deployment/<name> -n <namespace>

# Check events
kubectl get events -n <namespace>

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- sh

# Port forward
kubectl port-forward -n <namespace> deployment/<name> <local-port>:<container-port>
```

## Service URLs

### Authentication
- LLDAP: https://ldap.picklemustard.dev
- Authelia: https://auth.picklemustard.dev

### Media
- Jellyfin: https://jellyfin.picklemustard.dev
- Sonarr: https://media-docs.picklemustard.dev
- Radarr: (To be configured)

### Productivity
- Vaultwarden: https://vault.picklemustard.dev
- Firefly III: https://firefly.picklemustard.dev
- Nextcloud: https://nextcloud.picklemustard.dev

### Gaming
- Pterodactyl: https://pterodactyl.picklemustard.dev
- Minecraft: minecraft.picklemustard.dev:25565

### Communication
- Stalwart Mail: https://mail.picklemustard.dev

### Infrastructure
- Traefik Dashboard: https://traefik-kube.picklemustard.dev
- Rancher: https://rancher.picklemustard.dev
- Homarr: http://dashboard.andromeda.picklemustard.dev

## Maintenance

### Regular Tasks
- **Daily:** Monitor pod health and logs
- **Weekly:** Check certificate expiration
- **Monthly:** Review storage usage and cleanup
- **Quarterly:** Update services and dependencies

### Backup Checklist
- [ ] LLDAP data directory
- [ ] Vaultwarden database
- [ ] PostgreSQL dumps
- [ ] Stalwart Mail data
- [ ] Jellyfin configuration
- [ ] Minecraft server worlds
- [ ] Nextcloud data

### Update Process
1. Update Git repository
2. Apply configuration changes
3. Rollout restart affected services
4. Verify functionality
5. Monitor logs for issues

## Troubleshooting

### Common Issues

#### Services Not Accessible
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check service status: `kubectl get svc -n <namespace>`
3. Check ingress: `kubectl get ingress -n <namespace>`
4. Verify DNS records
5. Check Traefik dashboard

#### Authentication Failures
1. Verify LLDAP is running: `kubectl get pods -n auth`
2. Check Authelia logs: `kubectl logs -f deployment/authelia -n lldap`
3. Verify secret references
4. Check LDAP connectivity

#### Storage Issues
1. Check PVC status: `kubectl get pvc -n <namespace>`
2. Verify storage class: `kubectl get storageclass`
3. Check disk space on nodes
4. Review pod events

#### Certificate Issues
1. Check cert-manager: `kubectl get pods -n cert-manager`
2. Review certificate status: `kubectl get certificates -A`
3. Check ACME challenges
4. Verify DNS configuration

### Emergency Procedures

#### Restart All Services
```bash
kubectl rollout restart deployment --all -A
```

#### Restore from Backup
1. Stop affected services
2. Restore PVC from backup
3. Restart services
4. Verify data integrity

#### Cluster Recovery
1. Check k3s status: `systemctl status k3s`
2. Review logs: `journalctl -u k3s -f`
3. Restart k3s if needed: `systemctl restart k3s`

## Future Enhancements

### Planned Additions
- [ ] Monitoring stack (Prometheus, Grafana)
- [ ] Log aggregation (ELK/Loki)
- [ ] Automated backups (Velero)
- [ ] CI/CD pipelines
- [ ] Service mesh (Istio/Linkerd)

### Improvements
- [ ] Enable Prometheus metrics in Traefik
- [ ] Implement health checks for all services
- [ ] Add resource limits and requests
- [ ] Configure network policies
- [ ] Set up alerting

## References

- **k3s Documentation:** https://docs.k3s.io/
- **Kubernetes Documentation:** https://kubernetes.io/docs/
- **Traefik Documentation:** https://doc.traefik.io/traefik/
- **Rancher Documentation:** https://ranchermanager.docs.rancher.com/

## Contributing

When adding new services:
1. Follow the naming conventions
2. Create appropriate documentation
3. Update this overview
4. Test thoroughly
5. Commit with descriptive messages

## License

This configuration is for personal homelab use.
