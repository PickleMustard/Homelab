# Stalwart Mail Server - Prometheus Metrics Configuration

## Summary

This document outlines how to enable Prometheus metrics in Stalwart mail server.

---

## 1. Configuration Options for Enabling the /metrics Endpoint

The Prometheus metrics exporter is **disabled by default**. To enable it, you need to add the following TOML configuration:

```toml
[metrics.prometheus]
enable = true
```

### Optional Authentication

You can optionally protect the metrics endpoint with basic authentication:

```toml
[metrics.prometheus]
enable = true

[metrics.prometheus.auth]
username = "prometheus"
secret = "password123"
```

### Configuration Options Summary

| Setting | Description | Default |
|---------|-------------|---------|
| `metrics.prometheus.enable` | Enables/disables the Prometheus metrics exporter | `false` |
| `metrics.prometheus.auth.username` | Username for basic auth (optional) | - |
| `metrics.prometheus.auth.secret` | Password/secret for basic auth (optional) | - |

---

## 2. Port Exposure

**The `/metrics/prometheus` endpoint is exposed on the same HTTP listener as the web interface.**

According to the documentation, Stalwart's HTTP service serves multiple functions including:
- JMAP access
- WebDAV access  
- API management
- ACME certificate issuance
- **Metrics collection**
- OAuth authentication

The endpoint is accessible at: `http://<http-listener-host>:<http-listener-port>/metrics/prometheus`

### Example Listener Configuration

```toml
[server.listener."management"]
bind = ["127.0.0.1:8080"]
protocol = "http"
```

With this configuration, metrics would be available at:
- `http://127.0.0.1:8080/metrics/prometheus`

**Note:** The metrics endpoint is NOT on a separate port like many other applications. It shares the HTTP listener with the web admin interface and API.

---

## 3. Metrics Format

Stalwart uses the **standard Prometheus text format** for metrics export. This is fully compatible with Prometheus scraping and can be queried using PromQL.

The metrics exposed include:
- Resource usage
- Request handling statistics
- Error rates
- Network traffic
- Response times

---

## 4. Complete TOML Configuration Example

### Basic Configuration (No Auth)

```toml
# Enable Prometheus metrics
[metrics.prometheus]
enable = true

# HTTP listener (required for metrics endpoint)
[server.listener."http"]
bind = ["[::]:8080"]
protocol = "http"
```

### Configuration with Basic Auth

```toml
# Enable Prometheus metrics with authentication
[metrics.prometheus]
enable = true

[metrics.prometheus.auth]
username = "prometheus_user"
secret = "secure_password_here"

# HTTP listener
[server.listener."http"]
bind = ["0.0.0.0:8080"]
protocol = "http"
```

### Disabling Specific Metrics (Optional)

If you want to disable collection of certain metrics:

```toml
[metrics]
disabled-events = ["auth.error", "smtp.error"]

[metrics.prometheus]
enable = true
```

---

## 5. Prometheus Scrape Configuration

Add the following to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'stalwart'
    static_configs:
      - targets: ['stalwart-host:8080']
    metrics_path: '/metrics/prometheus'
    # If using basic auth:
    basic_auth:
      username: prometheus_user
      password: secure_password_here
```

---

## 6. Kubernetes Deployment Notes

For your k3s homelab, the metrics endpoint will be accessible through the Stalwart service. Key considerations:

1. **Service Port**: Ensure your Stalwart service exposes the HTTP port (e.g., 8080)
2. **Ingress**: The metrics endpoint could be accessed via ingress at `/metrics/prometheus`
3. **ServiceMonitor**: If using Prometheus Operator, create a ServiceMonitor that targets the `/metrics/prometheus` path

### Example ServiceMonitor (Prometheus Operator)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: stalwart
  namespace: stalwart
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: stalwart
  endpoints:
    - port: http
      path: /metrics/prometheus
      interval: 30s
      # Optional basic auth:
      # basicAuth:
      #   username:
      #     name: stalwart-metrics-auth
      #     key: username
      #   password:
      #     name: stalwart-metrics-auth
      #     key: password
```

---

## Sources

- Stalwart Telemetry Overview: https://stalw.art/docs/telemetry/overview
- Stalwart Prometheus Metrics: https://stalw.art/docs/telemetry/metrics/prometheus
- Stalwart Metrics Overview: https://stalw.art/docs/telemetry/metrics/overview
- Stalwart HTTP Overview: https://stalw.art/docs/http/overview
- Stalwart Listener Configuration: https://stalw.art/docs/server/listener
