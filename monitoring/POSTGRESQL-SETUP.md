# PostgreSQL Setup for Grafana

This document provides the SQL commands and steps to configure PostgreSQL for Grafana integration.

## Manual Configuration Steps

### 1. Connect to PostgreSQL

```bash
# Connect to the PostgreSQL pod
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres
```

### 2. Create the postgres_fid User

Run the following SQL command in the PostgreSQL prompt:

```sql
-- Create the grafana database user
CREATE USER postgres_fid WITH PASSWORD 'YOUR_SECURE_PASSWORD_HERE';

-- Grant necessary privileges
ALTER USER postgres_fid WITH SUPERUSER;

-- Exit PostgreSQL
\q
```

**Important**: Replace `YOUR_SECURE_PASSWORD_HERE` with a strong, secure password.

### 3. Create the grafana Database

Connect again with the postgres_fid user (recommended) or continue as postgres to create the database:

```sql
-- Connect to PostgreSQL
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres

-- Create the grafana database
CREATE DATABASE grafana OWNER postgres_fid;

-- Grant all privileges on grafana database to postgres_fid
GRANT ALL PRIVILEGES ON DATABASE grafana TO postgres_fid;

-- Exit PostgreSQL
\q
```

### 4. Update Grafana Secret

After setting the password, update the Kubernetes secret:

```bash
# Edit the secret and set the password
kubectl create secret generic grafana-db-credentials \
  --from-literal=password='YOUR_SECURE_PASSWORD_HERE' \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
```

Or edit the existing secret:

```bash
kubectl edit secret grafana-db-credentials -n monitoring
```

### 5. Verify Database Access

Test the connection from Grafana namespace:

```bash
# Create a test pod
kubectl run postgres-test -n monitoring --rm -i --tty --image=bitnami/postgresql:16 \
  --env="PGPASSWORD=YOUR_SECURE_PASSWORD_HERE" \
  -- psql -h postgres-postgresql.postgres.svc.cluster.local -U postgres_fid -d grafana -c "SELECT 1"
```

### 6. Apply Updated Configuration

After configuring the database and updating the secret, upgrade the Helm release:

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus-values.yml
```

### 7. Verify Grafana Started with PostgreSQL

Check Grafana logs to confirm it's using PostgreSQL:

```bash
kubectl logs -n monitoring deployment/prometheus-grafana -c grafana | grep -i "database"
```

You should see:
```
logger=sqlstore t=... level=info msg="Connecting to DB" dbtype=postgres
logger=sqlstore t=... level=info msg="Using Postgres driver" driver="..."
```

---

## Complete SQL Script

Save this as `setup-grafana-db.sql` and run it in PostgreSQL:

```sql
-- Create Grafana database user
CREATE USER postgres_fid WITH PASSWORD 'YOUR_SECURE_PASSWORD_HERE';

-- Create Grafana database
CREATE DATABASE grafana OWNER postgres_fid;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE grafana TO postgres_fid;

-- Verify creation
\l
\du postgres_fid
```

## PostgreSQL Connection Details

Grafana will connect using these parameters:

- **Host**: postgres-postgresql.postgres.svc.cluster.local
- **Port**: 5432
- **Database**: grafana
- **User**: postgres_fid
- **Password**: From Kubernetes secret `grafana-db-credentials`

---

## Migration Notes (Reference Only)

Since you're doing a **clean start**, there's no need to migrate existing SQLite data.
If you ever need to migrate from SQLite in the future:

1. Export Grafana data from SQLite:
   ```bash
   kubectl exec -n monitoring prometheus-grafana-xxx -- grafana-cli admin export-admin > backup.json
   ```

2. Import into PostgreSQL setup (advanced, requires manual migration tools)

---

## Troubleshooting

### Connection Errors

If Grafana cannot connect:

1. Check secret exists:
   ```bash
   kubectl get secret grafana-db-credentials -n monitoring
   ```

2. Verify PostgreSQL pod is running:
   ```bash
   kubectl get pods -n postgres
   ```

3. Test network connectivity:
   ```bash
   kubectl run network-test -n monitoring --rm -i --tty --image=curlimages/curl \
     -- curl -v postgres-postgresql.postgres.svc.cluster.local:5432
   ```

4. Check PostgreSQL logs:
   ```bash
   kubectl logs -n postgres postgres-postgresql-0
   ```

### Permission Errors

If Grafana gets permission denied, verify:
- Database exists: `\l` in psql
- User exists: `\du postgres_fid` in psql
- Privileges: `\l grafana` should show postgres_fid as owner

---

## Summary Checklist

- [ ] Create postgres_fid user with strong password
- [ ] Create grafana database
- [ ] Grant privileges to postgres_fid
- [ ] Update Kubernetes secret with password
- [ ] Apply updated Helm values
- [ ] Verify Grafana logs show PostgreSQL connection
- [ ] Access Grafana UI and login
