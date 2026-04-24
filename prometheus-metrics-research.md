# Prometheus Metrics Configuration Research

This document summarizes how to enable Prometheus metrics for various services in the homelab.

---

## 1. Authelia

### Native Support
✅ **Yes** - Authelia has built-in Prometheus metrics support.

### Configuration
Add the following to your Authelia configuration file (`configuration.yml`):

```yaml
telemetry:
  metrics:
    enabled: true
    address: 'tcp://:9959/metrics'  # Default endpoint
    buffers:
      read: 4096
      write: 4096
    timeouts:
      read: '6s'
      write: '6s'
      idle: '30s'
```

### Environment Variables
Can also be configured via environment variables:
```bash
AUTHELIA_TELEMETRY_METRICS_ENABLED=true
AUTHELIA_TELEMETRY_METRICS_ADDRESS=tcp://:9959/metrics
```

### Metrics Endpoint
- **Path**: `/metrics`
- **Port**: `9959` (default)
- **Full URL**: `http://authelia-host:9959/metrics`

### Source
- https://www.authelia.com/configuration/telemetry/metrics/

---

## 2. Jellyfin

### Native Support
❌ **No** - Jellyfin does not have native Prometheus metrics. Requires a 3rd party exporter.

### Options

#### Option A: jellyfin_exporter (Python-based)
There are several community exporters available. The most common approach is to use a standalone exporter that queries the Jellyfin API.

#### Option B: Prometheus Plugin (if available)
Check for community plugins in Jellyfin's plugin catalog.

### Recommended: Use a Dedicated Exporter
Deploy a jellyfin exporter as a sidecar container. You'll need:

1. Jellyfin API key (from Dashboard > API Keys)
2. Exporter container pointing to Jellyfin

### Example Exporter Configuration
```yaml
# Example using a generic jellyfin exporter
env:
  - name: JELLYFIN_URL
    value: "http://jellyfin:8096"
  - name: JELLYFIN_API_KEY
    valueFrom:
      secretKeyRef:
        name: jellyfin-secrets
        key: api-key
```

### Metrics Endpoint (via exporter)
- **Path**: `/metrics`
- **Port**: Varies by exporter (commonly `9708` or similar)

### Notes
- Jellyfin's official plugin repository does not currently have a maintained Prometheus plugin
- Consider using a community exporter or creating custom metrics via the Jellyfin API

---

## 3. Forgejo (Gitea Fork)

### Native Support
✅ **Yes** - Forgejo/Gitea has built-in Prometheus metrics support.

### Configuration
Edit `custom/conf/app.ini` and add:

```ini
[metrics]
ENABLED = true
ENABLED_ISSUE_BY_LABEL = false
ENABLED_ISSUE_BY_REPOSITORY = false
TOKEN = ""  # Optional: Set a bearer token for authentication
```

### Environment Variables (Docker)
```bash
GITEA__metrics__ENABLED=true
GITEA__metrics__TOKEN=your-secure-token
```

### Metrics Endpoint
- **Path**: `/metrics`
- **Port**: Main Forgejo port (default `3000`)
- **Full URL**: `http://forgejo-host:3000/metrics`

### Optional Token Authentication
If `TOKEN` is set, configure Prometheus with:
```yaml
bearer_token: "your-secure-token"
```

### Available Metrics
- Issue counts by label (`gitea_issues_by_label`)
- Issue counts by repository (`gitea_issues_by_repository`)
- Standard Go metrics
- Process metrics

### Sources
- https://docs.gitea.com/administration/config-cheat-sheet#metrics-metrics
- https://forgejo.org/docs/latest/admin/config-cheat-sheet/

---

## 4. OpenProject

### Native Support
✅ **Yes** - OpenProject has built-in Prometheus metrics via Yabeda gem.

### Configuration (Environment Variables)
```bash
OPENPROJECT_PROMETHEUS_EXPORT=true
PROMETHEUS_EXPORTER_BIND=0.0.0.0
PROMETHEUS_EXPORTER_PORT=9394
```

