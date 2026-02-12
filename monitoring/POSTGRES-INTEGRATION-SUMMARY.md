# PostgreSQL Integration for Grafana - Setup Complete

## Summary

All configuration files have been created to integrate Grafana with PostgreSQL database. Grafana will now use PostgreSQL instead of SQLite for better performance and centralized data management.

## Files Created/Modified

### Configuration Files

1. **monitoring/prometheus-values.yml** (Modified)
   - Updated Grafana configuration to use PostgreSQL
   - Disabled Grafana PVC (data now in PostgreSQL)
   - Added environment variables for PostgreSQL connection:
     - `GF_DATABASE_TYPE=postgres`
     - `GF_DATABASE_HOST=postgres-postgresql.postgres.svc.cluster.local:5432`
     - `GF_DATABASE_NAME=grafana`
     - `GF_DATABASE_USER=postgres_fid`
     - `GF_DATABASE_PASSWORD` (from secret)

2. **monitoring/grafana-db-secret.yml** (New)
   - Kubernetes secret template for Grafana database credentials
   - Placeholder password: `SET_PASSWORD_HERE`

3. **monitoring/deploy-prometheus.sh** (Modified)
   - Added pre-flight check for database configuration
   - Validates that secret exists and is configured
   - Fails early if database not set up (prevents broken deployment)

### Documentation Files

4. **monitoring/POSTGRESQL-SETUP.md** (New)
   - Comprehensive PostgreSQL setup guide
   - SQL commands to create user and database
   - Troubleshooting steps
   - Connection verification commands

5. **monitoring/grafana-postgres-setup.sql** (New)
   - Quick reference SQL commands
   - Ready to copy and paste into psql
   - Creates postgres_fid user and grafana database

6. **monitoring/QUICK-START.md** (New)
   - Step-by-step quick start guide
   - Pre-deployment checklist
   - Verification steps
   - Troubleshooting common issues

7. **monitoring/README.md** (Modified)
   - Updated architecture section
   - Added database configuration details
   - Documented Prometheus TSDB vs PostgreSQL distinction

## Manual Setup Required (You Do This)

### Step 1: Create Database User and Database in PostgreSQL

```bash
# Connect to PostgreSQL
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres

# Copy and run the SQL commands from monitoring/grafana-postgres-setup.sql
```

**Or run these commands directly:**

```sql
CREATE USER postgres_fid WITH PASSWORD 'YOUR_SECURE_PASSWORD_HERE';
ALTER USER postgres_fid WITH SUPERUSER;
CREATE DATABASE grafana OWNER postgres_fid;
\l
\du postgres_fid
\q
```

**Important**: Replace `YOUR_SECURE_PASSWORD_HERE` with a strong, secure password.

### Step 2: Create Kubernetes Secret with Your Password

```bash
kubectl create secret generic grafana-db-credentials \
  --from-literal.password='YOUR_SECURE_PASSWORD_HERE' \
  -n monitoring
```

**Note**: Use the same password you created in Step 1.

### Step 3: Verify Setup (Optional but Recommended)

```bash
# Test database connectivity
kubectl run postgres-test -n monitoring --rm -i --tty --image=bitnami/postgresql:16 \
  --env="PGPASSWORD=YOUR_PASSWORD" \
  -- psql -h postgres-postgresql.postgres.svc.cluster.local -U postgres_fid -d grafana -c "SELECT 1"
```

## Deploy After Database Setup

Once you've completed the manual database setup (steps above), deploy the monitoring stack:

```bash
cd /app-storage/k3s/monitoring
./deploy-prometheus.sh
```

The deployment script will:
- ✓ Verify database configuration exists
- ✓ Create monitoring namespace
- ✓ Label namespaces for monitoring
- ✓ Create Prometheus PVC (20Gi, TSDB)
- ✓ Deploy kube-prometheus-stack with PostgreSQL-backed Grafana
- ✓ Create ingresses for Prometheus and Grafana
- ✓ Create TLS certificates (if cert-manager available)
- ✓ Deploy ServiceMonitors for all services
- ✓ Deploy postgres-exporter
- ✓ Deploy redis-exporter

## What Changed

### Grafana Storage

