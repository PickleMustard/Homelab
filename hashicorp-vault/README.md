# Hashicorp Vault Deployment

## Deployment Overview

Hashicorp Vault deployed in the `auth` namespace, integrated with existing PostgreSQL instance.

## Access

- **Web UI**: https://auth.picklemustard.dev/vault
- **API**: https://auth.picklemustard.dev/vault:8200
- **Root Token**: Generated during initialization (see Post-Deployment Setup)

## Deployment Commands

Deploy in order:

```bash
# 1. Create Persistent Volume Claim
kubectl apply -f /app-storage/k3s/hasicorp-vault/vault-pvc.yml

# 2. Create Secrets
kubectl apply -f /app-storage/k3s/secrets/vault-secrets.yml

# 3. Create ConfigMap
kubectl apply -f /app-storage/k3s/hasicorp-vault/vault-configmap.yml

# 4. Create Deployment
kubectl apply -f /app-storage/k3s/hasicorp-vault/vault-deployment.yml

# 5. Create Service
kubectl apply -f /app-storage/k3s/hasicorp-vault/vault-service.yml

# 6. Create Ingress
kubectl apply -f /app-storage/k3s/hasicorp-vault/vault-ingress.yml
```

Or apply all at once:

```bash
kubectl apply -f /app-storage/k3s/secrets/vault-secrets.yml
kubectl apply -f /app-storage/k3s/hasicorp-vault/
```

## Configuration Details

### Storage
- **PVC**: vault-data
- **Size**: 2Gi
- **Storage Class**: local-path

### Database
- **Host**: postgres-postgresql.postgres.svc.cluster.local
- **Port**: 5432
- **Database**: vault
- **User**: postgres_fid
- **Backend**: PostgreSQL storage backend

### Container
- **Image**: hashicorp/vault:1.17.2
- **Port**: 8200 (HTTP), 8201 (cluster)
- **Namespace**: auth

### Authentication Methods
- `token` - Token-based authentication (default)
- `userpass` - Username/password authentication
- `jwt` - JWT token-based authentication
- `kubernetes` - Kubernetes native authentication

### Health Checks
- **Readiness Probe**: /v1/sys/health (after 30s delay)
- **Liveness Probe**: /v1/sys/health (after 60s delay)

## Post-Deployment Setup

### 1. Initialize Vault

Vault starts in a sealed state and must be initialized first:

```bash
# Exec into the pod
kubectl exec -it deployment/vault -n auth -- sh

# Initialize Vault (generates 5 unseal keys and root token)
vault operator init -key-shares=5 -key-threshold=3

# IMPORTANT: Store the unseal keys and root token securely!
# You'll need 3 of the 5 unseal keys to unseal Vault.
```

### 2. Unseal Vault

After initialization, Vault is sealed. Unseal it using 3 of the 5 unseal keys:

```bash
# Unseal Vault (repeat 3 times with different unseal keys)
vault operator unseal
```

Alternatively, you can use `kubectl exec` from outside:

```bash
kubectl exec -it deployment/vault -n auth -- vault operator unseal
```

### 3. Enable Authentication Methods

```bash
# Enable userpass auth
vault auth enable userpass

# Enable JWT auth
vault auth enable jwt

# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth method
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"
```

### 4. Create Initial Policies

```bash
# Create a simple policy
vault policy write admin - <<EOF
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

# Create a read-only policy
vault policy write read-only - <<EOF
path "*" {
  capabilities = ["read", "list"]
}
EOF
```

### 5. Create Users (userpass)

```bash
# Create a user with admin policy
vault write auth/userpass/users/admin \
  password="secure_password" \
  policies="admin"

# Create a user with read-only access
vault write auth/userpass/users/readonly \
  password="secure_password" \
  policies="read-only"
```

### 6. Store Your First Secret

```bash
# Store a secret
vault kv put secret/api database_password="my_db_password"

# Retrieve the secret
vault kv get secret/api
```

## Verification Commands

```bash
# Check pod status
kubectl get pods -n auth -l app.kubernetes.io/name=vault

# View logs
kubectl logs -f deployment/vault -n auth

# Check deployment status
kubectl get deployment vault -n auth

# Check ingress
kubectl get ingress vault-ingress -n auth

# View service
kubectl get service vault-service -n auth

# Check seal status
kubectl exec deployment/vault -n auth -- vault status
```

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod <pod-name> -n auth
kubectl logs <pod-name> -n auth
```

### Database connection issues
```bash
# Check PostgreSQL service
kubectl get svc -n postgres

# Test database connectivity
kubectl exec -it deployment/vault -n auth -- sh
# Inside pod: nc -zv postgres-postgresql.postgres.svc.cluster.local 5432
```

### Vault is sealed
```bash
# Check seal status
kubectl exec deployment/vault -n auth -- vault status

# If sealed, unseal with 3 of 5 unseal keys
kubectl exec deployment/vault -n auth -- vault operator unseal
```

### Ingress not accessible
```bash
kubectl get ingress vault-ingress -n auth -o yaml
kubectl describe ingress vault-ingress -n auth
```

### Resetting Vault

If you need to completely reset Vault:

```bash
# Delete deployment and PVC
kubectl delete deployment vault -n auth
kubectl delete pvc vault-data -n auth

# Optionally, drop the PostgreSQL database table
kubectl exec -it postgres-postgresql-0 -n postgres -- psql -U postgres_fid -d vault -c "DROP TABLE IF EXISTS vault;"

# Re-deploy from scratch
kubectl apply -f /app-storage/k3s/hasicorp-vault/
```

## Notes

- HTTP only (no TLS) - traffic is unencrypted between Traefik and Vault
- PostgreSQL database must exist before Vault starts
- The `auth` namespace is shared with LLDAP and Authelia
- Data is persisted via the vault-data PVC and PostgreSQL
- After initialization, save unseal keys and root token securely - they cannot be recovered if lost
- Consider using Auto-unseal with AWS KMS, GCP KMS, or similar for production environments

## Migration from Conjur

When migrating secrets from Conjur to Vault:

1. Export secrets from Conjur
2. Initialize and unseal Vault
3. Store secrets in Vault KV secrets engine
4. Update applications to use Vault API or CLI
5. Revoke Conjur access after successful migration

## Additional Resources

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [PostgreSQL Storage Backend](https://developer.hashicorp.com/vault/docs/configuration/storage/postgresql)
- [Kubernetes Authentication](https://developer.hashicorp.com/vault/docs/auth/kubernetes)
