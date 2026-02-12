# Authelia - Single Sign-On

**Namespace:** `lldap`

**URL:** https://auth.picklemustard.dev

**Port:** 9091

---

## Overview

Authelia is an open-source authentication and authorization server providing 2FA (two-factor authentication) and SSO (single sign-on) capabilities. It acts as a middleware for protecting web applications.

---

## Configuration Files

- `authelia/authelia-deployment.yml` - Main deployment
- `authelia/authelia-service.yml` - Service definition
- `authelia/authelia-ingress.yml` - HTTP ingress
- `authelia/authelia-pvc.yml` - 1Gi PVC for data
- `authelia/authelia-configmap.yml` - Main configuration
- `authelia/ingress-tcp.yml` - TCP ingress for SMTP
- `authelia/authelia-cert.yml` - TLS certificate

---

## Deployment

```bash
# Create namespace (if not exists)
kubectl create namespace lldap

# Apply all Authelia configurations
kubectl apply -f authelia/
```

---

## Secrets Required

Create a secret named `authelia-credentials`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: authelia-credentials
  namespace: lldap
type: Opaque
stringData:
  hmac-secret: "<random-hmac-secret>"
  jwt-secret: "<random-jwt-secret>"
  storage-encryption-key: "<random-encryption-key>"
  session-secret: "<random-session-secret>"
  stalwart-client-secret: "<client-secret>"
  ldap-password: "<ldap-admin-password>"
  postmaster-secret: "<smtp-password>"
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `HMAC_SECRET` | Secret for HMAC signing |
| `JWT_SECRET` | Secret for JWT token signing |
| `STORAGE_ENCRYPTION_KEY` | Encryption key for database |
| `SESSION_SECRET` | Secret for session cookies |
| `LDAP_PASSWORD` | LLDAP admin password |
| `STALWART_CLIENT_SECRET` | OAuth2 client secret for Stalwart |
| `AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE` | Path to SMTP password file |

---

## Storage

- **PVC Name:** `authelia-data-pvc`
- **Size:** 1Gi
- **Mount Path:** `/data`
- **Storage Class:** `local-path`

---

## Configuration Map

The main configuration is stored in the `authelia-config` ConfigMap and includes:

- Authentication methods (LDAP integration)
- Session settings
- Access control rules
- SMTP notification settings
- TOTP (Time-based One-Time Password) configuration
- Duo 2FA settings (if configured)

---

## Integration

Authelia integrates with:

- **LLDAP** - User authentication backend
- **Stalwart Mail** - SMTP for email notifications and OAuth2
- **Traefik** - Forward authentication middleware
- **All Services** - Protects web applications with 2FA

---

## Access Control

Services protected by Authelia are configured via Traefik middleware. The access policy is defined in the Authelia configuration file.

Common access policies:
- `bypass` - No authentication required
- `one_factor` - Username/password required
- `two_factor` - 2FA required (default for protected services)

---

## Access

### Web Interface
URL: https://auth.picklemustard.dev

After initial setup, users can:
- Configure 2FA methods (TOTP, Duo)
- View authentication logs
- Reset passwords (if configured)

### Health Check
```bash
kubectl exec -n lldap deployment/authelia -- curl http://localhost:9091/api/health
```

---

## Management

### Check Status
```bash
kubectl get pods -n lldap
kubectl logs -f deployment/authelia -n lldap
```

### View Configuration
```bash
kubectl get configmap authelia-config -n lldap -o yaml
```

---

## Troubleshooting

### Authentication Not Working
1. Verify LLDAP is accessible: `kubectl get pods -n auth`
2. Check Authelia logs for LDAP connection errors
3. Verify LDAP password in secret matches LLDAP admin password

### 2FA Issues
1. Check that `duo_secret` is configured (if using Duo)
2. Verify time synchronization on the server
3. Check TOTP secret configuration

### SMTP Notifications
1. Verify Stalwart Mail is running
2. Check `postmaster-secret` in the secret
3. Verify SMTP settings in ConfigMap

---

## Upgrade

```bash
# Update image tag
kubectl set image deployment/authelia authelia=authelia/authelia:<version> -n lldap

# Watch rollout
kubectl rollout status deployment/authelia -n lldap
```

---

## Backup

Backup Authelia configuration and database:

```bash
# Backup database
kubectl exec -n lldap deployment/authelia -- tar czf /tmp/authelia-backup.tar.gz /data
kubectl cp -n lldap deployment/authelia:/tmp/authelia-backup.tar.gz ./authelia-backup.tar.gz

# Backup configuration
kubectl get configmap authelia-config -n lldap -o yaml > authelia-config-backup.yml
```

---

## Notes

- Authelia is deployed in the `lldap` namespace for logical grouping with LLDAP
- TLS certificates are mounted from secrets for secure communication
- The `enableServiceLinks: false` is set to prevent automatic environment variable injection
