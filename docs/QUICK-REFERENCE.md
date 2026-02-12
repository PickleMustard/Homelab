# Quick Reference Guide

This guide provides quick access to common commands and information for managing the k3s homelab cluster.

## Quick Commands

### Check Cluster Health
```bash
# Check all namespaces
kubectl get namespaces

# Check all pods
kubectl get pods -A

# Check all deployments
kubectl get deployments -A

# Check system status
kubectl get nodes
kubectl get cs
```

### Service Management
```bash
# Get services in a namespace
kubectl get svc -n <namespace>

# Get deployment details
kubectl describe deployment/<name> -n <namespace>

# View logs
kubectl logs -f deployment/<name> -n <namespace>

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>
```

### Ingress Management
```bash
# Get all ingress
kubectl get ingress -A

# Get ingress in namespace
kubectl get ingress -n <namespace>

# Describe ingress
kubectl describe ingress <name> -n <namespace>
```

### Storage Management
```bash
# List all PVCs
kubectl get pvc -A

# List all PVs
kubectl get pv

# Check storage class
kubectl get storageclass
```

## Service Access URLs

| Service | URL | Namespace |
|---------|-----|-----------|
| LLDAP | https://ldap.picklemustard.dev | auth |
| Authelia | https://auth.picklemustard.dev | lldap |
| Vaultwarden | https://vault.picklemustard.dev | vaultwarden |
| Jellyfin | https://jellyfin.picklemustard.dev | media |
| Sonarr | https://media-docs.picklemustard.dev | media |
| Firefly III | https://firefly.picklemustard.dev | finance |
| Pterodactyl | https://pterodactyl.picklemustard.dev | pterodactyl |
| Stalwart Mail | https://mail.picklemustard.dev | stalwart |
| Nextcloud | https://nextcloud.picklemustard.dev | nextcloud |
| Traefik Dashboard | https://traefik-kube.picklemustard.dev | kube-system |
| Rancher | https://rancher.picklemustard.dev | - |
| Homarr | http://dashboard.andromeda.picklemustard.dev | homarr |

## Namespace Quick Reference

| Namespace | Purpose | Services |
|-----------|---------|----------|
| `auth` | Authentication | LLDAP |
| `lldap` | Authentication | Authelia |
| `media` | Media | Jellyfin, Sonarr, Radarr |
| `vaultwarden` | Password Manager | Vaultwarden, Vaultwarden-LDAP |
| `pterodactyl` | Game Server Panel | Pterodactyl |
| `minecraft` | Minecraft | Minecraft Servers |
| `stalwart` | Email | Stalwart Mail |
| `postgres` | Database | PostgreSQL |
| `redis` | Cache | Redis |
| `finance` | Finance | Firefly III |
| `nextcloud` | Collaboration | Nextcloud |
| `homarr` | Dashboard | Homarr |
| `agones-system` | Game Server Operator | Agones |
| `cert-manager` | Certificates | cert-manager |
| `kube-system` | Infrastructure | Traefik |

## Common Port References

| Port | Service | Purpose |
|------|---------|---------|
| 80 | Traefik | HTTP |
| 443 | Traefik | HTTPS |
| 3890 | LLDAP | LDAP |
| 9091 | Authelia | Web UI |
| 8096 | Jellyfin | Web UI |
| 5432 | PostgreSQL | Database |
| 6379 | Redis | Cache |
| 25565 | Minecraft | Game Port |
| 25 | Stalwart | SMTP |
| 587 | Stalwart | Submission |
| 465 | Stalwart | Submissions |
| 143 | Stalwart | IMAP |
| 993 | Stalwart | IMAPS |
| 110 | Stalwart | POP3 |
| 995 | Stalwart | POP3S |
| 4190 | Stalwart | Sieve |

## Service Status Commands

### Authentication Services
```bash
# LLDAP
kubectl get pods -n auth
kubectl logs -f deployment/lldap -n auth

# Authelia
kubectl get pods -n lldap
kubectl logs -f deployment/authelia -n lldap
```

### Media Services
```bash
# Jellyfin
kubectl get pods -n media
kubectl logs -f deployment/jellyfin-deployment -n media

# Sonarr
kubectl logs -f deployment/sonarr -n media
```

### Database Services
```bash
# PostgreSQL
kubectl get pods -n postgres
kubectl logs -f deployment/postgres-postgresql -n postgres

# Redis
kubectl get pods -n redis
kubectl logs -f deployment/redis-master -n redis
```

### Gaming Services
```bash
# Pterodactyl
kubectl get pods -n pterodactyl
kubectl logs -f deployment/pterodactyl -n pterodactyl

# Minecraft
kubectl get pods -n minecraft
kubectl get gameservers -n minecraft
```

## Troubleshooting Quick Steps

### Service Not Starting
1. Check pod status: `kubectl get pods -n <namespace>`
2. Describe pod: `kubectl describe pod <pod-name> -n <namespace>`
3. View logs: `kubectl logs <pod-name> -n <namespace>`
4. Check events: `kubectl get events -n <namespace>`

