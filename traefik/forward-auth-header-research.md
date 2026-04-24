# Traefik Forward-Auth & Authelia Header Issue Research

## Problem Summary

**Architecture:** External Traefik (Docker) → Cluster's Traefik (Kubernetes) → Authelia (Kubernetes)

**Issue:** When External Traefik's forwardAuth middleware calls Authelia, Authelia receives the request without the `X-Forwarded-Method` header, causing a 400 error.

---

## Research Findings

### 1. Headers Traefik forwardAuth Adds Automatically

According to the [Traefik ForwardAuth documentation](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/forwardauth/), when forwardAuth makes a request to an auth server, Traefik automatically adds these `X-Forwarded-*` headers:

| Property | Forward-Request Header |
|----------|------------------------|
| HTTP Method | `X-Forwarded-Method` |
| Protocol | `X-Forwarded-Proto` |
| Host | `X-Forwarded-Host` |
| Request URI | `X-Forwarded-Uri` |
| Source IP-Address | `X-Forwarded-For` |

**Important:** These headers are added by the Traefik forwardAuth middleware when making the auth request, NOT from the original client request.

---

### 2. Can Headers Be Stripped/Modified Through Multiple Traefik Instances?

**YES - This is the root cause.**

Traefik's entrypoint configuration includes a `forwardedHeaders` setting that controls how Traefik handles incoming `X-Forwarded-*` headers:

```yaml
entryPoints:
  websecure:
    address: :443
    forwardedHeaders:
      trustedIPs:
        - 192.168.200.200  # IP of the external Traefik
      insecure: false  # Default - only trust IPs in trustedIPs
```

**Key Behavior:**
- By default, `insecure: false` means Traefik **REMOVES** all `X-Forwarded-*` headers from requests NOT coming from trusted IPs
- If External Traefik is NOT in the `trustedIPs` list, Cluster's Traefik strips the `X-Forwarded-Method` header that External Traefik's forwardAuth added

