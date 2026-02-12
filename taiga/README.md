# Taiga Agile Project Management - Kubernetes Deployment

## Overview

This directory contains Kubernetes manifests for deploying Taiga Agile Project Management with LDAP authentication and SMB storage.

## Features

- **LDAP Authentication**: Integration with LLDAP using bind_reader account
- **Admin User**: Pre-configured superuser "endmin"
- **SMB Storage**: 50Gi documents share at //192.168.200.205/documents
- **Subpath Deployment**: Served at https://andromeda.picklemustard.dev/collab/taiga
- **Minimal Setup**: No RabbitMQ, real-time features disabled

## Prerequisites

1. Existing `collab` namespace
2. PostgreSQL database running in `postgres` namespace
3. LLDAP service running in `auth` namespace
4. SMB CSI driver installed
5. SMB server at 192.168.200.205 with documents share

## Deployment Steps

### 1. Apply Secrets
```bash
kubectl apply -f taiga-secrets.yml
kubectl apply -f taiga-smb-secret.yml
```

### 2. Apply Storage Configuration
```bash
kubectl apply -f taiga-storageclass.yml
kubectl apply -f taiga-pv.yml
kubectl apply -f taiga-pvc.yml
```

### 3. Apply Configurations
```bash
kubectl apply -f taiga-configmap.yml
kubectl apply -f taiga-back-configmap.yml
kubectl apply -f frontend-conf.yml
```

### 4. Deploy Applications
```bash
kubectl apply -f deployment.yml
```

### 5. Expose Services
```bash
kubectl apply -f service.yml
kubectl apply -f ingress.yml
```

### 6. Initialize Database and Create Admin User
```bash
kubectl apply -f init-job.yml
```

### 7. Verify Deployment
```bash
# Check pods are running
kubectl get pods -n collab

# Check services
kubectl get svc -n collab

# Check ingress
kubectl get ingress -n collab

# View logs
kubectl logs -f deployment/taiga-back -n collab
kubectl logs -f deployment/taiga-front -n collab

# Check init job status
kubectl get job taiga-init -n collab
kubectl logs job/taiga-init -n collab
```

## Access Taiga

URL: https://andromeda.picklemustard.dev/collab/taiga

Admin Login:
- Username: endmin
- Password: purple14735#

LDAP users can log in using their LLDAP credentials.

## Configuration Files

- `taiga-secrets.yml`: Sensitive data (passwords, secret keys)
- `taiga-smb-secret.yml`: SMB credentials
- `taiga-configmap.yml`: Basic Taiga configuration
- `taiga-back-configmap.yml`: LDAP plugin configuration
- `frontend-conf.yml`: Frontend configuration with LDAP login
- `taiga-storageclass.yml`: SMB storage class definition
- `taiga-pv.yml`: PersistentVolume for documents
- `taiga-pvc.yml`: PersistentVolumeClaim
- `deployment.yml`: Backend and frontend deployments
- `service.yml`: Service definitions
- `ingress.yml`: Traefik ingress configuration
- `init-job.yml`: Database initialization and admin user creation

## Troubleshooting

### LDAP Authentication Issues
Check taiga-back logs for LDAP errors:
```bash
kubectl logs deployment/taiga-back -n collab
```

Verify LLDAP connectivity:
```bash
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n collab -- sh -c 'nc -zv lldap-service.auth.svc.cluster.local 3890'
```

### Database Connection Issues
Verify PostgreSQL is accessible:
```bash
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n collab -- psql "postgresql://postgres_fid:IKj#0y1mZb#zdDS#TrLP@postgres-postgresql.postgres.svc.cluster.local:5432/postgres" -c "SELECT 1"
```

### Storage Issues
Check PVC status:
```bash
kubectl get pvc taiga-data -n collab
kubectl describe pvc taiga-data -n collab
```

Verify SMB mount is working:
```bash
kubectl exec -it deployment/taiga-back -n collab -- ls -la /taiga-back/media
```

### Init Job Fails
View init job logs:
```bash
kubectl logs job/taiga-init -n collab
```

If job fails, delete and retry:
```bash
kubectl delete job taiga-init -n collab
kubectl apply -f init-job.yml
```

## Notes

- Telemetry is disabled by default
- Public registration is disabled (LDAP only)
- No RabbitMQ - real-time features and async tasks unavailable
- Uses existing `postgres_fid` user in PostgreSQL
- Database name: `taiga`
- SMB credentials match those used for OpenProject
