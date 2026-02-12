# Prometheus Monitoring Setup

This directory contains all the configuration files for deploying Prometheus monitoring in the k3s homelab.

## Architecture

- **Prometheus Operator**: Uses kube-prometheus-stack for simplified management
- **Grafana**: Visualization dashboard (PostgreSQL-backed)
- **Node Exporter**: Node-level metrics collection
- **Kube-State-Metrics**: Kubernetes object state metrics
- **Custom Exporters**: postgres-exporter, redis-exporter

### Database Configuration

**Grafana** uses PostgreSQL for data storage instead of SQLite:
- **Database**: `grafana`
- **Host**: `postgres-postgresql.postgres.svc.cluster.local:5432`
- **User**: `postgres_fid`
- **Password**: Stored in Kubernetes secret `grafana-db-credentials`

**Prometheus** uses its own TSDB (Time Series Database) on disk:
- **Retention**: 15 days
- **Storage**: 20Gi PVC
- **Note**: Prometheus cannot use PostgreSQL (TSDB is by design)

## Database Setup (Required Before Deployment)

Before deploying Grafana with PostgreSQL, you must manually configure the database:

### 1. Set Up PostgreSQL Database

Follow the instructions in `POSTGRESQL-SETUP.md` or run the SQL commands from `grafana-postgres-setup.sql`:

```bash
# Connect to PostgreSQL
kubectl exec -it -n postgres postgres-postgresql-0 -- psql -U postgres

# Run the SQL commands to create user and database
# See grafana-postgres-setup.sql for exact commands
```

### 2. Update Kubernetes Secret

After creating the database and user, update the secret with the password:

```bash
# Edit the secret and set the password
kubectl edit secret grafana-db-credentials -n monitoring
```

Or create/replace the secret:

```bash
kubectl create secret generic grafana-db-credentials \
  --from-literal=password='YOUR_PASSWORD' \
  -n monitoring
```

### 3. Verify Database Configuration

```bash
# Test connectivity from monitoring namespace
kubectl run postgres-test -n monitoring --rm -i --tty --image=bitnami/postgresql:16 \
  --env="PGPASSWORD=YOUR_PASSWORD" \
  -- psql -h postgres-postgresql.postgres.svc.cluster.local -U postgres_fid -d grafana -c "SELECT 1"
```

**Important**: Complete database setup before running the deployment script.

## Deployment

### Quick Start

```bash
cd monitoring
./deploy-prometheus.sh
```

### Manual Deployment

1. **Create namespace and label namespaces:**
   ```bash
   kubectl apply -f create-namespace.yml
   kubectl apply -f label-namespaces.yml
   ```

2. **Create Prometheus PVC:**
   ```bash
   kubectl apply -f prometheus-pvc.yml
   ```

