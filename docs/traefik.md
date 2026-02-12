# Traefik - Ingress Controller

**Namespace:** `traefik`

**Dashboard:** https://traefik.picklemustard.dev

**Ports:** 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)

---

## Overview

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It serves as the ingress controller for the k3s homelab, handling all external traffic.

---

## Configuration Files

- `traefik/traefik.yml` - Static configuration
- `traefik/dynamic_conf.yml` - Dynamic configuration
- `traefik/docker-compose.yml` - Docker Compose configuration (legacy)
- `traefik-values.yml` - Helm chart values
- `traefik-helm-values.yml` - Additional Helm values
- `traefik-config.yml` - Additional configuration
- `traefik-dashboard-ingress.yml` - Dashboard ingress
- `traefik-dashboard-service.yml` - Dashboard service
- `traefik-dashboard-ingress-route.yml` - Dashboard ingress route
- `traefik-tls-certificate.yml` - TLS certificate configuration

---

## Deployment

### Using Helm (Recommended)
```bash
# Add Traefik Helm repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Install Traefik
helm install --namespace traefik traefik traefik/traefik -f traefik-values.yml -f traefik-helm-values.yml
```

### Or Apply YAML Files
```bash
# Create namespace
kubectl create namespace traefik

# Apply configuration files
kubectl apply -f traefik-dashboard-ingress.yml
kubectl apply -f traefik-dashboard-service.yml
kubectl apply -f traefik-tls-certificate.yml
```

---

## Configuration

### Static Configuration
Static configuration is defined in `traefik.yml`:
- EntryPoints (web, websecure)
- Provider settings (Kubernetes Ingress)
- Dashboard settings
- TLS configuration

### Dynamic Configuration
Dynamic configuration is defined in `dynamic_conf.yml`:
- Middleware (auth, headers, redirects)
- TLS options
- Routers and services

---

## EntryPoints

| EntryPoint | Port | Protocol | Description |
|------------|------|----------|-------------|
| web | 80 | HTTP | Unsecured HTTP traffic |
| websecure | 443 | HTTPS | Secured HTTPS traffic |
| traefik | 8080 | HTTP | Traefik dashboard (internal) |

---

## Middleware

Traefik provides middleware for common tasks:

### Authelia Forward Auth
Protects services with Authelia authentication:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: authelia
spec:
  forwardAuth:
    address: http://authelia.lldap.svc.cluster.local:9091/api/verify?rd=https://auth.picklemustard.dev
```

### HTTP to HTTPS Redirect
Redirects all HTTP traffic to HTTPS:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: https-redirect
spec:
  redirectScheme:
    scheme: https
    permanent: true
```

### Security Headers
Adds security headers to responses:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: security-headers
spec:
  headers:
    sslRedirect: true
    stsSeconds: 31536000
    browserXssFilter: true
```

---

## TLS/SSL

### Certificate Management
Traefik uses cert-manager for automatic TLS certificate provisioning:
- **Issuer:** Let's Encrypt ACME
- **Configuration:** `cert-manager-acme-issuer.yaml`

### Manual Certificates
Manual TLS certificates can be configured in `traefik-tls-certificate.yml`:
- Certificate: `tls.crt`
- Private Key: `tls.key`

---

## Dashboard

Access the Traefik dashboard for monitoring and debugging:

**URL:** https://traefik.picklemustard.dev

Features:
- View all routes and services
- Monitor middleware execution
- Debug routing issues
- View real-time statistics

---

## Ingress Configuration

Standard ingress pattern for services:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: service-ingress
  namespace: namespace
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
    - host: service.picklemustard.dev
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: service
                port:
                  number: 80
```

### Protecting Services with Authelia

Add the Authelia middleware:

```yaml
annotations:
  traefik.ingress.kubernetes.io/router.middlewares: lldap-authelia@kubernetescrd
```

---

## TCP Ingress

For non-HTTP services (SMTP, IMAP, etc.):

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRouteTCP
metadata:
  name: smtp-ingress
  namespace: stalwart
spec:
  entryPoints:
    - smtp
  routes:
    - match: HostSNI(`mail.picklemustard.dev`)
      services:
        - name: stalwart
          port: 25
```

---

## Management

### Check Status
```bash
kubectl get pods -n traefik
kubectl logs -f deployment/traefik -n traefik
```

### View Configuration
```bash
kubectl get configmap traefik -n traefik -o yaml
```

### Check Routes
```bash
kubectl get ingress -A
kubectl get ingressroute -A
```

---

## Troubleshooting

### Services Not Accessible
1. Check Ingress: `kubectl get ingress -n <namespace>`
2. Verify Service exists: `kubectl get svc -n <namespace>`
3. Check Traefik logs: `kubectl logs -f deployment/traefik -n traefik`
4. Review Traefik dashboard for routing issues

### Certificate Issues
1. Check cert-manager: `kubectl get certificate -A`
2. Verify issuer: `kubectl get clusterissuer`
3. Check DNS A/AAAA records
4. Review Let's Encrypt logs in Traefik

### Middleware Not Working
1. Verify middleware exists: `kubectl get middleware -A`
2. Check middleware reference in ingress annotation
3. Test middleware with curl
4. Review middleware logs

### Performance Issues
1. Check Traefik resource limits
2. Monitor connection counts
3. Review middleware overhead
4. Check for routing loops

---

## Monitoring

Traefik provides built-in metrics:

### Prometheus Metrics
Configure Traefik to expose Prometheus metrics for monitoring with Prometheus/Grafana.

### Access Logs
Enable access logs in configuration to track all incoming requests.

---

## Upgrade

### Helm Upgrade
```bash
helm upgrade --namespace traefik traefik traefik/traefik -f traefik-values.yml -f traefik-helm-values.yml
```

### Verify Upgrade
```bash
kubectl rollout status deployment/traefik -n traefik
```

---

## Best Practices

1. **Use HTTPS Always:** Redirect HTTP to HTTPS
2. **Protect Sensitive Services:** Use Authelia middleware
3. **Rate Limiting:** Implement rate limiting middleware for public services
4. **Health Checks:** Enable health checks for backend services
5. **Security Headers:** Add security headers middleware to all services
6. **Monitor Logs:** Regularly review Traefik logs for issues
7. **Certificate Rotation:** Ensure automatic certificate renewal works

---

## Notes

- Traefik serves as the single entry point for all external traffic
- It automatically discovers services from Kubernetes Ingress resources
- All services use `ingressClassName: traefik`
- TLS certificates are managed by cert-manager with Let's Encrypt
- Dashboard provides real-time visibility into routing
