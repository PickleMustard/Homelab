# Traefik Request Tracing and Header Capture Configuration

This document covers Traefik's configuration for request tracing and header capture, with specific examples for Helm chart values files.

## Table of Contents
1. [Access Logs Configuration](#1-access-logs-configuration)
2. [Tracing Configuration](#2-tracing-configuration)
3. [Header Capture](#3-header-capture)
4. [Production-Ready Helm Values Examples](#4-production-ready-helm-values-examples)
5. [Best Practices](#5-best-practices)
6. [Sources](#sources)

---

## 1. Access Logs Configuration

Access logs capture information about incoming HTTP requests handled by Traefik.

### Access Log Formats

Traefik supports three access log formats:

| Format | Description |
|--------|-------------|
| `common` | Traefik's extended Common Log Format (default) |
| `genericCLF` | Generic CLF format compatible with standard log analyzers |
| `json` | JSON format for structured logging (recommended for production) |

### Available JSON Fields

When using JSON format, the following fields are available:

| Field | Description |
|-------|-------------|
| `StartUTC` | Time at which request processing started (UTC) |
| `StartLocal` | Local time at which request processing started |
| `Duration` | Total time taken in nanoseconds |
| `RouterName` | Name of the Traefik router |
| `ServiceName` | Name of the Traefik backend service |
| `ServiceURL` | URL of the Traefik backend |
| `ServiceAddr` | IP:port of the Traefik backend |
| `ClientAddr` | Remote address in its original form (usually IP:port) |
| `ClientHost` | Remote IP address from which the client request was received |
| `ClientPort` | Remote TCP port from which the client request was received |
| `ClientUsername` | Username provided in the URL, if present |
| `RequestAddr` | HTTP Host header (usually IP:port) |
| `RequestHost` | HTTP Host server name (not including port) |
| `RequestPort` | TCP port from the HTTP Host |
| `RequestMethod` | HTTP method |
| `RequestPath` | HTTP request URI |
| `RequestProtocol` | HTTP version requested |
| `RequestScheme` | HTTP scheme (`http` or `https`) |
| `RequestLine` | RequestMethod + RequestPath + RequestProtocol |
| `RequestContentSize` | Number of bytes in the request body |
| `OriginDuration` | Time taken by the origin server (upstream) |
| `OriginContentSize` | Content length specified by origin server |
| `OriginStatus` | HTTP status code returned by origin server |
| `OriginStatusLine` | OriginStatus + status code explanation |
| `DownstreamStatus` | HTTP status code returned to client |
| `DownstreamStatusLine` | DownstreamStatus + status code explanation |
| `DownstreamContentSize` | Bytes in response entity returned to client |
| `RequestCount` | Number of requests since Traefik started |
| `GzipRatio` | Response body compression ratio |
| `Overhead` | Processing time overhead caused by Traefik |
| `RetryAttempts` | Number of retry attempts |
| `TLSVersion` | TLS version used (if connection is TLS) |
| `TLSCipher` | TLS cipher used (if connection is TLS) |
| `TLSClientSubject` | TLS client certificate's Subject |

### Access Log Filters

You can filter access logs to reduce volume:

- **statusCodes**: Keep logs only for specific status codes or ranges
- **retryAttempts**: Keep logs when at least one retry occurred
- **minDuration**: Keep logs for requests longer than specified duration

---

## 2. Tracing Configuration

Traefik uses **OpenTelemetry** for distributed tracing. It supports sending traces to OpenTelemetry collectors via HTTP or gRPC.

### Key Tracing Options

| Option | Description | Default |
|--------|-------------|---------|
| `serviceName` | Service name used in the backend | `traefik` |
| `sampleRate` | Proportion of requests to trace (0.0-1.0) | `1.0` |
| `capturedRequestHeaders` | List of request headers to add as span attributes | `[]` |
| `capturedResponseHeaders` | List of response headers to add as span attributes | `[]` |
| `safeQueryParams` | Query parameters that should NOT be redacted | `[]` |
| `addInternals` | Enable tracing for internal resources | `false` |
| `resourceAttributes` | Additional resource attributes to send | `{}` |

### Sampling Strategy

Traefik uses `ParentBased(TraceIDRatioBased)` sampling:

- **Root spans** (originating at Traefik): Sampled according to `sampleRate`
- **Child spans** (with existing trace context): Inherit sampling decision from parent

### OpenTelemetry Collector Endpoints

| Protocol | Default Endpoint | Format |
|----------|------------------|--------|
| HTTP | `https://localhost:4318/v1/traces` | `<scheme>://<host>:<port><path>` |
| gRPC | `localhost:4317` | `<host>:<port>` |

---

## 3. Header Capture

### Headers in Access Logs

Configure header capture in access logs using the `fields.headers` section:

```yaml
fields:
  headers:
    defaultMode: drop  # Options: keep, drop, redact
    names:
      User-Agent: keep
      X-Forwarded-For: keep
      X-Real-IP: keep
      Authorization: redact  # Redact sensitive headers
      Cookie: drop           # Drop completely
```

### Standard HTTP Headers Typically Captured

| Header | Description | Recommended Mode |
|--------|-------------|------------------|
| `User-Agent` | Client browser/application info | `keep` or `redact` |
| `X-Forwarded-For` | Original client IP (behind proxy) | `keep` |
| `X-Real-IP` | Real client IP | `keep` |
| `X-Forwarded-Proto` | Original protocol | `keep` |
| `X-Forwarded-Host` | Original host | `keep` |
| `X-Request-ID` | Request correlation ID | `keep` |
| `Authorization` | Auth credentials | `redact` or `drop` |
| `Cookie` | Session cookies | `redact` or `drop` |
| `Content-Type` | Request content type | `keep` |
| `Accept` | Accepted content types | `keep` |
| `Referer` | Referring page | `keep` or `redact` |

### Headers in Tracing

Configure captured headers for tracing:

```yaml
tracing:
  capturedRequestHeaders:
    - X-Request-ID
    - X-Forwarded-For
    - X-Real-IP
    - User-Agent
  capturedResponseHeaders:
    - X-Response-Time
    - X-RateLimit-Remaining
```

---

## 4. Production-Ready Helm Values Examples

### Example 1: Basic Access Logs with Header Capture

Add to `traefik-values.yml`:

```yaml
# Access Logs Configuration
logs:
  access:
    enabled: true
    format: json
    bufferingSize: 100
    addInternals: false
    fields:
      general:
        defaultmode: keep
        names:
          StartUTC: drop        # Drop UTC timestamp if using local
          ClientUsername: drop  # Drop if not used
      headers:
        defaultmode: drop
        names:
          User-Agent: keep
          X-Forwarded-For: keep
          X-Real-IP: keep
          X-Forwarded-Proto: keep
          X-Request-ID: keep
          Content-Type: keep
          Authorization: redact
          Cookie: drop
```

### Example 2: OpenTelemetry Tracing

```yaml
# Enable experimental OTLP logs feature
experimental:
  otlpLogs: false  # Set to true if using OTLP for logs

# Tracing Configuration
tracing:
  addInternals: false
  serviceName: traefik-ingress
  sampleRate: 0.1  # Sample 10% of requests
  capturedRequestHeaders:
    - X-Request-ID
    - X-Forwarded-For
    - X-Real-IP
    - User-Agent
  capturedResponseHeaders:
    - X-Response-Time
  safeQueryParams:
    - search
    - page
  resourceAttributes:
    environment: production
    cluster: homelab
  otlp:
    enabled: true
    http:
      enabled: true
      endpoint: http://otel-collector.observability.svc.cluster.local:4318/v1/traces
      headers: {}
      tls:
        insecureSkipVerify: false
```

### Example 3: Full Observability Stack

```yaml
# Experimental Features
experimental:
  otlpLogs: true  # Enable OTLP logging

# General Logs
logs:
  general:
    format: json
    level: INFO
    # filePath: /var/log/traefik/traefik.log  # Uncomment for file logging
  access:
    enabled: true
    format: json
    bufferingSize: 100
    timezone: "America/New_York"
    addInternals: false
    filters:
      statuscodes: ""
      retryattempts: false
      minduration: ""
    fields:
      general:
        defaultmode: keep
        names:
          StartUTC: drop
          ClientUsername: drop
      headers:
        defaultmode: drop
        names:
          User-Agent: keep
          X-Forwarded-For: keep
          X-Real-IP: keep
          X-Forwarded-Proto: keep
          X-Forwarded-Host: keep
          X-Request-ID: keep
          Content-Type: keep
          Accept: keep
          Referer: redact
          Authorization: redact
          Cookie: drop
    otlp:
      enabled: false  # Set to true to send access logs via OTLP

# Tracing
tracing:
  addInternals: false
  serviceName: traefik-proxy
  sampleRate: 0.1
  capturedRequestHeaders:
    - X-Request-ID
    - X-Forwarded-For
    - X-Real-IP
    - User-Agent
  capturedResponseHeaders:
    - X-Response-Time
  resourceAttributes:
    environment: production
    service.version: "3.0"
  otlp:
    enabled: true
    http:
      enabled: true
      endpoint: http://tempo.observability.svc.cluster.local:4318/v1/traces
    grpc:
      enabled: false

# Metrics (Prometheus)
metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true
```

### Example 4: Per-EntryPoint Observability

Configure observability at the entrypoint level:

```yaml
ports:
  web:
    port: 8000
    exposedPort: 80
    observability:
      metrics: true
      accessLogs: true
      tracing: true
      traceVerbosity: minimal  # Options: minimal, detailed
  websecure:
    port: 8443
    exposedPort: 443
    observability:
      metrics: true
      accessLogs: true
      tracing: true
      traceVerbosity: minimal
  metrics:
    port: 9100
    exposedPort: 9100
    observability:
      metrics: true
      accessLogs: false
      tracing: false
```

---

## 5. Best Practices

### Access Logs

1. **Use JSON format** for production - easier to parse and analyze with log aggregation tools
2. **Set bufferingSize** (e.g., 100) to improve performance by batching log writes
3. **Drop sensitive headers** (Authorization, Cookie) or use `redact` mode
4. **Keep X-Forwarded headers** when behind a load balancer or CDN
5. **Use filters** to reduce log volume for high-traffic endpoints:
   ```yaml
   filters:
     statuscodes: "400-599"  # Only log errors
     minduration: "100ms"    # Only log slow requests
   ```

### Tracing

1. **Use sampling** in production (0.1-0.5) to reduce overhead and storage costs
2. **Capture only necessary headers** - avoid capturing all headers
3. **Use meaningful serviceName** to identify the Traefik instance
4. **Add resourceAttributes** for environment, cluster, and version info
5. **Configure safeQueryParams** to whitelist query parameters that shouldn't be redacted

### Security

1. **Never log full Authorization headers** - always use `redact` or `drop`
2. **Redact or drop Cookie headers** to protect session tokens
3. **Be cautious with Referer headers** - may contain sensitive URL parameters
4. **Consider GDPR/privacy requirements** when capturing User-Agent and IP addresses

### Performance

1. **Use bufferingSize** for access logs to reduce I/O overhead
2. **Sample traces** rather than capturing 100% in high-traffic environments
3. **Use gRPC over HTTP** for tracing when possible (lower overhead)
4. **Drop unnecessary fields** to reduce log volume

### Per-Router Configuration

Disable observability for specific routes if needed:

```yaml
# IngressRoute example
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: health-check
spec:
  routes:
    - kind: Rule
      match: PathPrefix(`/health`)
      services:
        - name: api-service
          port: 80
      observability:
        accessLogs: false
        tracing: false
```

---

## 6. Recommendations for Current Setup

Based on the existing `/app-storage/k3s/traefik/traefik.yml` configuration, here are specific recommendations:

### Current Configuration Analysis

The current setup has:
- ✅ Access logs enabled with JSON format
- ✅ Header capture for User-Agent
- ✅ Log level set to TRACE (very verbose)
- ✅ Tracing enabled on websecure entrypoint
- ⚠️ Tracing section is commented out
- ⚠️ Only capturing User-Agent header
- ⚠️ bufferingSize is 0 (no buffering)

### Recommended Enhancements to traefik.yml

```yaml
global:
  checkNewVersion: true
  sendAnonymousUsage: false

# Enable tracing with OpenTelemetry
tracing:
  addInternals: false
  serviceName: traefik-homelab
  sampleRate: 0.5  # Sample 50% of requests
  capturedRequestHeaders:
    - X-Request-ID
    - X-Forwarded-For
    - X-Real-IP
    - User-Agent
  capturedResponseHeaders:
    - X-Response-Time
  otlp:
    http:
      endpoint: http://otel-collector:4318/v1/traces

accessLog:
  filePath: "/logs/traefik.log"
  format: json
  bufferingSize: 100  # Enable buffering for better performance
  filters:
    statusCodes:
      - "200"
      - "400-599"
    retryAttempts: true
    minDuration: "10ms"
  fields:
    defaultMode: keep
    names:
      StartUTC: drop
      ClientUsername: drop
    headers:
      defaultMode: drop
      names:
        User-Agent: keep
        X-Forwarded-For: keep
        X-Real-IP: keep
        X-Forwarded-Proto: keep
        X-Request-ID: keep
        Content-Type: keep
        Authorization: redact
        Cookie: drop

log:
  level: INFO  # Reduce from TRACE for production
  format: json  # Add JSON format for general logs too

# ... rest of config
```

### For Kubernetes/Helm Deployment

If migrating to Kubernetes with Helm, convert the above to Helm values format as shown in Section 4.

---

## Sources

- [Traefik Logs & Access Logs Documentation](https://doc.traefik.io/traefik/reference/install-configuration/observability/logs-and-accesslogs/)
- [Traefik Tracing Documentation](https://doc.traefik.io/traefik/reference/install-configuration/observability/tracing/)
- [Traefik Observe - Logs & Access Logs](https://doc.traefik.io/traefik/observe/logs-and-access-logs/)
- [Traefik Observe - Tracing](https://doc.traefik.io/traefik/observe/tracing/)
- [Traefik Helm Chart Values](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml)
- [OpenTelemetry Specification](https://opentelemetry.io/)