### Docker Compose Example
```yaml
environment:
  - OPENPROJECT_PROMETHEUS_EXPORT=true
  - PROMETHEUS_EXPORTER_BIND=0.0.0.0
  - PROMETHEUS_EXPORTER_PORT=9394
```

### Kubernetes ConfigMap Example
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openproject-config
data:
  OPENPROJECT_PROMETHEUS_EXPORT: "true"
  PROMETHEUS_EXPORTER_BIND: "0.0.0.0"
  PROMETHEUS_EXPORTER_PORT: "9394"
```

### Metrics Endpoint
- **Path**: `/metrics`
- **Port**: `9394` (default, configurable)
- **Full URL**: `http://openproject-host:9394/metrics`

### Available Metrics
- Puma web server metrics
- ActiveRecord database metrics
- Rails request metrics
- Custom application metrics

### Source
- https://www.openproject.org/docs/installation-and-operations/operation/monitoring/#prometheus-metrics

---

## 5. Servarr Stack (Sonarr, Radarr, Prowlarr, Bazarr)

### Native Support
❌ **No** - These services do not have native Prometheus endpoints. Use **exportarr**.

### Solution: Exportarr
A dedicated Prometheus exporter for the Servarr ecosystem.

**Repository**: https://github.com/onedr0p/exportarr

### Supported Apps
- Sonarr
- Radarr
- Lidarr
- Prowlarr
- Readarr
- Bazarr
- Sabnzbd

### Configuration

#### Docker Example (per app)
```yaml
# Sonarr Exporter
services:
  exportarr-sonarr:
    image: ghcr.io/onedr0p/exportarr:latest
    container_name: exportarr-sonarr
    command: sonarr
    environment:
      - PORT=9707
      - URL=http://sonarr:8989
      - API_KEY=${SONARR_API_KEY}
      - ENABLE_ADDITIONAL_METRICS=false
      - LOG_LEVEL=INFO
    ports:
      - "9707:9707"
    restart: unless-stopped

  # Radarr Exporter
  exportarr-radarr:
    image: ghcr.io/onedr0p/exportarr:latest
    container_name: exportarr-radarr
    command: radarr
    environment:
      - PORT=9708
      - URL=http://radarr:7878
      - API_KEY=${RADARR_API_KEY}
      - ENABLE_ADDITIONAL_METRICS=false
      - LOG_LEVEL=INFO
    ports:
      - "9708:9708"
    restart: unless-stopped

  # Prowlarr Exporter
  exportarr-prowlarr:
    image: ghcr.io/onedr0p/exportarr:latest
    container_name: exportarr-prowlarr
    command: prowlarr
    environment:
      - PORT=9709
      - URL=http://prowlarr:9696
      - API_KEY=${PROWLARR_API_KEY}
      - PROWLARR__BACKFILL=false  # Set true to backfill historical data
      - LOG_LEVEL=INFO
    ports:
      - "9709:9709"
    restart: unless-stopped

  # Bazarr Exporter
  exportarr-bazarr:
    image: ghcr.io/onedr0p/exportarr:latest
    container_name: exportarr-bazarr
    command: bazarr
    environment:
      - PORT=9710
      - URL=http://bazarr:6767
      - API_KEY=${BAZARR_API_KEY}
      - LOG_LEVEL=INFO
    ports:
      - "9710:9710"
    restart: unless-stopped
```

### Kubernetes Deployment Example
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: exportarr-sonarr
  namespace: media
spec:
  replicas: 1
  selector:
    matchLabels:
      app: exportarr-sonarr
  template:
    metadata:
      labels:
        app: exportarr-sonarr
    spec:
      containers:
        - name: exportarr
          image: ghcr.io/onedr0p/exportarr:latest
          args: ["sonarr"]
          env:
            - name: PORT
              value: "9707"
            - name: URL
              value: "http://sonarr.media.svc.cluster.local:8989"
            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: servarr-secrets
                  key: sonarr-api-key
          ports:
            - containerPort: 9707
              name: metrics
