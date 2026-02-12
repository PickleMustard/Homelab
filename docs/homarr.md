# Homarr

Homarr is a sleek, modern dashboard that gives you access to all your self-hosted services in one place.

## Deployment

- **Type:** Kubernetes Deployment
- **Namespace:** `homarr`
- **Ingress:** `homarr-ingress.yml`
- **Port:** 7575

## Configuration

### Ingress
- **Ingress Class:** `traefik`
- **TLS:** Disabled (HTTP only)
- **Entrypoints:** `web`

### Hosts
- **External:** `dashboard.andromeda.picklemustard.dev`
- **Internal:** `dashboard.andromeda.picklemustard.home`
- **Path:** `/` (Prefix)
- **Path Type:** Prefix

### Service
- **Name:** `homarr`
- **Port:** 7575

## Features

### Dashboard
- Customizable widgets
- Service status monitoring
- Quick access to self-hosted apps
- Docker integration
- Search functionality
- Theme support (light/dark mode)

### Widgets
- Service cards with status
- Weather widget
- Calendar integration
- RSS feeds
- Media server widgets (Jellyfin, Plex)
- Docker container stats
- Custom iframe widgets

## Access

### URLs
- **External:** http://dashboard.andromeda.picklemustard.dev
- **Internal:** http://dashboard.andromeda.picklemustard.home

### Authentication
- Can be configured with basic auth
- Optional OAuth integration
- Supports custom authentication providers

## Deployment Commands

```bash
# Create namespace
kubectl create namespace homarr

# Apply ingress
kubectl apply -f homarr-ingress.yml

# Deploy Homarr (example - actual deployment file may vary)
kubectl apply -f homarr-deployment.yml
```

## Management

### Access Dashboard
```bash
# Check deployment status
kubectl get deployment -n homarr

# View logs
kubectl logs -f deployment/homarr -n homarr

# Port forward to test
kubectl port-forward -n homarr deployment/homarr 7575:7575
```

### Configuration
- Configuration is typically stored in a PVC or ConfigMap
- Widgets can be added/removed through the web UI
- Settings are persisted across restarts

## Integration

### Service Integration
- **Jellyfin:** Media server widget
- **Plex:** Media server widget
- **Sonarr/Radarr:** TV/Movie manager widgets
- **Prowlarr:** Indexer widget
- **Vaultwarden:** Password manager shortcut
- **Nextcloud:** Cloud storage widget
- **Authelia:** Authentication status
- **Custom URLs:** Any self-hosted service

### Docker Integration
- Display running containers
- Show container stats
- Quick access to container logs
- Restart containers from dashboard

### Other Services
- **Weather:** OpenWeatherMap integration
- **Calendar:** CalDAV calendar integration
- **RSS:** Feed reader widget
- **Custom Iframes:** Embed any web content

## Storage

If configured, Homarr typically uses:
- **Storage Class:** `local-path`
- **Access Mode:** `ReadWriteOnce`
- **Size:** Small (10-100Mi sufficient for config)

## Architecture

```
External Access
    ↓
Homarr Dashboard
    ↓
Service Links & Widgets
    ↓
Self-Hosted Services
    ├─ Jellyfin
    ├─ Vaultwarden
    ├─ Nextcloud
    ├─ Pterodactyl
    ├─ Authelia
    └─ Others
```

## Use Cases

### Dashboard View
- Central monitoring of all self-hosted services
- Quick access to frequently used apps
- Visual status of service health
- Single sign-on experience

### Management
- Start/stop Docker containers
- View service logs
- Monitor resource usage
- Restart services

### Information
- Weather display
- Calendar events
- RSS feed updates
- Custom notifications

## Related Services

- **Traefik:** Ingress controller for external access
- **All Self-Hosted Services:** Integrated as widgets in dashboard
- **Authelia:** Can provide SSO for dashboard

## Notes

- Currently configured without TLS - consider enabling for production
- Internal hostname allows access on home network without public internet
- Widgets can be customized for personal preferences
- Dashboard layout is responsive and mobile-friendly

## Troubleshooting

### Dashboard Not Loading
- Check pod status: `kubectl get pods -n homarr`
- View logs: `kubectl logs -f deployment/homarr -n homarr`
- Verify ingress: `kubectl get ingress -n homarr`
- Check Traefik routing

### Service Widgets Not Updating
- Verify service is running
- Check service URLs are correct
- Ensure services are accessible from the cluster
- Review widget configuration

### High CPU/Memory Usage
- Reduce number of active widgets
- Increase widget refresh intervals
- Check for stuck widgets or services

## Future Enhancements

- Enable TLS for secure external access
- Integrate with Authelia for SSO
- Add more service-specific widgets
- Configure automated backups
- Set up monitoring and alerts

## References

- **Documentation:** https://homarr.dev/
- **GitHub:** https://github.com/homarr-labs/Homarr
- **Demo:** Available on official website
