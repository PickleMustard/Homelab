# AGENTS.md

This repository contains Kubernetes configuration files for a k3s homelab environment running various services (LLDAP, Traefik, Authelia, Vaultwarden, Jellyfin, Pterodactyl, Stalwart Mail, etc.).

## Deployment Commands

Apply configuration files:
```bash
# Apply specific service configurations
kubectl apply -f <service>/deployment.yml
kubectl apply -f <service>/service.yml
kubectl apply -f <service>/ingress.yml
kubectl apply -f <service>-pvc.yml

# Apply all files in a directory
kubectl apply -f <service-directory>/

# Create namespace
kubectl apply -f create-namespace.yml

# Apply Helm release with values
helm install --namespace <namespace> <release-name> <chart> -f <service>-values.yml

# Start k3s server (if applicable)
./start-server.sh
```

Verification and debugging:
```bash
# Check resource status
kubectl get all -n <namespace>
kubectl describe deployment <name> -n <namespace>

# View logs
kubectl logs -f deployment/<name> -n <namespace>

# Validate YAML syntax
kubectl apply --dry-run=client -f <file.yml>

# Check ingress
kubectl get ingress -n <namespace>
```

## Code Style Guidelines

### File Naming and Organization

- Use `.yml` extension (not `.yaml`)
- Naming conventions:
  - `<service>-deployment.yml` or `deployment.yml` in service directories
  - `<service>-service.yml` or `service.yml` in service directories
  - `<service>-ingress.yml` or `ingress.yml` in service directories
  - `<service>-pvc.yml` or `<service>-persistent-volume-claim.yml`
  - `<service>-values.yml` for Helm values files
- Group service-specific files in directories: `<service>/`
- Keep common infrastructure in root: ingress routes, certificates, cluster config

### Kubernetes Labels and Selectors

Modern style (preferred):
```yaml
labels:
  app.kubernetes.io/name: <service-name>
  app.kubernetes.io/instance: <instance-name>
```

Legacy style (acceptable for consistency):
```yaml
labels:
  app: <service-name>
```

Always match selector labels to deployment labels for proper pod selection.

### Namespaces

Organize services by namespace:
- `auth` - authentication services (LLDAP, Authelia)
- `media` - media services (Jellyfin, Sonarr, etc.)
- `vaultwarden` - password manager
- `pterodactyl` - game hosting panel
- `minecraft` - Minecraft servers
- `finance` - financial tools (Firefly III)
- `stalwart` - mail server
- `postgres` - database services

### Deployment Specifications

Standard deployment pattern:
```yaml
replicas: 1
restartPolicy: Always
imagePullPolicy: IfNotPresent
```

For stateful services requiring data persistence:
```yaml
strategy:
  type: Recreate
```

### Persistent Volume Claims

Standard PVC configuration:
```yaml
spec:
  storageClassName: local-path
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: <size>  # Use Mi or Gi (e.g., 100Mi, 10Gi)
```

Labels follow PVC naming:
```yaml
labels:
  app.kubernetes.io/instance: <pvc-name>
  app.kubernetes.io/name: <pvc-name>
```

### Ingress Configuration

Traefik ingress with annotations:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
  spec:
    ingressClassName: traefik
```

Host patterns: `<service>.picklemustard.dev`

### Secrets and Environment Variables

Never hardcode secrets in manifests. Use secret references:
```yaml
env:
  - name: SECRET_NAME
    valueFrom:
      secretKeyRef:
        name: <secret-name>
        key: <key-name>
```

Store secret definitions in `secrets/` directory. Use `secretKeyRef` for all sensitive data.

### ConfigMaps

Use ConfigMaps for application configuration:
```yaml
envFrom:
  - configMapRef:
      name: <configmap-name>
```

Or mount as volumes:
```yaml
volumes:
  - name: config
    configMap:
      name: <configmap-name>
```

### Service Configuration

Standard service pattern:
```yaml
ports:
  - name: "<port-number>"
    port: <port-number>
    targetPort: <port-number>
selector:
  app.kubernetes.io/instance: <deployment-instance>
  app.kubernetes.io/name: <deployment-name>
```

### Volume Mounts

For PVCs:
```yaml
volumeMounts:
  - mountPath: /data
    name: <volume-name>
volumes:
  - name: <volume-name>
    persistentVolumeClaim:
      claimName: <pvc-name>
```

For subPaths:
```yaml
volumeMounts:
  - mountPath: /config
    name: data-storage
    subPath: jellyfin-config
```

### Resource Limits

Specify resource limits for containers, especially for GPU usage:
```yaml
resources:
  limits:
    nvidia.com/gpu: 1
```

### Image Tags

Prefer specific version tags over `latest` for production:
- Use `:latest` only for development/testing
- Pin versions for stability: `image: <image>:<version>`

## Common Patterns

### Standard Service Setup

1. Create namespace (if needed)
2. Create PVCs for data storage
3. Create ConfigMaps for configuration
4. Create Secrets for sensitive data
5. Create Deployment
6. Create Service
7. Create Ingress for external access

### Traefik Integration

- All ingresses use `ingressClassName: traefik`
- Services expose appropriate ports referenced in Traefik configuration
- TLS certificates stored as secrets with pattern: `<domain>-tls`

### Database Services

- Postgres uses LDAP authentication via LLDAP
- Services connect to `postgres-postgresql.postgres.svc.cluster.local:5432`
- Connection strings: `postgresql://<user>:<password>@<host>:5432/<database>`

## Validation Checklist

Before committing changes:
- [ ] YAML syntax is valid (use `kubectl apply --dry-run=client`)
- [ ] No hardcoded secrets or passwords
- [ ] Labels match between deployments and services
- [ ] Namespace references are correct
- [ ] PVC storage sizes are appropriate
- [ ] Service ports match container ports
- [ ] Ingress host follows naming convention
- [ ] Images use appropriate tags (avoid `latest` in production)
