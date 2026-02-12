# Stalwart Mail - Email Server

**Namespace:** `stalwart`

**URL:** https://mail.picklemustard.dev

---

## Overview

Stalwart Mail is a modern, full-featured mail server providing IMAP, SMTP, and POP3 services. It serves as the email infrastructure for the homelab.

---

## Configuration Files

- `stalwart/deployment.yml` - Main deployment
- `stalwart/service.yml` - Service definition (multi-port)
- `stalwart/persistentvolumeclaim.yml` - 50Gi PVC
- `stalwart/configmap.yml` - Server configuration
- `stalwart/tcp-ingress.yml` - TCP ingress for mail protocols
- `stalwart/stalwart-cert.yml` - TLS certificate

---

## Deployment

```bash
# Create namespace
kubectl create namespace stalwart

# Apply all Stalwart Mail configurations
kubectl apply -f stalwart/
```

---

## Secrets Required

Create a secret named `stalwart-mail-env`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: stalwart-mail-env
  namespace: stalwart
type: Opaque
stringData:
  # Add required environment variables here
  # See Stalwart documentation for specific variables
```

---

## Ports

| Port | Protocol | Purpose | External Access |
|------|----------|---------|-----------------|
| 80 | HTTP | Web UI | Yes (via Traefik) |
| 25 | SMTP | Outgoing mail | Yes (via TCP ingress) |
| 587 | Submission | SMTP with STARTTLS | Yes (via TCP ingress) |
| 465 | Submissions | SMTP with SSL | Yes (via TCP ingress) |
| 143 | IMAP | Incoming mail | Yes (via TCP ingress) |
| 993 | IMAPS | IMAP with SSL | Yes (via TCP ingress) |
| 110 | POP3 | Incoming mail (legacy) | Yes (via TCP ingress) |
| 995 | POP3S | POP3 with SSL | Yes (via TCP ingress) |
| 14190 | Sieve | Mail filtering | Yes (via TCP ingress) |

---

## Storage

### Persistent Volume Claim

| PVC Name | Size | Mount Paths |
|----------|------|-------------|
| `stalwart` | 50Gi | `/data`, `/data/blobs`, `/data/queue`, `/data/reports` |

### Storage Class
Uses the `local-path` storage class.

---

## Configuration

### Main Configuration
The server configuration is stored in the `stalwart` ConfigMap and mounted to `/opt/stalwart/etc/config.toml`.

### TLS Certificates
TLS certificates are mounted from secrets:
- Certificate: `picklemustard-dev-tls-stalwart` → `/opt/stalwart/etc/private/tls.cert`
- Private Key: `picklemustard-dev-tls-stalwart` → `/opt/stalwart/etc/private/tls.key`

### Environment Variables
Configuration is injected via `envFrom` from the `stalwart-mail-env` secret.

---

## Features

- **IMAP/IMAPS** - Full-featured email access
- **SMTP/SMTPS** - Email sending with authentication
- **POP3/POP3S** - Legacy email protocol support
- **Sieve** - Server-side email filtering
- **TLS Encryption** - Secure connections for all protocols
- **Spam Filtering** - Built-in spam detection
- **Web UI** - Email client interface
- **OAuth2** - OAuth2 authentication support (integrates with Authelia)

---

## Access

### Web Interface
URL: https://mail.picklemustard.dev

### Email Client Configuration
- **IMAP:** `mail.picklemustard.dev:993` (SSL) or `mail.picklemustard.dev:143` (STARTTLS)
- **SMTP:** `mail.picklemustard.dev:465` (SSL) or `mail.picklemustard.dev:587` (STARTTLS)
- **POP3:** `mail.picklemustard.dev:995` (SSL) or `mail.picklemustard.dev:110` (STARTTLS)

---

## Management

### Check Status
```bash
kubectl get pods -n stalwart
kubectl logs -f deployment/stalwart -n stalwart
```

### Access Shell
```bash
kubectl exec -it deployment/stalwart -n stalwart -- /bin/sh
```

### View Configuration
```bash
kubectl get configmap stalwart -n stalwart -o yaml
```

---

## Troubleshooting

### Cannot Send Email (SMTP)
1. Check TCP ingress for port 25/587/465: `kubectl get ingress -n stalwart`
2. Verify DNS MX records point to correct IP
3. Check firewall allows outbound port 25
4. Review logs: `kubectl logs -f deployment/stalwart -n stalwart`

### Cannot Receive Email (IMAP/POP3)
1. Check TCP ingress for IMAP/POP3 ports
2. Verify authentication is working (check with LLDAP)
3. Review logs for authentication errors
4. Check mailbox configuration

### TLS/SSL Issues
1. Verify certificate secret exists: `kubectl get secret picklemustard-dev-tls-stalwart -n stalwart`
2. Check certificate is not expired
3. Verify certificate files are mounted correctly
4. Review configuration for TLS settings

### Email Not Delivered
1. Check mail queue: `kubectl exec -n stalwart deployment/stalwart -- ls -la /data/queue`
2. Review logs for delivery errors
3. Verify recipient domain accepts email from your server
4. Check SPF/DKIM records if configured

---

## Backup

### Backup Data
```bash
# Backup all data
kubectl exec -n stalwart deployment/stalwart -- tar czf /tmp/stalwart-backup.tar.gz /data
kubectl cp -n stalwart deployment/stalwart:/tmp/stalwart-backup.tar.gz ./stalwart-backup.tar.gz
```

### Backup Configuration
```bash
kubectl get configmap stalwart -n stalwart -o yaml > stalwart-config-backup.yml
```

---

## Upgrade

```bash
# Update image tag
kubectl set image deployment/stalwart stalwart=ghcr.io/stalwartlabs/stalwart:<version> -n stalwart

# Watch rollout
kubectl rollout status deployment/stalwart -n stalwart
```

---

## Integration

Stalwart Mail integrates with:

- **LLDAP** - User authentication for email access
- **Authelia** - OAuth2 authentication provider
- **Traefik** - HTTP ingress for web UI and TCP ingress for mail protocols

---

## Spam Protection

Stalwart Mail includes built-in spam filtering. Configure:
- SpamAssassin or Rspamd integration
- Greylisting
- SPF/DKIM/DMARC verification
- DNS blocklists

---

## Sieve Filters

Sieve scripts allow server-side email filtering. Configure Sieve rules to:
- Automatically sort incoming mail into folders
- Filter spam to specific folders
- Set up auto-responders
- Forward specific messages

---

## Notes

- TCP ingress is configured for all mail protocols
- TLS certificates are mounted from secrets for secure connections
- Data is stored in multiple subPaths on a single PVC
- Health checks are currently commented out in the deployment
- Consider enabling liveness/readiness probes for production use
