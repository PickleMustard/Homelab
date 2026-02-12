# Grafana PostgreSQL Integration - Quick Start Guide

## Overview

This guide walks you through setting up Grafana to use PostgreSQL instead of SQLite for better performance and centralized data management.

## Pre-Deployment Checklist

Before running the deployment, complete these steps:

### ✓ Step 1: Create PostgreSQL User and Database

```bash
# Connect to PostgreSQL
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres

# Run the SQL commands (see grafana-postgres-setup.sql)
```

Or copy and run these SQL commands:

```sql
-- Create postgres_fid user (replace password!)
CREATE USER postgres_fid WITH PASSWORD 'YOUR_SECURE_PASSWORD_HERE';

-- Grant superuser privileges
ALTER USER postgres_fid WITH SUPERUSER;

-- Create grafana database
CREATE DATABASE grafana OWNER postgres_fid;

-- Verify
\l
\du postgres_fid
\q
```

### ✓ Step 2: Create Kubernetes Secret

```bash
kubectl create secret generic grafana-db-credentials \
  --from-literal.password='YOUR_SECURE_PASSWORD_HERE' \
  -n monitoring
```

**Important**: Replace `YOUR_SECURE_PASSWORD_HERE` with the same password you used in Step 1.

### ✓ Step 3: Verify Database Setup (Optional but Recommended)

```bash
# Test connection
kubectl run postgres-test -n monitoring --rm -i --tty --image=bitnami/postgresql:16 \
  --env="PGPASSWORD=YOUR_PASSWORD" \
  -- psql -h postgres-postgresql.postgres.svc.cluster.local -U postgres_fid -d grafana -c "SELECT 1"
```

## Deploy

Once database setup is complete:

```bash
cd /app-storage/k3s/monitoring
./deploy-prometheus.sh
```

The script will:
1. ✓ Verify database configuration exists
2. Create namespace and label namespaces
3. Create Prometheus PVC
4. Deploy kube-prometheus-stack (with PostgreSQL-enabled Grafana)
5. Create ingresses
6. Deploy ServiceMonitors and exporters

## Verify Deployment

### Check Grafana is Using PostgreSQL

```bash
kubectl logs -n monitoring deployment/prometheus-grafana -c grafana | grep -i database
```

Expected output:
```
logger=sqlstore t=... level=info msg="Connecting to DB" dbtype=postgres
logger=sqlstore t=... level=info msg="Using Postgres driver" driver="..."
```

### Check Grafana Pod Status

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

Should show `Running` status.

### Access Grafana

Open browser to: `http://grafana.picklemustard.dev`

Login with:
- Username: `admin`
- Password: Run `kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode`

## Configuration Files

| File | Purpose |
|-------|---------|
| `prometheus-values.yml` | Helm values with PostgreSQL configuration |
| `grafana-db-secret.yml` | Secret template for database password |
| `POSTGRESQL-SETUP.md` | Detailed database setup instructions |
| `grafana-postgres-setup.sql` | SQL commands to copy and run |
| `deploy-prometheus.sh` | Deployment script with validation |

## Troubleshooting

### Script Fails with "grafana-db-credentials secret not found"

**Solution**: Create the secret first:
```bash
kubectl create secret generic grafana-db-credentials \
  --from-literal.password='YOUR_PASSWORD' \
  -n monitoring
```

### Script Fails with "secret has not been configured yet"

**Solution**: The secret still contains the placeholder. Update it:
```bash
kubectl edit secret grafana-db-credentials -n monitoring
# Replace SET_PASSWORD_HERE with your actual password
```

### Grafana Logs Show SQLite Instead of PostgreSQL

**Solution**: Verify values file has correct environment variables and secret reference. Check the values file:
```bash
grep -A 5 "GF_DATABASE" monitoring/prometheus-values.yml
```

### Grafana Cannot Connect to Database

**Solution**: Check these items:
1. PostgreSQL pod is running: `kubectl get pods -n postgres`
2. Database exists: `\l` in psql
3. User exists: `\du postgres_fid` in psql
4. Secret password matches: `kubectl get secret grafana-db-credentials -n monitoring -o yaml`
5. Network connectivity: Test with kubectl run command (see Step 3)

### Grafana Pod Keeps Restarting

**Solution**: Check Grafana logs for connection errors:
```bash
kubectl logs -n monitoring deployment/prometheus-grafana -c grafana --tail=100
```

Common errors:
- `FATAL: password authentication failed for user "postgres_fid"` → Wrong password in secret
- `database "grafana" does not exist` → Database not created
- `no pg_hba.conf entry` → PostgreSQL authentication issue

## Architecture Summary

```
Grafana Pod
    ↓
Environment Variables:
- GF_DATABASE_TYPE=postgres
- GF_DATABASE_HOST=postgres-postgresql.postgres.svc.cluster.local:5432
- GF_DATABASE_NAME=grafana
- GF_DATABASE_USER=postgres_fid
- GF_DATABASE_PASSWORD=(from secret)
    ↓
PostgreSQL Instance
- Host: postgres-postgresql.postgres.svc.cluster.local
- Port: 5432
- Database: grafana
- User: postgres_fid
- Password: From secret
```

## Benefits

✅ **Centralized database management** - Grafana data in PostgreSQL with other services
✅ **Better performance** - PostgreSQL handles concurrent users better than SQLite
✅ **Easier backups** - Single backup process for all databases
✅ **Scalability** - PostgreSQL can handle larger Grafana installations
✅ **No local PVC needed** - Grafana persistence disabled, data stored in PostgreSQL

## Notes

- Prometheus continues to use its own TSDB on disk (by design)
- This is a **clean start** - existing SQLite data is not migrated
- To migrate SQLite data later, export dashboards and reimport
- Database password should be secure and stored only in Kubernetes secret