**Before (SQLite)**:
- Local PVC: 5Gi (no longer needed)
- Database file: `/var/lib/grafana/grafana.db`
- Slower performance with many users/dashboards

**After (PostgreSQL)**:
- No local PVC for Grafana
- Database: `grafana` in PostgreSQL cluster
- Better performance, centralized backups

### Prometheus Storage

**No Change**:
- Continues using TSDB on 20Gi PVC
- This is correct - Prometheus TSDB cannot use PostgreSQL

## Database Connection Details

| Parameter | Value |
|-----------|-------|
| Database Type | PostgreSQL |
| Host | postgres-postgresql.postgres.svc.cluster.local |
| Port | 5432 |
| Database Name | grafana |
| User | postgres_fid |
| Password | From Kubernetes secret `grafana-db-credentials` |

## Verification After Deployment

### 1. Check Grafana is Running

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
```

### 2. Verify PostgreSQL Connection in Logs

```bash
kubectl logs -n monitoring deployment/prometheus-grafana -c grafana | grep -i database
```

Should see:
```
logger=sqlstore t=... level=info msg="Connecting to DB" dbtype=postgres
```

### 3. Access Grafana UI

- URL: http://grafana.picklemustard.dev
- Username: `admin`
- Password: `kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode`

### 4. Check Prometheus Targets

```bash
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090
# Open http://localhost:9090/targets
```

## Troubleshooting

### Deployment Script Fails

**"grafana-db-credentials secret not found"**:
- Create the secret: See Step 2 above

**"secret has not been configured yet"**:
- Edit the secret: `kubectl edit secret grafana-db-credentials -n monitoring`
- Replace `SET_PASSWORD_HERE` with your actual password

### Grafana Cannot Connect to Database

1. Verify PostgreSQL pod is running: `kubectl get pods -n postgres`
2. Verify database exists: `\l` in psql
3. Verify user exists: `\du postgres_fid` in psql
4. Check Grafana logs: `kubectl logs -n monitoring deployment/prometheus-grafana -c grafana`
5. Test network connectivity: See Step 3 in "Manual Setup Required" section

### Grafana Keeps Restarting

Check logs for connection errors:
```bash
kubectl logs -n monitoring deployment/prometheus-grafana -c grafana --tail=100
```

## Benefits of This Configuration

✅ **Centralized Data Management**: All application data in PostgreSQL
✅ **Better Performance**: PostgreSQL handles concurrent connections better
✅ **Easier Backups**: Single backup strategy for all databases
✅ **Scalability**: PostgreSQL can handle larger Grafana installations
✅ **No Duplicate PVC**: Grafana PVC removed, saving storage space
✅ **Clean Architecture**: Separation of concerns (PostgreSQL for apps, TSDB for metrics)

## Important Notes

⚠️ **Prometheus Still Uses Disk**: Prometheus TSDB cannot use PostgreSQL - this is by design
⚠️ **Clean Start**: This setup starts fresh - existing SQLite Grafana data is not migrated
⚠️ **Manual Configuration**: Database setup must be completed before deployment
⚠️ **Security**: Database password is only stored in Kubernetes secret, never in plain text files

## File Reference

| File | Purpose |
|-------|---------|
| `prometheus-values.yml` | Helm values with PostgreSQL config |
| `grafana-db-secret.yml` | Secret template for DB password |
| `deploy-prometheus.sh` | Deployment script with validation |
| `POSTGRESQL-SETUP.md` | Detailed setup guide |
| `grafana-postgres-setup.sql` | SQL commands to run |
| `QUICK-START.md` | Quick reference guide |
| `README.md` | General documentation |

## Next Steps

1. ✅ Review SQL commands in `monitoring/grafana-postgres-setup.sql`
2. ✅ Connect to PostgreSQL and create user/database
3. ✅ Update Kubernetes secret with your password
4. ✅ Run deployment script: `./deploy-prometheus.sh`
5. ✅ Verify Grafana is using PostgreSQL
6. ✅ Add DNS records for prometheus.picklemustard.dev and grafana.picklemustard.dev

## Need Help?

- See `monitoring/POSTGRESQL-SETUP.md` for detailed troubleshooting
- See `monitoring/QUICK-START.md` for step-by-step guide
- See `monitoring/README.md` for general documentation
