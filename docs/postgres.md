# PostgreSQL - Database Service

**Namespace:** `postgres`

**Port:** 5432

---

## Overview

PostgreSQL is a powerful, open-source object-relational database system that provides reliable data storage for multiple homelab services.

---

## Configuration Files

- `postgres-values.yml` - Helm chart values
- `postgres_tcp_ingress.yml` - TCP ingress configuration

---

## Deployment

PostgreSQL is deployed using Helm:

```bash
# Create namespace
kubectl create namespace postgres

# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL
helm install --namespace postgres postgres bitnami/postgresql -f postgres-values.yml
```

---

## Configuration

### Main Settings (postgres-values.yml)

Key configuration options:
- **Replica count:** Number of replicas
- **Auth:** Authentication settings
- **Primary:** Primary database configuration
- **Resources:** CPU and memory limits
- **Persistence:** Storage configuration

### LDAP Authentication

PostgreSQL is configured to use LDAP authentication via LLDAP:
- **LDAP Server:** LLDAP service
- **Base DN:** `dc=picklemustard,dc=dev`
- **Bind DN:** Configured in values
- **Search Filter:** For user lookup

---

## Storage

### Persistent Volume Claim

PostgreSQL uses a PVC for data persistence (configured in values file):

- **Storage Class:** `local-path`
- **Size:** Configured in values file
- **Access Mode:** ReadWriteOnce

---

## Clients

The following services use PostgreSQL:

| Service | Database | User |
|---------|----------|------|
| Vaultwarden | `vaultwarden` | `postgres_fid` |
| Pterodactyl | `pterodactyl` | `postgres` |
| Firefly III | Configured in values | Configured in values |

---

## Access

### Connection String Pattern
```
postgresql://<user>:<password>@postgres-postgresql.postgres.svc.cluster.local:5432/<database>
```

### Internal Access
```bash
# From within the cluster
kubectl exec -it -n postgres deployment/postgres-postgresql -- psql -U postgres

# Or use psql client
kubectl run -it --rm psql-client --image=postgres:14 --restart=Never -- psql -h postgres-postgresql.postgres.svc.cluster.local -U postgres
```

### External Access
External access is available via TCP ingress (if configured):
- **Host:** postgres.picklemustard.dev
- **Port:** Configured in `postgres_tcp_ingress.yml`

---

## Management

### Check Status
```bash
kubectl get pods -n postgres
kubectl logs -f deployment/postgres-postgresql -n postgres
```

### Access Shell
```bash
kubectl exec -it deployment/postgres-postgresql -n postgres -- /bin/bash
```

### View Configuration
```bash
kubectl get secret postgres-postgresql -n postgres -o yaml
```

---

## Common Operations

### Create Database
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "CREATE DATABASE dbname;"
```

### Create User
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "CREATE USER username WITH PASSWORD 'password';"
```

### Grant Privileges
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE dbname TO username;"
```

### List Databases
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "\l"
```

### List Users
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "\du"
```

---

## Troubleshooting

### Service Not Starting
1. Check pod status: `kubectl get pods -n postgres`
2. Review logs: `kubectl logs -f deployment/postgres-postgresql -n postgres`
3. Check PVC: `kubectl get pvc -n postgres`
4. Verify storage class: `kubectl get storageclass`

### Connection Issues
1. Check service: `kubectl get svc -n postgres`
2. Verify service endpoints: `kubectl get endpoints -n postgres`
3. Check network policies
4. Test from client pod

### Authentication Issues
1. Verify credentials in secret: `kubectl get secret postgres-postgresql -n postgres -o yaml`
2. Check LDAP configuration if using LDAP auth
3. Review PostgreSQL logs for auth errors

### Performance Issues
1. Check resource usage: `kubectl top pod -n postgres`
2. Review queries and indexes
3. Consider increasing resource limits

---

## Backup

### Backup All Databases
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- pg_dumpall -U postgres > postgres-backup.sql
```

### Backup Specific Database
```bash
kubectl exec -n postgres deployment/postgres-postgresql -- pg_dump -U postgres dbname > dbname-backup.sql
```

### Restore from Backup
```bash
kubectl exec -i -n postgres deployment/postgres-postgresql -- psql -U postgres < postgres-backup.sql
```

---

## Upgrade

### Using Helm
```bash
helm upgrade --namespace postgres postgres bitnami/postgresql -f postgres-values.yml
```

### Manual Upgrade
```bash
# Set image tag
kubectl set image deployment/postgres-postgresql postgres=bitnami/postgresql:<version> -n postgres

# Watch rollout
kubectl rollout status deployment/postgres-postgresql -n postgres
```

### Run Migrations
After upgrading, run database migrations as needed:

```bash
kubectl exec -n postgres deployment/postgres-postgresql -- psql -U postgres -c "ALTER DATABASE dbname REFRESH COLLATE VERSION;"
```

---

## Security

### LDAP Authentication
PostgreSQL is configured to use LLDAP for authentication:
- Users are authenticated against LLDAP
- Reduces credential management overhead
- Centralized identity management

### Best Practices
1. Use strong passwords for database users
2. Enable SSL/TLS for connections
3. Restrict external access with network policies
4. Regularly update PostgreSQL version
5. Implement backup strategy
6. Monitor resource usage

---

## Maintenance

### Regular Tasks
1. Run `VACUUM ANALYZE` regularly
2. Update statistics with `ANALYZE`
3. Check for bloated tables
4. Review and optimize slow queries
5. Monitor disk usage

### Replication
Configure replication for high availability (if needed):
- Set up streaming replication
- Configure read replicas
- Monitor replication lag

---

## Notes

- PostgreSQL is deployed via Helm chart in the `postgres` namespace
- Uses LDAP authentication via LLDAP
- Multiple services share this database instance
- Consider resource limits based on workload
- Regular backups are critical for data safety
- TCP ingress allows external access (if configured)
