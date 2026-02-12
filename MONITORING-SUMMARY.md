# Prometheus Monitoring Implementation Summary

## Files Created

### Core Configuration Files (monitoring/)

1. **create-namespace.yml**
   - Creates the `monitoring` namespace
   - Labels it with `monitoring: enabled`

2. **prometheus-pvc.yml**
   - Creates 20Gi PersistentVolumeClaim for Prometheus data
   - Uses local-path storage class
   - 15-day retention period

3. **prometheus-values.yml**
   - Helm values configuration for kube-prometheus-stack
   - Configures Prometheus retention, storage, and ServiceMonitor selectors
   - Configures Grafana persistence (5Gi)
   - Enables Node Exporter
   - Disables some Kubernetes components not running in this cluster

4. **prometheus-ingress.yml**
   - Traefik ingress for Prometheus UI
   - Host: prometheus.picklemustard.dev

5. **grafana-ingress.yml**
   - Traefik ingress for Grafana UI
   - Host: grafana.picklemustard.dev

6. **prometheus-certificate.yml**
   - Certificate request for Prometheus TLS
   - Uses cert-manager with Let's Encrypt

7. **grafana-certificate.yml**
   - Certificate request for Grafana TLS
   - Uses cert-manager with Let's Encrypt

8. **label-namespaces.yml**
   - Labels namespaces with `monitoring: enabled` for ServiceMonitor discovery
   - Applies to: auth, media, vaultwarden, postgres, redis, stalwart, kube-system

9. **deploy-prometheus.sh**
   - Automated deployment script
   - Creates all resources in correct order
   - Includes verification steps

### ServiceMonitors (monitoring/servicemonitors/)

1. **traefik-servicemonitor.yml**
   - Monitors Traefik ingress controller
   - Scrape interval: 30s
   - Path: /metrics

2. **coredns-servicemonitor.yml**
   - Monitors CoreDNS
   - Port: 9153
   - Scrape interval: 30s

3. **authelia-servicemonitor.yml**
   - Monitors Authelia
   - Port: 9091
   - Scrape interval: 30s

4. **vaultwarden-servicemonitor.yml**
   - Monitors Vaultwarden
   - Port: 80
   - Scrape interval: 30s

5. **jellyfin-servicemonitor.yml**
   - Monitors Jellyfin
   - Port: 8096
   - Scrape interval: 30s

6. **servarr-servicemonitor.yml**
   - Monitors Starr stack (Sonarr, Radarr, Prowlarr, Bazarr)
   - Multiple ports: 8989, 7878, 9696, 6767
   - Scrape interval: 30s

7. **stalwart-servicemonitor.yml**
   - Monitors Stalwart Mail
   - Port: 80
   - Scrape interval: 30s

8. **lldap-servicemonitor.yml**
   - Monitors LLDAP
   - Port: 17170
   - Scrape interval: 30s

9. **postgres-exporter-servicemonitor.yml**
   - Monitors PostgreSQL exporter
   - Port: 9187
   - Scrape interval: 30s

10. **redis-exporter-servicemonitor.yml**
    - Monitors Redis exporter
    - Port: 9121
    - Scrape interval: 30s

### Exporter Deployments

1. **postgres/postgres-exporter.yml**
   - Deployment for postgres-exporter
   - Service exposing port 9187
   - Connects to PostgreSQL instance

2. **postgres/postgres-exporter-secret.yml**
   - Secret containing database connection string
   - Reference to postgres password secret

3. **redis/redis-exporter.yml**
   - Deployment for redis-exporter
   - Service exposing port 9121
   - Connects to redis-master:6379

## Service Modifications

### Updated Services with Prometheus Annotations

1. **authelia/authelia-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "9091"`
   - Added: `prometheus.io/path: "/metrics"`

2. **vaultwarden/server.yml**
   - Added Prometheus annotations to vaultwarden-service

3. **jellyfin/service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "8096"`
   - Added: `prometheus.io/path: "/metrics"`

4. **starr-config/sonarr/sonarr-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "8989"`
   - Added: `prometheus.io/path: "/metrics"`

5. **starr-config/radarr/radarr-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "7878"`
   - Added: `prometheus.io/path: "/metrics"`

6. **starr-config/prowlarr/prowlarr-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "9696"`
   - Added: `prometheus.io/path: "/metrics"`

7. **starr-config/bazarr/bazarr-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "6767"`
   - Added: `prometheus.io/path: "/metrics"`

8. **stalwart/service.yml**
   - Added Prometheus annotations to stalwart service

