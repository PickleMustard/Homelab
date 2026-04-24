# Vaultwarden Prometheus Metrics Research

## Summary

**As of February 2026, Vaultwarden does NOT have built-in Prometheus metrics support in the official/main branch.** However, there is an open Pull Request that adds this functionality.

## Current Status

The official Vaultwarden release does not include Prometheus metrics. The feature is currently being developed in:

- **Open PR #6202**: [feat: Add comprehensive Prometheus metrics support](https://github.com/dani-garcia/vaultwarden/pull/6202)
- **Status**: Open (as of Feb 2026), awaiting final review and merge

## Configuration (from PR #6202)

Once merged, the following environment variables will enable Prometheus metrics:

### Required Environment Variables

```bash
# Enable the metrics endpoint (disabled by default)
ENABLE_METRICS=true

# Authentication token for accessing /metrics endpoint
# Supports plain text or Argon2 PHC hashed tokens
METRICS_TOKEN=your-secret-token-here
```

### Optional Environment Variables

```bash
# Cache timeout for business metrics (in seconds)
# Prevents excessive database queries when scraping frequently
# Default: 60 seconds
METRICS_BUSINESS_CACHE_SECONDS=60
```

## Technical Details

### Endpoint

| Property | Value |
|----------|-------|
| **Endpoint** | `/metrics` |
| **Port** | Same as main application (80 in Docker, 8000 by default) |
| **Format** | Standard Prometheus text format |
| **Method** | GET |

### Authentication

The metrics endpoint supports two authentication methods:

1. **Bearer Token Header**:
   ```bash
   curl -H "Authorization: Bearer your-token" http://vaultwarden:80/metrics
   ```

2. **Query Parameter**:
   ```bash
   curl "http://vaultwarden:80/metrics?token=your-token"
   ```

### Token Formats

The `METRICS_TOKEN` supports two formats:

1. **Plain Text** (less secure):
   ```bash
   METRICS_TOKEN=my-secret-token
   ```

2. **Argon2 PHC Hash** (recommended):
   ```bash
   # Generate using vaultwarden hash command
   METRICS_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$...'
   ```

## Available Metrics

### HTTP Metrics
- `vaultwarden_http_requests_total` - Total HTTP requests by method, path, status
- `vaultwarden_http_request_duration_seconds` - Request duration histogram

### Database Metrics
- `vaultwarden_db_connections_active` - Active database connections
- `vaultwarden_db_connections_idle` - Idle database connections

### Authentication Metrics
- `vaultwarden_auth_attempts_total` - Authentication attempts by method (password, sso, etc.) and status (success/failed)

### Business Metrics
- `vaultwarden_users_total` - User count by status (enabled/disabled)
- `vaultwarden_organizations_total` - Organization count
- `vaultwarden_vault_items_total` - Vault items by type and organization
- `vaultwarden_collections_total` - Collections per organization

### System Metrics
- `vaultwarden_uptime_seconds` - Application uptime
- `vaultwarden_build_info` - Version, revision, branch information

## Build Requirements

**Important**: The metrics feature requires a special compile-time flag:

```bash
# Building from source with metrics enabled
cargo build --features enable_metrics
```

For Docker builds, you would need to use a custom image that includes this feature.

## Security Considerations

1. **Disabled by default**: Must explicitly set `ENABLE_METRICS=true`
2. **Token authentication**: Required to access metrics endpoint
3. **Path normalization**: Prevents metric cardinality explosion from dynamic paths
4. **Network isolation recommended**: Consider restricting access via firewall/proxy

## Prometheus Configuration Example

```yaml
scrape_configs:
  - job_name: 'vaultwarden'
    static_configs:
      - targets: ['vaultwarden:80']
    metrics_path: '/metrics'
    bearer_token: 'your-secret-token'
    # Or use params for query parameter auth:
    # params:
    #   token: ['your-secret-token']
    scrape_interval: 60s
```

## Current Workaround Options

Since the official build doesn't include metrics yet, you have these options:

1. **Wait for PR merge**: The PR is actively maintained and under review
2. **Build from PR branch**: Use the fork at `rossigee/vaultwarden` branch `feature/prometheus-metrics`
3. **Use external monitoring**: Monitor Vaultwarden via HTTP health checks and reverse proxy metrics

## Sources

- PR #6202: https://github.com/dani-garcia/vaultwarden/pull/6202
- Original issue #496: https://github.com/dani-garcia/vaultwarden/issues/496
- Previous PR #3634 (closed): https://github.com/dani-garcia/vaultwarden/pull/3634
- Vaultwarden repository: https://github.com/dani-garcia/vaultwarden

## Recommendation

For production use, wait for the PR to be merged into the official Vaultwarden release. The implementation looks solid with proper authentication and caching, but using an unmerged feature branch in production carries risks.

If you need metrics immediately, consider using Traefik or your reverse proxy's metrics to monitor request patterns to Vaultwarden endpoints as a temporary solution.
