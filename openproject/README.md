# OpenProject Deployment

This directory contains Kubernetes YAML manifests for deploying OpenProject on the k3s cluster.

## Prerequisites

### Database Setup

Before deploying, create the PostgreSQL database and user:

```bash
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres -c "CREATE USER openproject WITH PASSWORD 'YOUR_SECURE_PASSWORD';"
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres -c "CREATE DATABASE openproject OWNER openproject;"
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE openproject TO openproject;"
```

### LLDAP Setup

Create an LLDAP user for OpenProject LDAP authentication:

1. Access LLDAP admin panel at `http://auth.picklemustard.dev`
2. Create user with username: `openproject_bind`
3. Note the password for the secret configuration

### Update Secrets

Edit `openproject-secrets.yml` and update the following values:

- `secret-key-base`: Generate a secure 64-character random string
- `postgres-password`: Use the same password from database setup
- `ldap-password`: Use the LLDAP bind user password

Generate a random secret key:
```bash
openssl rand -base64 64
```

## Deployment Steps

### 1. Create Namespace
```bash
kubectl apply -f create-namespace.yml
```

### 2. Create SMB Secret
```bash
kubectl apply -f openproject-smb-secret.yml
```

### 3. Create Storage Class
```bash
kubectl apply -f openproject-storageclass.yml
```

### 4. Create PVC (This will provision automatically)
```bash
kubectl apply -f openproject-data-pvc.yml
```

### 5. Apply Configuration
```bash
kubectl apply -f openproject-configmap.yml
kubectl apply -f openproject-secrets.yml
```

### 6. Apply Middleware
```bash
kubectl apply -f middleware.yml
```

### 7. Create Deployment
```bash
kubectl apply -f deployment.yml
```

### 8. Create Service
```bash
kubectl apply -f service.yml
```

### 9. Create Ingress
```bash
kubectl apply -f ingress.yml
```

Or deploy all at once:
```bash
kubectl apply -f openproject/
```

## Verification

Check all resources:
```bash
kubectl get all -n collab
kubectl get pvc -n collab
kubectl get ingress -n collab
```

View logs:
```bash
kubectl logs -f deployment/openproject -n collab
```

## Access

OpenProject will be available at:
```
https://andromeda.picklemustard.dev/collab/plan
```

Default credentials after first startup:
- Username: `admin`
- Password: `admin`

**IMPORTANT:** Change the default admin password immediately after first login!

## Configuration

### Environment Variables

Key environment variables are configured in `openproject-configmap.yml`:

- `OPENPROJECT_HOST__NAME`: External URL for OpenProject
- `OPENPROJECT_HTTPS`: Set to `false` (TLS handled by Traefik)
- `OPENPROJECT_RAILS__RELATIVE__URL__ROOT`: Base path `/collab/plan`
- LDAP settings for LLDAP integration

### Storage

- Storage Class: `documents-data` (SMB share at `//192.168.200.205/documents`)
- PVC Size: 20Gi
- Access Mode: ReadWriteMany (RWX)
- Mounted to: `/var/openproject/assets` and `/var/openproject/files`

### Authentication

OpenProject is configured to use LLDAP for user authentication:
- Host: `lldap-service.auth.svc.cluster.local:3890`
- Base DN: `dc=andromeda,dc=picklemustard,dc=dev`
- Bind DN: `uid=openproject_bind,ou=people,dc=andromeda,dc=picklemustard,dc=dev`

To configure LDAP in OpenProject after deployment:
1. Log in as admin
2. Navigate to Administration → Authentication → LDAP
3. Create new LDAP connection using environment variables

## Troubleshooting

### Pod Not Starting
```bash
kubectl describe pod -n collab -l app.kubernetes.io/name=openproject
kubectl logs deployment/openproject -n collab
```

### PVC Issues
```bash
kubectl describe pvc openproject-data -n collab
```

### Database Connection Issues
```bash
kubectl exec -it deployment/openproject -n collab -- env | grep DATABASE
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres -c "\l"
```

### Ingress Issues
```bash
kubectl describe ingress openproject-ingress -n collab
kubectl get ingress -n collab -o yaml
```

## Backup

Backup OpenProject database:
```bash
kubectl exec -n postgres postgres-postgresql-0 -- pg_dump -U postgres_fid openproject > openproject-backup.sql
```

Backup files from SMB share or use OpenProject's built-in backup functionality.

## Upgrade

To upgrade OpenProject to a new version:
1. Update image tag in `deployment.yml`
2. Apply updated deployment: `kubectl apply -f deployment.yml`
3. OpenProject will automatically run database migrations on startup
