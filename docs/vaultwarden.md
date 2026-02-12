# Vaultwarden - Password Manager

**Namespace:** `vaultwarden`

**URL:** https://vault.picklemustard.dev

**Port:** 80

---

## Overview

Vaultwarden is a self-hosted Bitwarden-compatible password manager. It allows you to store and sync passwords across devices while maintaining control over your data.

---

## Configuration Files

- `vaultwarden/deployment.yml` - Main deployment
- `vaultwarden-ldap/deployment.yml` - LDAP sync deployment (if used)
- `vaultwarden-ldap/config-map.yml` - LDAP sync configuration

---

## Deployment

```bash
# Create namespace
kubectl create namespace vaultwarden

# Apply deployment
kubectl apply -f vaultwarden/deployment.yml

# Apply LDAP sync (optional)
kubectl apply -f vaultwarden-ldap/
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `DOMAIN` | Public URL for the instance |
| `ROCKET_PORT` | Port to listen on (80) |
| `ADMIN_TOKEN` | Admin panel access token (Argon2id hash) |
| `SENDS_ALLOWED` | Enable Bitwarden Sends feature |
| `SMTP_HOST` | SMTP server hostname |
| `SMTP_PORT` | SMTP port (587 for STARTTLS) |
| `SMTP_FROM` | From email address |
| `SMTP_USERNAME` | SMTP username |
| `SMTP_PASSWORD` | SMTP password |
| `SMTP_SECURITY` - STARTTLS |
| `PUSH_ENABLED` | Enable push notifications |
| `PUSH_INSTALLATION_ID` | Bitwarden push installation ID |
| `PUSH_INSTALLATION_KEY` | Bitwarden push installation key |
| `PUSH_RELAY_URI` | Push relay endpoint |
| `PUSH_IDENTITY_URI` | Push identity endpoint |

---

## Database

Vaultwarden uses PostgreSQL for data storage:

- **Host:** `postgres-postgresql.postgres.svc.cluster.local`
- **Port:** 5432
- **Database:** `vaultwarden`
- **User:** `postgres_fid`

**Note:** Database credentials are currently hardcoded in the deployment. Consider moving to secrets.

---

## Features

- **Bitwarden Compatible:** Works with all official Bitwarden clients
- **Push Notifications:** Real-time sync across devices
- **Bitwarden Sends:** Secure sharing of text and files
- **SMTP Email:** Email verification and invitations
- **Admin Panel:** Web-based administration interface
- **LDAP Sync:** Optional LDAP synchronization (via vaultwarden-ldap)

---

## Access

### Web Interface
URL: https://vault.picklemustard.dev

### Admin Panel
URL: https://vault.picklemustard.dev/admin

Access with the `ADMIN_TOKEN` from environment variables.

---

## Management

### Check Status
```bash
kubectl get pods -n vaultwarden
kubectl logs -f deployment/vaultwarden -n vaultwarden
```

### Access Shell
```bash
kubectl exec -it deployment/vaultwarden -n vaultwarden -- /bin/sh
```

---

## Troubleshooting

### Cannot Access Web Interface
1. Check pod status: `kubectl get pods -n vaultwarden`
2. Verify ingress is configured: `kubectl get ingress -n vaultwarden`
3. Check Traefik dashboard for routing issues

### Database Connection Issues
1. Verify PostgreSQL is running: `kubectl get pods -n postgres`
2. Check database connection string in deployment
3. Test connection from pod: `kubectl exec -n vaultwarden deployment/vaultwarden -- nc -zv postgres-postgresql.postgres.svc.cluster.local 5432`

### Email Not Sending
1. Check SMTP credentials in deployment
2. Verify Stalwart Mail is accessible
3. Check Vaultwarden logs for SMTP errors
4. Ensure SMTP security settings are correct (STARTTLS, port 587)

### Push Notifications Not Working
1. Verify `PUSH_ENABLED` is set to `true`
2. Check `PUSH_INSTALLATION_ID` and `PUSH_INSTALLATION_KEY`
3. Ensure push endpoints are accessible

---

## Security Recommendations

1. **Move Secrets to Kubernetes Secrets:**
   ```yaml
   env:
     - name: SMTP_PASSWORD
       valueFrom:
         secretKeyRef:
           name: vaultwarden-credentials
           key: smtp-password
     - name: DATABASE_URL
       valueFrom:
         secretKeyRef:
           name: vaultwarden-credentials
           key: database-url
   ```

2. **Use Specific Image Tags:** Replace `latest` with a specific version

3. **Regular Backups:** Backup PostgreSQL database regularly

4. **Enable Resource Limits:** Add CPU and memory limits to the deployment

---

## Backup

Backup the PostgreSQL database:

```bash
# From postgres pod
kubectl exec -n postgres postgres-postgresql-0 -- pg_dump -U postgres_fid vaultwarden > vaultwarden-backup.sql

# Or using pg_dump directly
kubectl exec -n postgres deployment/postgres-postgresql -- pg_dump -U postgres_fid vaultwarden > vaultwarden-backup.sql
```

---

## Upgrade

```bash
# Update image tag
kubectl set image deployment/vaultwarden vaultwarden=ghcr.io/dani-garcia/vaultwarden:<version> -n vaultwarden

# Watch rollout
kubectl rollout status deployment/vaultwarden -n vaultwarden
```

---

## LDAP Sync (Optional)

The `vaultwarden-ldap` deployment syncs users from LLDAP to Vaultwarden:

- **Config Map:** `vaultwarden-ldap/config-map.yml`
- **Features:**
  - Automatic user creation
  - Group-based access control
  - Password sync (read-only)

Note: LDAP sync is optional and not required for basic Vaultwarden functionality.

---

## Client Setup

Download official Bitwarden clients and connect to:
- **Server URL:** https://vault.picklemustard.dev

Clients are available for:
- Web browsers (Chrome, Firefox, Edge, Safari)
- Desktop (Windows, macOS, Linux)
- Mobile (iOS, Android)
- CLI (command-line interface)

---

## Notes

- Vaultwarden does not include persistent storage as it uses PostgreSQL
- The deployment currently has hardcoded credentials - these should be moved to secrets
- Admin token is hashed using Argon2id for security
