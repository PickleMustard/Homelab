# LLDAP - Lightweight LDAP

**Namespace:** `auth`

**URL:** https://ldap.picklemustard.dev

**Ports:** 3890 (LDAP), 17170 (HTTP UI)

---

## Overview

LLDAP is a lightweight LDAP authentication server that serves as the central identity provider for the entire homelab. It provides user authentication and directory services for all applications.

---

## Configuration Files

- `lldap/lldap-deployment.yml` - Main deployment configuration
- `lldap/lldap-service.yml` - Service definition
- `lldap/lldap-ingress.yml` - HTTP UI ingress
- `lldap/lldap-tcp-ingress.yml` - LDAP TCP ingress
- `lldap/lldap-persistent-volume-claim.yml` - 10Gi PVC for data

---

## Deployment

```bash
# Create namespace (if not exists)
kubectl create namespace auth

# Apply all LLDAP configurations
kubectl apply -f lldap/

# Or apply individually
kubectl apply -f lldap/lldap-deployment.yml
kubectl apply -f lldap/lldap-service.yml
kubectl apply -f lldap/lldap-ingress.yml
kubectl apply -f lldap/lldap-tcp-ingress.yml
```

---

## Secrets Required

Create a secret named `lldap-credentials` with the following keys:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: lldap-credentials
  namespace: auth
type: Opaque
stringData:
  lldap-jwt-secret: "<random-jwt-secret>"
  base-dn: "dc=picklemustard,dc=dev"
  lldap-ldap-user-pass: "<admin-password>"
```

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `UID` | User ID (1001) |
| `GID` | Group ID (1001) |
| `TZ` | Timezone (CET) |
| `LLDAP_JWT_SECRET` | JWT signing secret |
| `LLDAP_LDAP_BASE_DN` | Base DN for LDAP directory |
| `LLDAP_LDAP_USER_PASS` | LDAP admin password |

---

## Storage

- **PVC Name:** `lldap-data`
- **Size:** 10Gi
- **Mount Path:** `/data`
- **Storage Class:** `local-path`

---

## Integration

LLDAP is integrated with the following services:

- **Authelia** - Primary authentication provider
- **PostgreSQL** - LDAP authentication for database access
- **Vaultwarden** - User directory (via LDAP sync)
- **Stalwart Mail** - User authentication for email

---

## Access

### Web UI
URL: https://ldap.picklemustard.dev

Use LDAP admin credentials configured in the secret.

### LDAP Connection
- **Host:** `ldap-lldap.auth.svc.cluster.local:3890`
- **Base DN:** `dc=picklemustard,dc=dev`
- **Bind DN:** `cn=admin,ou=people,dc=picklemustard,dc=dev`

---

## Management

### Check Status
```bash
kubectl get pods -n auth
kubectl logs -f deployment/lldap -n auth
```

### Access Web Interface
```bash
kubectl port-forward -n auth svc/lldap 8080:3890
```
Then visit http://localhost:8080

---

## Troubleshooting

### Service Not Starting
```bash
kubectl describe deployment lldap -n auth
kubectl logs deployment/lldap -n auth
```

### LDAP Connection Issues
1. Verify TCP ingress is configured
2. Check firewall allows port 3890
3. Verify service endpoints: `kubectl get endpoints lldap -n auth`

### Data Persistence
Ensure PVC is bound:
```bash
kubectl get pvc lldap-data -n auth
```

---

## Backup

Backup the LLDAP data directory:
```bash
kubectl exec -n auth deployment/lldap -- tar czf /tmp/lldap-backup.tar.gz /data
kubectl cp -n auth deployment/lldap:/tmp/lldap-backup.tar.gz ./lldap-backup.tar.gz
```

---

## Upgrade

```bash
# Update image tag in deployment
kubectl set image deployment/lldap lldap=nitnelave/lldap:<version> -n auth

# Watch rollout
kubectl rollout status deployment/lldap -n auth
```
