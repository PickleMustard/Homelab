# Forgejo Deployment on k3s Homelab

## Overview
Forgejo instance configured with external PostgreSQL, Redis, and LDAP authentication.

## Architecture
- **Namespace**: `git`
- **Image**: `code.forgejo.org/forgejo/forgejo:14.0.1` (rootless)
- **Storage**: SMB share `//192.168.200.205/documents` (20Gi)
- **Database**: PostgreSQL (external)
- **Cache/Session**: Redis (external)
- **Authentication**: LDAP with two groups (git-users, git-admin)
- **Exposure**: HTTP at `git.picklemustard.dev`, SSH via Traefik TCP route

## Features Enabled
- Git LFS
- Actions/CI-CD
- Container registry
- Packages support
- OAuth2 integration

## Prerequisites

### 1. LLDAP Groups
Create these groups in LLDAP before deployment:
- `git-users` (Standard users) - DN: `cn=git-users,ou=groups,dc=andromeda,dc=picklemustard,dc=dev`
- `git-admin` (Administrators) - DN: `cn=git-admin,ou=groups,dc=andromeda,dc=picklemustard,dc=dev`

Access LLDAP at: `http://auth.picklemustard.dev`

### 2. Traefik Entry Point
Add `git-ssh` entrypoint to Traefik configuration:

In `traefik-helm-values.yml`, add under `ports:`:
```yaml
      git-ssh:
        port: 22
        exposedPort: 22
        expose:
          default: true
        protocol: TCP
```

Apply updated Traefik config.

### 3. PostgreSQL Database
Create the Forgejo database:
```bash
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres_fid -c "CREATE DATABASE forgejo;"
```

## Deployment Steps

### 1. Create namespace
```bash
kubectl apply -f forgejo/create-namespace.yml
```

### 2. Create secrets
```bash
kubectl apply -f secrets/forgejo-secrets.yml
kubectl apply -f forgejo/forgejo-smb-secret.yml
```

### 3. Create storage resources
```bash
kubectl apply -f forgejo/forgejo-storageclass.yml
kubectl apply -f forgejo/forgejo-pv.yml
kubectl apply -f forgejo/forgejo-pvc.yml
```

### 4. Create SSH TCP route
```bash
kubectl apply -f forgejo/forgejo-ssh-tcp-route.yml
```

### 5. Install Forgejo
```bash
helm install forgejo -n git oci://code.forgejo.org/forgejo-helm/forgejo -f forgejo/forgejo-values.yml
```

## Verification

### Check all resources
```bash
kubectl get all -n git
kubectl get ingress -n git
kubectl get ingressroutetcp -n git
kubectl get pvc -n git
```

### View logs
```bash
kubectl logs -f deployment/forgejo -n git
```

### Test HTTP access
Browse to: `http://git.picklemustard.dev`

### Test SSH access
```bash
git clone git@git.picklemustard.dev:username/repo.git
```

## Configuration Files

### Core Files
- `forgejo/create-namespace.yml` - Namespace
- `forgejo/forgejo-values.yml` - Helm values
- `forgejo/forgejo-smb-secret.yml` - SMB credentials
- `forgejo/forgejo-storageclass.yml` - SMB storage class
- `forgejo/forgejo-pv.yml` - Persistent volume
- `forgejo/forgejo-pvc.yml` - Persistent volume claim
- `forgejo/forgejo-ssh-tcp-route.yml` - SSH Traefik route
- `secrets/forgejo-secrets.yml` - Application secrets

### External Dependencies
- PostgreSQL: `postgres-postgresql.postgres.svc.cluster.local:5432`
- Redis: `redis-master.redis.svc.cluster.local:6379`
- LLDAP: `lldap-service.auth.svc.cluster.local:3890`

## LDAP Group Management

### Add user to git-users
In LLDAP UI, add user to `git-users` group for standard access.

### Add user to git-admin
In LLDAP UI, add user to `git-admin` group for administrative access.

### Remove Forgejo access
Remove user from both groups in LLDAP UI.

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod -n git
kubectl logs -f deployment/forgejo -n git
```

### Storage issues
```bash
kubectl describe pvc forgejo-data -n git
kubectl describe pv forgejo-documents -n git
```

### Database connection
```bash
kubectl exec -it -n git deployment/forgejo -- sh
# Test connection
nc -zv postgres-postgresql.postgres.svc.cluster.local 5432
```

### LDAP connection
```bash
kubectl exec -it -n git deployment/forgejo -- sh
# Test connection
nc -zv lldap-service.auth.svc.cluster.local 3890
```

## Upgrade Forgejo

```bash
helm upgrade forgejo -n git oci://code.forgejo.org/forgejo-helm/forgejo -f forgejo/forgejo-values.yml
```

## Uninstall Forgejo

```bash
helm uninstall forgejo -n git
kubectl delete namespace git
kubectl delete pv forgejo-documents -n git
```

## Notes

- Registration is disabled (LDAP only)
- All authentication via LLDAP groups
- Storage is on SMB share with ReadWriteMany access
- SSH requires `git-ssh` Traefik entrypoint to be configured
- Git operations via `git@git.picklemustard.dev`