### Can't Access Service
1. Check service exists: `kubectl get svc <name> -n <namespace>`
2. Check ingress: `kubectl get ingress -n <namespace>`
3. Verify DNS: `nslookup <service>.picklemustard.dev`
4. Check Traefik dashboard
5. Check firewall rules

### Storage Issues
1. Check PVC: `kubectl get pvc -n <namespace>`
2. Check PV: `kubectl get pv`
3. Check storage class: `kubectl get storageclass`
4. Check node disk space

### Authentication Issues
1. Check LLDAP: `kubectl get pods -n auth`
2. Check Authelia: `kubectl get pods -n lldap`
3. Verify secrets: `kubectl get secrets -n <namespace>`
4. Check secret references in deployment

## Deployment Quick Steps

### Deploy New Service
```bash
# 1. Create namespace
kubectl create namespace <namespace>

# 2. Create PVC
kubectl apply -f <service>-pvc.yml

# 3. Create ConfigMap/Secrets
kubectl apply -f <service>-configmap.yml
kubectl apply -f <service>-secrets.yml

# 4. Create Deployment
kubectl apply -f <service>-deployment.yml

# 5. Create Service
kubectl apply -f <service>-service.yml

# 6. Create Ingress
kubectl apply -f <service>-ingress.yml

# 7. Verify
kubectl get all -n <namespace>
```

### Update Service
```bash
# Update configuration
kubectl apply -f <service>-deployment.yml

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# Check status
kubectl rollout status deployment/<name> -n <namespace>
```

## Helm Commands

### List Helm Releases
```bash
helm list -A
```

### Install Chart
```bash
helm install --namespace <namespace> <name> <chart> -f values.yml
```

### Upgrade Chart
```bash
helm upgrade --namespace <namespace> <name> <chart> -f values.yml
```

### Uninstall Chart
```bash
helm uninstall --namespace <namespace> <name>
```

## Useful Utilities

### Port Forwarding
```bash
# Forward service to local port
kubectl port-forward -n <namespace> svc/<service> <local-port>:<service-port>

# Forward pod to local port
kubectl port-forward -n <namespace> <pod-name> <local-port>:<container-port>
```

### Execute Commands
```bash
# Get shell in pod
kubectl exec -it <pod-name> -n <namespace> -- sh

# Execute command
kubectl exec -n <namespace> <pod-name> -- <command>
```

### Copy Files
```bash
# Copy from pod
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file

# Copy to pod
kubectl cp ./local-file <namespace>/<pod-name>:/path/to/file
```

## Monitoring

### Resource Usage
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -n <namespace>

# Describe node
kubectl describe node <node-name>
```

### Logs
```bash
# All pods in namespace
kubectl logs -f --all-containers=true -n <namespace>

# Specific deployment
kubectl logs -f deployment/<name> -n <namespace>

# Previous pod logs
kubectl logs --previous <pod-name> -n <namespace>
```

## YAML Validation

### Dry Run
```bash
# Validate without applying
kubectl apply --dry-run=client -f <file.yml>
```

### Linting
```bash
# Use kube-linter if available
kube-lint <file.yml>

# Or use kubectl explain
kubectl explain <resource>
```

## Emergency Commands

### Rollback Deployment
```bash
# Check rollout history
kubectl rollout history deployment/<name> -n <namespace>

# Rollback to previous version
kubectl rollout undo deployment/<name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<revision>
```

### Scale Deployment
```bash
# Scale up
kubectl scale deployment/<name> --replicas=<count> -n <namespace>

# Scale down to zero
kubectl scale deployment/<name> --replicas=0 -n <namespace>
```

### Delete Resources
```bash
# Delete deployment
kubectl delete deployment/<name> -n <namespace>

# Delete all resources in namespace
kubectl delete all --all -n <namespace>

# Delete namespace (and all resources)
kubectl delete namespace <namespace>
```

## Git Workflow

```bash
# Pull latest changes
git pull origin main

# Check status
git status

# Add files
git add <files>

# Commit changes
git commit -m "message"

# Push changes
git push origin main
```

## Common Patterns

### Find pod by label
```bash
kubectl get pods -n <namespace> -l <label-key>=<label-value>
```

### Find services by port
```bash
kubectl get svc -A | grep <port>
```

### Get pod IP
```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.podIP}'
```

### Get service IP
```bash
kubectl get svc <service-name> -n <namespace> -o jsonpath='{.spec.clusterIP}'
```

## Notes

- Always use `--dry-run=client` to validate before applying
- Check logs before restarting pods
- Use namespaces to organize resources
- Label resources for easy management
- Document changes in commit messages
- Test in staging before production

## Support

For detailed documentation, see:
- [Cluster Overview](CLUSTER-OVERVIEW.md)
- [Individual Service Documentation](README.md)
- [Deployment Guide](../AGENTS.md)
