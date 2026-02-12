# Pterodactyl - Game Server Panel

**Namespace:** `pterodactyl`

**URL:** https://pterodactyl.picklemustard.dev

**Port:** 80

---

## Overview

Pterodactyl is a game server management panel that allows you to deploy and manage multiple game servers from a web interface. It's commonly used for Minecraft, but supports many other games.

---

## Configuration Files

- `pterodactyl/deployment.yml` - Main deployment
- `pterodactyl/service.yml` - Service definition
- `pterodactyl/pvc.yml` - Multiple PVCs for data

---

## Deployment

```bash
# Create namespace
kubectl create namespace pterodactyl

# Apply all Pterodactyl configurations
kubectl apply -f pterodactyl/
```

---

## Secrets Required

Create a secret named `pterodactyl-credentials`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: pterodactyl-credentials
  namespace: pterodactyl
type: Opaque
stringData:
  postgres-passwd: "<database-password>"
  redis-passwd: "<redis-password>"
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `APP_ENV` | Application environment (production) |
| `APP_ENVIRONMENT_ONLY` | Allow only production environment (false) |
| `APP_URL` | Public URL for the panel |
| `APP_TIMEZONE` | Server timezone (UTC) |
| `APP_SERVICE_AUTHOR` | Panel administrator email |
| `TRUSTED_PROXIES` | Trusted proxy IPs (*) |
| `DB_HOST` | PostgreSQL host |
| `DB_PORT` | PostgreSQL port (5432) |
| `DB_DATABASE` | Database name (pterodactyl) |
| `DB_PASSWORD` | Database password (from secret) |
| `CACHE_DRIVER` | Cache driver (redis) |
| `SESSION_DRIVER` | Session driver (redis) |
| `QUEUE_DRIVER` | Queue driver (redis) |
| `REDIS_HOST` | Redis host |
| `REDIS_PASSWORD` | Redis password (from secret) |

---

## Storage

### Persistent Volume Claims

| PVC Name | Purpose | Mount Path |
|----------|---------|------------|
| `pterodactyl-app-claim` | Application data | `/app/var/` |
| `pterodactyl-nginx-claim` | Nginx configuration | `/etc/nginx/http.d/` |
| `pterodactyl-le-claim` | Let's Encrypt certificates | `/etc/letsencrypt/` |
| `pterodactyl-logs-claim` | Application logs | `/app/storage/logs` |

---

## Dependencies

### PostgreSQL
- **Host:** `postgres-postgresql.postgres.svc.cluster.local`
- **Port:** 5432
- **Database:** `pterodactyl`
- **Password:** From `pterodactyl-credentials` secret

### Redis
- **Host:** `redis-master.redis.svc.cluster.local`
- **Port:** 6379
- **Password:** From `pterodactyl-credentials` secret

---

## Architecture

Pterodactyl consists of two main components:

1. **Panel** - Web interface for managing servers (this deployment)
2. **Wings** - Server daemon that runs on game server nodes (not deployed here)

This deployment only includes the **Panel**. The **Wings** daemon should be deployed on separate nodes or VMs where game servers will run.

---

## Access

### Web Interface
URL: https://pterodactyl.picklemustard.dev

Initial setup requires running database migrations and creating an admin account.

### Initial Setup

After deployment, access the shell and run setup:

```bash
kubectl exec -it deployment/pterodactyl -n pterodactyl -- /bin/sh

# Run migrations
php artisan migrate --seed

# Create admin user
php artisan p:user:make
```

---

## Management

### Check Status
```bash
kubectl get pods -n pterodactyl
kubectl logs -f deployment/pterodactyl -n pterodactyl
```

### Access Shell
```bash
kubectl exec -it deployment/pterodactyl -n pterodactyl -- /bin/sh
```

### Run Artisan Commands
```bash
kubectl exec -n pterodactyl deployment/pterodactyl -- php artisan <command>
```

---

## Troubleshooting

### Database Connection Issues
1. Check PostgreSQL is running: `kubectl get pods -n postgres`
2. Verify secret contains correct password: `kubectl get secret pterodactyl-credentials -n pterodactyl -o yaml`
3. Test connection: `kubectl exec -n pterodactyl deployment/pterodactyl -- nc -zv postgres-postgresql.postgres.svc.cluster.local 5432`

### Redis Connection Issues
1. Check Redis is running: `kubectl get pods -n redis`
2. Verify secret contains correct password
3. Test connection: `kubectl exec -n pterodactyl deployment/pterodactyl -- nc -zv redis-master.redis.svc.cluster.local 6379`

### Cannot Access Web Interface
1. Check pod status: `kubectl get pods -n pterodactyl`
2. Verify service: `kubectl get svc -n pterodactyl`
3. Check ingress: `kubectl get ingress -n pterodactyl`

### Queue Not Processing
1. Check queue worker logs
2. Restart the deployment: `kubectl rollout restart deployment/pterodactyl -n pterodactyl`
3. Ensure Redis is accessible

---

## Backup

### Backup Database
```bash
kubectl exec -n postgres postgres-postgresql-0 -- pg_dump -U postgres pterodactyl > pterodactyl-backup.sql
```

### Backup Application Data
```bash
kubectl exec -n pterodactyl deployment/pterodactyl -- tar czf /tmp/pterodactyl-backup.tar.gz /app/var
kubectl cp -n pterodactyl deployment/pterodactyl:/tmp/pterodactyl-backup.tar.gz ./pterodactyl-backup.tar.gz
```

---

## Upgrade

```bash
# Update image tag
kubectl set image deployment/pterodactyl pterodactyl=ghcr.io/pterodactyl/panel:<version> -n pterodactyl

# Watch rollout
kubectl rollout status deployment/pterodactyl -n pterodactyl

# Run migrations after upgrade
kubectl exec -n pterodactyl deployment/pterodactyl -- php artisan migrate --force
```

---

## Configuration

### Panel Settings
Access the web interface to configure:
- Company name and logo
- Email settings (SMTP)
- Notification preferences
- Security settings

### Nginx Configuration
Nginx configuration is stored in `pterodactyl-nginx-claim` PVC at `/etc/nginx/http.d/`.

### SSL/TLS
Let's Encrypt certificates are stored in `pterodactyl-le-claim` PVC at `/etc/letsencrypt/`.

---

## Integration with Minecraft

Minecraft servers are deployed using **Agones** (see `minecraft/` directory):
- Agones manages game server lifecycles
- Pterodactyl Panel connects to Wings for management
- Wings can be configured to use Agones for server allocation

---

## Notes

- Deployment uses `Recreate` strategy (no rolling updates)
- Only the Panel is deployed; Wings must be deployed separately
- Requires PostgreSQL and Redis to be running
- Uses `TRUSTED_PROXIES: "*"` - restrict in production