9. **lldap/lldap-service.yml**
   - Added: `prometheus.io/scrape: "true"`
   - Added: `prometheus.io/port: "17170"`
   - Added: `prometheus.io/path: "/metrics"`

## Deployment Instructions

### Quick Deployment

```bash
cd /app-storage/k3s/monitoring
./deploy-prometheus.sh
```

### Manual Deployment

```bash
# 1. Create namespace and label namespaces
kubectl apply -f monitoring/create-namespace.yml
kubectl apply -f monitoring/label-namespaces.yml

# 2. Create Prometheus PVC
kubectl apply -f monitoring/prometheus-pvc.yml

# 3. Install kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus-values.yml

# 4. Create ingress
kubectl apply -f monitoring/prometheus-ingress.yml
kubectl apply -f monitoring/grafana-ingress.yml

# 5. Create certificates (optional)
kubectl apply -f monitoring/prometheus-certificate.yml
kubectl apply -f monitoring/grafana-certificate.yml

# 6. Deploy ServiceMonitors
kubectl apply -f monitoring/servicemonitors/

# 7. Deploy exporters
kubectl apply -f postgres/postgres-exporter-secret.yml
kubectl apply -f postgres/postgres-exporter.yml
kubectl apply -f redis/redis-exporter.yml
```

## DNS Configuration Required

Add the following DNS records to Cloudflare:

| Domain | Type | Value |
|--------|------|-------|
| prometheus.picklemustard.dev | A | 192.168.1.142 |
| grafana.picklemustard.dev | A | 192.168.1.142 |

## Access Information

### Prometheus
- **URL**: http://prometheus.picklemustard.dev
- **Port**: 9090
- **Targets**: /targets

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

## Storage Requirements

- Prometheus data: 20Gi PVC (15-day retention)
- Grafana data: 5Gi PVC
- Total: 25Gi
- Storage class: local-path

## Monitored Services Summary

| Service | Namespace | Type | Metrics Port | Status |
|---------|-----------|------|--------------|--------|
| Kubernetes Cluster | kube-system | System | - | ✓ |
| Node Exporter | - | System | 9100 | ✓ (via kube-prometheus-stack) |
| Traefik | kube-system | Ingress | 8080 | ✓ |
| CoreDNS | kube-system | DNS | 9153 | ✓ |
| Authelia | auth | Auth | 9091 | ✓ |
| Vaultwarden | vaultwarden | Password | 80 | ✓ |
| Jellyfin | media | Media | 8096 | ✓ |
| Sonarr | media | Media | 8989 | ✓ |
| Radarr | media | Media | 7878 | ✓ |
| Prowlarr | media | Media | 9696 | ✓ |
| Bazarr | media | Media | 6767 | ✓ |
| Stalwart Mail | stalwart | Email | 80 | ✓ |
| LLDAP | auth | Auth | 17170 | ✓ |
| PostgreSQL | postgres | Database | 9187 | ✓ (via exporter) |
| Redis | redis | Cache | 9121 | ✓ (via exporter) |

## Verification Steps

After deployment, verify the following:

1. **Check pod status**:
   ```bash
   kubectl get pods -n monitoring
   ```

2. **Check Prometheus targets**:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090
   # Open http://localhost:9090/targets
   ```

3. **Check Grafana**:
   ```bash
   # Access at http://grafana.picklemustard.dev
   # Login with default credentials
   ```

4. **Check ServiceMonitors**:
   ```bash
   kubectl get servicemonitor -n monitoring
   ```

5. **Check exporters**:
   ```bash
   kubectl get pods -n postgres -l app.kubernetes.io/name=postgres-exporter
   kubectl get pods -n redis -l app.kubernetes.io/name=redis-exporter
   ```

## Troubleshooting

### Common Issues

1. **ServiceMonitor not discovered**
   - Ensure namespace has label `monitoring: enabled`
   - Check ServiceMonitor selector matches service labels

2. **Targets showing down**
   - Verify service exposes metrics port
   - Check service annotations
   - Verify metrics endpoint is accessible

3. **Storage issues**
   - Ensure PVC is bound
   - Check available disk space
   - Verify storage class is correct

4. **Ingress not working**
   - Verify DNS records are configured
   - Check Traefik is running
   - Validate ingress YAML

## Maintenance

### Backup Prometheus Data
```bash
kubectl exec -n monitoring prometheus-k8s-0 -- tar czf - /prometheus > prometheus-backup.tar.gz
```

### Upgrade
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus-values.yml
```

### Remove Deployment
```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```