---
apiVersion: v1
kind: Service
metadata:
  name: exportarr-sonarr
  namespace: media
spec:
  selector:
    app: exportarr-sonarr
  ports:
    - port: 9707
      targetPort: 9707
      name: metrics
```

### Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| `PORT` | Port exporter listens on | ✅ Yes |
| `URL` | Full URL to the service | ✅ Yes |
| `API_KEY` | API key for the service | ✅ Yes |
| `ENABLE_ADDITIONAL_METRICS` | Enable slower, additional metrics | No (default: false) |
| `LOG_LEVEL` | Logging verbosity | No (default: INFO) |

### Prowlarr-Specific Options
| Variable | Description |
|----------|-------------|
| `PROWLARR__BACKFILL` | Enable backfill of historical metrics |
| `PROWLARR__BACKFILL_SINCE_DATE` | Start date for backfill (default: epoch) |

### Metrics Endpoints
| Service | Default Port | Full URL |
|---------|--------------|----------|
| Sonarr | 9707 | `http://exportarr-sonarr:9707/metrics` |
| Radarr | 9708 | `http://exportarr-radarr:9708/metrics` |
| Prowlarr | 9709 | `http://exportarr-prowlarr:9709/metrics` |
| Bazarr | 9710 | `http://exportarr-bazarr:9710/metrics` |

### Notes
- Each service requires its own exportarr instance
- Ports must be unique across all exportarr instances
- Exportarr is in maintenance mode per the maintainer, but still functional

---

## Summary Table

| Service | Native Support | Configuration Method | Metrics Port | Metrics Path |
|---------|----------------|---------------------|--------------|--------------|
| Authelia | ✅ Yes | YAML config | 9959 | `/metrics` |
| Jellyfin | ❌ No | External exporter | Varies | `/metrics` |
| Forgejo | ✅ Yes | INI config | 3000 | `/metrics` |
| OpenProject | ✅ Yes | Environment vars | 9394 | `/metrics` |
| Sonarr | ❌ No | Exportarr | 9707 (custom) | `/metrics` |
| Radarr | ❌ No | Exportarr | 9708 (custom) | `/metrics` |
| Prowlarr | ❌ No | Exportarr | 9709 (custom) | `/metrics` |
| Bazarr | ❌ No | Exportarr | 9710 (custom) | `/metrics` |

---

## Prometheus Scrape Configuration Example

```yaml
scrape_configs:
  # Authelia
  - job_name: 'authelia'
    static_configs:
      - targets: ['authelia.auth.svc.cluster.local:9959']

  # Forgejo
  - job_name: 'forgejo'
    static_configs:
      - targets: ['forgejo.forgejo.svc.cluster.local:3000']
    # If token is set:
    # bearer_token: "your-token"

  # OpenProject
  - job_name: 'openproject'
    static_configs:
      - targets: ['openproject.openproject.svc.cluster.local:9394']

  # Servarr Stack via Exportarr
  - job_name: 'sonarr'
    static_configs:
      - targets: ['exportarr-sonarr.media.svc.cluster.local:9707']

  - job_name: 'radarr'
    static_configs:
      - targets: ['exportarr-radarr.media.svc.cluster.local:9708']

  - job_name: 'prowlarr'
    static_configs:
      - targets: ['exportarr-prowlarr.media.svc.cluster.local:9709']

  - job_name: 'bazarr'
    static_configs:
      - targets: ['exportarr-bazarr.media.svc.cluster.local:9710']
```

---

## Next Steps

1. **Authelia**: Add `telemetry.metrics.enabled: true` to existing config
2. **Forgejo**: Add `[metrics]` section to `app.ini`
3. **OpenProject**: Add environment variables to deployment
4. **Servarr Stack**: Deploy exportarr sidecars for each service
5. **Jellyfin**: Research and deploy a suitable exporter (requires more investigation)
6. Configure Prometheus to scrape all endpoints
7. Create Grafana dashboards for visualization