**Source:** [Traefik EntryPoints Documentation](https://doc.traefik.io/traefik/reference/install-configuration/entrypoints/)

---

### 3. Known Issues with Multi-Traefik ForwardAuth Architecture

**GitHub Issue #12418** - Matches your exact scenario:

> "X-Forwarded-Method Header missing in ForwardAuth Requests"
> 
> User reported: "ForwardAuth stopped working on Authelia, since the header 'X-Forwarded-Method' is empty when traefik redirects to Authelia for forwardAuth."
> 
> **Resolution:** The issue was closed as "invalid" - user needed to configure the `forwardHeaders.trustedIPs` setting on the entrypoint.

**GitHub Issue #6978** - Original report about X-Forwarded-Method being missing:
> "The header 'X-Forwarded-Method' is missing from request received by backend server. It's missing also when using ForwardAuth."

**Source:** 
- https://github.com/traefik/traefik/issues/12418
- https://github.com/traefik/traefik/issues/6978

---

### 4. Recommended Solutions

#### Solution A: Configure forwardedHeaders.trustedIPs on Cluster's Traefik

On Cluster's Traefik entrypoint configuration:

```yaml
entryPoints:
  websecure:
    address: :443
    forwardedHeaders:
      trustedIPs:
        - 192.168.200.200  # External Traefik's IP
```

Or via CLI arguments:
```bash
--entrypoints.websecure.forwardedHeaders.trustedIPs=192.168.200.200
```

#### Solution B: Use Internal Service Address (Bypass External Traefik)

Configure External Traefik's forwardAuth to call Authelia directly via internal Kubernetes service address instead of going through Cluster's Traefik:

```yaml
# External Traefik forwardAuth middleware
forwardAuth:
  address: "http://authelia.auth.svc.cluster.local:9091/api/authz/forward-auth"
  trustForwardHeader: true
```

**Benefits:**
- Bypasses Cluster's Traefik entirely
- Eliminates the double-proxy header stripping issue
- Simpler configuration

#### Solution C: Combine trustForwardHeader with Proper trustedIPs

Ensure BOTH Traefik instances have proper configuration:

**External Traefik:**
```yaml
http:
  middlewares:
    authelia:
      forwardAuth:
        address: "https://auth.picklemustard.dev/authelia/api/authz/forward-auth"
        trustForwardHeader: true  # Trust headers from client
        authResponseHeaders:
          - Remote-User
          - Remote-Groups
          - Remote-Email
          - Remote-Name
```

**Cluster's Traefik:**
```yaml
entryPoints:
  websecure:
    address: :443
    forwardedHeaders:
      trustedIPs:
        - 192.168.200.200  # External Traefik's IP
```

---

### 5. Traefik Version Bugs Related to ForwardAuth Headers

| Version | Issue | Status |
|---------|-------|--------|
| v2.8.2 | Panic with ForwardAuth (Issue #9249) | Fixed |
| v3.4+ | New `preserveRequestMethod` option added (Issue #11438) | Enhancement |
| v3.6.4 | X-Forwarded-Method missing (Issue #12418) | Configuration issue, not bug |

**Important:** The `preserveRequestMethod` option was added in Traefik v3.4 to allow preserving the original request method when forwarding to the auth server:

```yaml
forwardAuth:
  address: "https://auth.example.com/api/authz/forward-auth"
  preserveRequestMethod: true  # New in v3.4
```

---

## Authelia-Specific Notes

### Required Headers for Authelia ForwardAuth

According to [Authelia documentation](https://www.authelia.com/integration/proxies/traefik/), Authelia's forward-auth endpoint requires:

- `X-Forwarded-Method` - **REQUIRED** (causes 400 error if missing)
- `X-Forwarded-Proto`
- `X-Forwarded-Host`
- `X-Forwarded-Uri`
- `X-Forwarded-For`

### Authelia Error Message (from logs):
```
level=error msg="Error getting Target URL and Request Method" 
error="header 'X-Forwarded-Method' is empty" 
method=GET path=/api/authz/forward-auth
```

---

## Summary & Recommended Fix

### Root Cause
Cluster's Traefik is stripping the `X-Forwarded-Method` header because External Traefik's IP is not in the `trustedIPs` list.

### Immediate Fix
Add External Traefik's IP to Cluster's Traefik entrypoint configuration:

```yaml
# Cluster's Traefik - traefik-values.yml or static config
entryPoints:
  websecure:
    forwardedHeaders:
      trustedIPs:
        - 192.168.200.200/32  # External Traefik IP with CIDR
```

### Alternative Fix (Better Architecture)
Have External Traefik call Authelia directly via Kubernetes internal DNS:

```yaml
# External Traefik - docker-compose or dynamic config
http:
  middlewares:
    authelia-forwardauth:
      forwardAuth:
        # Direct internal call, bypassing Cluster's Traefik
        address: "http://authelia.auth.svc.cluster.local:9091/api/authz/forward-auth"
        trustForwardHeader: true
```

This requires External Traefik to have network access to the Kubernetes cluster internal network.

---

## Specific Recommendations for Your Configuration

### Your Current Setup (from `/app-storage/k3s/traefik/traefik.yml`)

Your Cluster's Traefik `websecure` entrypoint:
```yaml
entryPoints:
  websecure:
    address: ":443"
    http:
      tls:
        certResolver: "letsencrypt"
```

**Missing:** `forwardedHeaders.trustedIPs` configuration

Your forwardAuth middleware (from `dynamic_conf.yml`):
```yaml
middlewares:
  authelia:
    forwardAuth:
      address: 'https://auth.picklemustard.dev/authelia/api/verify?rd=https://auth.picklemustard.dev/authelia'
      trustForwardHeader: true
      authResponseHeaders:
        - "Remote-User"
        - "Remote-Group"
        - "Remote-Email"
        - "Remote-Name"
```

### Fix #1: Add trustedIPs to Cluster's Traefik Entrypoint

Edit `/app-storage/k3s/traefik/traefik.yml`:

```yaml
entryPoints:
  websecure:
    address: ":443"
    forwardedHeaders:
      trustedIPs:
        - "192.168.200.200/32"  # External Traefik's IP - ADJUST THIS!
    http:
      tls:
        certResolver: "letsencrypt"
        domains:
          - main: "picklemustard.dev"
            sans:
              - "*.picklemustard.dev"
```

### Fix #2: Update Authelia Endpoint (Recommended by Authelia)

Authelia's newer versions recommend using the `forward-auth` endpoint instead of `verify`:

```yaml
middlewares:
  authelia:
    forwardAuth:
      # Updated to use the recommended forward-auth endpoint
      address: 'https://auth.picklemustard.dev/authelia/api/authz/forward-auth'
      trustForwardHeader: true
      authResponseHeaders:
        - "Remote-User"
        - "Remote-Group"
        - "Remote-Email"
        - "Remote-Name"
```

### Fix #3: Direct Internal Access (Bypass Double-Proxy)

If External Traefik has access to your internal network, configure it to call Authelia directly:

```yaml
# On External Traefik (Docker)
http:
  middlewares:
    authelia:
      forwardAuth:
        # Direct call to internal IP - bypasses Cluster's Traefik entirely
        address: 'http://192.168.200.242:9091/authelia/api/authz/forward-auth'
        trustForwardHeader: true
        authResponseHeaders:
          - "Remote-User"
          - "Remote-Group"
          - "Remote-Email"
          - "Remote-Name"
```

### Debugging Steps

1. **Enable debug logging** (you already have `log.level: TRACE`)

2. **Check incoming headers on Cluster's Traefik**:
   ```bash
   # Look for X-Forwarded-* headers in the access log
   kubectl logs -f deployment/traefik -n traefik | grep -i "X-Forwarded"
   ```

3. **Test directly**:
   ```bash
   # Test Authelia directly (bypassing External Traefik)
   curl -v https://auth.picklemustard.dev/authelia/api/authz/forward-auth \
     -H "X-Forwarded-Method: GET" \
     -H "X-Forwarded-Proto: https" \
     -H "X-Forwarded-Host: test.picklemustard.dev" \
     -H "X-Forwarded-Uri: /"
   ```

4. **Check External Traefik logs** to confirm it's adding the headers

---

## Sources

1. **Traefik ForwardAuth Documentation**
   - https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/forwardauth/

2. **Traefik EntryPoints Documentation**
   - https://doc.traefik.io/traefik/reference/install-configuration/entrypoints/

3. **Authelia Traefik Integration**
   - https://www.authelia.com/integration/proxies/traefik/

4. **Authelia Forwarded Headers Documentation**
   - https://www.authelia.com/integration/proxies/forwarded-headers/

5. **GitHub Issues**
   - Issue #12418: https://github.com/traefik/traefik/issues/12418
   - Issue #6978: https://github.com/traefik/traefik/issues/6978
   - Issue #11438: https://github.com/traefik/traefik/issues/11438 (preserveRequestMethod feature)

6. **Authelia Kubernetes Traefik Ingress**
   - https://www.authelia.com/integration/kubernetes/traefik-ingress/