3. **Deploy kube-prometheus-stack:**
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   helm install prometheus prometheus-community/kube-prometheus-stack \
     --namespace monitoring \
     -f prometheus-values.yml
   ```

4. **Create ingress:**
   ```bash
   kubectl apply -f prometheus-ingress.yml
   kubectl apply -f grafana-ingress.yml
   ```

5. **Create certificates (optional):**
   ```bash
   kubectl apply -f prometheus-certificate.yml
   kubectl apply -f grafana-certificate.yml
   ```

6. **Deploy ServiceMonitors:**
   ```bash
   kubectl apply -f servicemonitors/
   ```

7. **Deploy exporters:**
   ```bash
   kubectl apply -f ../postgres/postgres-exporter-secret.yml
   kubectl apply -f ../postgres/postgres-exporter.yml
   kubectl apply -f ../redis/redis-exporter.yml
   ```

## Access

### Prometheus
- **URL**: http://prometheus.picklemustard.dev
- **Port**: 9090

### Grafana
- **URL**: http://grafana.picklemustard.dev
- **Port**: 3000
- **Default Credentials**:
  - Username: `admin`
  - Password: Get with:
    ```bash
    kubectl get secret -n monitoring grafana \
      -o jsonpath="{.data.admin-password}" | base64 --decode
    ```

## DNS Configuration

Add the following DNS records to Cloudflare:

| Domain | Type | Value |
|--------|------|-------|
| prometheus.picklemustard.dev | A | 192.168.1.142 |
| grafana.picklemustard.dev | A | 192.168.1.142 |

## Service Integration

### Services with Prometheus Annotations

The following services have been updated to expose metrics:

| Service | Namespace | Metrics Port | Metrics Path |
|---------|-----------|--------------|--------------|
| Authelia | auth | 9091 | /metrics |
| Vaultwarden | vaultwarden | 80 | /metrics |
| Jellyfin | media | 8096 | /metrics |
| Sonarr | media | 8989 | /metrics |
| Radarr | media | 7878 | /metrics |
| Prowlarr | media | 9696 | /metrics |
| Bazarr | media | 6767 | /metrics |
| Stalwart Mail | stalwart | 80 | /metrics |
| LLDAP | auth | 17170 | /metrics |
| Traefik | kube-system | - | /metrics |
| CoreDNS | kube-system | 9153 | /metrics |

### Custom Exporters

#### PostgreSQL Exporter
- **Namespace**: postgres
- **Service**: postgres-exporter
- **Port**: 9187
- **Configuration**: Connects to PostgreSQL instance with credentials from secret

#### Redis Exporter
- **Namespace**: redis
- **Service**: redis-exporter
- **Port**: 9121
- **Configuration**: Connects to redis-master:6379

## ServiceMonitors

ServiceMonitors are defined in the `servicemonitors/` directory:

- `traefik-servicemonitor.yml`: Monitors Traefik ingress controller
- `coredns-servicemonitor.yml`: Monitors CoreDNS
- `authelia-servicemonitor.yml`: Monitors Authelia
- `vaultwarden-servicemonitor.yml`: Monitors Vaultwarden
- `jellyfin-servicemonitor.yml`: Monitors Jellyfin
- `servarr-servicemonitor.yml`: Monitors Starr stack
- `stalwart-servicemonitor.yml`: Monitors Stalwart Mail
- `lldap-servicemonitor.yml`: Monitors LLDAP
- `postgres-exporter-servicemonitor.yml`: Monitors PostgreSQL exporter
- `redis-exporter-servicemonitor.yml`: Monitors Redis exporter

## Storage

- **Prometheus Data**: 20Gi PVC (15-day retention)
- **Grafana Data**: 5Gi PVC
- **Storage Class**: local-path

## Configuration

### Prometheus Values

Key configuration options in `prometheus-values.yml`:

- **Retention**: 15 days
- **Storage**: 20Gi PVC
- **Scrape Interval**: 30s (default)
- **ServiceMonitor Selector**: All namespaces with label `monitoring: enabled`

### Customization

To add new service monitoring:

1. Add `prometheus.io/scrape: "true"` annotation to the service
2. Specify port: `prometheus.io/port: "<port>"`
3. Specify path: `prometheus.io/path: "<path>"`
4. Create a ServiceMonitor CRD in `servicemonitors/` directory
5. Label the namespace with `monitoring: enabled`

## Troubleshooting

### Check Prometheus Targets

```bash
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090
# Open http://localhost:9090/targets
```

### Check Pod Status

```bash
kubectl get pods -n monitoring
```

### View Logs

```bash
# Prometheus logs
kubectl logs -n monitoring deployment/prometheus-k8s -f

# Grafana logs
kubectl logs -n monitoring deployment/grafana -f

# Operator logs
kubectl logs -n monitoring deployment/prometheus-operator -f
```

### Verify ServiceMonitors

```bash
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor <name> -n monitoring
```

## Metrics Collection

### Kubernetes Metrics
- API Server
- Nodes (via kubelet)
- Pods and containers
- Services and endpoints

### Application Metrics
- HTTP request rates and latencies
- Database query performance
- Cache hit rates
- Resource usage (CPU, memory, disk, network)

### Custom Dashboards
Import pre-configured dashboards from:
- Grafana.com dashboards
- Helm chart default dashboards
- Community-contributed dashboards

## Upgrades

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f prometheus-values.yml
```

## Backup and Restore

### Backup

```bash
kubectl exec -n monitoring prometheus-k8s-0 -- tar czf - /prometheus > prometheus-backup.tar.gz
```

### Restore

```bash
cat prometheus-backup.tar.gz | kubectl exec -n monitoring prometheus-k8s-0 -- tar xzf - -C /prometheus
```

## References

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
